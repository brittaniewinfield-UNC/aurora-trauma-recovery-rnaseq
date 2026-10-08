# AURORA Longitudinal RNA-seq: Trauma Recovery

**What this is about, in plain terms:** after a traumatic event, some people recover while others go on to develop chronic pain, PTSD, or related symptoms. This study asks whether the body's early biological response to trauma -- not just one marker, but the coordinated behavior of the immune system, stress hormones, and gene expression together -- looks different in people who recover versus people who don't. Using paired blood samples from trauma survivors collected in the early aftermath of the trauma and again six months later, we find that recovery tracks with a robust, resolving immune and stress response, while chronic symptoms track with a more blunted or incomplete one. This repository contains the complete analysis code behind that finding, organized as one script per analysis step, each runnable and readable on its own.

Analysis code accompanying "Robust coordinated molecular response following trauma promotes recovery and protects against chronic pain and neuropsychiatric symptoms" (AURORA cohort).

Written in [Quarto](https://quarto.org) (`.qmd`). Each script renders to a fully annotated GitHub-flavored-markdown file (code + narrative + figures) via `quarto render`, viewable directly on GitHub.

## Repository structure

```
01_data_prep/                  Data loading, cleaning, and cohort/feature-matrix preparation
  01_libraries_helpers.qmd
  02_rna_data_and_cohorts.qmd      RNA-seq counts/log2 data; ED/6M and ED/2WK/6M cohort definitions
  03_metadata.qmd                  Clinical/survey metadata loading, merging, cleaning
  04_pid_inventory_and_export.qmd  Participant/inventory code mapping; processed RNA export
  05_cell_fractions.qmd            CIBERSORTx cell-fraction preparation
  06_hormones.qmd                  Biocrates hormone panel preparation
  07_cytokines.qmd                 Cytokine panel preparation
  08_crp.qmd                       CRP preparation
  09_transcription_factors.qmd     Transcription factor activity inference

02_primary_analyses/           Main ED-vs-6M manuscript analyses
  00_setup.R                       Shared libraries, helpers, base data load, checkpoint helpers (sourced by every script below -- not a standalone analysis)
  01_cohort_characteristics_table1.qmd
  02_apns_change_scores_and_odds_ratios.qmd
  03_trajectory_plots.qmd
  04a_differential_expression_core.qmd
  04b_deg_heatmap_and_volcano_plots.qmd      (Figure 2)
  05_fgsea.qmd
  06_reactome.qmd
  07_ed_vs_6m_cytokines_cellfractions_tfs_crp.qmd
  08_recovered_vs_chronic_cytokines_cellfractions_tfs_crp.qmd
  09_cell_by_gene_interactions.qmd
  10a_rrs_construction_and_evaluation.qmd
  10b_rrs_external_validation_painomics.qmd  (Figure 5)
  11_rrs_risk_resilience_factors.qmd
  12_rrs_hormones_cortisol.qmd
  13a_cmap_query_and_processing.qmd
  13b_cmap_plots_figure6.qmd                 (Figure 6)

03_two_week_subset_analyses/   Secondary analyses in the n=40 two-week subsample
  01_setup_and_functions.qmd
  02_differential_expression.qmd
  03_pathway_analyses.qmd
  04_transcription_factor_activity.qmd
  05_cell_fractions.qmd
  06_cytokines.qmd
  07_crp.qmd
  08_stable_genes_and_figure6_assembly.qmd

data/                          See data/README.md -- no participant-level data is included in this repository
```

## Data

**No raw or processed participant-level data is included in this repository, and none ever will be.** This is human-subjects trauma-cohort data (RNA-seq, clinical/survey measures, hormone/cytokine/CRP panels); it is deposited separately in **Harvard Dataverse** (see `data/README.md` for the access statement -- add the DOI once deposited).

Locally, this repo is meant to sit as a subfolder of your working project directory, alongside your local `Data/` folder and the various named analysis-output folders (`Differential Expression Analyses/`, `CMap Analysis Final/`, `RNA-based Recovery Score Final/`, etc.) -- i.e. exactly where they already are on your machine. Every script's setup chunk resolves a `data_root <- dirname(here::here())` one level up from this repo and both sets `knitr::opts_knit$set(root.dir = data_root)` (for rendering) and calls `setwd(data_root)` directly (so the same thing also works when you run chunks interactively in RStudio, which `opts_knit$set()` alone does not do). None of the 150+ existing relative file paths (`"Data/RNA Data/..."`, `"CMap Analysis Final/..."`, etc.) needed to change. git only tracks what's inside this folder, so none of that local data ever ends up in the commit history, regardless of `.gitignore`. A `Checkpoints/` folder is also created at that same level -- see "Script dependencies" below.

## How to run a script

1. Open this folder in RStudio (or VS Code with the R + Quarto extensions). `_quarto.yml` marks it as a Quarto project, so `here::here()` resolves correctly no matter which script you're in.
2. Make sure your local `Data/` and output folders are present one level up (see above).
3. Run `01_data_prep/` scripts first, in numbered order (01 through 09) -- they read raw/intermediate files and write the processed CSVs that `02_primary_analyses/` and `03_two_week_subset_analyses/` read back in.
4. Within `02_primary_analyses/`, run in numbered order -- `10a`/`10b` (RRS construction + external validation) must run before `03_two_week_subset_analyses/`, since the two-week scripts read the RRS scores those produce (`RNA-based Recovery Score Final/Final_RRS_Scores_Full_Cohort.csv`).
5. To render a script to its annotated markdown file: `quarto render 01_data_prep/01_libraries_helpers.qmd --to gfm`, or open it in RStudio and click Render. Each chunk currently has `eval: false` set at the project level (`_quarto.yml`) as a safety default since this is reference/reproduction code with long-running steps (elastic net modeling, CMap queries) -- flip it to `eval: true` per-script (or project-wide) once you're ready to actually execute a given script.

## Running everything at once

`run_all.R`, at the repo root, walks every script in order (the same order as "How to run a script" above) and either sources each one into your current R session or renders it with Quarto -- edit the `MODE`/`STAGES`/`START_AT` settings at the top of the file, then Source it in RStudio or run `Rscript run_all.R` from a terminal.

You only need to run through everything once. After that, every `Checkpoints/*.rds` file a script needs already exists on disk (see "Script dependencies" below), and you can open and run any single script on its own -- no need to replay everything upstream of it again. `START_AT` is there for resuming a partial run (e.g. after fixing an error partway through) without redoing the scripts before it.

## How to edit a script

Each file is self-contained and editable independently -- edit the `.qmd` directly in RStudio like you would any R Markdown file (the syntax is nearly identical; the only Quarto-specific part is the `#| option: value` chunk-option style in the setup chunk, which you can write more of as needed, e.g. `#| echo: false`). Every script in `02_primary_analyses/` sources a shared `00_setup.R` (libraries, helper functions/constants, and the base data load) and, where needed, reads a small number of objects that a *different*, earlier script in the folder computed -- see "Script dependencies" immediately below before you edit or reorder anything, since removing a `save_checkpoint()`/`read_checkpoint()` call will silently break a later script rather than erroring immediately.

## Script dependencies (`02_primary_analyses/`)

The original 9,289-line file these 16 scripts were split from relied on R Markdown chunks sharing one in-memory session -- some sections never wrote their results to disk because the next section just used the object directly. Splitting into separate files broke that. Every script now starts with:

```r
source(file.path(here::here(), "02_primary_analyses", "00_setup.R"))
```

which restores the packages, helper functions/constants, and base data load that almost all of them need (this is the restored "DATA PREP" section from the original file -- see "How this repository was built" below). A handful of scripts also depend on a specific *earlier* script's output. Each producing script calls `save_checkpoint(obj, "name")`, which writes `Checkpoints/name.rds` one level above this repo; each consuming script calls `read_checkpoint("name")` to read it back. This means:

- **Run order matters the first time.** A script that needs a checkpoint will stop with a clear error (naming the checkpoint and pointing back here) if you run it before its producer.
- **After that, every script is independently runnable and re-runnable** -- you do not need to keep re-running earlier scripts in the same R session, only once, in order, so the `Checkpoints/*.rds` files exist on disk.

| Script | Produces (checkpoint) | Needs (checkpoint, from) |
|---|---|---|
| `03_trajectory_plots.qmd` | `trajectory_lines` | -- |
| `04a_differential_expression_core.qmd` | `all_DEA_results`, `DEA_results_recovered`, `shared_DEGs_list`, `DEA_results_recovered_shared_summary` | -- |
| `04b_deg_heatmap_and_volcano_plots.qmd` | `DEG_heatmap` | `all_DEA_results`, `DEA_results_recovered` (04a); `trajectory_lines` (03) |
| `05_fgsea.qmd` | `GOBP_heatmap` | `all_DEA_results` (04a) |
| `06_reactome.qmd` | `Reactome_heatmap` | `all_DEA_results` (04a) |
| `07_ed_vs_6m_cytokines_cellfractions_tfs_crp.qmd` | `TF_data` | `all_DEA_results` (04a); `DEG_heatmap` (04b); `GOBP_heatmap` (05); `Reactome_heatmap` (06) |
| `08_recovered_vs_chronic_cytokines_cellfractions_tfs_crp.qmd` | -- | `TF_data` (07) |
| `09_cell_by_gene_interactions.qmd` | -- | `shared_DEGs_list` (04a) |
| `10a_rrs_construction_and_evaluation.qmd` | `RRS_AUC`, `RRS_full_cohort`, `beta_vec_final`, `final_stable_genes`, `p_holdout`, `p_train`, `meta_RRS_df` | `shared_DEGs_list`, `DEA_results_recovered_shared_summary` (04a) |
| `10b_rrs_external_validation_painomics.qmd` | -- | `RRS_AUC`, `RRS_full_cohort`, `beta_vec_final`, `final_stable_genes`, `p_holdout`, `p_train` (10a) |
| `11_rrs_risk_resilience_factors.qmd` | `regression_results_df_plot` | `meta_RRS_df` (10a) |
| `12_rrs_hormones_cortisol.qmd` | -- | `meta_RRS_df` (10a); `regression_results_df_plot` (11) |
| `13a_cmap_query_and_processing.qmd` | `all_cmap_results`, `mimicker_summary`, `opposer_summary` | -- |
| `13b_cmap_plots_figure6.qmd` | -- | `all_cmap_results`, `mimicker_summary`, `opposer_summary` (13a) |

Scripts not listed (`01`, `02`) only need `00_setup.R` and nothing else. A safe run order satisfying every row above: `01, 02, 03, 04a, 04b, 05, 06, 07, 08, 09, 10a, 10b, 11, 12, 13a, 13b`.

## How this repository was built

This structure was generated by splitting three original analysis notebooks into one file per analysis/figure, at clean chunk boundaries (every file was checked to have a balanced number of code-chunk fences, so no chunk was cut in half):

| Original file | Lines | Became |
|---|---|---|
| `AURORA Data Prep - v6.Rmd` | 1,519 | all of `01_data_prep/` (9 files, 1,519 lines -- full accounting, nothing dropped) |
| `v4 - AURORA Manuscript Analyses ED vs M6.Rmd` | 9,289 | all of `02_primary_analyses/` (16 files, 7,565 lines) |
| `v2 AURORA RNA Week 2 Analyses-SOMC39JC7TQKD.rmd` | 2,526 | all of `03_two_week_subset_analyses/` (8 files, 2,526 lines -- full accounting) |

For the main analyses file, 1,703 lines were not carried into any split file as their own script:
- Lines 22-220 ("DATA PREP"): package loads, shared helper functions/constants, the base data load, and a few derived objects (notably `metadata_RNA_paired`). This is *not* pure duplication of `01_data_prep` -- it reads the already cohort-filtered exports `01_data_prep` produces and does some additional lightweight derivation on top. It's preserved, unchanged, as `02_primary_analyses/00_setup.R`, sourced by every script in that folder (see "Script dependencies" above) rather than as its own numbered analysis script, since it's shared infrastructure rather than an analysis in its own right.
- Lines 1963-2220 and 8044-9289 (~450+ lines): sections explicitly labeled "Sarah grant 9-25" / "Sarah grant 9-26" in the source -- a CD177/neutrophil side-analysis and subsetted plot variants reusing manuscript objects, not part of the analyses reported in the paper. Excluded from this repository entirely per author decision.

Every other line of all three original files is preserved verbatim -- this was a structural reorganization, not a rewrite. Code was not re-executed or re-verified during this process.

## Issue found and fixed during review: orphaned code at the 13a/13b boundary

Original lines 7667-7680 (the tail of what became `13a_cmap_query_and_processing.qmd`) sat outside any code-chunk fence, immediately after a closing ` ``` ` with no opening ` ```{r} ` before it. Because it was unfenced, it was never executed as R code -- Quarto/R Markdown would have rendered it as literal text. On inspection it turned out to be a duplicate fragment of the bordered-plot loop from `04b_deg_heatmap_and_volcano_plots.qmd` (it referenced `all_plots` and `bordered_plots`, objects defined there, not in 13a/13b), apparently pasted in during editing and left dangling. It has been removed; nothing of substance was lost since it was dead code in the original file as well (it never ran).

## Dependencies (renv)

`_dependencies.R` lists every package this repo uses (CRAN and Bioconductor, scanned from all 33 scripts). To pin exact, reproducible versions from your own working R library:

```r
install.packages("renv")      # if you don't have it already
renv::init()                  # scans the project (incl. _dependencies.R), creates renv.lock
renv::snapshot()               # records the exact installed versions you're actually running on
```

Commit the resulting `renv.lock` (and `renv/activate.R`, `renv/settings.json` -- `renv::init()` creates a `renv/.gitignore` automatically that keeps the actual package library itself out of git). Anyone cloning the repo can then run `renv::restore()` to recreate your exact environment.

## License

MIT (see `LICENSE`) -- code only; see Data section above.
