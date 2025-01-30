---
title: Introducing graphlayouts with Game of Thrones
author:
- name: David Schoch
  orcid: 0000-0003-2952-4812
date: '2019-04-14'
categories:
- R
- networks
- visualization

---



*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/introducing-graphlayouts-with-got/).*

**The post has been updated because the API has changed since the
release of this post. Checkout the new API in the [release
post](http://blog.schochastics.net/post/graphlouts-v0-5-0/)**

This post introduces the new R package `graphlayouts` which is available
on [CRAN](https://cran.r-project.org/package=graphlayouts) since a few
days. We will use network data from the *Game of Thrones* TV series
(seemed timely at the time of writing) to illustrate the core layout
algorithms of the package. Most of the algorithms use stress
majorization as its basis, which I described in more detail in and
[older](http://blog.schochastics.net/post/stress-based-graph-layouts/)
post. Here, I will only focus on the practical aspects of the package.

![](got_all.png)

``` r
library(tidyverse)
library(igraph)
library(graphlayouts)
library(ggraph)
library(extrafont)
loadfonts()
```

# Preparing the Data

To illustrate the functionality of `graphlayouts` we will use data
compiled from the TV Show *Game of Thrones*, specifically the character
interaction networks. See
[here](https://www.macalester.edu/~abeverid/thrones.html) and
[here](https://networkofthrones.wordpress.com/) for original work with
the data. The raw data can be downloaded from
[github](https://github.com/mathbeveridge/gameofthrones). We do this
using the `map()` function of `purrr`.

``` r
edges <- paste0("https://raw.githubusercontent.com/mathbeveridge/gameofthrones/master/data/got-s",1:7,"-edges.csv")
edges_tbl <- map(edges,read_csv)
```

Next, we transform the raw edgelists into igraph objects, again using
`map`.

``` r
got_graphs <- map(1:7,function(x) {
    g <- graph_from_data_frame(edges_tbl[x],directed = F)
    g$title <- paste0("Season ",x)
    g
  })
```

Lastly, we transform and add some node variables. First, we change the
character names from upper case to title case. Then we compute a
clustering, and the total number of interactions per character.

``` r
mutate_graph <- function(x){
  V(x)$name <- str_replace_all(V(x)$name,"\\_"," ") %>% 
    str_to_title()
  clu <- cluster_louvain(x)
  V(x)$clu <- as.character(clu$membership)
  V(x)$size <- graph.strength(x)
  x
}

got_graphs <- map(got_graphs,mutate_graph)
```

`got_graphs` now contains all seven season networks in a list.
~~`graphlayouts` contains the function `qgraph()` which can be used to
get a very rough visualization of the network, without the need of
lengthy `ggraph` code.~~ The function `qgraph()` is now part of
`ggraph`.

``` r
qgraph(got_graphs[[1]])
```

![](qgraph_ex-1.png)

# Visualizing each season

The core layout algorithm of `graphlayouts` is implemented in the
function `layout_with_stress()`, which is also called in `qgraph` by the
way. The package also contains a convenience function to work smoothly
with `ggraph`. Instead of

``` r
xy <- layout_with_stress(x)
ggraph(x,layout="manual",x=xy[,1],y=xy[,2])+...
```

you can do

``` r
ggraph(x,layout = "stress")+...
```

Creating nice plots is now “just” a matter of stitching some `ggraph`
code together. For our character networks, we define a function that
does that for all seasons simultaneously. I usually would not use hard
to read fonts for visualizations but I thought *Enchanted Land*
(available [here](https://www.dafont.com/enchanted-land.font)) kind of
fits here.

``` r
got_palette <- c("#1A5878","#C44237","#AD8941","#E99093",
                 "#50594B","#DE9763","#5D5F5D","#E2E9E7")

plot_graph <- function(x){
  ggraph(x,layout = "stress")+
    geom_edge_link0(aes(width=Weight),edge_colour="grey66")+
    geom_node_point(aes(fill=clu,size=size),shape=21,col="grey25")+
    geom_node_text(aes(size=size,label=name),family = "Enchanted Land",repel=F)+
    scale_edge_width_continuous(range=c(0.1,1.5))+
    scale_size_continuous(range=c(1,8))+
    scale_fill_manual(values=got_palette)+
    theme_graph(title_family = "Enchanted Land",
                title_size = 20)+
    labs(title=paste0("Game of Thrones (",x$title,")"))+
    theme(legend.position = "none")
}

got_plot <- map(got_graphs,plot_graph)
got_plot[[1]]
```

![](plot_fct-1.png) *(Open image in a new tab to view it in
full size)*

The advantages of stress based layouts are outlined in [this
post](http://blog.schochastics.net/post/stress-based-graph-layouts/). It
has been my goto layout algorithm since years and I’d wish that more SNA
software would implement it. The below figure shows all seven network in
one plot.

![](all_seasons_small_multiple-1.png)

# Focus on Characters

While “stress” is the key graph layout in the package, there are other,
more specialized layouts that can be used for different purposes.
`layout_with_focus()` for instance allows you to focus the network on a
specific character and order all other nodes in concentric circles
(depending on distance) around it. Here is Season one with focus on Ned
Stark.

``` r
ggraph(got_graphs[[1]],"focus",focus=1)+
  geom_edge_link0(aes(width=Weight),edge_colour="grey66")+
  geom_node_point(aes(fill=clu,size=size),shape=21,col="grey25")+
  geom_node_text(aes(filter=(name=="Ned"),size=size,label=name),family = "Enchanted Land",repel=F)+
  scale_edge_width_continuous(range=c(0.2,0.9))+
  scale_size_continuous(range=c(1,8))+
  scale_fill_manual(values=got_palette)+
  theme_graph(title_family = "Enchanted Land",
              subtitle_family = "Enchanted Land",
              title_size = 20,
              subtitle_size = 16)+
  labs(title=paste0("Game of Thrones (Season 1)"),
       subtitle = "Focus on Ned Stark")+
  theme(legend.position = "none")
```

![](focus_ned-1.png)

Based on a similar principle is `layout_with_centrality()`. You can
specify any centrality index (or numeric vector for that matter), and
create a concentric layout where the most central nodes are put in the
center.

``` r
ggraph(got_graphs[[1]],layout="centrality",cent=graph.strength(got_graphs[[1]]))+
  geom_edge_link0(aes(width=Weight),edge_colour="grey66")+
  geom_node_point(aes(fill=clu,size=size),shape=21,col="grey25")+
  geom_node_text(aes(size=size,label=name),family = "Enchanted Land",repel=F)+
  scale_edge_width_continuous(range=c(0.2,0.9))+
  scale_size_continuous(range=c(1,8))+
  scale_fill_manual(values=got_palette)+
  theme_graph(title_family = "Enchanted Land",
              title_size = 20)+
  labs(title=paste0("Game of Thrones (Season 1)"),
       subtitle = "weighted degree layout")+
  theme(legend.position = "none")
```

![](cent_layout1-1.png)

To get someone else in the center than Ned Stark, here is season seven.

``` r
ggraph(got_graphs[[7]],layout="centrality",cent=graph.strength(got_graphs[[7]]))+
  geom_edge_link0(aes(width=Weight),edge_colour="grey66")+
  geom_node_point(aes(fill=clu,size=size),shape=21,col="grey25")+
  geom_node_text(aes(size=size,label=name),family = "Enchanted Land",repel=F)+
  scale_edge_width_continuous(range=c(0.2,0.9))+
  scale_size_continuous(range=c(1,8))+
  scale_fill_manual(values=got_palette)+
  theme_graph(title_family = "Enchanted Land",
              title_size = 20)+
  labs(title=paste0("Game of Thrones (Season 7)"),
       subtitle = "weighted degree layout")+
  theme(legend.position = "none")
```

![](cent_layout7-1.png)

# Combining all Seasons

The last important layout algorithm is `layout_as_backbone()` which is
tailored to work with “hairball” networks that may contain a hidden
group structure. The below plot shows its impressive performance.

![](hairball.jpg)

Of course the network used in the above example is specifically tailored
to show this power. So what about real networks?

We will put all seasons together and create one big GoT network that
contains all character interactions from Season 1-7 to illustrate its
performance with our example.

``` r
got_all <- map_dfr(edges_tbl,bind_rows) %>% 
  group_by(Source,Target) %>% 
  summarise(Weight=sum(Weight)) %>% 
  ungroup() %>% 
  rename(weight=Weight) %>% 
  mutate_if(is.character,function(x) str_replace_all(x,"\\_"," ") %>% 
              str_to_title()) %>% 
  graph_from_data_frame(directed=FALSE)

clu <- cluster_louvain(got_all)
V(got_all)$clu <- as.character(clu$membership)
V(got_all)$size <- graph.strength(got_all)
```

First, let’s check what it looks like using `layout_with_stress()`.

``` r
ggraph(got_all,layout="stress")+
  geom_edge_link0(aes(width=weight),edge_colour="grey66",alpha=0.5)+
  geom_node_point(aes(fill=clu,size=size),shape=21)+
  scale_edge_width_continuous(range=c(0.8,1.8))+
  scale_size_continuous(range=c(2,10))+
  scale_fill_manual(values=got_palette)+
  theme_graph(title_family = "Enchanted Land",
              subtitle_family = "Enchanted Land",
              title_size = 20,
              subtitle_size = 16)+
  labs(title=paste0("Game of Thrones"),subtitle = "Character Network (Season 1-7)")+
  theme(legend.position = "none")
```

![](got_all_stress-1.png)

It is clearly hard to see anything here, since the network is too dense.
Enter, `layout_as_backbone()`. The algorithm itself is rather involved
but some of the key points are:

-   Find strongly embedded edges depending on graph motifs
-   Compute the union of all maximum spanning trees to “hold the network
    together”

If you are interested in all the technical details, consult the
[original
paper](http://jgaa.info/accepted/2015/NocajOrtmannBrandes2015.19.2.pdf).

`layout_as_backbone()` takes a parameter `to_keep` which determines the
percentage of edges to keep for the layout calculation. In our case, we
will the 20% most embedded edges. (The parameter always requires some
experimenting to find out what works best). Note that this does not mean
that we throw away the rest of the edges. They are just not used to
calculate the layout. But you can still do that afterwards (as we will
do here) since the function returns a logical vector which indicates if
an edge belongs to the backbone or not.

``` r
bb <- layout_as_backbone(got_all,keep=0.2)
E(got_all)$backbone <- F
E(got_all)$backbone[bb$backbone] <- T

ggraph(got_all,layout="manual",x=bb$xy[,1],y=bb$xy[,2])+
  geom_edge_link0(aes(filter=backbone,width=weight),edge_colour="grey66",alpha=0.5)+
  geom_node_point(aes(fill=clu,size=size),shape=21)+
  geom_node_text(aes(filter=(size>=800),size=size,label=name),
                 family = "Enchanted Land",repel=T)+
  scale_edge_width_continuous(range=c(0.8,1.8))+
  scale_size_continuous(range=c(2,10))+
  scale_fill_manual(values=got_palette)+
  theme_graph(title_family = "Enchanted Land",
              subtitle_family = "Enchanted Land",
              title_size = 20,
              subtitle_size = 16)+
  labs(title=paste0("Game of Thrones"),subtitle = "Character Network (Season 1-7)")+
  theme(legend.position = "none")
```

![](got_backbone-1.png)

There is definitely not as much structure going on as in the contrived
example. The algorithm can’t uncover a hidden structure if there is no
such thing to uncover. Yet, the layout still reveals some structure and
clearly enhances readability over the stress based layout.

# Addendum

This post introduced only the core layout algorithms of `graphlayouts`.
Check out the vignette of the package for a more extensive list of
algorithms. Also, if you are having trouble with the `ggraph` code,
check out my [RStudio Addin](https://github.com/schochastics/snahelper)
that provides a tiny GUI to plot networks. Now that `graphlayouts` is
out, I will continue working on that package.

