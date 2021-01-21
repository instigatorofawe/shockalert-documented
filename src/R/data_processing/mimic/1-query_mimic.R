rm(list=ls())

library(RPostgres)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "mimic"

### Query chart data
hr.items = c(211, 220045)
sbp.items = c(6, 51, 6701, 220050, 225309)
sbp.nbp.items = c(442, 455, 3313, 220179)
dbp.items = c(8364, 8368, 8555, 220051, 225310)
dbp.nbp.items = c(8440, 8441, 8502, 220180)
mbp.items = c(52, 456, 6702, 220052, 225312)
mbp.nbp.items = c(443, 3312, 220181)
resp.items = c(615, 618, 8113, 3603, 224690, 220210)
temp.c.items = c(676, 677, 223762)
temp.f.items = c(678, 679, 223761)
cvp.items = c(716, 1103, 113, 220074)
pao2.items = c(490, 779, 3785, 3837, 220224)
fio2.items = c(190, 191, 3420, 3422, 1863, 2518, 2981, 7570, 223835)
gcs.items = c(198)
gcs.mv.items = c(220739, 223900, 223901)
bili.items = c(848, 5483, 5543, 4049, 3220, 5821, 1538, 5032, 5045, 4354, 225690)
platelets.items = c(828, 3789, 6256, 227457)
creat.items = c(791, 3750, 1525, 220615)
lact.items = c(818, 1531, 225668)
bun.items = c(1162, 781, 5876, 3737, 225624)
ph.items = c(1126, 4753, 780, 223830)
wbc.items = c(1127, 861, 4200, 1542, 220546)
paco2.items = c(777, 778, 3784, 3835, 220235)
hgb.items = c(814, 220228)
hct.items = c(813, 3761, 226540)
potassium.items = c(829, 3792, 1535, 4194, 227442, 227464)
epi.items = c(3112, 5752, 30119, 30309, 30044, 221289)
dop.items = c(4501, 5329, 30043, 30307, 221662)
dob.items = c(5747, 30306, 30042, 221653)
norepi.items = c(221906, 30047, 30120)
phen.items = c(5656, 6752, 6090, 221749, 30127, 30128)
vasopressin.items = c(4501, 5329, 30043, 30307, 221662)
urine.items = c(40405,40428,40534,41857,42001,42362,42463,42507,42510,42556,42676,43171,43173,43175,40288,42042,42068,42111,42119,42209,40715,40056,40061,40085,40094,40096,43897,43931,43966,44080,44103,44132,44237,44313,43348,43355,43365,43372,43373,43374,43379,43380,43431,43462,43522,44706,44911,44925,42810,42859,43093,44325,44506,43856,45304,46532,46578,46658,46748,40651,40055,40057,40065,40069,44752,44824,44837,43576,43589,43633,43811,43812,46177,46727,46804,43987,44051,44253,44278,46180,45804,45841,45927,42592,42666,42765,42892,43053,43057,42130,41922,40473,43333,43347,44684,44834,43638,43654,43519,43537,42366,45991,227489,45415,226627,226631)

chart.items = c(hr.items,sbp.items,sbp.nbp.items,dbp.items,dbp.nbp.items,mbp.items,mbp.nbp.items,
    resp.items,temp.c.items,temp.f.items,cvp.items,pao2.items,fio2.items,gcs.items,gcs.mv.items,bili.items,
    platelets.items,creat.items,lact.items,bun.items,ph.items,wbc.items,paco2.items,hgb.items,hct.items,potassium.items)
query = sprintf("select * from chartevents where itemid in (%s)",paste(chart.items,collapse=","))

Sys.setenv(TZ="GMT")

tic("Querying chart data")
connection = dbConnect(Postgres()), user=user, password=password, dbname=db)
chart.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(chart.data,file="data/mimic/chart.data.rds")
save(hr.items,sbp.items,sbp.nbp.items,dbp.items,dbp.nbp.items,mbp.items,mbp.nbp.items,
    resp.items,temp.c.items,temp.f.items,cvp.items,pao2.items,fio2.items,gcs.items,gcs.mv.items,bili.items,
    platelets.items,creat.items,lact.items,bun.items,ph.items,wbc.items,paco2.items,hgb.items,hct.items,potassium.items,
    epi.items,dop.items,dob.items,norepi.items,phen.items,vasopressin.items,urine.items,
    file="data/mimic/query.items.mimic3.rdata")

