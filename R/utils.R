suppressMessages(library(igraph))
suppressMessages(library(mclust))
suppressMessages(library(fpc))

ptr <- function(g)
{
    if (class(g) != "igraph") {
        if (!is.matrix(g)) stop("the input has to be either an igraph object or a matrix!")
        else {
            if (ncol(g)==2) g <- graph_from_edgelist(g)
            else if (nrow(g)==ncol(g)) g <- graph_from_adjacency_matrix(g, weighted = TRUE)
            else stop("the input matrix is not a graph format!")
        }
    }

    if (is.weighted(g)) {
        W <- E(g)$weight
    } else { # no-op!
        W <- rep(1,ecount(g))
    }

    E(g)$weight <- rank(W)*2 / (ecount(g)+1)
    return(g)
}

giant.component <- function(graph, ...)
{
    cl <- igraph::clusters(graph, ...)
    #    subgraph(graph, which(cl$membership == which.max(cl$csize)-1)-1)
    induced.subgraph(graph, which(cl$membership == which.max(cl$csize)))
}

getLCC.sim <- function(g, weight="ptr", use4=TRUE, thresh=0, label=c("L","R","G","W"))
{
    ## use vertices of LR & GW !!
    if (use4) {
        g <- induced_subgraph(g,
                              V(g)[hemisphere %in% label[1:2] &
                                       tissue %in% label[3:4]])
    }

    g <- giant.component(g)
    #	table(V(gtt.lcc)$hemisphere, V(gtt.lcc)$tissue)
    #	is.connected(gtt.lcc)

    if (is.weighted(g)) {
        if (weight=="ptr") {
            g <- ptr(g)
        } else if (weight=="binary") {
            #			g <- delete_edge_attr(g,"weight")
            E(g)$weight <- ifelse(E(g)$weight>thresh,1,0)
        }
    }

    return(g)
}



getLCC <- function(g, weight="binary", thresh=0)
{
    ## use vertices of LR & GW !!
    ght <- induced_subgraph(g,
                            V(g)[hemisphere %in% c("left", "right") &
                                     tissue %in% c("gray","white")])
    #                            V(g)[hemisphere %in% c("L", "R") &
    #                                     tissue %in% c("G","W")])
    ght.lcc <- giant.component(ght)
    #	table(V(gtt.lcc)$hemisphere, V(gtt.lcc)$tissue)
    #	is.connected(gtt.lcc)

    if (is.weighted(ght.lcc)) {
        if (weight=="ptr") {
            ght.lcc <- ptr(ght.lcc)
        } else if (weight=="binary") {
            E(ght.lcc)$weight <- ifelse(E(ght.lcc)$weight>thresh,1,0)
        }
    }

    return(ght.lcc)
}

# alg:
#  ZG: Zhu & Ghodsi
#  manual: manual dhat
#  else: which(val > 2*sqrt(dmax))
doEmbed <- function(g, dmax, embed="ASE", abs="abs", alg="ZG", plot.elbow=FALSE)
{
    if (embed=="ASE") {
        emb <- embed_adjacency_matrix(g, dmax, options=list(maxiter=500000))
    } else { # type="DAD" => normalized Laplacian
        emb <- embed_laplacian_matrix(g, dmax, type="DAD", options=list(maxiter=500000))
    }

    gname <- graph_attr(g,"name")
    if (abs=="abs") {
        val <- abs(emb$D)
    } else {
        val <- emb$D
        val.ord <- order(val, decreasing = TRUE)
        val <- val[val.ord]
        emb$X <- emb$X[,val.ord]
        emb$Y <- emb$Y[,val.ord]
    }
    emb$D <- val

    if (alg=="ZG") {
        elb <- getElbows(val, plot=plot.elbow,
                         main=paste0(embed,": Elbows for ", gname))
    } else if (alg == "manual") {
        elb <- dmax
    } else {
        elb <- which(val > 2*sqrt(length(val)))
    }
        #	elb[1] <- ifelse(elb[1]==1,2,elb[1])
    return(list(embed=emb, elbow=elb))
}

doMclust <- function(X, Kmax, g, plot.bic=FALSE, verbose=FALSE, M=3000)
{
    if (ncol(X)>1)
        #		modelNames <- c("VII","VEI","VVI","VEE","VVE","VEV","EEV","VVV")
        #		modelNames <- c("VEV","VVV")
        modelNames <- c("VVV")
    else {
        modelNames <- c("E","V")
    }
    if (length(Kmax)>1) {
        Kmin <- Kmax[1]; Kmax <- Kmax[2]
    } else {
        Kmin <- 2; Kmax <- Kmax
    }

    set.seed(12345)
    if (nrow(X) > M) {
        mout <- Mclust(X, Kmin:Kmax, verbose=verbose, modelNames=modelNames, initialization=list(subset=sample(1:nrow(X), size=M)),prior=priorControl())
    } else {
        mout <- Mclust(X, Kmin:Kmax, verbose=verbose, modelNames=modelNames, prior=priorControl())
    }

    #	mout <- Mclust(X, 2:Kmax, verbose=verbose)
    Yhat <- mout$class
    if (plot.bic) plot(mout,what="BIC", legendArgs = list(cex=0.5))
    #	table(V(out.g1)$hemisphere, Yhat1);
    ari.LR <- adjustedRandIndex(V(g)$hemisphere, Yhat)
    #	table(V(out.g1)$tissue, Yhat1);
    ari.GW <- adjustedRandIndex(V(g)$tissue, Yhat)
    #	table(V(out.g1)$Y, Yhat1);
    ari.LRGW <- adjustedRandIndex(V(g)$Y, Yhat)

    df <- data.frame(dhat=ncol(X), Khat=mout$G, LR=ari.LR, GW=ari.GW, LRGW=ari.LRGW)
    if (verbose) print(df)

    return(list(mout=mout, df=df))
}

