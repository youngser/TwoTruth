suppressMessages(library(tidyverse))
suppressMessages(library(igraph))
suppressMessages(library(mclust))

#load("data//B4andMore.Rdata")
data(Bout4)

(rho <- Bout4$rho)
(tau <- Bout4$tau)
(B <- Bout4$B4)
(rhop <- rho/sum(rho))

totaln <- 1000
(rnp <- round(rhop*totaln)); sum(rnp)

(n <- sum(rnp))
Y <- factor(rep(names(rnp),rnp))
P <- B[Y,Y]

## ----genA
set.seed(1234)
g1 <- sample_sbm(n, B*10, rnp); summary(g1)

r.names <- names(rho)
df.v <- data.frame(v=1:n,
				   Yh=rep(sapply(r.names, function(x) substr(x,1,1)),times=rnp),
				   Yt=rep(sapply(r.names, function(x) substr(x,2,2)),times=rnp),
				   Y=rep(r.names, times=rnp))
V(g1)$hemisphere <- as.character(df.v$Yh)
V(g1)$tissue <- as.character(df.v$Yt)
V(g1)$Y <- as.character(df.v$Y)
summary(g1)

tab1 <- table(V(g1)$hemisphere, V(g1)$tissue)
tab1 <- cbind(tab1, rowSums(tab1))
(tab1 <- rbind(tab1, colSums(tab1)))


## ----doemb
lcc <- getLCC.sim(g1, weight="binary", use4=FALSE); summary(lcc)
dmax <- 20
emb.ase1 <- doEmbed(lcc, dmax, embed="ASE", abs="abs")
emb.ase2 <- doEmbed(lcc, dmax, embed="ASE", abs="noabs")
emb.ase3 <- doEmbed(lcc, dmax, embed="LSE", abs="abs")
#(elb1 <- getElbows(emb.ase1$embed$D, main=expression(paste("Elbows for ASE using ",group("|",lambda,"|")))))
#(elb2 <- getElbows(emb.ase2$embed$D, main=expression(paste("Elbows for ASE using reordered ",lambda))))
#(elb3 <- getElbows(emb.ase3$embed$D, main="Elbows for LSE"))

## ----runme
runme <- function(X, lcc, elb, dmin=1, Kmax=10, models=NULL, emb="ASE", abs=NULL, plotbic=FALSE, mout=NULL)
{
	if (is.null(mout)) {
		mout <- doMclust.sim(X[,1:max(elb[1],dmin),drop=FALSE], Kmax, lcc, models=models, plot.bic=plotbic)
		if (plotbic) title(mout$mout$modelName);
	} else {
#		plot(mout$mout$df, what="BIC", legendArgs = list(cex=0.5))
	}
	df <- mout$df; rownames(df) <- paste0(emb,":",abs); print(round(df,3))
	if (vcount(lcc) < 1000 & plotbic) {
		plot(mout$mout$data, type="n", xlab="", ylab="")#, xlim=range(mout$mout$data), ylim=range(mout$mout$data))
		title(main=paste0(emb, "(",abs,"): dhat=",max(elb[1],dmin), ", Khat=",mout$mout$G,
		  "\nARI(LR, GW, LRGW) = (",round(df$LR,2), ", ",round(df$GW,2), ", ",round(df$LRGW,2),")"), cex.main=1)
#	plot(mout$mout$data, type="n", main=as.character(round(df,2)))
		text(mout$mout$data, col=mout$mout$class, labels=as.character(V(lcc)$Y), cex=0.5)
	}
	return(mout)
}

## ----dmin4
dmin <- 2
elb1 <- elb2 <- elb3 <- 2
#models <- c("EVV","EEV","EVE","EEE","EVI","EEI","VII","EII")
models <-  mclust.options("emModelNames")

#out1 <- runme(emb.ase1$embed$X, lcc, elb1, dmin, Kmax=c(2,2), models=models, emb="ASE",abs="abs")
out2 <- runme(emb.ase2$embed$X, lcc, elb2, dmin, Kmax=c(2,2), models=models, emb="ASE",abs="noabs")
out3 <- runme(emb.ase3$embed$X, lcc, elb3, dmin, Kmax=c(2,2), models=models, emb="LSE")
tab.ase <- table(Y=V(lcc)$Y, Yhat=out2$mout$class); colnames(tab.ase) <- paste0("ASE-K",1:2)
tab.lse <- table(Y=V(lcc)$Y, Yhat=out3$mout$class); colnames(tab.lse) <- paste0("LSE-K",1:2)
(df <- cbind(ASE=tab.ase, LSE=tab.lse))

