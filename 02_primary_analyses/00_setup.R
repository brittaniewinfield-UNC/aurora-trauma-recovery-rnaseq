# =============================================================================
# 00_setup.R
#
# Shared setup for every script in 02_primary_analyses/.
#
# When `v4 - AURORA Manuscript Analyses ED vs M6.Rmd` was split into the 16
# per-analysis scripts in this folder, its "# DATA PREP" section (original
# lines 22-220) was intentionally left out, per the decision to consolidate
# data prep into 01_data_prep/. That section was not pure duplication of
# 01_data_prep, though: it also loaded packages, defined helper
# functions/constants used throughout almost every downstream script, and
# computed a few small derived objects -- most importantly
# `metadata_RNA_paired` -- that are not produced anywhere else. Splitting the
# file without restoring this left every script below missing objects it
# needs. This file restores exactly that section, unchanged, so every script
# can `source()` it and run on its own.
#
# This does NOT re-derive the ED-M6 cohort from raw/unfiltered data -- it
# reads the exports 01_data_prep/04_pid_inventory_and_export.qmd already
# writes, which are already filtered to the 245-participant / 490-paired-
# sample ED-M6 cohort used throughout the manuscript.
#
# Usage, at the top of every script's setup chunk:
#   source(file.path(here::here(), "02_primary_analyses", "00_setup.R"))
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(purrr)
  library(limma)
  library(edgeR)
  library(variancePartition)
  library(BiocParallel)
  library(flextable)
  library(officer)
  library(epitools)
  library(viridis)
  library(e1071)
  library(sva)
  library(ggpubr)
  library(parallel)
  library(tidyverse)
  library(emmeans)
  library(caret)
  library(msigdbr)
  library(fgsea)
  library(cowplot)
  library(glmnet)
  library(pROC)
  library(broom)
  library(cmapR)
  library(AnnotationDbi)
  library(org.Hs.eg.db)
  library(openxlsx)
  library(scales)
  library(tibble)
  library(ggrepel)
  library(data.table)
  library(UpSetR)
})

## ---- Helpers / constants ---------------------------------------------------
# Verbatim from the original "Helpers/Constants" chunk.

format_num <- function(x) {
  ifelse(
    is.na(x), NA_character_,
    ifelse(
      abs(x) < 0.001 & x != 0,
      formatC(x, format = "e", digits = 1),
      formatC(x, format = "f", digits = 3)))
}

APNS_ordered <- c("Pain","Avoidance","Reexperience","Hyperarousal","Anxious","Depression","Somatic","MentalFatigue","Nightmare","Sleep")

APNS_labels <- c("Pain","Avoidance","Reexperiencing","Hyperarousal","Anxiety","Depression", "Somatic","Mental Fatigue","Nightmares","Sleep")

class_order <- c("Low", "Moderate Recovery", "Moderate", "High")

# recovered group mapping
recovered_class_for <- function(APNS) {
  if (APNS %in% c("Pain", "Avoidance")) "Moderate Recovery" else "Low"
}
recovered_groups <- setNames(vapply(APNS_ordered, recovered_class_for, character(1)), APNS_ordered)

# chronic group mapping
chronic_class_for <- function(APNS) "High"
chronic_groups <- setNames(vapply(APNS_ordered, chronic_class_for, character(1)), APNS_ordered)

# convert specified domain columns into ordered factors
factorize_domains <- function(df, domains = DOMAIN_ORDER, classes = CLASS_ORDER) {
  for (d in domains) {
    if (d %in% names(df)) df[[d]] <- factor(df[[d]], levels = classes)
  }
  df
}

header_style <- createStyle(textDecoration = "bold", halign = "center", valign = "center")
body_style <- createStyle(valign = "center")
num_style <- createStyle(numFmt = "0.000")

## ---- Data root --------------------------------------------------------------
# Data/ and all analysis-output folders live one level above this repo (see
# README) and are never part of the git repository.
data_root <- dirname(here::here())

## ---- Load data ---------------------------------------------------------------
# Same files, same paths as the original "Load data" chunk, just resolved
# against data_root explicitly (robust whether this is sourced interactively
# or during a Quarto render).

RNA_manifest <- read.csv(file.path(data_root, "Data/RNA Data/Analysis Data/RNA_manifest_ED6M_analysis.csv"))
RNA_seq_counts <- read.csv(file.path(data_root, "Data/RNA Data/Analysis Data/AURORA_RNAseq_counts_ED6M_analysis.csv"))
RNA_seq_log2 <- read.csv(file.path(data_root, "Data/RNA Data/Analysis Data/AURORA_RNAseq_log2_ED6M_analysis.csv"))

