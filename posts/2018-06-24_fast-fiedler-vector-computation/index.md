---
title: "Fast Fiedler Vector Computation"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2018-06-24
categories: []
aliases: ["http://archive.schochastics.net/post/fast-fiedler-vector-computation/"]
---

# Fast Fiedler Vector Computation

*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/fast-fiedler-vector-computation/).*


This is a short post on how to quickly calculate the [Fiedler
vector](http://mathworld.wolfram.com/FiedlerVector.html) for large
graphs with the `igraph` package.

``` r
#used libraries
library(igraph)    # for network data structures and tools
library(microbenchmark)    # for benchmark results
```

## Fiedler Vector with `eigen`

My goto approach at the start was using the `eigen()` function to
compute the whole spectrum of the Laplacian Matrix.

``` r
g <- sample_gnp(n = 100,p = 0.1,directed = FALSE,loops = FALSE)
M <- laplacian_matrix(g,sparse = FALSE)
spec <- eigen(M)
comps <- sum(round(spec$values,8)==0)
fiedler <- spec$vectors[,comps-1]
```

While this is easy to implement, it comes with the huge drawback of
computing many unnecessary eigenvectors. We just need one, but we
calculate all 100 in the example. The bigger the graph, the bigger the
overheat from computing all eigenvectors.

``` r
# 100 nodes
g <- sample_gnp(n = 100,p = 0.1,directed = FALSE,loops = FALSE)
M <- laplacian_matrix(g,sparse = FALSE)
system.time(eigen(M))
```

``` hljs
##    user  system elapsed 
##   0.003   0.000   0.004
```

``` r
# 1000 nodes
g <- sample_gnp(n = 1000,p = 0.02,directed = FALSE,loops = FALSE)
M <- laplacian_matrix(g,sparse = FALSE)
system.time(eigen(M))
```

``` hljs
##    user  system elapsed 
##   1.659   0.011   1.672
```

``` r
# 2500 nodes
g <- sample_gnp(n = 2500,p = 0.01,directed = FALSE,loops = FALSE)
M <- laplacian_matrix(g,sparse = FALSE)
system.time(eigen(M))
```

``` hljs
##    user  system elapsed 
##  21.153   0.119  21.276
```

It would thus be useful to have a function that computes only a small
number of eigenvectors, which should speed up the calculations
considerably.

## Fiedler Vector with `arpack`

What I found after some digging is that `igraph` provides an interface
to the ARPACK library for calculating eigenvectors of sparse matrices
via the function `arpack()`.

The function below is an implementation to calculate the Fiedler vector
for connected graphs.

``` r
fiedler_vector <- function(g){
  M <- laplacian_matrix(g, sparse = TRUE)
  f <- function(x,extra = NULL){
    as.vector(M%*%x)
  }
  fvec <- arpack(f,sym = TRUE,options=list(n = vcount(g),nev = 2,ncv = 8, 
                                           which = "SM",maxiter = 2000))
  return(fvec$vectors[,2])
}
```

The parameters `n` and `maxiter` should be self explanatory. `nev`
specifies the number of eigenvectors to return and `which` if it should
be the largest (“LM”) or smallest (“SM”) one’s. Since the Fiedler vector
of connected graphs is the second smallest, we need to return the two
smallest eigenvalues.

Let’s see how much we gain.

``` r
g <- sample_gnp(n = 2500,p = 0.01,directed = FALSE,loops = FALSE)
system.time(fiedler_vector(g))
```

``` hljs
##    user  system elapsed 
##   0.771   0.032   0.812
```

The speed up is enormous (20x) and a nice feature of the `arpack()`
function is that its performance mostly depends on the sparsity of the
graph.

``` r
g <- sample_gnp(n = 10000,p = 0.005,directed = FALSE,loops = FALSE)
system.time(fiedler_vector(g))
```

``` hljs
##    user  system elapsed 
##   0.605   0.004   0.610
```

