rm(list=ls())

load("results/concomitant.combined.results2.rdata")

ewt.glm.all = do.call(c,ewts.glm)

png("figures/fig5.png",width=800,height=800)
ggplot(data.frame(ewt=ewt.glm.all),aes(x=ewt))+geom_histogram()+xlim(0,50)+geom_vline(xintercept=median(ewt.glm.all),size=1,color="red")+
    xlab("Early Warning Time (hours)") + ylab("Frequency")+
    theme(axis.text=element_text(size=20),
          axis.title=element_text(size=24))
dev.off()