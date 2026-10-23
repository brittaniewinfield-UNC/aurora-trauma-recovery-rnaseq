# "A robust coordinated molecular response following trauma promotes recovery and protects against chronic pain and neuropsychiatric symptoms" analysis code by Winfield et al.

## Summary 
This repository contains the analysis code behind a longitudinal multi-omic study of recovery from traumatic stress exposure, using paired whole-blood transcriptomic, immune cell, cytokine, and steroid hormone profiles collected from AURORA study participants at an initial emergency department visit and again six months later. Because prior work has largely examined single biological markers in cross-sectional cohorts, these analyses were designed to capture how transcriptional, innate immune, and stress-hormone biology change together over time, and to test whether that coordinated trajectory distinguishes individuals who recover from those who develop chronic posttraumatic neuropyschiatric symptoms. Each script corresponds to one analysis step and is runnable and readable independently.

## Abstract

The biological processes mediating recovery versus development of adverse posttraumatic neuropsychiatric sequelae (APNS) after traumatic stress exposure remain poorly understood. Here, we characterized longitudinal molecular trajectories among trauma survivors who recovered or had persistent APNS across ten domains (e.g., anxiety, pain). Recovery involved rapid widespread transcriptional changes signaling an early innate immune response that transitioned into homeostatic and wound-healing processes within two weeks and adaptive immunity by six months, whereas persistent APNS trajectories showed fewer molecular changes. To quantify this molecular program, we derived an externally validated RNA Recovery Score (RRS); individuals with higher RRS showed greater clinical recovery, elevated peritraumatic cortisol, and lower cumulative stress. Drug-response profiling identified candidate pathways and molecular interventions with potential to modulate the recovery-associated response. Together, these findings reveal posttraumatic recovery as an active, coordinated biological process and provide a framework for developing interventions that harness endogenous recovery mechanisms to prevent persistent APNS.


## Repository structure

