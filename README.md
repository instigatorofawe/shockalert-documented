# Data-driven discovery of a novel sepsis pre-shock state predicts impending septic shock in the ICU
## Liu et al. Scientific Reports 2019

### Overview
This is a repository of code for data processing/analysis accompanying the above paper.

Unfortunately, the processed data files are several gigabytes in size, and have not been included with this repository.
In theory one should be able to reproduce them by re-running the data processing pipeline, however.

Be aware that some steps of analyses/data processing may take on the order of *days* to complete, depending on your machine.
Some portions have been parallelized using the *parallel* package for performance.

### MIMIC-3 data processing pipeline

Processed data should be generated and stored in the *processed* folder, whereas functions are in the *functions* folder.

#### Querying data

These scripts should be run in order, as subsequent scripts depend on the output of those earlier in the pipeline.

query_mimic.R - Queries chart data
query_urine.R - Queries urine output
query_mimic_vasopressors.R - Queries input items, both fluids and vasopressors
query_weight.R - Queries patient weight
query_admissions.R
query_icustay.R
query_is_adult.R - Determines which patients are adults
query_infection_antibiotics_cultures

#### Generating data tables/evaluating sepsis labels
read_clinical_data_v2.R - Generates clinical data tables
eval_sepsis3_mimic_v3.R - Evaluates clinical labels
eval_sepsis2_mimic.R - Evaluates Sepsis-2 (based on SIRS criteria) clinical labels
generate_test_tables.R - Generates data tables for evaluating early prediction

### eICU data processing pipeline

Processed data should be stored in the *eicu* folder, whereas functions are in *eicu_functions*

#### Generating data tables/evaluating Sepsis-3

These scripts should be run in order, as subsequent scripts depend on the output of those earlier in the pipeline.

1. query_suspected_infection_eicu.R - queries eICU postres database for ICD-9 codes
2. analyze_suspected_infection_icd9_eicu.R - determines which ICD-9 codes are indicative of suspected infection according to Angus et al.
3. generate_clinical_tables_eicu.R - queries eICU postgres database and generates data tables
4. validate_clinical_data_eicu.R - throws out patients with no data
5. eval_sepsis3_eicu.R - evaluates Sepsis-3 criteria

### Analysis

Checkpoint files produced by Keras will be stored in the *checkpoints* folder, and results in the *results* folder.

1. final_concomitant_combined.R - produces results for glm/cox/xgboost
2. 

### Figures
1. generate_figure_1.R
2. generate_figure_2.R
3. generate_figure_3.R
4. generate_figure_4.R
5. generate_figure_5.R

### Validation in an external dataset (eICU)