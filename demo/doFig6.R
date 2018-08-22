suppressMessages(library(tidyverse))
suppressMessages(library(colorRamps))
suppressMessages(library(latex2exp))


data(dd3)
data(dk.df)

dd7 <- dd3 %>% filter(weight=="binary") %>% dplyr::select(-c(x,y))#; head(dd7)
dk.df$graph <- as.factor(dk.df$graph)
df.dk <- dk.df %>% filter(DS=="DS72784" & weight=="binary")
df.dk$scan <- paste("scan", df.dk$scan)
dk <- left_join(df.dk, dd7)#; head(dk,10)
dk$dhat <- as.numeric(as.character(dk$dhat))
dk$Khat <- as.numeric(as.character(dk$Khat))
dk <- dk %>% filter(inout != "yet")

dk2 <- reshape2::melt(dk, id.vars = c(1:7,11))
# ggplot(dk2, aes(x=dhat, y=Khat, col=as.numeric(as.character(value)))) +
#     #	geom_point(alpha=0.5) +
#     geom_jitter(width=0.5,height=0.5,alpha=0.5) + facet_grid(emb~variable) +
#     #    scale_colour_gradientn(colours=rev(rainbow(5))) +
#     scale_color_gradientn(colours=colorRamps::matlab.like(10)) +
#     labs(color = "ARI")
#
# dk2 %>% filter(variable!="LRGW") %>% filter(graph!=50) %>%
#     ggplot(aes(x=dhat, y=Khat, col=as.numeric(as.character(value)))) +
#     #	geom_point(alpha=0.5) +
#     geom_jitter(width=0.5,height=0.5) + facet_grid(emb~variable) +
#     #    scale_colour_gradientn(colours=rev(rainbow(5))) +
#     scale_color_gradientn(colours=colorRamps::matlab.like(10)) +
#     labs(color = "ARI")

#thresh <- 0.00081
thresh <- 0.05
dk3 <- dk2 %>% filter(variable!="LRGW") %>% mutate(value2 = ifelse(value>thresh, thresh, ifelse(value<0,0,value)))
dk3$value2 <- as.numeric(dk3$value2)
pp.ari <- dk3 %>% ggplot(aes(x=dhat, y=Khat, col=value2)) +
    #	geom_point(alpha=0.5) +
    geom_jitter(width=0.5,height=0.5) + facet_grid(emb~variable) +
    scale_color_gradientn(colours=matlab.like(10),
                          label=expression(
                              "0.000",
                              "0.025",
                              "0.050",
                              "0.075",
                              "0.100",
                              "> 0.125")) +
    labs(x=TeX('$\\hat{d}$'), y=TeX('$\\hat{K}$'), color = "ARI")
print(pp.ari)
