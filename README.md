# Data-driven discovery of a novel sepsis pre-shock state predicts impending septic shock in the ICU
## Liu et al. Scientific Reports 2019

### Overview
This is a repository of code for data processing/analysis accompanying the above paper.

Unfortunately, the processed data files are several gigabytes in size, and have not been included with this repository.
In theory one should be able to reproduce them by re-running the data processing pipeline, however.

Be aware that some steps of analyses/data processing may take on the order of *days* to complete, depending on your machine.
Some portions have been parallelized using the *parallel* package for performance.

### MIMIC-3 data processing pipeline

Processed data is generated and stored in the *processed* folder, whereas functions are in the *functions* folder.

#### Querying data

These scripts should be run in order, as subsequent scripts depend on the output of those earlier in the pipeline.

1. query_mimic.R - Queries chart data
2. query_urine.R - Queries urine output
3. query_mimic_vasopressors.R - Queries input items, both fluids and vasopressors
4. query_weight.R - Queries patient weight
5. query_admissions.R
6. query_icustay.R
7. query_is_adult.R - Determines which patients are adults
8. query_infection_antibiotics_cultures

#### Generating data tables/evaluating sepsis labels
1. read_clinical_data_v2.R - Generates clinical data tables
2. eval_sepsis3_mimic_v3.R - Evaluates clinical labels
3. eval_sepsis2_mimic.R - Evaluates Sepsis-2 (based on SIRS criteria) clinical labels
4. generate_test_tables.R - Generates data tables for evaluating early prediction
5. generate_reference_data_mimic_2.R - Generates training data tables for cross-database validation

### eICU data processing pipeline

Processed data is stored in the *eicu* folder, whereas functions are in *eicu_functions*

#### Generating data tables/evaluating Sepsis-3

These scripts should be run in order, as subsequent scripts depend on the output of those earlier in the pipeline.

1. query_suspected_infection_eicu.R - queries eICU postres database for ICD-9 codes
2. analyze_suspected_infection_icd9_eicu.R - determines which ICD-9 codes are indicative of suspected infection according to Angus et al.
3. generate_clinical_tables_eicu.R - queries eICU postgres database and generates data tables
4. validate_clinical_data_eicu.R - throws out patients with no data
5. eval_sepsis3_eicu.R - evaluates Sepsis-3 criteria
7. generate_eicu_test_tables.R - Generates testing data tables for cross-database validation

### Analysis

Checkpoint files produced by Keras will be stored in the *checkpoints* folder, and results in the *results* folder.

1. final_concomitant_combined.R - produces results for glm/cox/xgboost
2. final_concomitant_gru_replicates.R - produces results for RNN

### Figures

Scripts for generating figures

1. generate_figure_1.R
2. generate_figure_2.R
3. generate_figure_3.R
4. generate_figure_4.R
5. generate_figure_5.R
6. generate_figure_6.R

### Validation in an external dataset (eICU)
Trains on MIMIC-3, tests on eICU
1. analyze_cross_database_5.R - Validation for glm/xgboost
2. final_icd9_gru_eicu_2 - Validation for RNN