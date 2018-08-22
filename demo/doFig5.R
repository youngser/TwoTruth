suppressMessages(library(tidyverse))

#devtools::use_data(Bht, Bout2, internal = TRUE)
data(sysdata)

a <- 0.50 #value of "a", 0.1
my.max.val <- 100 # 1000 #number of initial steps; increase value when decreasing "a"
my.vals <- t(combn(seq(1:(my.max.val-1)),2))/(my.max.val) #columns for b and c
#my.vals <- t(combn(seq(0:my.max.val),2))/(my.max.val) - 0.01 #columns for b and c
my.vals <- as.data.frame(rbind(my.vals,
                               my.vals[,c(2,1)],
                               replicate(2,seq(1:(my.max.val-1))/(my.max.val))))
colnames(my.vals) <- c("b","c")
my.vals <- my.vals[which((my.vals$b < a) & (my.vals$c < a)),] #restrict to well-defined domain
dim(my.vals)[1] #number of final x/y steps to be plotted

# an ancillary function used to call the main function approx_chernoff_ratio
plotter <- function(vec) {
    vec.pi <- c(1/2,1/2) #specify pi vector
    matrix.B <- matrix(c(a,vec[1],vec[1],vec[2]),nrow=2,ncol=2)
    return(approx_chernoff_ratio(matrix.B, vec.pi)) }

data.pts <- apply(my.vals, 1, plotter)
data <- data.frame(cbind(my.vals/a,data.pts))
colnames(data) <- c("bDIVa","cDIVa","ratio")

## Bout2: internal data
bh.x <- min(Bout2$B.h[1,1],Bout2$B.h[2,2]) / max(Bout2$B.h[1,1],Bout2$B.h[2,2])
bt.x <- min(Bout2$B.t[1,1],Bout2$B.t[2,2]) / max(Bout2$B.t[1,1],Bout2$B.t[2,2])
bh.y <- Bout2$B.h[1,2] / max(Bout2$B.h[1,1],Bout2$B.h[2,2])
bt.y <- Bout2$B.t[1,2] / max(Bout2$B.t[1,1],Bout2$B.t[2,2])
TT <- data.frame(x=c(bh.x,bt.x), y=c(bh.y,bt.y), type=c("{Left,Right}","{Gray,White}"))
levels(Bht$label) <- rev(levels(TT$type))

pp5 <- ggplot(Bht, aes(x=x,y=y)) + #theme(legend.position = "top") +
    geom_point(aes(color=label),alpha=1) + #facet_wrap(~DS) +
    scale_color_manual(values=c("red","blue")) +
    #	geom_text_repel(aes(label=graph, color=model), alpha=1, size=2, force=0.25,
    #					segment.color="lightgrey", segment.alpha = 0.3) +
    xlim(0,1) + ylim(0,1) + coord_fixed(ratio = 1) +
    stat_function(fun=sqrt, geom="line", color="black", linetype="solid") +
    theme(legend.title=element_blank(), legend.position = c(0.1,0.9))

pp6 <- pp5 + geom_tile(data=data, aes(x=cDIVa, y=bDIVa, fill=ratio), alpha=0.5, show.legend=FALSE) +
    stat_contour(data=data, aes(x=cDIVa, y=bDIVa, z=ratio), size=1.1, breaks=seq(1,1.001, by=0.011), color="black") +
    scale_fill_distiller(palette="Spectral") +
    geom_point(aes(x=1,y=1), size=5) +
    #	labs(x="min(a,c) / max(a,c)", y="b / max(a,c)") +
    theme(legend.title=element_blank(), legend.position=c(0.1,0.92)) +
    geom_point(data=Bht, aes(x=x, y=y, color=label)) +
    guides(colour = guide_legend(override.aes = list(size=2,shape=19))) #+
##	geom_point(data=TT, aes(x=x,y=y), size=20, shape="*", stroke=2) +
#	geom_point(data=TT, aes(x=x,y=y), size=17, shape="*", color=c("purple","cyan"))
pp6 <- pp6 + geom_text(data=TT, aes(x=x,y=y), label="★", size=10, family = "HiraKakuPro-W3") +
    geom_text(data=TT, aes(x=x,y=y), label="★", size=5, family = "HiraKakuPro-W3", color=c("red","blue"))
print(pp6)