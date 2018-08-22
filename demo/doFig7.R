suppressMessages(library(tidyverse))
suppressMessages(library(ggExtra))

data(dd3)

# df <- twotruth %>% select(label, x, y)
# levels(df$label) <- c("{Gray,White}", "{Left,Right}")
#
# pp1 <- df %>%
#     ggplot(aes(x=x,y=y)) + #theme(legend.position = "top") +
#     geom_point(aes(color=label),alpha=1) + #facet_wrap(~DS) +
#     scale_color_manual(values=c("red","blue")) +
#     xlim(0,1) + ylim(0,1) + coord_fixed(ratio = 1) +
#     stat_function(fun=sqrt, geom="line", color="black", linetype="solid") +
#     theme(legend.title=element_blank(), legend.position = c(0.1,0.9))
#
pp2 <- dd3 %>% filter(DS=="DS72784" & weight=="binary" & x!=0) %>%
    ggplot(aes(x=x,y=y,label=graph)) + coord_fixed(ratio = 1) +
    #		geom_text_repel(size=1,segment.color="lightgrey") +
    geom_point(aes(color=inout),alpha=0.7) + #facet_wrap(~graph, scales="fixed", ncol=4) + scale_color_manual(values=dcol) +
    xlim(-0.05,0.15) + ylim(-0.15,0.05) +
    labs (x="ARI(LSE,LR) - ARI(LSE,GW)",y="ARI(ASE,LR) - ARI(ASE,GW)") +
    annotate("rect", xmin = 0, xmax = Inf, ymin = -Inf, ymax = 0,
             alpha = 0.2, fill = c("orange")) + theme(legend.position = "none")
#         geom_rug(col=rgb(.5,0,0,alpha=.2))
pp3 <- ggMarginal(pp2, type="histogram", size=8, fill="lightgrey") #groupColour=TRUE, groupFill=TRUE)
print(pp3)
