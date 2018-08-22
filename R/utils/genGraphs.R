require(igraph)
require(tidyverse)
require(stringi)
require(R.utils)

gg_color_hue <- function(n) {
    hues = seq(15, 375, length = n + 1)
    hcl(h = hues, l = 65, c = 100)[1:n]
}

getLabels <- function(dname, gname)
{
    anat_file <- paste0(dname,"/vertex-contract-master/data/DS-anat/",gname,"_desikan.csv")
    anat <- read_csv(anat_file, col_types=cols()); #dim(anat) # 1st col is row index
    Y <- apply(anat[,-1], 1, which.max)
    Yh <- case_when(Y==1 ~ "none", Y>=2 & Y<=36 ~ "L", Y>=37 ~ "R")
    (n <- length(Y))

    tissue_file <- paste0(dname,"/DS-tissue/",gname,"_tissue.csv")
    tissue <- read_csv(tissue_file, col_types=cols()); #dim(tissue) # 1st col is row index
    Yt <- apply(tissue[,-1], 1, which.max)-1;
    Yt <- case_when(Yt==0 ~ "none", Yt==1 ~ "cf", Yt==2 ~ "G", Yt==3 ~ "W")

    Y4 <- paste0(stri_sub(capitalize(Yh),1,1),
                 stri_sub(capitalize(Yt),1,1))
    return(data.frame(Yh=Yh, Yt=Yt, Y4=Y4))
}

getGraphs3 <- function(dname, gname, s=1, i=1)
{
    dname2 <- file.path(dname, gname)
    if (s==1) {
        dirs <- dir(dname2, pattern=glob2rx("*-1_*.edgelist"))
    } else {
        dirs <- dir(dname2, pattern=glob2rx("*-2_*.edgelist"))
    }

    g <- read_graph(file.path(dname2,dirs[i]), format="ncol")

    gnames <- strsplit(dirs,"\\.")[[1]][1]

    ## desikan labels
    Y <- apply(anat[,-1], 1, which.max);
    Yh <- case_when(Y==1 ~ "none", Y>=2 & Y<=36 ~ "left", Y>=37 ~ "right")
    #Yh <- ifelse(Y<=35,"left","right")
    (htab <- table(Yh)); sum(htab)
    (maxv <- max(anat$dsreg))

    # tissue labels
    Yt <- apply(tissue[,-1], 1, which.max)-1;
    Yt <- case_when(Yt==0 ~ "none", Yt==1 ~ "cf", Yt==2 ~ "gray", Yt==3 ~ "white")
    (ttab <- table(Yt)); sum(ttab)

    graph_attr(g, "name") <- gnames
    vname1 <- as.numeric(V(g)$name)
    V(g)$hemisphere <- Yh[vname1]
    V(g)$tissue <- Yt[vname1]
    V(g)$Y <- paste0(stri_sub(capitalize(V(g)$hemisphere),1,1),
                     stri_sub(capitalize(V(g)$tissue),1,1))
    return(g)
}

giant.component <- function(graph, ...) {
    require(igraph)
    cl <- igraph::clusters(graph, ...)
    #    subgraph(graph, which(cl$membership == which.max(cl$csize)-1)-1)
    induced.subgraph(graph, which(cl$membership == which.max(cl$csize)))
}

getLCC <- function(g, weight="none", thresh=0)
{
    source("~/Dropbox/RFiles/lcc-igraph.r")

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


getGraph <- function(type="raw")
{
    wname <- "~/Dropbox/MRC/"
    oname <- paste0(wname,"Output/")
    dname <- paste0(wname,"DATA/")
    gname <- "DS72784"

    ng <- 57
    nscan <- 2
    n <- 72783

    ind <- 1
    glist <- list()
    for (s in 1:nscan) {
        for (i in 1:ng) {
            cat("s = ", s, ", i = ", i, "\n")
            g <- getGraphs3(dname, gname, s, i)
            if (type=="lcc") {
                g <- getLCC(g, "none")
            } else { # "raw" weight
                newv <- setdiff(1:n, as.integer(V(g)$name))
                g <- delete_edge_attr(g,"weight") + vertex(as.character(newv))
                g <- permute.vertices(g, as.integer(V(g)$name)) # match
            }
            glist[[ind]] <- g # rawe
            ind <- ind+1
        }
    }

    if (type=="raw") {
        save(glist, file="TT-glist114-n72783-raw.rda")
    } else {
        save(glist, file="TT-glist114-lcc-binary.rda")
    }
}

sortG <- function(glist, Y)
{
    numg <- length(g)
    n <- length(Y)

    newv <- setdiff(1:n, as.integer(V(glist[[i]])$name))
    gnew <- delete_edge_attr(glist[[i]],"weight") + vertex(as.character(newv))
    gsort <- permute.vertices(gnew, as.integer(V(gnew)$name)) # match
    gsort
}

getAbar <- function(glist, Y)
{
    numg <- length(glist)
    n <- length(Y)

    newv <- setdiff(1:n, as.integer(V(glist[[i]])$name))
    gnew <- delete_edge_attr(glist[[i]],"weight") + vertex(as.character(newv))
    gsort <- permute.vertices(gnew, as.integer(V(gnew)$name)) # match
    gsort
}

plotB4 <- function(B, df=NULL, legend=FALSE, thresh=0.02)
{
    B2 <- melt(B)
    B2 = B2 %>% mutate(rank2=rank(value,ties.method = "first")) %>%
        mutate(col=ifelse(rank2<(nrow(B2)-1),"black","white"))
    #	B2 <- B2 %>% mutate(col=ifelse(value==max(value),"white","black"))
    B2 <- B2 %>% mutate(col=ifelse(value>thresh,"white","black"))

    p <- ggplot(data=B2, aes(x=Var1, y=fct_rev(Var2))) + coord_equal() +
        #		facet_wrap(~scan+weight+L1, ncol=2, scales = 'free') + coord_equal() +
        geom_tile(aes(fill=value)) + geom_text(aes(label=sprintf("%.3f",round(value,3)), color=col), size=10) +
        scale_color_manual(values=c('white'='white', 'black'='black'), guide="none") +
        scale_fill_gradientn(colors=gray(255:0/255), limit=c(0,max(unlist(B)))) +
        theme(axis.title.x=element_blank(), axis.title.y=element_blank(), panel.background = element_rect(fill = "white", colour = "grey50")) +
        theme(axis.text.x=element_text(size=13)) +
        theme(axis.text.y=element_text(size=13))

    if (legend==FALSE) p <- p + theme(legend.position = "none")
    print(p)

    if (!is.null(df)) {
        p2 <- melt(df) %>% ggplot(aes(x=Var1, y=value, fill=Var1)) + xlab("") + ylab("") +
            geom_bar(stat = "identity") + theme(legend.position = "none") +
            geom_text(aes(label=value), position=position_dodge(width=0.9), vjust=-0.25) +
            geom_text(aes(y=value/2,label=paste(round(value/sum(df),2),"%")),position = position_dodge(.9))
        print(p2)
    }
}

