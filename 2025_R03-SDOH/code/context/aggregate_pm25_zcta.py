#!/usr/bin/env python3
"""Download pinned public PM2.5 inputs and area-weight them to private study ZCTAs."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import geopandas as gpd
import numpy as np
import pandas as pd
import rasterio
import xarray as xr
from exactextract import exact_extract
from exactextract.raster import RasterioRasterSource
from rasterio.io import MemoryFile
from rasterio.transform import from_origin


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def log_cache(source_id: str, filename: str, action: str) -> None:
    path = os.environ.get("SDOH_CACHE_LOG")
    if path:
        with open(path, "a", encoding="utf-8") as stream:
            stream.write(f"{source_id}\t{filename}\t{action}\n")


def valid_file(path: Path, item: dict) -> bool:
    return (path.exists() and path.stat().st_size == int(item["bytes"])
            and sha256(path).lower() == item["sha256"].lower())


def download_verified(source_id: str, item: dict, destination: Path) -> None:
    if valid_file(destination, item):
        log_cache(source_id, item["local_filename"], "reused")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(f"{destination}.part")
    temporary.unlink(missing_ok=True)
    request = urllib.request.Request(item["url"], headers={"User-Agent": "SDOH-reproduction/1"})
    last_error: Exception | None = None
    for attempt in range(1, 4):
        try:
            print(f"Downloading pinned public reference: {destination.name} (attempt {attempt}/3)", flush=True)
            with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as out:
                while chunk := response.read(1024 * 1024):
                    out.write(chunk)
            if not valid_file(temporary, item):
                raise ValueError(f"checksum or byte-size mismatch for {item['local_filename']}")
            temporary.replace(destination)
            log_cache(source_id, item["local_filename"], "downloaded")
            return
        except (OSError, urllib.error.URLError, ValueError) as exc:
            last_error = exc
            temporary.unlink(missing_ok=True)
            if attempt < 3:
                time.sleep(2 ** (attempt - 1))
    raise RuntimeError(f"Failed to retrieve verified source {source_id}: {last_error}")


def atomic_csv(frame: pd.DataFrame, destination: Path) -> None:
    temporary = destination.with_name(f".{destination.name}.part")
    frame.to_csv(temporary, index=False)
    temporary.replace(destination)


def load_sources(path: Path) -> tuple[dict, dict]:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    by_id = {item["id"]: item for item in manifest["sources"]}
    try:
        return by_id["acag_pm25_v5na05"], by_id["zcta_boundaries_2020"]
    except KeyError as exc:
        raise ValueError(f"Source manifest is missing {exc.args[0]}") from exc


def netcdf_raster(path: Path):
    data = xr.open_dataset(path)["GWRPM25"].squeeze(drop=True)
    lat = np.asarray(data["lat"].values, dtype=float)
    lon = np.asarray(data["lon"].values, dtype=float)
    values = np.asarray(data.values, dtype="float32")
    if values.shape != (lat.size, lon.size):
        raise ValueError(f"Unexpected grid shape in {path.name}: {values.shape}")
    if lat[0] < lat[-1]:
        values = np.flipud(values)
        lat = lat[::-1]
    dx = float(np.median(np.abs(np.diff(lon))))
    dy = float(np.median(np.abs(np.diff(lat))))
    transform = from_origin(lon.min() - dx / 2, lat.max() + dy / 2, dx, dy)
    profile = {
        "driver": "GTiff", "height": values.shape[0], "width": values.shape[1],
        "count": 1, "dtype": "float32", "crs": "EPSG:4326", "transform": transform,
        "nodata": -9999.0, "compress": "deflate", "tiled": True,
    }
    values[~np.isfinite(values)] = profile["nodata"]
    return values, lat, profile


def aggregate_year(path: Path, polygons: gpd.GeoDataFrame) -> pd.DataFrame:
    values, lat, profile = netcdf_raster(path)
    area_weights = np.repeat(np.cos(np.deg2rad(lat)).astype("float32")[:, None], values.shape[1], axis=1)
    with MemoryFile() as value_memory, MemoryFile() as weight_memory:
        with value_memory.open(**profile) as value_ds, weight_memory.open(**profile) as weight_ds:
            value_ds.write(values, 1)
            weight_ds.write(area_weights, 1)
            result = exact_extract(
                RasterioRasterSource(value_ds), polygons, ["weighted_mean"],
                weights=RasterioRasterSource(weight_ds), include_cols=["ZCTA5CE20"],
                output="pandas", strategy="feature-sequential",
            )
    return result.rename(columns={"weighted_mean": "pm25"})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference-dir", required=True, type=Path)
    parser.add_argument("--derived-dir", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()
    pm_source, boundary_source = load_sources(args.manifest)
    args.reference_dir.mkdir(parents=True, exist_ok=True)
    args.derived_dir.mkdir(parents=True, exist_ok=True)

    for item in pm_source["files"]:
        download_verified(pm_source["id"], item, args.reference_dir / item["local_filename"])
    boundary = args.reference_dir / boundary_source["local_filename"]
    download_verified(boundary_source["id"], boundary_source, boundary)

    linkage = pd.read_csv(args.derived_dir / "zip-zcta-linkage-private.csv", dtype=str)
    requested = set(linkage["zcta_current"].dropna().str.zfill(5))
    polygons = gpd.read_file(f"zip://{boundary}")
    if "ZCTA5CE20" not in polygons:
        raise ValueError("2020 Census ZCTA boundary lacks ZCTA5CE20")
    polygons = polygons[polygons["ZCTA5CE20"].isin(requested)].to_crs("EPSG:4326")
    missing_shapes = sorted(requested - set(polygons["ZCTA5CE20"]))
    if missing_shapes:
        print(f"Warning: {len(missing_shapes)} linked ZCTAs lack a 2020 boundary.", file=sys.stderr)

    annual_frames = []
    for item in sorted(pm_source["files"], key=lambda value: value["year"]):
        print(f"Area-weighting ACAG PM2.5 for {item['year']}", flush=True)
        frame = aggregate_year(args.reference_dir / item["local_filename"], polygons)
        frame["year"] = item["year"]
        annual_frames.append(frame)
    annual = pd.concat(annual_frames, ignore_index=True)
    annual = annual.rename(columns={"ZCTA5CE20": "zcta"})[["zcta", "year", "pm25"]]
    atomic_csv(annual, args.derived_dir / "pm25-zcta-annual.csv")

    summary = annual.groupby("zcta", as_index=False).agg(
        pm25_2012_2022_zcta=("pm25", "mean"), pm25_variability=("pm25", "std"),
        pm25_years_available=("pm25", "count"),
    )
    recent = annual[annual["year"].between(2018, 2022)].groupby("zcta")["pm25"].mean()
    summary["pm25_recent_mean"] = summary["zcta"].map(recent)
    lookup = summary.set_index("zcta")
    out = pd.DataFrame({"study_id": linkage["study_id"]})
    for column in ["pm25_2012_2022_zcta", "pm25_recent_mean", "pm25_variability", "pm25_years_available"]:
        out[column] = linkage["zcta_current"].map(lookup[column])
    atomic_csv(out, args.derived_dir / "context-pm25.csv")

    checksums = [{"year": item["year"], "filename": item["local_filename"],
                  "sha256": sha256(args.reference_dir / item["local_filename"])}
                 for item in pm_source["files"]]
    atomic_csv(pd.DataFrame(checksums), args.reference_dir / "pm25" / "annual-file-checksums.csv")
    print(f"PM2.5 linkage complete for {out['pm25_2012_2022_zcta'].notna().sum()} participants.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
