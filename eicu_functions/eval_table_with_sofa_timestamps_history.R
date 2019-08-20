eval.table.with.sofa.timestamps.history = function(timestamps, data, interval, history.n) {
    result = array(NA, dim=c(length(timestamps),10,history.n+1))

    # For each timestamp, compute history intervals
    eval.timestamps = sapply(timestamps, function(x) x - (0:history.n)*interval, simplify=F)

    # Cardio SOFA
    cardio.sofa.timestamps = sort(unique(c(data$mbp$timestamps,data$dop$timestamps,data$dob$timestamps,data$ep$timestamps,data$norep$timestamps)))
    cardio.sofa.raw = rep(0, length(cardio.sofa.timestamps))

    cardio.sofa = rep(0, length(timestamps))
    vasopressors = rep(0, length(timestamps))

    if (!is.null(data$mbp)) {
        current.mbp = eval.carry.forward(cardio.sofa.timestamps,data$mbp$timestamps,data$mbp$values)
        cardio.sofa.raw[current.mbp < 70] = 1
    }

    if (!is.null(data$dop)) {
        # If vasopressors given in the past hour
        current.dop = eval.carry.forward(cardio.sofa.timestamps,data$dop$timestamps,data$dop$values,60)
        cardio.sofa.raw[current.dop>0] = 2
        vasopressors[eval.carry.forward(timestamps,data$dop$timestamps,data$dop$values,60)>0] = TRUE
    }

    if (!is.null(data$dob)) {
        current.dob = eval.carry.forward(cardio.sofa.timestamps,data$dob$timestamps,data$dob$values,60)
        cardio.sofa.raw[current.dob>0] = 2
        vasopressors[eval.carry.forward(timestamps,data$dob$timestamps,data$dob$values,60)>0] = TRUE
    }

    if (!is.null(data$ep)) {
        current.ep = eval.carry.forward(cardio.sofa.timestamps,data$ep$timestamps,data$ep$values,60)
        cardio.sofa.raw[current.ep>0] = 2
        vasopressors[eval.carry.forward(timestamps,data$ep$timestamps,data$ep$values,60)>0] = TRUE
    }

    if (!is.null(data$norep)) {
        current.norep = eval.carry.forward(timestamps,data$norep$timestamps,data$norep$values,60)
        cardio.sofa.raw[current.norep>0] = 2
        vasopressors[current.norep>0] = TRUE
    }

     # Kidneys: creat & urine output
    if (!is.null(data$creat)) {
        creat.timestamps = sort(unique(data$creat$timestamps))
        current.creat = eval.carry.forward(creat.timestamps,data$creat$timestamps,data$creat$values)
        kidney.sofa.raw = rep(0,length(creat.timestamps))
        kidney.sofa.raw[current.creat>=1.2&current.creat<2] = 1
        kidney.sofa.raw[current.creat>=2&current.creat<3.5] = 2
        kidney.sofa.raw[current.creat>=3.5&current.creat<5] = 3
        kidney.sofa.raw[current.creat>=5] = 4
    }

    # Coag: platelets
    if (!is.null(data$platelets)) {
        coag.timestamps = sort(unique(data$platelets$timestamps))
        current.platelets = eval.carry.forward(coag.timestamps,data$platelets$timestamps,data$platelets$values)
        coag.sofa.raw = rep(0,length(coag.timestamps))
        coag.sofa.raw[current.platelets<150] = 1
        coag.sofa.raw[current.platelets<100] = 2
        coag.sofa.raw[current.platelets<50] = 3
        coag.sofa.raw[current.platelets<20] = 4
    }


    if (!is.null(data$pao2)) {
        resp.sofa.timestamps = sort(unique(c(data$pao2$timestamps,data$fio2$timestamps)))
        resp.sofa.raw = rep(0, length(resp.sofa.timestamps))
        sofa.pao2 = eval.carry.forward(resp.sofa.timestamps,data$pao2$timestamps,data$pao2$values)
        sofa.fio2 = rep(NA, length(resp.sofa.timestamps))
        sofa.vent = rep(NA, length(resp.sofa.timestamps))

        if(!is.null(data$fio2)) {
            sofa.fio2 = eval.carry.forward(resp.sofa.timestamps,data$fio2$timestamps,data$fio2$values)
        }
        if(!is.null(data$vent)) {
            sofa.vent = eval.interval(resp.sofa.timestamps,data$vent$starts,data$vent$stops)
        }

        sofa.fio2[is.na(sofa.fio2)] = 21
        pao2.fio2.ratio = sofa.pao2 / sofa.fio2 * 100

        resp.sofa.raw[pao2.fio2.ratio<400] = 1
        resp.sofa.raw[pao2.fio2.ratio<300] = 2
        resp.sofa.raw[pao2.fio2.ratio<200&sofa.vent] = 3
        resp.sofa.raw[pao2.fio2.ratio<100&sofa.vent] = 4

    }

    for (i in 1:length(timestamps)) {
        # 1. Lactate
        if (!is.null(data$lactate)) {
            result[i,1,] = eval.carry.forward(eval.timestamps[[i]],data$lactate$timestamps,data$lactate$values)
        }
        # 2. Cardio SOFA
        result[i,2,] = eval.max.in.past(eval.timestamps[[i]], timestamps, cardio.sofa.raw, hours(24))

        # 3. GCS
        if (!is.null(data$gcs)) {
            result[i,3,]=eval.carry.forward(eval.timestamps[[i]],data$gcs$timestamps,data$gcs$values)
        }

        # 4. HR
        if (!is.null(data$hr)) {
            result[i,4,]=eval.carry.forward(eval.timestamps[[i]],data$hr$timestamps,data$hr$values)
        }

        # 5. PaO2
        if (!is.null(data$pao2)) {
            result[i,5,]=eval.carry.forward(eval.timestamps[[i]],data$pao2$timestamps,data$pao2$values)
        }

        # 6. FiO2
        if (!is.null(data$fio2)) {
            result[i,6,]=eval.carry.forward(eval.timestamps[[i]],data$fio2$timestamps,data$fio2$values)
        }

        # 7. Resp
        if (!is.null(data$hr)) {
            result[i,7,]=eval.carry.forward(eval.timestamps[[i]],data$resp$timestamps,data$resp$values)
        }

        # 8. Kidney SOFA
        if (!is.null(data$creat)) {
            result[i,8,] = eval.max.in.past(eval.timestamps[[i]], creat.timestamps, kidney.sofa.raw, hours(24), 0)
        } else {
            result[i,8,] = rep(0,length(eval.timestamps[[i]]))
        }

        # 9. Resp SOFA
        if (!is.null(data$pao2)) {
            result[i,9,] = eval.max.in.past(eval.timestamps[[i]], resp.sofa.timestamps, resp.sofa.raw, hours(24), 0)

        } else {
            result[i,9,] = rep(0,length(eval.timestamps[[i]]))
        }

        # 10. Coag SOFA
        if (!is.null(data$platelets)) {
            result[i,10,] = eval.max.in.past(eval.timestamps[[i]], coag.timestamps, coag.sofa.raw, hours(24), 0)
        } else {
            result[i,10,] = rep(0,length(eval.timestamps[[i]]))
        }
    }

    return(result)
}