rm(list=ls())

library(ggplot2)

model = readRDS("analysis.glm.rds")

coefficients = summary(model)$coefficients
ordering = order(abs(coefficients[-1,1]),decreasing = T)+1

ordered.coefficients = coefficients[ordering,]

exponentiated.coefficients = 1/(1+exp(-ordered.coefficients[,1]))
exponentiated.lower = 1/(1+exp(-ordered.coefficients[,1]-2*ordered.coefficients[,2]))
exponentiated.upper = 1/(1+exp(-ordered.coefficients[,1]+2*ordered.coefficients[,2]))


exponentiated.coefficients = exp(ordered.coefficients[,1])
exponentiated.lower = exp(ordered.coefficients[,1]-2*ordered.coefficients[,2])
exponentiated.upper = exp(ordered.coefficients[,1]+2*ordered.coefficients[,2])

data = data.frame(x=1:10,y=exponentiated.coefficients,lower=exponentiated.lower,upper=exponentiated.upper)

png("figures/fig3.png",width=800,height=600)
ggplot(data,aes(x=x,y=y))+geom_point(size=2)+geom_errorbar(aes(ymin=lower,ymax=upper),size=0.5,width=0.5)+
    scale_x_continuous(breaks=1:10,labels=c("Lactate","Cardio.\nSOFA","GCS","Heart\nRate","PaO2","FiO2","Resp.\nRate","Kidney\nSOFA","Resp.\nSOFA","Coag.\nSOFA"))+
    xlab("")+ylab("Exponentiated Coefficient")+geom_hline(yintercept=1,color="red",size=1)+
    scale_y_continuous(breaks=0:6)+
    theme(axis.text=element_text(size=20),
          axis.text.y=element_text(size=24),
          axis.title=element_text(size=24))
dev.off()