rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "eicu"

query = "SELECT * FROM medication WHERE lower(drugname) SIMILAR TO '%amikacin%|%gentamicin%|%kanamycin%|%netilmicin%|%tobramycin%|%paromomycin%|%spectinomycin%|%geldanamycin%|%ertapenem%|%doripenem%|%imipenem%|%meropenem%|%cefadroxil%|%cefalexin%|%cefaclor%|%cefoxitin%|%cefprozil%|%cefamandole%|%cefuroxime%|%cefixime%|%cefotaxime%|%cefpodoxime%|%ceftazidime%|%ceftriaxone%|%cefepime%|%vancomycin%|%vanc%|%clindamycin%|%daptomycin%|%azithromycin%|%clarithromycin%|%erythromycin%|%telithromycin%|%aztreonam%|%nitrofurantoin%|%linezolid%|%amoxicillin%|%ampicillin%|%dicloxacillin%|%flucloxacillin%|%methicillin%|%nafcillin%|%oxacillin%|%penicillin%|%piperacillin%|%cefotetan%|%ticarcillin%|%timentin%|%colistin%|%bactrim%|%polymyxin%|%ciprofloxacin%|%gatifloxacin%|%levofloxacin%|%moxifloxacin%|%nalidixic acid%|%norfloxacin%|%ofloxacin%|%trovafloxacin%|%sulfadiazine%|%sulfamethoxazole%|%trimethoprim%|%TMP%|%doxycycline%|%minocycline%|%tetracycline%|%dapsone%|%ethambutol%|%isoniazid%|%pyrazinamide%|%rifampicin%|%rifampin%|%rifabutin%|%streptomycin%|%chloramphenicol%|%synercid%|%fosfomycin%|%metronidazole%|%mupirocin%|%quinupristin%|%tigecycline%|%unasyn%'"

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
abx.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(abx.data,file="eicu.abx.data.rds")

subjects = unique(abx.data$patientunitstayid)
times = sapply(subjects, function(x) {
    current.abx.data = abx.data[abx.data$patientunitstayid==x,]
    if (dim(current.abx.data)[1]==0) {
        return(NA)
    } else {
        return(min(current.abx.data$drugorderoffset))
    }
})