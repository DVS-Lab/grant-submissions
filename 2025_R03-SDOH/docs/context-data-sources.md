# Context data sources

This readable inventory records provenance only. The machine-readable authority
used by the code is `config/reproducibility-sources.json`. The private
`private-data/reference/source-manifest.csv` additionally records retrieval
dates, local filenames, and SHA256 checksums; it remains ignored because it is
an operational local cache inventory.

## ZIP to ZCTA

- Source: archived 2022 UDS Mapper ZIP-to-ZCTA crosswalk, mirrored by the
  open-source `uds-mapper` project.
- Download: immutable commit URL recorded in the public source manifest.
- Geography: five-digit ZIP to ZCTA, with ZIP type and join type.
- Use: current ZIP is primary; childhood ZIP is feasibility-only.

## Social Deprivation Index

- Organization: Robert Graham Center / American Academy of Family Physicians.
- Release: ZCTA SDI based on ACS 2015–2019.
- Documentation: <https://www.graham-center.org/evidence-based-research/featured-work/social-deprivation-index>
- Download: <https://www.aafp.org/assets/raw/upload/v1779124857/asset_rgc_sdi_2015_through_2019_zcta.csv>
- Direction: higher scores indicate greater social deprivation.

## PM2.5

- Organization: Washington University Atmospheric Composition Analysis Group.
- Product: V5.NA.05 North American hybrid annual PM2.5 grids; annual 2012–2022
  files selected to mirror the lab's prior exposure window.
- Documentation/download folder: <https://sites.wustl.edu/acag/datasets/surface-pm2-5/>
- Geography/resolution: 0.01° North America grid (approximately 1 km).
- Aggregation: grid cells intersecting 2020 Census ZCTA polygons at 1:500,000;
  overlap fractions are weighted by cosine(latitude) to approximate surface
  area. The result is area weighted, not population weighted.
- Units: µg/m³. License: CC BY 4.0 as stated for the ACAG data product.
- Boundary: <https://www2.census.gov/geo/tiger/GENZ2020/shp/cb_2020_us_zcta520_500k.zip>

## Social Capital Atlas

- Organization: Opportunity Insights.
- Release: 2022 ZIP-level Social Capital Atlas data.
- Study page: <https://opportunityinsights.org/paper/social-capital-ii-determinants-of-economic-connectedness/>
- Download: <https://data.humdata.org/dataset/85ee8e10-0c66-4635-b997-79b6fad44c71/resource/ab878625-279b-4bef-a2b3-c132168d536e/download/social_capital_zip.csv>
- Variables: economic connectedness, high-SES exposure, friending bias,
  clustering, support ratio, volunteering rate, and civic organizations.
- Geography: Social Capital source ZIP matched directly to normalized
  participant current ZIP. The primary variables do not use the ZIP-to-ZCTA
  crosswalk and do not substitute a ZCTA value when the direct ZIP is unmatched.

## Income inequality

- Organization: U.S. Census Bureau.
- Product: fixed ACS 2024 five-year table-based summary file B19083, estimate B19083_E001.
- Geography: ZCTA. Range: 0–1.
- Download: the fixed official Census file recorded in the public source manifest.
- The code downloads the national table and filters ZCTA rows locally; it never
  sends a participant-derived ZCTA list.

## Rural–Urban Commuting Area codes

- Organization: USDA Economic Research Service.
- Product: 2020 RUCA codes by ZIP, released/updated in 2025.
- Documentation: <https://www.ers.usda.gov/data-products/rural-urban-commuting-area-codes>
- Download: <https://www.ers.usda.gov/media/5444/2020-rural-urban-commuting-area-codes-zip-codes.csv?v=49164>
- The project retains the primary 1–10 code and groups 1–3 as metropolitan,
  4–6 micropolitan, 7–9 small town, and 10 rural.
- Geography: direct source-ZIP to participant-current-ZIP match, independent of
  the ZIP-to-ZCTA crosswalk.

## Sources deliberately not linked

- Neighborhood Atlas ADI: no ZIP variable was created. The intended source
  geography is census block group and files are credentialed; any future
  ZCTA approximation must be explicitly labeled and use documented weights.
- Crime/disorder: FBI/UCR and academic sources were reviewed, but no consistent
  national contemporary ZIP/ZCTA product was found. A private source-audit
  memorandum records the options and tradeoffs.