doMclust.sim <- function(X, Kmax, g, plot.bic=FALSE, verbose=FALSE, M=1000, models=NULL)
{
    if (length(Kmax)>1) {
        Kmin <- Kmax[1]; Kmax <- Kmax[2]
    } else {
        Kmin <- 2; Kmax <- Kmax
    }

    if (ncol(X)==1) {
        if (is.null(models)) models <- c("E","V")
        M <- nrow(X)
    } else {
        if (nrow(X) > M) {
            if (is.null(models)) models <- c("VII","VEI","VVI","VEE","VVE","VEV","VVV")
        } else {
            M <- nrow(X)
            if (is.null(models)) models <- mclust.options("emModelNames")
        }
    }

    mout <- Mclust(X, Kmin:Kmax, verbose=verbose, modelNames=models, initialization=list(subset=sample(1:nrow(X), size=M)))

    #	mout <- Mclust(X, 2:Kmax, verbose=verbose)
    Yhat <- mout$class
    if (plot.bic) plot(mout, what="BIC", legendArgs = list(cex=0.5))
    #	table(V(out.g1)$hemisphere, Yhat1);
    ari.LR <- adjustedRandIndex(V(g)$hemisphere, Yhat)
    #	table(V(out.g1)$tissue, Yhat1);
    ari.GW <- adjustedRandIndex(V(g)$tissue, Yhat)
    #	table(V(out.g1)$Y, Yhat1);
    ari.LRGW <- adjustedRandIndex(V(g)$Y, Yhat)

    df <- data.frame(dhat=ncol(X), Khat=mout$G, LR=ari.LR, GW=ari.GW, LRGW=ari.LRGW)
    if (verbose) print(df)

    return(list(mout=mout, df=df))
}



doKmeans <- function(X, Kmax, g, plot.bic=FALSE, verbose=FALSE, M=3000)
{
    if (length(Kmax)>1) {
        Kmin <- max(Kmax[1],2); Kmax <- min(Kmax[2],nrow(X)/2)
    } else {
        Kmin <- 2; Kmax <- min(Kmax, nrow(X)/2)
    }

    if (nrow(X) > M) {
        pk <- pamk(X, krange=Kmin:Kmax, criterion="multiasw", ns=2, usepam=FALSE)
    } else {
        pk <- pamk(X, krange=Kmin:Kmax)
    }
    Khat <- (Kmin:Kmax)[which.max(pk$crit)]

    Yhat <- pk$pamobject$clustering
    if (plot.bic) plot(pk$crit, type="b")
    #	table(V(out.g1)$hemisphere, Yhat1);
    ari.LR <- adjustedRandIndex(V(g)$hemisphere, Yhat)
    #	table(V(out.g1)$tissue, Yhat1);
    ari.GW <- adjustedRandIndex(V(g)$tissue, Yhat)
    #	table(V(out.g1)$Y, Yhat1);
    ari.LRGW <- adjustedRandIndex(V(g)$Y, Yhat)

    df <- data.frame(dhat=ncol(X), Khat=Khat, LR=ari.LR, GW=ari.GW, LRGW=ari.LRGW)
    if (verbose) print(df)

    return(list(mout=pk, df=df))
}


sclust <- function(g, weight="binary", embed="ASE", dmax=100, alg="ZG", elb=NULL, Kmax=50, clustering="mclust") #was 70
{
    lcc <- getLCC(g, weight=weight)
    Bout <- getB(lcc)
    #	emb.out <- doEmbed(lcc, dmax, embed, abs="noabs", plot.elbow = FALSE);
    emb.out <- doEmbed(lcc, dmax, embed, abs="abs", alg=alg, plot.elbow = FALSE);
    emb <- emb.out$embed;
    if (is.null(elb)) {
        X <- emb$X[,1:max(2, emb.out$elbow[1])]
    } else {
        X <- emb$X[,1:elb, drop=FALSE]
    }

    if(clustering=="mclust") {
        mout <- doMclust(X, Kmax, lcc)
    } else {
        mout <- doKmeans(X, Kmax, lcc)
    }
    df.mc <- mout$df
    return(list(weight=weight,dmax=dmax,Kmax=Kmax,g=lcc,B=Bout,emb=emb.out,mout=mout,df.mc=df.mc))
}
