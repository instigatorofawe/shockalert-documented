rm(list=ls())
library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "mimic"

query = "SELECT * FROM prescriptions WHERE lower(drug) SIMILAR TO '%amikacin%|%gentamicin%|%kanamycin%|%netilmicin%|%tobramycin%|%paromomycin%|%spectinomycin%|%geldanamycin%|%ertapenem%|%doripenem%|%imipenem%|%meropenem%|%cefadroxil%|%cefalexin%|%cefaclor%|%cefoxitin%|%cefprozil%|%cefamandole%|%cefuroxime%|%cefixime%|%cefotaxime%|%cefpodoxime%|%ceftazidime%|%ceftriaxone%|%cefepime%|%vancomycin%|%vanc%|%clindamycin%|%daptomycin%|%azithromycin%|%clarithromycin%|%erythromycin%|%telithromycin%|%aztreonam%|%nitrofurantoin%|%linezolid%|%amoxicillin%|%ampicillin%|%dicloxacillin%|%flucloxacillin%|%methicillin%|%nafcillin%|%oxacillin%|%penicillin%|%piperacillin%|%cefotetan%|%ticarcillin%|%timentin%|%colistin%|%bactrim%|%polymyxin%|%ciprofloxacin%|%gatifloxacin%|%levofloxacin%|%moxifloxacin%|%nalidixic acid%|%norfloxacin%|%ofloxacin%|%trovafloxacin%|%sulfadiazine%|%sulfamethoxazole%|%trimethoprim%|%TMP%|%doxycycline%|%minocycline%|%tetracycline%|%dapsone%|%ethambutol%|%isoniazid%|%pyrazinamide%|%rifampicin%|%rifampin%|%rifabutin%|%streptomycin%|%chloramphenicol%|%synercid%|%fosfomycin%|%metronidazole%|%mupirocin%|%quinupristin%|%tigecycline%|%unasyn%'"

Sys.setenv(TZ="GMT")

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
abx.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(abx.data,file="abx.data.rds")

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
query = "SELECT * FROM chartevents WHERE itemid in (938, 941, 942, 4855, 3333);"
culture.data.1 = dbGetQuery(connection, query)

query = "SELECT * FROM procedureevents_mv WHERE itemid in (225401, 225437);"
culture.data.2 = dbGetQuery(connection, query)

query = "SELECT * FROM microbiologyevents WHERE spec_itemid in (70011, 70012);"
culture.data.3 = dbGetQuery(connection, query)

dbDisconnect(connection)
toc()

abx.data = readRDS("data/mimic/abx.data.rds")
load("data/mimic/culture.data.rdata")

icustays = readRDS("icustays.rds")

infection.abx.icustays = sort(unique(abx.data$icustay_id))
infection.abx.subject.ids = sort(unique(abx.data$subject_id))

infection.culture.subject.ids = sort(unique(c(culture.data.1$subject_id,culture.data.2$subject_id,culture.data.3$subject_id)))
infection.culture.icustays = sort(unique(icustays$icustay_id[is.element(icustays$subject_id,infection.culture.subject.ids)]))

save(infection.abx.icustays,infection.abx.subject.ids,infection.culture.icustays,infection.culture.subject.ids,file="infection.antibiotics.cultures.rdata")