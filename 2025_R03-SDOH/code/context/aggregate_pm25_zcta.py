#!/usr/bin/env python3
"""Download ACAG annual PM2.5 grids and area-weight them to study ZCTAs.

Participant geography never leaves the local machine: all remote requests are
fixed public national files, and the private ZCTA list is read only after those
files have been cached.
"""

from __future__ import annotations

import argparse
import hashlib
import math
import sys
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


PM25_SHARED_NAME = "c3lmvqrvbjcrfpqoxb68nwl9tqhkl81g"
PM25_FILES = {
    2012: ("1754603492661", "V5NA05.HybridPM25.NorthAmerica.2012001-2012366.nc"),
    2013: ("1754602504541", "V5NA05.HybridPM25.NorthAmerica.2013001-2013365.nc"),
    2014: ("1754596682182", "V5NA05.HybridPM25.NorthAmerica.2014001-2014365.nc"),
    2015: ("1754593833587", "V5NA05.HybridPM25.NorthAmerica.2015001-2015365.nc"),
    2016: ("1754598627620", "V5NA05.HybridPM25.NorthAmerica.2016001-2016366.nc"),
    2017: ("1754605120234", "V5NA05.HybridPM25.NorthAmerica.2017001-2017365.nc"),
    2018: ("1754596084589", "V5NA05.HybridPM25.NorthAmerica.2018001-2018365.nc"),
    2019: ("1754599987175", "V5NA05.HybridPM25.NorthAmerica.2019001-2019365.nc"),
    2020: ("1754597327085", "V5NA05.HybridPM25.NorthAmerica.2020001-2020366.nc"),
    2021: ("1754599202283", "V5NA05.HybridPM25.NorthAmerica.2021001-2021365.nc"),
    2022: ("1754595614364", "V5NA05.HybridPM25.NorthAmerica.2022001-2022364.nc"),
}
ZCTA_URL = "https://www2.census.gov/geo/tiger/GENZ2020/shp/cb_2020_us_zcta520_500k.zip"
ZCTA_NAME = "cb_2020_us_zcta520_500k.zip"


def download(url: str, destination: Path) -> None:
    if destination.exists() and destination.stat().st_size > 10_000:
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".part")
    print(f"Downloading public reference: {destination.name}", flush=True)
    with urllib.request.urlopen(url) as response, temporary.open("wb") as out:
        while chunk := response.read(1024 * 1024):
            out.write(chunk)
    temporary.replace(destination)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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
    # cos(latitude) corrects the longitude-width component of geographic cell
    # area. exactextract then multiplies these weights by polygon coverage.
    area_weights = np.repeat(np.cos(np.deg2rad(lat)).astype("float32")[:, None], values.shape[1], axis=1)
    with MemoryFile() as value_memory, MemoryFile() as weight_memory:
        with value_memory.open(**profile) as value_ds, weight_memory.open(**profile) as weight_ds:
            value_ds.write(values, 1)
            weight_ds.write(area_weights, 1)
            result = exact_extract(
                RasterioRasterSource(value_ds), polygons, ["weighted_mean"],
                weights=RasterioRasterSource(weight_ds),
                include_cols=["ZCTA5CE20"], output="pandas", strategy="feature-sequential",
            )
    return result.rename(columns={"weighted_mean": "pm25"})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference-dir", required=True, type=Path)
    parser.add_argument("--derived-dir", required=True, type=Path)
    args = parser.parse_args()
    pm_dir = args.reference_dir / "pm25"
    pm_dir.mkdir(parents=True, exist_ok=True)
    args.derived_dir.mkdir(parents=True, exist_ok=True)

    for year, (file_id, filename) in PM25_FILES.items():
        url = (
            "https://wustl.app.box.com/index.php?rm=box_download_shared_file"
            f"&shared_name={PM25_SHARED_NAME}&file_id=f_{file_id}"
        )
        download(url, pm_dir / filename)
    boundary = args.reference_dir / ZCTA_NAME
    download(ZCTA_URL, boundary)

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
    for year, (_, filename) in sorted(PM25_FILES.items()):
        print(f"Area-weighting ACAG PM2.5 for {year}", flush=True)
        frame = aggregate_year(pm_dir / filename, polygons)
        frame["year"] = year
        annual_frames.append(frame)
    annual = pd.concat(annual_frames, ignore_index=True)
    annual = annual.rename(columns={"ZCTA5CE20": "zcta"})[["zcta", "year", "pm25"]]
    annual.to_csv(args.derived_dir / "pm25-zcta-annual.csv", index=False)

    summary = annual.groupby("zcta", as_index=False).agg(
        pm25_2012_2022_zcta=("pm25", "mean"),
        pm25_variability=("pm25", "std"),
        pm25_years_available=("pm25", "count"),
    )
    recent = annual[annual["year"].between(2018, 2022)].groupby("zcta")["pm25"].mean()
    summary["pm25_recent_mean"] = summary["zcta"].map(recent)
    lookup = summary.set_index("zcta")
    out = pd.DataFrame({"study_id": linkage["study_id"]})
    for column in ["pm25_2012_2022_zcta", "pm25_recent_mean", "pm25_variability", "pm25_years_available"]:
        out[column] = linkage["zcta_current"].map(lookup[column])
    out.to_csv(args.derived_dir / "context-pm25.csv", index=False)

    manifest_rows = []
    for year, (_, filename) in sorted(PM25_FILES.items()):
        manifest_rows.append({"year": year, "filename": filename, "sha256": sha256(pm_dir / filename)})
    pd.DataFrame(manifest_rows).to_csv(pm_dir / "annual-file-checksums.csv", index=False)
    print(f"PM2.5 linkage complete for {out['pm25_2012_2022_zcta'].notna().sum()} participants.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
