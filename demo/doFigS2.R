suppressMessages(library(tidyverse))
data(dhatKhat)

Khat.x <- apply(aseB[,-c(1,2)], 1, which.max)+1
Khat.y <- apply(aseB[,-c(1,2)], 1, max, na.rm=TRUE)
df2.ase <- data.frame(g=factor(1:nrow(aseE)), Khat.x=Khat.x, Khat.y=Khat.y, aseB[,3:50])
Khat.x <- apply(lseB[,-c(1,2)], 1, which.max)+1
Khat.y <- apply(lseB[,-c(1,2)], 1, max, na.rm=TRUE)
df2.lse <- data.frame(g=factor(1:nrow(lseE)), Khat.x=Khat.x, Khat.y=Khat.y, lseB[,3:50])
df.ase.bic <- gather(df2.ase, `X1`:`X48`, key = "K", value = "BIC", factor_key = TRUE)
df.lse.bic <- gather(df2.lse, `X1`:`X48`, key = "K", value = "BIC", factor_key = TRUE)
df.bic <- rbind(cbind(df.ase.bic, type="ASE"), cbind(df.lse.bic, type="LSE"))
ggplot(df.bic, aes(x=K, y=BIC, group=g)) + #geom_line(aes(color=g)) +
    geom_line(color="grey") + geom_point(aes(x=Khat.x,y=Khat.y,color=type), size=1) +
    facet_grid(type~., scales="free_y") +
    scale_x_discrete(breaks = paste0("X",seq(2,50,by=2)), labels=seq(2,50,2)) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1), legend.position = "none")
