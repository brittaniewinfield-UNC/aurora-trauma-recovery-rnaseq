# =============================================================================
# run_all.R
#
# Runs every script in this repo, in the dependency order documented in
# README.md, either by sourcing each one's R code directly into your current
# session (fast, no file output beyond what the script itself writes) or by
# rendering it with Quarto (slower, but produces the annotated .md file each
# script is meant to leave behind).
#
# You only need to run this (or otherwise work through the files in order)
# ONCE per checkpoint -- see the "Script dependencies" section of README.md.
# After that, every script in 02_primary_analyses reads what it needs from
# Checkpoints/*.rds and runs on its own; you do not need to re-run this
# whole thing again just to edit one downstream script.
#
# Usage: edit the three settings below, then either click Source in RStudio
# or run from a terminal with:  Rscript run_all.R
# =============================================================================

MODE <- "source"   # "source" (fast, just runs the code) or "render" (slower,
                    # also writes each script's annotated .md via Quarto)

STAGES <- c("data_prep", "primary_analyses", "two_week")  # any subset, in this order

START_AT <- NULL   # NULL runs the whole selection. Or name a file (with or
                    # without the .qmd extension) to resume partway through,
                    # e.g. START_AT <- "04a_differential_expression_core"

# -----------------------------------------------------------------------------
# File lists, in the order required by README.md's dependency table. Don't
# reorder these without checking that table -- several files in
# 02_primary_analyses read a Checkpoints/*.rds file an earlier one writes.
# -----------------------------------------------------------------------------

FILES <- list(
  data_prep = file.path("01_data_prep", c(
    "01_libraries_helpers.qmd",
    "02_rna_data_and_cohorts.qmd",
    "03_metadata.qmd",
    "04_pid_inventory_and_export.qmd",
    "05_cell_fractions.qmd",
    "06_hormones.qmd",
    "07_cytokines.qmd",
    "08_crp.qmd",
    "09_transcription_factors.qmd"
  )),
  primary_analyses = file.path("02_primary_analyses", c(
    "01_cohort_characteristics_table1.qmd",
    "02_apns_change_scores_and_odds_ratios.qmd",
    "03_trajectory_plots.qmd",
    "04a_differential_expression_core.qmd",
    "04b_deg_heatmap_and_volcano_plots.qmd",
    "05_fgsea.qmd",
    "06_reactome.qmd",
    "07_ed_vs_6m_cytokines_cellfractions_tfs_crp.qmd",
    "08_recovered_vs_chronic_cytokines_cellfractions_tfs_crp.qmd",
    "09_cell_by_gene_interactions.qmd",
    "10a_rrs_construction_and_evaluation.qmd",
    "10b_rrs_external_validation_painomics.qmd",
    "11_rrs_risk_resilience_factors.qmd",
    "12_rrs_hormones_cortisol.qmd",
    "13a_cmap_query_and_processing.qmd",
    "13b_cmap_plots_figure6.qmd"
  )),
  two_week = file.path("03_two_week_subset_analyses", c(
    "01_setup_and_functions.qmd",
    "02_differential_expression.qmd",
    "03_pathway_analyses.qmd",
    "04_transcription_factor_activity.qmd",
    "05_cell_fractions.qmd",
    "06_cytokines.qmd",
    "07_crp.qmd",
    "08_stable_genes_and_figure6_assembly.qmd"
  ))
)

# -----------------------------------------------------------------------------
# Implementation -- shouldn't need to edit below this line.
# -----------------------------------------------------------------------------

repo_root <- here::here()
run_list <- unlist(FILES[STAGES], use.names = FALSE)

if (!is.null(START_AT)) {
  hit <- which(grepl(START_AT, run_list, fixed = TRUE))
  if (length(hit) == 0) {
    stop("START_AT '", START_AT, "' doesn't match any file in the selected STAGES.")
  }
  run_list <- run_list[hit[1]:length(run_list)]
}

run_one_by_sourcing <- function(qmd_path) {
  # Extracts just the R code from the .qmd (chunk-option comments like
  # `#| label: setup` are kept as plain R comments, which is harmless) and
  # sources it into the current global environment -- the same place your
  # objects land when you click "Run All" on a chunk-by-chunk basis.
  tmp_r <- tempfile(fileext = ".R")
  knitr::purl(qmd_path, output = tmp_r, documentation = 0, quiet = TRUE)
  on.exit(unlink(tmp_r), add = TRUE)
  source(tmp_r)
}

run_one_by_rendering <- function(qmd_path) {
  if (Sys.which("quarto") == "") {
    stop("Quarto CLI not found on PATH. Install it from https://quarto.org, ",
         "or set MODE <- \"source\" instead.")
  }
  # _quarto.yml sets eval: false project-wide as a safety default (see
  # README) -- override it for this render so the code actually executes.
  status <- system2("quarto", c("render", qmd_path, "--to", "gfm", "-M", "eval:true"))
  if (status != 0) {
    stop("quarto render failed for ", qmd_path, " (exit code ", status, ")")
  }
}

cat(sprintf("Running %d file(s) in MODE = \"%s\"\n", length(run_list), MODE))

for (f in run_list) {
  full_path <- file.path(repo_root, f)
  if (!file.exists(full_path)) stop("File not found: ", full_path)
  cat(sprintf("\n==== [%s] %s ====\n", toupper(MODE), f))
  t0 <- Sys.time()
  if (MODE == "source") {
    run_one_by_sourcing(full_path)
  } else if (MODE == "render") {
    run_one_by_rendering(full_path)
  } else {
    stop("MODE must be \"source\" or \"render\", not: ", MODE)
  }
  cat(sprintf("---- done in %.1f sec ----\n", as.numeric(Sys.time() - t0, units = "secs")))
}

cat(sprintf("\nAll %d requested file(s) completed.\n", length(run_list)))
