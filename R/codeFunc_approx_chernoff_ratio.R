############################################
## codeFunc_approx_chernoff_ratio.R ########
############################################
## J. Cape #################################
############################################

suppressMessages(require(MASS))
suppressMessages(require(Matrix))
suppressMessages(require(methods))
suppressMessages(require(stats))
suppressMessages(require(graphics))
suppressMessages(require(grDevices))
suppressMessages(require(stringr))
suppressMessages(require(utils))

###########################################################
## [BEGIN] Master function: approx_chernoff_ratio #########
###########################################################
## This function computes rho^star in the Chernoff paper ##
###########################################################

approx_chernoff_ratio <- function(matrix.B, vec.pi){
  
    LB <- eigen(matrix.B)
    index.keep <- which(abs(LB$values) > sqrt(.Machine$double.eps))
    vals.B <- LB$values[index.keep]
    vecs.B <- LB$vectors[,index.keep]
    matrix.lp <- vecs.B %*% diag(sqrt(abs(vals.B)), nrow=length(vals.B))
    dim.K <- dim(matrix.lp)[1]
    dim.lp <- dim(matrix.lp)[2]
    Ipq = diag(sign(vals.B))
    
    vec.mu <- colSums(diag(vec.pi) %*% matrix.lp)
    
    delta <- matrix(0, nrow = dim.lp, ncol = dim.lp)
    for(i in 1:dim.K){ delta = delta + vec.pi[i] * (matrix.lp[i,] %o% matrix.lp[i,])}
    delta.inv <- solve(delta)
    
    delta.tilde <- matrix(0, nrow = dim.lp, ncol = dim.lp)
    for(i in 1:dim.K){ delta.tilde = delta.tilde + vec.pi[i] *
      (1/(drop(matrix.lp[i,] %*% Ipq %*% vec.mu))) * (matrix.lp[i,] %o% matrix.lp[i,])}
    delta.tilde.inv <- solve(delta.tilde)
    
    covar_ASE <- function(lp){
      inner.covar <- matrix(0, nrow = dim.lp, ncol = dim.lp)
      for(i in 1:dim.K){ inner.covar = inner.covar + vec.pi[i] *
        drop((lp %*% Ipq %*% matrix.lp[i,]) * (1 - (lp %*% Ipq %*% matrix.lp[i,]))) * 
        matrix.lp[i,] %o% matrix.lp[i,]}
      return(Ipq %*% delta.inv %*% inner.covar %*% delta.inv %*% Ipq)
    }
      
    covar_LSE <- function(lp){
      temp.covar <- matrix(0, nrow = dim.lp, ncol = dim.lp)
      for(i in 1:dim.K){ temp.covar = temp.covar + vec.pi[i] *
        drop(((lp %*% Ipq %*% matrix.lp[i,])*(1 - lp %*% Ipq %*% matrix.lp[i,]))/(lp %*% Ipq %*% vec.mu)) *
        (as.vector(matrix.lp[i,] %*% delta.tilde.inv %*% Ipq / drop(matrix.lp[i,] %*% Ipq %*% vec.mu)) - (lp / drop(2*lp %*% Ipq %*% vec.mu))) %o%
        (as.vector(matrix.lp[i,] %*% delta.tilde.inv %*% Ipq / drop(matrix.lp[i,] %*% Ipq %*% vec.mu)) - (lp / drop(2*lp %*% Ipq %*% vec.mu))) }
      return(temp.covar)
    }
    
    chernoff_ASE <- function(t, lp1, lp2){
      (t*(1-t)/2)*drop(as.vector(lp1 - lp2)%*%solve(t*covar_ASE(lp1) + (1-t)*covar_ASE(lp2))%*%as.vector(lp1 - lp2))
    }
  
    chernoff_LSE <- function(t, lp1, lp2){
      (t*(1-t)/2)*
        drop(
          ((lp1/sqrt(drop(lp1 %*% Ipq %*% vec.mu))) - (lp2/sqrt(drop(lp2 %*% Ipq %*% vec.mu)))) %*%
          solve(t*covar_LSE(lp1) + (1-t)*covar_LSE(lp2)) %*%
          ((lp1/sqrt(drop(lp1 %*% Ipq %*% vec.mu))) - (lp2/sqrt(drop(lp2 %*% Ipq %*% vec.mu))))
          )
    }
    
    all.combs <- t(combn(seq(1:dim.K), 2))
    vec.rhoA <- as.vector(rep(0, length = dim(all.combs)[1]))
    vec.rhoL <- as.vector(rep(0, length = dim(all.combs)[1]))
    
    for(i in 1:dim(all.combs)[1]){
      temp_ASE <- function(t){ chernoff_ASE(t, matrix.lp[all.combs[i,1],], matrix.lp[all.combs[i,2],]) }
      vec.rhoA[i] <- optimize(temp_ASE, interval=c(0,1), maximum=TRUE)$objective
        
      temp_LSE <- function(t){ chernoff_LSE(t, matrix.lp[all.combs[i,1],], matrix.lp[all.combs[i,2],]) }
      vec.rhoL[i] <- optimize(temp_LSE, interval=c(0,1), maximum=TRUE)$objective
    }
    
    return(min(vec.rhoA)/min(vec.rhoL))
    
}  

##################################################
## [END] Master function: approx_chernoff_ratio ##
##################################################
