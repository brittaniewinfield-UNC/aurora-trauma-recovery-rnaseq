# Explicit package manifest for this project.
#
# This file is not sourced by any analysis script -- it exists so renv's
# dependency scanner has an unambiguous, complete list to snapshot, and so
# a human can see at a glance what this project needs. Compiled by scanning
# every .qmd file in this repo for library()/require() calls and pkg::fn()
# usage; cross-check against your own libraries before snapshotting, since
# static scanning of ~12,000 lines of split-apart code can miss an edge case.

# ---- CRAN ----
library(tidyverse)   # dplyr, tidyr, purrr, readr, stringr, forcats, tibble, ggplot2
library(data.table)
library(broom)
library(cowplot)
library(flextable)
library(openxlsx)
library(skimr)
library(here)
library(knitr)
library(rlang)
library(scales)
library(UpSetR)
library(e1071)
library(epitools)
library(pROC)
library(car)
library(glmnet)
library(msigdbr)

# ---- Bioconductor (install via BiocManager::install(), not install.packages()) ----
library(edgeR)
library(limma)
library(variancePartition)
library(BiocParallel)
library(dorothea)
library(viper)
library(fgsea)
library(org.Hs.eg.db)
