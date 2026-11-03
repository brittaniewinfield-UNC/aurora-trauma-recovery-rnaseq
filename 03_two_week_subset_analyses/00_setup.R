# 00_setup.R

suppressPackageStartupMessages({
  library(edgeR)
  library(variancePartition)
  library(limma)
  library(BiocParallel)
  library(dplyr)
  library(tidyverse)
})

## Metadata 
metadata_2wk <- read.csv("Data/Metadata/Analysis Data/Metadata_analysis_ED2WK6M.csv") %>%
  dplyr::select(-any_of("X"))

metadata_ICs_2wk <- read.csv("Data/Metadata/Analysis Data/Metadata_ICs_analysis_ED2WK6M.csv") %>%
  mutate(PID = as.character(PID)) %>%
  dplyr::select(-any_of("X"))

## RRS data 
RRS_df <- read.csv("RNA-based Recovery Score/Final_RRS_Scores_Full_Cohort.csv")

# median split of full cohort based on RRS
rrs_median <- median(RRS_df$RRS, na.rm = TRUE)

RRS_df_median <- RRS_df %>%
  mutate(
    PID = as.character(PID),
    RRS_median_group = case_when(
      RRS > rrs_median ~ "High_RRS",
      RRS < rrs_median ~ "Low_RRS",
      TRUE ~ "Median"))

# n = 21 High RRS, n = 19 Low RRS in the two-week subset
RRS_df_median_2wk <- RRS_df_median %>%
  filter(PID %in% metadata_2wk$PID)

## RNA data 
RNA_counts_2wk <- read.csv("Data/RNA Data/Analysis Data/AURORA_RNAseq_counts_ED2WK6M_analysis.csv")

RNA_log2_2wk <- read.csv("Data/RNA Data/Analysis Data/AURORA_RNAseq_log2_ED2WK6M_analysis.csv")

## Transcription factor activity 
TF_data_EDWK2M6 <- read.csv("Data/Transcription Factor Data/Analysis Data/TF_activity_ED2WK6M_analysis.csv") %>%
  dplyr::select(-any_of("X")) %>%
  dplyr::select(PID, Timepoint, INVENTORY.CODE, everything()) %>%
  mutate(PID = as.character(PID))

## Helpers / constants

# interval comparisons shared by every within-class paired test below
intervals <- tribble(
  ~Comparison,   ~time1, ~time2,
  "ED_vs_WK2",   "ED",   "WK2",
  "WK2_vs_M6",   "WK2",  "M6",
  "ED_vs_M6",    "ED",   "M6")

# paired t-test between two timepoints, within one RRS group
run_paired_interval_test <- function(data, time1, time2) {

  data_use <- data %>%
    dplyr::filter(!is.na(.data[[time1]]),
                  !is.na(.data[[time2]]))

  change_values <- data_use[[time2]] - data_use[[time1]]

  test <- t.test(data_use[[time2]], data_use[[time1]], paired = TRUE )

  tibble(
    n = nrow(data_use),

    !!paste0("Avg ", time1) := mean(data_use[[time1]], na.rm = TRUE),

    !!paste0("Avg ", time2) := mean(data_use[[time2]], na.rm = TRUE),

    !!paste0("Avg Δ (", time2, " − ", time1, ")") := mean(change_values, na.rm = TRUE),

    SE = sd(change_values, na.rm = TRUE) / sqrt(sum(!is.na(change_values))),

    `T Stat` = unname(test$statistic),

    `P Value` = test$p.value,

    `95% CI` = paste0("[",round(test$conf.int[1], 3),", ", round(test$conf.int[2], 3),"]"))
}

# unpaired t-test on a change score, comparing High vs. Low RRS groups
run_delta_test <- function(df, delta_var) {

  df_use <- df %>%
    filter(!is.na(.data[[delta_var]]))


  test <- t.test(df_use[[delta_var]] ~ df_use$RRS_median_group)

  mean_High <- mean(df_use[[delta_var]][df_use$RRS_median_group == "High_RRS"], na.rm = TRUE)
  mean_Low  <- mean(df_use[[delta_var]][df_use$RRS_median_group == "Low_RRS"], na.rm = TRUE)

  tibble(
    n = nrow(df_use),
    `High RRS Avg Δ` = mean_High,
    `Low RRS Avg Δ` = mean_Low,
    `Avg Δ (High − Low)` = mean_High - mean_Low,
    SE = abs((mean_High - mean_Low) / unname(test$statistic)),
    `T Stat` = unname(test$statistic),
    `P Value` = test$p.value,
    `95% CI` = paste0("[",round(test$conf.int[1], 3), ", ", round(test$conf.int[2], 3), "]") )
}
