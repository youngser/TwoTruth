getB2 <- function (A, Y)
{
    n <- nrow(A)
    K <- length(unique(Y))
    B <- matrix(0, K, K)
    for (i in 1:K) {
        for (j in i:K) {
            if (i != j) {
                B[j, i] <- B[i, j] <- mean(A[which(Y == i), which(Y == j)])
            }
            else {
                n.i <- length(which(Y == i))
                B[i, i] <- sum(A[which(Y == i), which(Y == i)])/(n.i^2 - n.i)
            }
        }
    }
    return(B)
}

getB <- function(g, verbose=FALSE)
{
    suppressMessages(library(tidyverse))
    suppressMessages(library(Matrix))

    df <- as.tibble(data.frame(v=as.numeric(V(g)$name),
                               hemisphere=V(g)$hemisphere,
                               tissue=V(g)$tissue,
                               Y=V(g)$Y))

    ## LR
    rho.h <- table(df$hemisphere)
    rho.t <- table(df$tissue)
    h.name <- names(rho.h)
    t.name <- names(rho.t)
    K <- length(rho.h)
    #	df.a <- df %>% arrange(tissue) %>% arrange(hemisphere)
    #	ga <- permute.vertices(g, match(V(g)$name, df.a$v));

    D <- Diagonal(K)
    x <- Matrix(sapply(1:K, function(x) rep(D[,x],times=rho.h)))
    df.a <- df %>% arrange(hemisphere)
    ga <- permute.vertices(g, match(V(g)$name, df.a$v));
    system.time(tau.h <- Matrix::t(x) %*% ga[] %*% x);
    (tau.h <- tau.h/2)

    x <- Matrix(sapply(1:K, function(x) rep(D[,x],times=rho.t)))
    df.a <- df %>% arrange(tissue)
    ga <- permute.vertices(g, match(V(g)$name, df.a$v));
    system.time(tau.t <- Matrix::t(x) %*% ga[] %*% x);
    (tau.t <- tau.t/2)

    #	(tau.h <- sapply(h.name, function(x) sapply(h.name, function(y)
    #    	            sum(ga[][df.a$hemisphere==x,df.a$hemisphere==y])/2)))
    #	(tau.t <- sapply(t.name, function(x) sapply(t.name, function(y)
    #    	            sum(ga[][df.a$tissue==x,df.a$tissue==y])/2)))
    if (verbose) {print(tau.h); print(tau.t)}

    B1 <- matrix(0, K, K); rownames(B1) <- colnames(B1) <- h.name
    B2 <- matrix(0, K, K); rownames(B2) <- colnames(B2) <- t.name
    for (i in 1:K) {
        for (j in 1:K) {
            if (i==j) {
                nn.h <- choose(rho.h[i],2)
                nn.t <- choose(rho.t[i],2)
            } else {
                nn.h <- rho.h[i]*rho.h[j] / 2
                nn.t <- rho.t[i]*rho.t[j] / 2
            }
            B1[i,j] <- tau.h[i,j] / nn.h
            B2[i,j] <- tau.t[i,j] / nn.t
        }
    }
    return(list(B.h=B1,B.t=B2))
    #	round(B,4); #image(Matrix(B))
    #	det(B)
}


getBht <- function(g, Y)
{
    Bout <- getB(g)
    Bh <- Bout$B.h
    Bt <- Bout$B.t
    #				Bh <- Bh[c(1,3),c(1,3)] # c(1,3) for awesomer !!??
    #				Bt <- Bt[c(2,4),c(2,4)] # c(2,4) for awesomer !!??
    Bh <- Bh[c(1,2),c(1,2)]
    Bt <- Bt[c(1,2),c(1,2)]

    x.h <- min(Bh[1,1],Bh[2,2]) / max(Bh[1,1],Bh[2,2])
    y.h	<- Bh[1,2] / max(Bh[1,1],Bh[2,2])
    x.t <- min(Bt[1,1],Bt[2,2]) / max(Bt[1,1],Bt[2,2])
    y.t	<- Bt[1,2] / max(Bt[1,1],Bt[2,2])
    return(c(paste0(x.h, ":", y.h, ",", x.t,":", y.t)))
}
