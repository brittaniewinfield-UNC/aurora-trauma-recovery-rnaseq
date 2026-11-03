# run_all.R
#
# Runs every script in this repo, in the dependency order documented in
# README.md, either by sourcing each one's R code directly into your current
# session 
#
# You only need to run this (or otherwise work through the files in order)
# ONCE per checkpoint -- see the "Script dependencies" section of README.md.
# After that, every script in 02_primary_analyses reads what it needs from
# Checkpoints/*.rds and runs on its own; you do not need to re-run this
# whole thing again just to edit one downstream script.
#
# Usage: edit the three settings below, then either click Source in RStudio
# or run from a terminal with:  Rscript run_all.R


MODE <- "source"   # "source" 

STAGES <- c("data_prep", "primary_analyses", "two_week")  

START_AT <- NULL  
                  
FILES <- list(
  data_prep = file.path("01_data_prep", c(
    "01_libraries_helpers.qmd",
    "02_rna_data_and_cohorts.qmd",
    "03_metadata.qmd",
    "04_pid_inventory_and_export.qmd",
    "05_cell_fractions.qmd",
    "06_hormones.qmd",
    "07_cytokines.qmd",
    "08_transcription_factors.qmd")),
  primary_analyses = file.path("02_primary_analyses", c(
    "01_cohort_characteristics_table1.qmd",
    "02_apns_change_scores_and_odds_ratios.qmd",
    "03_trajectory_plots.qmd",
    "04a_differential_expression_core.qmd",
    "04b_deg_heatmap_and_volcano_plots.qmd",
    "05_fgsea.qmd",
    "06_ed_vs_6m_cytokines_cellfractions_tfs_crp.qmd",
    "07_cell_by_gene_interactions.qmd",
    "8a_rrs_construction_and_evaluation.qmd",
    "8b_rrs_external_validation_painomics.qmd",
    "9_rrs_risk_resilience_factors.qmd",
    "10_rrs_hormones_cortisol.qmd",
    "11a_cmap_query_and_processing.qmd",
    "11b_cmap_plots_figure6.qmd")),
  two_week = file.path("03_two_week_subset_analyses", c(
    "01_differential_expression.qmd",
    "02_pathway_analyses.qmd",
    "03_transcription_factor_activity.qmd",
    "04_cell_fractions.qmd",
    "05_cytokines.qmd",
    "06_stable_genes_and_figure6_assembly.qmd")))

# Implementation -- shouldn't need to edit below this line.


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
