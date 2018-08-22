library(TwoTruth)

print(load(url("http://www.cis.jhu.edu/~parky/TT/Data/TT-glist114-raw.rda")))
Abar <- getAbar(glist, Y)
gbar <- graph_from_adjacency_matrix(Abar/(ng*nscan),mode="undirected",weighted=TRUE)
V(gbar)$hemisphere <- Y$Yh
V(gbar)$tissue <- Y$Yt
V(gbar)$Y <- Y$Y4

gbreve <- getLCC(gbar, "raw")
Bout2 <- getB(gbreve)
Bout4 <- getB4(gbreve)
rownames(Bout2$B.h) <- c("L","R"); colnames(Bout2$B.h) <- c("L","R")
colnames(Bout2$B.t) <- c("G","W"); rownames(Bout2$B.t) <- c("G","W")
plotB4(Bout2$B.h*10)
plotB4(Bout2$B.t*10)
plotB4(Bout4$B4*10, legend=FALSE)