metadata <- read.csv(file.path(data_root, "Data/Metadata/Analysis Data/Metadata_analysis.csv"))
metadata_RNA <- read.csv(file.path(data_root, "Data/Metadata/Analysis Data/Metadata_ICs_analysis.csv")) 

TF_activity <- read.csv(file.path(data_root, "Data/Transcription Factor Data/Analysis Data/TF_activity_ED6M_analysis.csv"))

cell_fractions <- read.csv(file.path(data_root, "Data/Cibersort Data/Analysis Data/Cibersort_arcsin_estimated_cell_fractions_ED6M_analysis.csv"))

latent_class_trajectories <- read.csv(file.path(data_root, "Data/Metadata/Latent Class Data/AURORA_RNA_Expression_Latent_Class_Trajectories.csv"))

hormone_data <- read.csv(file.path(data_root, "Data/Steroid Hormone Data/Analysis Data/Steroid_hormone_data_ED_analysis.csv"))

cytokine_data <- read.csv(file.path(data_root, "Data/Cytokine Data/Analysis Data/Cytokine_data_ED6M_analysis.csv"))


## ---- Determine ED-M6 and ED-2WK-M6 RNA-seq cohorts ---------------------------
# Verbatim logic from the original chunk. RNA_manifest is already scoped to
# the 490-sample ED-M6 cohort by the exported file it's read from above, so
# this mostly just reshapes it and derives metadata_RNA_paired, the one
# object that several downstream scripts need and that is not written to
# disk anywhere in 01_data_prep.

RNA_manifest_wide <- RNA_manifest %>%
  dplyr::select(PID, INVENTORY.CODE, Timepoint) %>%
  filter(PID %in% metadata$PID) %>%
  pivot_wider(
    names_from  = Timepoint,
    values_from = INVENTORY.CODE,
    names_prefix = "InvCode_")

timepoints_flags <- RNA_manifest %>%
  filter(PID %in% metadata$PID) %>%
  group_by(PID) %>%
  summarize(
    has_ED  = any(Timepoint == "ED"),
    has_WK2 = any(Timepoint == "WK2"),
    has_M6  = any(Timepoint == "M6"),
    .groups = "drop")

ED_M6_paired_PIDs <- timepoints_flags %>%
  filter(has_ED & has_M6) %>%
  pull(PID)

ED_M6_paired_PIDs_df <- ED_M6_paired_PIDs %>%
  as.data.frame() %>%
  dplyr::rename(PID = ".") %>%
  mutate(PID = as.character(PID))

write.csv(ED_M6_paired_PIDs_df, file.path(data_root, "Data/Metadata/ED_M6_paired_PIDs_df.csv"), row.names = FALSE)

ED_M6_inventory_codes <- RNA_manifest_wide %>%
  filter(PID %in% ED_M6_paired_PIDs) %>%
  dplyr::select(InvCode_ED, InvCode_M6) %>%
  unlist(use.names = FALSE)

# length(ED_M6_paired_PIDs)     # 245 participants with paired ED and M6 RNA-seq + all 10 APNS
# length(ED_M6_inventory_codes) # 490 paired samples

metadata_RNA_paired <- metadata_RNA %>%
  filter(INVENTORY.CODE %in% ED_M6_inventory_codes) %>%
  dplyr::select(-X) %>%
  mutate(PID = as.character(PID))

## ---- Checkpoints for script-to-script handoffs -------------------------------
# A few scripts in this folder consume objects computed by one specific
# earlier script, rather than data loaded from disk -- the original
# monolithic file relied on those chunks sharing one in-memory R session.
# Each producing script saves the handful of objects a later script actually
# needs; each consuming script reads them back. This is what makes every
# script runnable on its own (given the checkpoint already exists -- see the
# dependency table in the README for run order).

checkpoint_dir <- file.path(data_root, "Checkpoints")
dir.create(checkpoint_dir, showWarnings = FALSE, recursive = TRUE)

save_checkpoint <- function(obj, name) {
  saveRDS(obj, file.path(checkpoint_dir, paste0(name, ".rds")))
}

read_checkpoint <- function(name) {
  path <- file.path(checkpoint_dir, paste0(name, ".rds"))
  if (!file.exists(path)) {
    stop(
      "Checkpoint '", name, ".rds' was not found in Checkpoints/. ",
      "Run the script that produces it first -- see the dependency table ",
      "in README.md.")
  }
  readRDS(path)
}
