---
title: "rang: make ancient R code run again"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2023-02-16
categories: [R, package, reproducibility]
---



*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/rang-make-ancient-r-code-run-again/).*

Reproducibility is a [big
issue](https://www.nature.com/articles/s41597-022-01143-6) in the
(computational) world of science. Code that runs today might not run
tomorrow because packages are updated, functions deprecated or removed,
and whole programming languages change. In the case of R, there exist a
great variety of packages to ensure that code written today, also runs
tomorrow (and hopefully also in a few years). Ths includes packages such
as [renv](https://cran.r-project.org/package=renv),
[groundhog](https://cran.r-project.org/package=groundhog),
[miniCRAN](https://cran.r-project.org/package=miniCRAN), and
[Require](https://cran.r-project.org/package=Require).

But the issue of reproducibility hasn’t always been as strong in the
focus as it is today, and particularly old code wasn’t necessarily
prepared to be future proof. Reproducing results of 5 year old code is
hence not as straightforward as simply executing the script.  
Enter the new package [rang](https://github.com/chainsawriot/rang).

![](rang.png)

The goal of rang[¹](#fn1) is to obtain the dependency graph of R
packages at a specific point in time. It can technically be used for
similar purposes as renv, groundhog and others, but its main use case is
as an “Rchaeological” tool, reconstructing historical R computational
environments which have not been completely declared at that point in
time.

You can install the development version of rang like so:

``` r
remotes::install_github("chainsawriot/rang")
```

The package was submitted to CRAN on 15/02/2023 and will hopefully soon
be available via

``` r
install.packages("rang")
```

# Example

``` r
library(rang)
```

The function `resolve()` can be used to obtain the dependency graph of R
packages. Currently, the package supports both CRAN and Github packages.

``` r
x <- resolve(pkgs = c("sna", "schochastics/rtoot"), snapshot_date = "2022-11-30")
```

``` r
graph <- resolve(pkgs = c("openNLP", "LDAvis", "topicmodels", "quanteda"),
                 snapshot_date = "2020-01-16")
graph
```

``` hljs
## resolved: 4 package(s). Unresolved package(s): 0 
## $`cran::openNLP`
## The latest version of `openNLP` [cran] at 2020-01-16 was 0.2-7, which has 3 unique dependencies (2 with no dependencies.)
## 
## $`cran::LDAvis`
## The latest version of `LDAvis` [cran] at 2020-01-16 was 0.3.2, which has 2 unique dependencies (2 with no dependencies.)
## 
## $`cran::topicmodels`
## The latest version of `topicmodels` [cran] at 2020-01-16 was 0.2-9, which has 7 unique dependencies (5 with no dependencies.)
## 
## $`cran::quanteda`
## The latest version of `quanteda` [cran] at 2020-01-16 was 1.5.2, which has 63 unique dependencies (33 with no dependencies.)
```

``` r
#system requirenments
graph$sysreqs
```

``` hljs
## [1] "apt-get install -y default-jdk" "apt-get install -y libxml2-dev"
## [3] "apt-get install -y make"        "apt-get install -y zlib1g-dev" 
## [5] "apt-get install -y libpng-dev"  "apt-get install -y libgsl0-dev"
## [7] "apt-get install -y libicu-dev"  "apt-get install -y python3"
```

``` r
#R version
graph$r_version
```

``` hljs
## [1] "3.6.2"
```

The resolved result is an S3 object called `rang` which can be exported
as an installation script. This script can be execute on a vanilla R
installation.

``` r
export_rang(graph, "rang.R")
```

The execution of the installation script, however, often fails (now) due
to missing system dependencies and incompatible R versions. Therefore,
the approach outlined below should be used for older code.

# Recreate the computational environment via Rocker

A `rang` object can be used to recreate the computational environment
via [Rocker](https://github.com/rocker-org/rocker). Note that the oldest
R version one can get from Rocker is R 3.1.0.

``` r
dockerize(graph, "~/rocker_test")
```

Now, you can build and run the Docker container.

``` bash
cd ~/rocker_test
docker build -t rang .
docker run --rm --name "rangtest" -ti rang
```

The folder “rocker_test” includes a README which gives more details on
how to use docker if you are unfamiliar with it.

More information can also be obtained from the [GitHub
README](https://github.com/chainsawriot/rang) and from the FAQ vignette.

``` r
vignette("faq", package = "rang")
```

If you want to include additional resources (e.g. analysis scripts) you
can set the parameter `material_dir` to the path of the material. This
will then be copied into `output_dir` and in turn also into the Docker
container.

# Recreate the computational environment for R \< 3.1.0

Above I mentioned that Rocker only supports old R version from 3.1.0
onward. But rang can still deal with older versions of R (until 2.1.0),
by generating the docker image differently. In this case, R is compiled
from source and the Dockerfile generated is based on Debian Woody (3.0).
This allows to make any (well, at least most) code dating back to 2005
reproducible again. A solution for code dating back to R 1.0.0 is still
being worked on.

# Further reading

If you are interested in more details on how to run old versions of R, I
suggest [this blog
post](https://chainsawriot.com/postmannheim/2023/01/30/oldestr.html) of
my colleague [Chung-hong Chan](https://github.com/chainsawriot) who is
also the main developer of rang.

In terms or reproducibility in R, I really enjoyed reading these two
posts by [Bruno Rodrigues](https://www.brodrigues.co/about/about):

-   [Reproducibility with Docker and GH Actions in
    R](https://www.brodrigues.co/blog/2022-11-19-raps/)
-   [Layers of Reproducibility in
    R](https://www.brodrigues.co/blog/2023-01-12-repro_r/)

------------------------------------------------------------------------

1.  **R**econstructing **A**ncient **N**umber-crunching **G**ears, but
    actually it is **R** **A**rchiving **N**erds at
    [**G**ESIS](ttps://gesis.org)[↩︎](#fnref1)

