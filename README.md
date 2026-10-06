# AURORA Longitudinal RNA-seq: Trauma Recovery

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

Locally, this repo is meant to sit as a subfolder of your working project directory, alongside your local `Data/` folder and the various named analysis-output folders (`Differential Expression Analyses/`, `CMap Analysis Final/`, `RNA-based Recovery Score Final/`, etc.) -- i.e. exactly where they already are on your machine. Every script's setup chunk points its working directory one level up from this repo (`knitr::opts_knit$set(root.dir = dirname(here::here()))`), so none of the 150+ existing relative file paths (`"Data/RNA Data/..."`, `"CMap Analysis Final/..."`, etc.) needed to change. git only tracks what's inside this folder, so none of that local data ever ends up in the commit history, regardless of `.gitignore`.

## How to run a script

1. Open this folder in RStudio (or VS Code with the R + Quarto extensions). `_quarto.yml` marks it as a Quarto project, so `here::here()` resolves correctly no matter which script you're in.
2. Make sure your local `Data/` and output folders are present one level up (see above).
3. Run `01_data_prep/` scripts first, in numbered order (01 through 09) -- they read raw/intermediate files and write the processed CSVs that `02_primary_analyses/` and `03_two_week_subset_analyses/` read back in.
4. Within `02_primary_analyses/`, run in numbered order -- `10a`/`10b` (RRS construction + external validation) must run before `03_two_week_subset_analyses/`, since the two-week scripts read the RRS scores those produce (`RNA-based Recovery Score Final/Final_RRS_Scores_Full_Cohort.csv`).
5. To render a script to its annotated markdown file: `quarto render 01_data_prep/01_libraries_helpers.qmd --to gfm`, or open it in RStudio and click Render. Each chunk currently has `eval: false` set at the project level (`_quarto.yml`) as a safety default since this is reference/reproduction code with long-running steps (elastic net modeling, CMap queries) -- flip it to `eval: true` per-script (or project-wide) once you're ready to actually execute a given script.

## How to edit a script

Each file is self-contained and editable independently -- edit the `.qmd` directly in RStudio like you would any R Markdown file (the syntax is nearly identical; the only Quarto-specific part is the `#| option: value` chunk-option style in the setup chunk, which you can write more of as needed, e.g. `#| echo: false`). Because these were split from larger files, a script may still reference an object or function defined earlier in what's now a *different* file within the same stage -- if you hit an "object not found" error, check whether it's created by an earlier-numbered script in the same folder and run that first.

## How this repository was built

This structure was generated by splitting three original analysis notebooks into one file per analysis/figure, at clean chunk boundaries (every file was checked to have a balanced number of code-chunk fences, so no chunk was cut in half):

| Original file | Lines | Became |
|---|---|---|
| `AURORA Data Prep - v6.Rmd` | 1,519 | all of `01_data_prep/` (9 files, 1,519 lines -- full accounting, nothing dropped) |
| `v4 - AURORA Manuscript Analyses ED vs M6.Rmd` | 9,289 | all of `02_primary_analyses/` (16 files, 7,565 lines) |
| `v2 AURORA RNA Week 2 Analyses-SOMC39JC7TQKD.rmd` | 2,526 | all of `03_two_week_subset_analyses/` (8 files, 2,526 lines -- full accounting) |

For the main analyses file, 1,703 lines were intentionally not carried into any split file:
- Lines 22-220: a duplicate data-preparation block (library loading, cohort determination) that re-derived what `01_data_prep` already produces. `01_data_prep` is now the single source of truth for these objects.
- Lines 1963-2220 and 8044-9289 (~450+ lines): sections explicitly labeled "Sarah grant 9-25" / "Sarah grant 9-26" in the source -- a CD177/neutrophil side-analysis and subsetted plot variants reusing manuscript objects, not part of the analyses reported in the paper. Excluded from this repository entirely per author decision.

Every other line of all three original files is preserved verbatim -- this was a structural reorganization, not a rewrite. Code was not re-executed or re-verified during this process.

## Known issue carried over from the source files

`02_primary_analyses/13b_cmap_plots_figure6.qmd` (original lines 7667-7680) contains R code that sits outside any code-chunk fence in the source document -- this looks like a missing or misplaced chunk delimiter in the original, not something introduced by splitting. It was preserved verbatim rather than silently "fixed." Needs author review.

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
