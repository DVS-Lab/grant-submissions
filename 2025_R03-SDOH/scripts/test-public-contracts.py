#!/usr/bin/env python3
"""Participant-free contract tests for scoring maps, sources, and public schemas."""

from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def numeric_vector(source: str, name: str) -> list[float]:
    match = re.search(rf"{re.escape(name)}\s*<-\s*c\(([^)]*)\)", source)
    require(match is not None, f"Missing vector {name}")
    return [float(value.strip()) for value in match.group(1).split(",")]


def main() -> int:
    project = Path(__file__).resolve().parents[1]
    scoring = (project / "code/pipeline/02_score_core_measures.R").read_text(encoding="utf-8")
    mac_setup = (project / "scripts/setup-macos.sh").read_text(encoding="utf-8")

    for required_fragment in (
        'expected_workbook_name="QualtricsData_SDOH_DEIDENTIFIED.xlsx"',
        '$HOME/Downloads/$expected_workbook_name',
        'mkdir -p',
        'git -C "$repo_root" check-ignore',
        'reference_r_version="4.5.2"',
        'install r-rig',
        'add "$reference_r_version"',
        'find_reference_rscript',
        'candidate_version=$(r_version_for "$candidate_path"',
        '/Library/Frameworks/R.framework/Versions/*/Resources/bin/Rscript',
        'install python@3.12',
    ):
        require(required_fragment in mac_setup, f"macOS setup contract missing: {required_fragment}")
    require("this script will not overwrite it" in mac_setup,
            "macOS setup must not overwrite a different private workbook")
    require('default "$reference_r_version"' not in mac_setup,
            "macOS setup must not address rig installations by patch-version name")

    oafem = csv_rows(project / "docs/oafem-item-map.csv")
    require(len(oafem) == 30, "OAFEM map must have 30 rows")
    weights = [int(row["severity_weight"]) for row in oafem]
    require({value: weights.count(value) for value in (1, 2, 3)} == {1: 11, 2: 6, 3: 13},
            "OAFEM severity counts changed")
    require('oafem_map <- c("no"=0,"suspected"=1,"yes"=2' in scoring,
            "OAFEM response map changed")
    require(numeric_vector(scoring, "oafem_weights") == weights,
            "OAFEM public map and scoring vector differ")

    require('promis_items <- paste0("promis_adult_", 1:29)' in scoring, "PROMIS item count changed")
    require("promis_items[18]" in scoring and "severity_reverse_map" in scoring,
            "PROMIS item 18 reverse map is missing")
    require("i in 21:24" in scoring and "social_reverse_map" in scoring,
            "PROMIS social-role reversal is missing")
    for name in ("pf_t", "anxiety_t", "depression_t", "fatigue_t", "sleep_t", "social_t", "pain_interference_t"):
        require(len(numeric_vector(scoring, name)) == 17, f"{name} must map raw scores 4:20")

    require('ctb_items <- paste0("cbt_adult_", 1:24)' in scoring, "CTB item count changed")
    require("valid_amounts <- c(0, 4, 8, 12, 16, 20)" in scoring, "CTB amount map changed")
    for block in ("ctb[1:6]", "ctb[7:12]", "ctb[13:18]", "ctb[19:24]"):
        require(block in scoring, f"CTB block missing: {block}")
    for output in ("fraud_lifetime_band", "fraud_lifetime_any", "fraud_12mo_band", "fraud_12mo_any"):
        require(output in scoring, f"Fraud output missing: {output}")

    expected_model_schema = {"outcome", "interaction_type", "term", "estimate", "std_error", "t_value", "p_value", "model_formula"}
    model_sets = [csv_rows(project / "derivatives/model-screening" / filename)
                  for filename in ("all-models.csv", "chetty-models.csv", "non-chetty-models.csv")]
    for models_for_file in model_sets:
        require(models_for_file and set(models_for_file[0]) == expected_model_schema,
                "Historical model-screen schema changed")
        require(not ({"study_id", "zip", "responseid", "participant", "email", "address"}
                     & {name.lower() for name in models_for_file[0]}),
                "Historical aggregate file contains a participant identifier field")
    models = model_sets[0]
    formulas = {row["model_formula"] for row in models}
    require(len(formulas) == 35, "Historical model-screen must contain 35 unique formulas")
    safe_formula = re.compile(r"^[A-Za-z0-9_. +*():~-]+$")
    require(all(formula.count("~") == 1 and safe_formula.fullmatch(formula) for formula in formulas),
            "Historical model formula is outside the allowed grammar")

    manifest = json.loads((project / "config/reproducibility-sources.json").read_text(encoding="utf-8"))
    ids = {source["id"] for source in manifest["sources"]}
    require(ids == {"uds_zip_zcta_2022", "rgc_sdi_2015_2019", "social_capital_atlas_zip_2022",
                    "acs_gini_2024", "ruca_zip_2020", "zcta_boundaries_2020", "acag_pm25_v5na05"},
            "Public source set changed")
    require("latest" not in json.dumps(manifest).lower(), "Mutable 'latest' reference found in source manifest")
    pm = next(source for source in manifest["sources"] if source["id"] == "acag_pm25_v5na05")
    require([item["year"] for item in pm["files"]] == list(range(2012, 2023)), "PM2.5 year set changed")
    sdi = next(source for source in manifest["sources"] if source["id"] == "rgc_sdi_2015_2019")
    require(len(sdi.get("fallback_urls", [])) == 1 and
            sdi["fallback_urls"][0].startswith("https://web.archive.org/web/20231213195651id_/"),
            "SDI must retain its fixed checksum-matched archival fallback")
    for source in manifest["sources"]:
        require(all(url.startswith("https://") for url in source.get("fallback_urls", [])),
                "Source fallback URLs must use HTTPS")
        items = source.get("files", [source])
        for item in items:
            require(re.fullmatch(r"[0-9a-f]{64}", item["sha256"]) is not None, "Invalid source SHA-256")
            require(item["bytes"] > 0 and item["url"].startswith("https://"), "Incomplete source pin")

    context_helpers = (project / "code/context/_context_helpers.R").read_text(encoding="utf-8")
    require('"--compressed"' in context_helpers and "entry$fallback_urls" in context_helpers,
            "Verified downloader must decode transport compression and try configured fallbacks")

    contract = json.loads((project / "config/reproduction-contract.json").read_text(encoding="utf-8"))
    require(contract["source_workbook"] == {"worksheets": 1, "rows": 709, "columns": 300},
            "Source-workbook contract changed")
    require(contract["analysis_master"] == {"rows": 709, "columns": 91}, "Analysis-master contract changed")
    require(contract["grant_framework"]["model_specifications"] == 216, "Grant model count changed")

    dictionary = csv_rows(project / "docs/analysis-master-dictionary.csv")
    required_dictionary_columns = {"variable", "construct", "role", "source", "calculation", "scale_units",
                                   "direction", "missing_data_rule", "status", "analysis_priority", "major_caveat"}
    require(set(dictionary[0]) == required_dictionary_columns, "Analysis dictionary schema changed")
    require(len(dictionary) == 91 and len({row["variable"] for row in dictionary}) == 91,
            "Analysis dictionary must contain 91 unique variables")
    dictionary_by_variable = {row["variable"]: row for row in dictionary}

    duration = dictionary_by_variable["demo_zip_prim_yr"]
    duration_text = " ".join(duration.values()).lower()
    require("zip code" not in duration_text and "five-digit zip" not in duration_text,
            "demo_zip_prim_yr must be documented as residence duration, not a ZIP code")

    geo = dictionary_by_variable["geo_f"]
    geo_text = f'{geo["source"]} {geo["calculation"]}'.lower()
    require("demo_quota" in geo_text and all(level in geo_text for level in ("urban", "suburban", "rural")),
            "geo_f must document its demo_quota-based Urban/Suburban/Rural reconstruction")

    oafem_missingness = dictionary_by_variable["oafem_weighted_total"]["missing_data_rule"].lower()
    require("requires all 30" not in oafem_missingness and "no items" in oafem_missingness,
            "Weighted OAFEM missingness must reflect available-item scoring")
    oafem_unweighted = dictionary_by_variable["oafem_unweighted_complete"]
    require(oafem_unweighted["scale_units"] == "0-60" and
            "0/1/2" in oafem_unweighted["calculation"],
            "Unweighted OAFEM diagnostic must be documented as a complete 0/1/2 sum")

    quota_text = " ".join(dictionary_by_variable["demo_quota"].values()).lower()
    require(all(level in quota_text for level in ("urban", "suburban", "rural")),
            "demo_quota must document the Urban/Suburban/Rural survey categories")

    race_text = " ".join(dictionary_by_variable["demo_race"].values()).lower()
    require("collapsed" not in race_text and "source categories retained" in race_text,
            "demo_race must document that the current master retains source categories")

    social_linkage = (project / "code/context/03_link_social_capital.R").read_text(encoding="utf-8")
    require("normalize_zip(link$zip_current)" in social_linkage and
            "match(current_zip, sc$zip)" in social_linkage and
            "zcta_current" not in social_linkage,
            "Social Capital linkage must use direct normalized current ZIP without ZCTA fallback")
    for relative in ("docs/context-exposure-map.md", "docs/context-data-sources.md"):
        linkage_doc = (project / relative).read_text(encoding="utf-8").lower().replace("-", " ")
        require("direct" in linkage_doc and "current zip" in linkage_doc and
                ("no zcta fallback" in linkage_doc or "do not substitute" in linkage_doc),
                f"{relative} must document direct current-ZIP Social Capital linkage without fallback")

    print("Public SDOH scoring/source/schema contract tests passed (no participant data used).")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
