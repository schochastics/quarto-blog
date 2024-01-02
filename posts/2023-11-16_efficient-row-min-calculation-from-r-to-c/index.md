---
title: "Efficient row min calculation: From R to C"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2023-11-16
categories: []
aliases: ["http://archive.schochastics.net/post/efficient-row-min-calculation-from-r-to-c/"]
---

# Efficient row min calculation: From R to C

*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/efficient-row-min-calculation-from-r-to-c/).*


My colleague [Chung-hong Chan](https://github.com/chainsawriot) started
a [new package](https://github.com/gesistsa/quanteda.proximity) in our
teams [GitHub organization](https://github.com/gesistsa). [An
issue](https://github.com/gesistsa/quanteda.proximity/issues/20#issue-1995146464)
there caught my attention. The performance was very slow of the main
function. The issue lay somewhere in the
[auxiliary](https://github.com/gesistsa/quanteda.proximity/blob/34377dc140a02dd473e7be53f0f249c676d198ce/R/get_dist.R#L1-L38)
functions. This lead me down quite a rabbit hole to optimize the
calculation of row minimums (you can skip the prelude, if you are not
interested in the backstory).

## Prelude

My goal initially was just to try to work around the identified
bottleneck of the auxiliary functions I isolated the bottleneck part
into a separate function, which looked like this.

``` r
# helper functions taken from the package
.cal_dist <- function(y, poss) {
    return(abs(y - poss))
}

.get_min <- function(pos, x) {
    min(purrr::map_dbl(x, pos))
}

target_idx <- c(4,7)
poss <- 1:1547
count_from <- 1
purrr_min <- function(){
  res <- lapply(target_idx, .cal_dist, poss = poss)
  purrr::map_dbl(poss, .get_min, x = res) + count_from
}
head(purrr_min())
```

``` hljs
## [1] 4 3 2 1 2 2
```

There is a lot of code here that is specific to the original structure
of the package but in essence `purrr_min` calculates the distance for
each element in `poss` to the indices `target_idx`. The output should be
the minimum distance to any index in `target_idx` (incremented by
`count_from`).

``` r
bench::mark(
  purrr_min()
)
```

``` hljs
## Warning: Some expressions had a GC in every iteration; so filtering is
## disabled.
```

``` hljs
## # A tibble: 1 × 6
##   expression       min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr>  <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 purrr_min()   79.5ms   81.4ms      12.3    64.8KB     14.1
```

The performance of one call is not too bad, but this has to be done many
times over and runtime accumulates quite quickly. The original code was
working with lists and purrr, but it is possible to also see this as a
matrix problem: Build a matrix with `length(target_idx)` columns and
`length(poss)` rows and an entry (i,j) of the matrix is the distance of
item i in `poss` to item j in `target_idx`. All that is left to do, is
calculate the minimum in each row to get the same output as above. This
can be a “simple” apply call.

``` r
apply_min <- function(){
  res <- sapply(target_idx, .cal_dist, poss = poss)
  apply(res,1,min)+count_from
}
```

``` r
bench::mark(
  purrr_min(),
  apply_min()
)
```

``` hljs
## Warning: Some expressions had a GC in every iteration; so filtering is
## disabled.
```

``` hljs
## # A tibble: 2 × 6
##   expression       min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr>  <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 purrr_min()  82.99ms  83.71ms      11.7    48.5KB     15.6
## 2 apply_min()   1.74ms   1.84ms     504.    151.3KB     20.0
```

The speed up is insane (it was actually quite surprising to me!). But
can this be even faster?

# Calculating row minimum fast

The prelude established the following optimization problem: Calculate
the minimum in each row of an (integer!) matrix fast. We will work with
the following matrix.

``` r
set.seed(654)
m <- matrix(sample(1:20, 50000, replace = TRUE), ncol = 5)
```

## Pure R solutions

The function derived in the prelude is based on `apply`.

``` r
rowmin_apply <- function(x){
  apply(x,1,min)
}
```

``` r
bench::mark(
  rowmin_apply(m)
)
```

``` hljs
## # A tibble: 1 × 6
##   expression           min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr>      <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 rowmin_apply(m)   11.9ms   14.3ms      68.7     391KB     22.0
```

Can this be improved? As a matter of fact, it can and the solution might
surprise a little.

``` r
rowmin_pmin <- function(x){
  do.call(pmin, as.data.frame(x))
}
```

The function converts the matrix x to a data frame (`pmin` doesn’t work
with matrices) and then applies `pmin` across it. The `pmin` function
takes multiple vectors as input and returns a vector of the minimum
values at each position. `do.call` is used to apply `pmin` across all
columns of the data frame (which are the rows of your original matrix).

This method is more efficient because `pmin` is vectorized and `do.call`
efficiently passes the columns of the data frame as arguments to `pmin`.

``` r
bench::mark(
  apply = rowmin_apply(m),
  pmin = rowmin_pmin(m)
)
```

``` hljs
## # A tibble: 2 × 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 apply        13.2ms   14.6ms      67.9     391KB     26.6
## 2 pmin        355.2µs  446.2µs    2050.      430KB     17.7
```

That is quite a speedup for a function that looks totally off. You can
squeeze out a little bit more by using the fact the matrix has only
integer values.

``` r
rowmin_pmin.int <- function(x){
  do.call(pmin.int, as.data.frame(x))
}
```

``` r
bench::mark(
  apply = rowmin_apply(m),
  pmin = rowmin_pmin(m),
  pmin.int = rowmin_pmin.int(m),
)
```

``` hljs
## # A tibble: 3 × 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 apply        13.2ms   14.1ms      68.3     391KB     21.8
## 2 pmin        356.9µs  406.4µs    2418.      430KB     19.5
## 3 pmin.int    354.4µs  411.7µs    2371.      433KB     19.6
```

At this point, I was sure that I will not be able to squeeze out more in
pure R (maybe there is a way?).

## C++/C solutions

An obvious way to keep optimizing the solution is to switch to Rcpp. Now
my C++ skills are still not the best, but I gave a naïve implementation
a shot.

``` r
Rcpp::cppFunction(
"
NumericVector rowmin_cpp_naive(NumericMatrix mat) {
    int nRows = mat.nrow();
    int nCols = mat.ncol();
    NumericVector mins(nRows);

    for(int i = 0; i < nRows; ++i) {
        double minVal = mat(i, 0);
        for(int j = 1; j < nCols; ++j) {
            if(mat(i, j) < minVal) {
                minVal = mat(i, j);
            }
        }
        mins[i] = minVal;
    }
    return mins;
}
"
)
```

``` r
bench::mark(
  apply = rowmin_apply(m),
  pmin = rowmin_pmin(m),
  pmin.int = rowmin_pmin.int(m),
  cpp_naive = rowmin_cpp_naive(m)
)
```

``` hljs
## # A tibble: 4 × 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 apply        12.1ms   12.5ms      77.0     391KB     38.5
## 2 pmin        403.7µs  495.2µs    1772.      430KB     13.6
## 3 pmin.int    383.8µs  424.8µs    2241.      430KB     19.2
## 4 cpp_naive   103.8µs  120.9µs    7717.      471KB     70.7
```

Nice, so a straightforward C++ implementation is faster. This can
probably be optimized even more, but I didn’t get much further than
this.

Out of pure curiosity, I also ventured into C. My C is really bad, but I
got something to work.

``` r
rowmin_c_naive <- inline::cfunction(
    signature(mat = "integer", nRows = "integer", nCols = "integer"),
    body = "
    int nrows = INTEGER(nRows)[0];
    int ncols = INTEGER(nCols)[0];
    SEXP mins = PROTECT(allocVector(INTSXP, nrows));
    int *pmat = INTEGER(mat);
    int *pmins = INTEGER(mins);

    for(int i = 0; i < nrows; i++) {
        int minVal = pmat[i];
        for(int j = 1; j < ncols; j++) {
            int currentVal = pmat[i + j * nrows];
            if (currentVal < minVal) {
                minVal = currentVal;
            }
        }
        pmins[i] = minVal;
    }

    UNPROTECT(1);
    return mins;
  ",
    language = "C"
)
```

``` r
bench::mark(
  apply = rowmin_apply(m),
  pmin = rowmin_pmin(m),
  pmin.int = rowmin_pmin.int(m),
  cpp_naive = rowmin_cpp_naive(m),
  c_naive = rowmin_c_naive(m,nrow(m), ncol(m))
)
```

``` hljs
## # A tibble: 5 × 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 apply        11.9ms   12.8ms      77.1   390.9KB     33.9
## 2 pmin        346.9µs  400.2µs    2422.    430.2KB     22.4
## 3 pmin.int    325.8µs  364.5µs    2622.    430.2KB     21.4
## 4 cpp_naive    90.2µs  106.3µs    8468.    471.3KB     79.7
## 5 c_naive      29.6µs     31µs   29544.     39.1KB     20.7
```

Again, probably still room for improvement, but I was not expecting to
squeeze out that much with C.

