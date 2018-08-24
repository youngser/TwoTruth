suppressMessages(library(tidyverse))
data(dhatKhat)

elb.y <- sapply(1:nrow(aseD), function(x) aseD[x, aseE[x,3]+2])
df.ase <- data.frame(g=factor(1:nrow(aseD)), elb.x=aseE[,3], elb.y=elb.y, aseD[,-c(1,2)])
elb.y <- sapply(1:nrow(lseD), function(x) lseD[x, lseE[x,3]+2])
df.lse <- data.frame(g=factor(1:nrow(lseD)), elb.x=lseE[,3], elb.y=elb.y, lseD[,-c(1,2)])
df.ase.elb <- gather(df.ase, `X1`:`X100`, key="dimension", value="eigenvalue", factor_key = TRUE)
df.lse.elb <- gather(df.lse, `X1`:`X100`, key="dimension", value="eigenvalue", factor_key = TRUE)
df.elb <- rbind(cbind(df.ase.elb, type="ASE"), cbind(df.lse.elb, type="LSE"))
df.elb$dimension <- as.numeric(df.elb$dimension)
p <- ggplot(df.elb, aes(x=dimension, y=eigenvalue, group=g)) + geom_line(color="grey", alpha=0.5) +
    geom_point(aes(x=elb.x,y=elb.y, color=type), alpha=0.5, size=1) +
    facet_grid(type~., scales="free_y") + theme(legend.position = "none")
print(p)