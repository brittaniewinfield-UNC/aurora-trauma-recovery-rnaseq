# Data availability

This repository contains analysis code only. It does not contain, and will never contain, raw or processed participant-level data.

This study uses human-subjects data from the AURORA (Advancing Understanding of RecOvery afteR traumA) cohort, including whole-blood RNA-seq, clinical/survey measures, and biomarker panels (hormones, cytokines, CRP). Because this is identifiable or potentially re-identifiable human-subjects data, it is not distributed through this public GitHub repository under any circumstances.

Participant-level data for this study is/will be made available through **Harvard Dataverse** at [add the Dataverse DOI/link here once deposited]. See the manuscript's Data Availability statement for the current access process.

Scripts in this repository read data via relative paths from a local `Data/` directory (and several named analysis-output directories) that are **not part of this repository** -- see the top-level README for how local paths are configured. To run these scripts, place or point to a local copy of the data obtained from Dataverse.

External validation data (PainOMICs cohort) used in `02_primary_analyses/10b_rrs_external_validation_painomics.Rmd` is drawn from a public GEO series -- the accession number should be added here once confirmed.
