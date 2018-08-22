suppressMessages(library(tidyverse))
suppressMessages(library(ggExtra)) # for ggMarginal

data(dd3)

pp2 <- dd3 %>% filter(DS=="DS72784" & weight=="binary" & x!=0) %>%
    ggplot(aes(x=x,y=y,label=graph)) + coord_fixed(ratio = 1) +
    geom_point(aes(color=inout),alpha=0.7) +
    xlim(-0.05,0.15) + ylim(-0.15,0.05) +
    labs (x="ARI(LSE,LR) - ARI(LSE,GW)",y="ARI(ASE,LR) - ARI(ASE,GW)") +
    annotate("rect", xmin = 0, xmax = Inf, ymin = -Inf, ymax = 0,
             alpha = 0.2, fill = c("orange")) + theme(legend.position = "none")
pp3 <- ggMarginal(pp2, type="histogram", size=8, fill="lightgrey")
print(pp3)