Written in [Quarto](https://quarto.org) (`.qmd`). Each script renders to a fully annotated GitHub-flavored-markdown file (code + narrative + figures) via `quarto render`, viewable directly on GitHub.

```
01_data_prep/                  Data loading, cleaning, and cohort/feature-matrix preparation
  01_libraries_helpers.qmd
  02_rna_data_and_cohorts.qmd      RNA-seq counts/log2 data; ED/6M and ED/2WK/6M cohort definitions
  03_metadata.qmd                  Clinical/survey metadata loading, merging, cleaning
  04_pid_inventory_and_export.qmd  Participant/inventory code mapping; processed RNA export
  05_cell_fractions.qmd            CIBERSORTx cell-fraction preparation
  06_hormones.qmd                  Biocrates hormone panel preparation
  07_cytokines.qmd                 Cytokine panel preparation
  08_transcription_factors.qmd     Transcription factor activity inference

02_primary_analyses/           Main ED-vs-6M manuscript analyses
  00_setup.R                       Shared libraries, helpers, base data load, checkpoint helpers (sourced by every script below -- not a standalone analysis)
  01_cohort_characteristics_table1.qmd
  02_apns_change_scores_and_odds_ratios.qmd
  03_trajectory_plots.qmd
  04a_differential_expression_core.qmd
  04b_deg_heatmap_and_volcano_plots.qmd      
  05_fgsea.qmd
  06_ed_vs_6m_cytokines_cellfractions_tfs_crp.qmd
  07_cell_by_gene_interactions.qmd
  08a_rrs_construction_and_evaluation.qmd
  08b_rrs_external_validation_painomics.qmd  
  09_rrs_risk_resilience_factors.qmd
  10_rrs_hormones_cortisol.qmd
  11a_cmap_query_and_processing.qmd
  11b_cmap_plots_figure6.qmd                 

03_two_week_subset_analyses/   Secondary analyses in the n=40 two-week subsample
  01_setup_and_functions.qmd
  02_differential_expression.qmd
  03_pathway_analyses.qmd
  04_transcription_factor_activity.qmd
  05_cell_fractions.qmd
  06_cytokines.qmd
  07_stable_genes_and_figure6_assembly.qmd

data/                          See data/README.md -- no participant-level data is included in this repository
```

## Data

**No raw or processed participant-level data is included in this repository** This is human-subjects trauma-cohort data (RNA-seq, clinical/survey measures, hormone/cytokine/CRP panels); it is deposited separately in **UNC Dataverse** (see `data/README.md`).

Locally, this repo is meant to sit as a subfolder of your working project directory, alongside your local `Data/` folder and the various named analysis-output folders (`Differential Expression Analyses/`, `CMap Analysis Final/`, `RNA-based Recovery Score Final/`, etc.). Every script's setup chunk resolves a `data_root <- dirname(here::here())` one level up from this repo and both sets `knitr::opts_knit$set(root.dir = data_root)` (for rendering) and calls `setwd(data_root)` directly (so the same thing also works when you run chunks interactively in RStudio, which `opts_knit$set()` alone does not do). git only tracks what's inside this folder, so none of that local data ever ends up in the commit history, regardless of `.gitignore`. A `Checkpoints/` folder is also created at that same level -- see "Script dependencies" below.

## How to run a script

1. Open this folder in RStudio. `_quarto.yml` marks it as a Quarto project, so `here::here()` resolves correctly no matter which script you're in.
2. Make sure your local `Data/` and output folders are present one level up (see above).
3. Run `01_data_prep/` scripts first, in numbered order (01 through 09) -- they read raw/intermediate files and write the processed CSVs that `02_primary_analyses/` and `03_two_week_subset_analyses/` read back in.
4. Within `02_primary_analyses/` and `03_two_week_subset_analyses/`, run in numbered order
5. To render a script to its annotated markdown file: open it in RStudio and click Render. Each chunk currently has `eval: false` set at the project level (`_quarto.yml`) as a safety default since this is reference/reproduction code with long-running steps -- flip it to `eval: true` per-script (or project-wide) once you're ready to actually execute a given script.

## Running everything at once

`run_all.R`, at the repo root, walks every script in order (the same order as "How to run a script" above) and either sources each one into your current R session or renders it with Quarto -- edit the `MODE`/`STAGES`/`START_AT` settings at the top of the file, then Source it in RStudio or run `Rscript run_all.R` from a terminal.

You only need to run through everything once. After that, every `Checkpoints/*.rds` file a script needs already exists on disk (see "Script dependencies" below), and you can open and run any single script on its own. `START_AT` is there for resuming a partial run (e.g. after fixing an error partway through) without redoing the scripts before it.

## How to edit a script

Each file is self-contained and editable independently -- edit the `.qmd` directly in RStudio like you would any R Markdown file. Every script in `02_primary_analyses/` sources a shared `00_setup.R and, where needed, reads a small number of objects that a *different*, earlier script in the folder computed -- see "Script dependencies" immediately below before you edit or reorder anything.

## Script dependencies (`02_primary_analyses/`)

Every script starts with:

```r
source(file.path(here::here(), "02_primary_analyses", "00_setup.R"))
```

which restores the packages, helper functions/constants, and base data load that almost all of them need. A handful of scripts also depend on a specific *earlier* script's output. Each producing script calls `save_checkpoint(obj, "name")`, which writes `Checkpoints/name.rds` one level above this repo; each consuming script calls `read_checkpoint("name")` to read it back. This means:

- **Run order matters the first time.** A script that needs a checkpoint will stop with a clear error if you run it before its producer.
- **After that, every script is independently runnable and re-runnable** -- you do not need to keep re-running earlier scripts in the same R session, only once, in order, so the `Checkpoints/*.rds` files exist on disk.

| Script | Produces (checkpoint) | Needs (checkpoint, from) |
|---|---|---|
| `03_trajectory_plots.qmd` | `trajectory_lines` | -- |
| `04a_differential_expression_core.qmd` | `all_DEA_results`, `DEA_results_recovered`, `shared_DEGs_list`, `DEA_results_recovered_shared_summary` | -- |
| `04b_deg_heatmap_and_volcano_plots.qmd` | `DEG_heatmap` | `all_DEA_results`, `DEA_results_recovered` (04a); `trajectory_lines` (03) |
| `05_fgsea.qmd` | `GOBP_heatmap` | `all_DEA_results` (04a) |
| `06_ed_vs_6m_cytokines_cellfractions_tfs.qmd` | `TF_data` | `all_DEA_results` (04a); `DEG_heatmap` (04b); `GOBP_heatmap` (05); `Reactome_heatmap` (06) |
| `07_cell_by_gene_interactions.qmd` | -- | `shared_DEGs_list` (04a) |
| `08a_rrs_construction_and_evaluation.qmd` | `RRS_AUC`, `RRS_full_cohort`, `beta_vec_final`, `final_stable_genes`, `p_holdout`, `p_train`, `meta_RRS_df` | `shared_DEGs_list`, `DEA_results_recovered_shared_summary` (04a) |
| `08b_rrs_external_validation_painomics.qmd` | -- | `RRS_AUC`, `RRS_full_cohort`, `beta_vec_final`, `final_stable_genes`, `p_holdout`, `p_train` (10a) |
| `09_rrs_risk_resilience_factors.qmd` | `regression_results_df_plot` | `meta_RRS_df` (10a) |
| `10_rrs_hormones_cortisol.qmd` | -- | `meta_RRS_df` (10a); `regression_results_df_plot` (11) |
| `11a_cmap_query_and_processing.qmd` | `all_cmap_results`, `mimicker_summary`, `opposer_summary` | -- |
| `11b_cmap_plots_figure6.qmd` | -- | `all_cmap_results`, `mimicker_summary`, `opposer_summary` (13a) |

## Dependencies (renv)

`_dependencies.R` lists every package this repo uses (CRAN and Bioconductor). 

```r
install.packages("renv")      # if you don't have it already
renv::init()                  # scans the project (incl. _dependencies.R), creates renv.lock
renv::snapshot()               # records the exact installed versions you're actually running on
```

Commit the resulting `renv.lock` (and `renv/activate.R`, `renv/settings.json` -- `renv::init()` creates a `renv/.gitignore` automatically that keeps the actual package library itself out of git). To clone the repo  you can then run `renv::restore()` to recreate your exact environment.

## License

MIT (see `LICENSE`) -- code only; see Data section above.
