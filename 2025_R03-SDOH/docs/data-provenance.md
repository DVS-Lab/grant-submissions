# SDOH data provenance

The preserved code expects an access-controlled analytic source derived from the
project's survey collection. That source remains outside this repository.

The scoring workflow:

1. reads the path in `SDOH_SOURCE_DATA` while skipping the exact-DOB field;
2. applies the existing attention-check passing value of `3` using the reviewed
   column named in `SDOH_ATTENTION_CHECK_FIELD`;
3. retains only an explicit demographic field list for analytic scoring;
4. calculates instrument scores without changing the existing scoring rules;
5. joins row-level scores using the private Qualtrics response key; and
6. writes all row-level outputs to `SDOH_PRIVATE_DERIVATIVES_DIR`, an ignored
   private location.

Exploratory analyses read the private scoring master from `SDOH_PRIVATE_MASTER`.
Full ZIP/address data needed for GIS work should remain in the controlled source
environment and should not flow into public derivatives.

The public repository currently contains code, documentation, aggregate figures,
and a non-row-level analytic variable dictionary only. It does not contain an
approved public participant dataset.