### Query urine
urine.items = c(40405,40428,40534,41857,42001,42362,42463,42507,42510,42556,42676,43171,43173,43175,40288,42042,42068,42111,42119,42209,40715,40056,40061,40085,40094,40096,43897,43931,43966,44080,44103,44132,44237,44313,43348,43355,43365,43372,43373,43374,43379,43380,43431,43462,43522,44706,44911,44925,42810,42859,43093,44325,44506,43856,45304,46532,46578,46658,46748,40651,40055,40057,40065,40069,44752,44824,44837,43576,43589,43633,43811,43812,46177,46727,46804,43987,44051,44253,44278,46180,45804,45841,45927,42592,42666,42765,42892,43053,43057,42130,41922,40473,43333,43347,44684,44834,43638,43654,43519,43537,42366,45991,227489,45415,226627,226631)

query = sprintf("SELECT * FROM outputevents where itemid in (%s)", paste(urine.items,collapse=","))

tic("Querying urine data")
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
urine.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(urine.data,file="data/mimic/urine.data.rds")

### Query vasopressors
epi.items = c(3112, 5752, 30119, 30309, 30044, 221289)
dop.items = c(4501, 5329, 30043, 30307, 221662)
dob.items = c(5747, 30306, 30042, 221653)
norepi.items = c(221906, 30047, 30120)
phen.items = c(5656, 6752, 6090, 221749, 30127, 30128)
vasopressin.items = c(4501, 5329, 30043, 30307, 221662)

vasopressor.items = c(epi.items,dop.items,dob.items,norepi.items,phen.items,vasopressin.items)

query = "SELECT * FROM inputevents_cv"

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
input.data.cv = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

query = "SELECT * FROM inputevents_mv"

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
input.data.mv = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

save(input.data.cv,input.data.mv,file="data/mimic/input.data.rdata")

### Query weight data
query = "select * from chartevents where itemid in (580,581,763,3580,3581,3582,3583,3693,224639,226512,226531)"

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
weight.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

weight.data = weight.data[weight.data$valueuom=="kg",]

saveRDS(weight.data,file="data/mimic/weight.data.rds")

### Query admissinos
query = "select * from admissions"

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
admission.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(admission.data,file="data/mimic/admission.data.rds")

### Query icustays
query = "select * from icustays"

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
icustay.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(icustay.data, file="data/mimic/icustays.rds")

### Query patients
query = "select * from patients"

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
patient.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(patient.data,"data/mimic/patient.data.rds")

### Query antibiotics
query = "SELECT * FROM prescriptions WHERE lower(drug) SIMILAR TO '%amikacin%|%gentamicin%|%kanamycin%|%netilmicin%|%tobramycin%|%paromomycin%|%spectinomycin%|%geldanamycin%|%ertapenem%|%doripenem%|%imipenem%|%meropenem%|%cefadroxil%|%cefalexin%|%cefaclor%|%cefoxitin%|%cefprozil%|%cefamandole%|%cefuroxime%|%cefixime%|%cefotaxime%|%cefpodoxime%|%ceftazidime%|%ceftriaxone%|%cefepime%|%vancomycin%|%vanc%|%clindamycin%|%daptomycin%|%azithromycin%|%clarithromycin%|%erythromycin%|%telithromycin%|%aztreonam%|%nitrofurantoin%|%linezolid%|%amoxicillin%|%ampicillin%|%dicloxacillin%|%flucloxacillin%|%methicillin%|%nafcillin%|%oxacillin%|%penicillin%|%piperacillin%|%cefotetan%|%ticarcillin%|%timentin%|%colistin%|%bactrim%|%polymyxin%|%ciprofloxacin%|%gatifloxacin%|%levofloxacin%|%moxifloxacin%|%nalidixic acid%|%norfloxacin%|%ofloxacin%|%trovafloxacin%|%sulfadiazine%|%sulfamethoxazole%|%trimethoprim%|%TMP%|%doxycycline%|%minocycline%|%tetracycline%|%dapsone%|%ethambutol%|%isoniazid%|%pyrazinamide%|%rifampicin%|%rifampin%|%rifabutin%|%streptomycin%|%chloramphenicol%|%synercid%|%fosfomycin%|%metronidazole%|%mupirocin%|%quinupristin%|%tigecycline%|%unasyn%'"

Sys.setenv(TZ="GMT")

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
abx.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(abx.data,file="data/mimic/abx.data.rds")

tic()
connection = dbConnect(Postgres(), user=user, password=password, dbname=db)
query = "SELECT * FROM chartevents WHERE itemid in (938, 941, 942, 4855, 3333);"
culture.data.1 = dbGetQuery(connection, query)

query = "SELECT * FROM procedureevents_mv WHERE itemid in (225401, 225437);"
culture.data.2 = dbGetQuery(connection, query)

query = "SELECT * FROM microbiologyevents WHERE spec_itemid in (70011, 70012);"
culture.data.3 = dbGetQuery(connection, query)

dbDisconnect(connection)
toc()

save(culture.data.1, culture.data.2, culture.data.3, file="data/mimic/culture.data.rdata")