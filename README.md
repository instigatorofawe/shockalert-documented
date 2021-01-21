# Data-driven discovery of a novel sepsis pre-shock state predicts impending septic shock in the ICU
## Liu et al. Scientific Reports 2019

### Overview
This is a repository of code for data processing/analysis accompanying the above paper.

The processed data files are several gigabytes in size, and have not been included with this repository.
One should be able to reproduce them exactly by re-running the data processing pipeline, however.

Be aware that some steps of analyses/data processing may take on the order of *days* to complete, depending on your machine.
Some portions have been parallelized using the *parallel* package for performance.

EDITED (January 21, 2021): Refactored the directory structure of the code to something more sensible, corrected some instructions, and added additional documentation. Note that using Keras/Tensorflow in RStudio is not recommended. It is much more advisable to load your data directly into Python using the *rpy2* package, and to work in Keras/Tensorflow or PyTorch in Python directly. However, for the sake of completeness, R code for running neural network models has been included in this repository. 

### MIMIC-3 data processing pipeline

Data is stored in the *data/mimic/* folder.

#### Querying data, generating data tables, evaluating Sepsis labels

Scripts located in: *src/R/data_processing/mimic*

These scripts should be run in order (and have filenames which are numbered accordingly), as subsequent scripts may depend on the output of those earlier in the pipeline.

1. query_mimic.R - Queries chart data
2. infection_antibiotics_cultures - Computes suspected infection using orders for antibiotics and cultures
3. read_clinical_data_v2.R - Generates clinical data tables
4. eval_sepsis3_mimic_v3.R - Evaluates clinical labels
5. eval_sepsis2_mimic.R - Evaluates Sepsis-2 (based on SIRS criteria) clinical labels
6. is_adult.R - Determines which patients are adults
7. generate_test_tables.R - Generates data tables for evaluating early prediction
8. generate_reference_data_mimic_2.R - Generates training data tables for cross-database validation
9. generate_lstm_reference_data.R - Generates training data tables for recurrent neural networks

### eICU data processing pipeline

Data is stored in the *data/eicu/* folder.

####  Querying data, generating data tables, evaluating Sepsis labels

Scripts located in: *src/R/data_processing/eicu*

These scripts should be run in order (and have filenames which are numbered accordingly), as subsequent scripts depend on the output of those earlier in the pipeline.

1. query_suspected_infection_eicu.R - queries eICU postres database for ICD-9 codes
2. analyze_suspected_infection_icd9_eicu.R - determines which ICD-9 codes are indicative of suspected infection according to Angus et al.
3. generate_clinical_tables_eicu.R - queries eICU postgres database and generates data tables
4. validate_clinical_data_eicu.R - throws out patients with no data
5. eval_sepsis3_eicu.R - evaluates Sepsis-3 criteria
7. generate_eicu_test_tables.R - Generates testing data tables for cross-database validation

### Analysis

Scripts located in *src/R/analysis*

Checkpoint files produced by Keras will be stored in the *checkpoints* folder, and results in the *results* folder.

1. final_concomitant_combined.R - produces results for glm/cox/xgboost
2. final_concomitant_gru_replicates.R - produces results for RNN

### Figures

RMarkdown notebooks for generating and displaying figures are located in: *src/R/notebooks*

1. figure_1.Rmd
2. figure_2.Rmd
3. figure_3.Rmd
4. figure_4.Rmd
5. figure_5.Rmd
6. figure_6.Rmd

### Validation in an external dataset (eICU)

Scripts located in *src/R/analysis*

Trains on MIMIC-3, tests on eICU
1. analyze_cross_database_5.R - Validation for glm/xgboost
2. final_icd9_gru_eicu_2 - Validation for RNN