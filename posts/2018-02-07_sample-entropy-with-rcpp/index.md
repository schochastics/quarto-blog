---
title: Sample Entropy with Rcpp
author:
- name: David Schoch
  orcid: 0000-0003-2952-4812
date: '2018-02-07'
categories: R

---



*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/sample-entropy-with-rcpp/).*

Entropy. I still shiver when I hear that word, since I never fully
understood that concept. Today marks the first time I was kind of forced
to look into it in more detail. And by “in detail”, I mean I found a
StackOverflow question that had something to do with a problem I am
having (sound familiar?). The problem was is about complexity of time
series and one of the suggested methods was [Sample
Entropy](https://en.wikipedia.org/wiki/Sample_entropy).

``` r
#used packages
library(tidyverse)  # for data wrangling
library(pracma) # for Sample Entropy code
library(Rcpp) # integrate C++ in R
```

# Sample Entropy

Sample entropy is similar to [Approximate
Entropy](https://en.wikipedia.org/wiki/Approximate_entropy) and used for
assessing the complexity of time-series. The less “complex” the time
series is the easier it may be to forecast it.

# Sample Entropy in R

I found two packages that implement sample entropy, `pracma` and
`nonlinearTimeSeries`. I looked into `nonlinearTimeSeries` first but the
data structure seemed a bit too complex on first glance (for me!). So I
decided to go for `pracma`. When you are ok with the default parameters,
then you can simple call `sample_entropy()`.

``` r
set.seed(1886)
ts <- rnorm(200)
sample_entropy(ts)
```

``` hljs
## [1] 2.302585
```

Simple. Problem is, I need to calculate the sample entropy of 150,000
time series. Can the function handle that in reasonable time?

``` r
#calculate sample entropy for 500 time series
set.seed(1886)
A <- matrix(runif(500*200),500,200)
system.time(apply(A,1,function(x)sample_entropy(x)))
```

``` hljs
##    user  system elapsed 
##  40.775   0.004  40.782
```

This translates to several hours for 150,000 time series, which is kind
of not ok. I would prefer it a little faster.

# Sample Entropy with Rcpp

Sample Entropy is actually super easy to implement. So I used my rusty
c++ skills and implemented the function myself with the help of `Rcpp`.

``` r
cppFunction(
  "double SampleEntropy(NumericVector data, int m, double r, int N, double sd)
{
  int Cm = 0, Cm1 = 0;
  double err = 0.0, sum = 0.0;
  
  err = sd * r;
  
  for (unsigned int i = 0; i < N - (m + 1) + 1; i++) {
    for (unsigned int j = i + 1; j < N - (m + 1) + 1; j++) {      
      bool eq = true;
      //m - length series
      for (unsigned int k = 0; k < m; k++) {
        if (std::abs(data[i+k] - data[j+k]) > err) {
          eq = false;
          break;
        }
      }
      if (eq) Cm++;
      
      //m+1 - length series
      int k = m;
      if (eq && std::abs(data[i+k] - data[j+k]) <= err)
        Cm1++;
    }
  }
  
  if (Cm > 0 && Cm1 > 0)
    return std::log((double)Cm / (double)Cm1);
  else
    return 0.0; 
  
}"
)
```

The code can also be found on
[github](https://gist.github.com/schochastics/e3684645763e93cbc2ed7d1b70ee5fe6).

Let’s see if it produces the same output as the `pracma` version.

``` r
set.seed(1886)
ts <- rnorm(200)
sample_entropy(ts)
```

``` hljs
## [1] 2.302585
```

``` r
SampleEntropy(ts,2L,0.2,length(ts),sd(ts))
```

``` hljs
## [1] 2.302585
```

Perfect. Now let’s check if we gained some speed up.

``` r
system.time(apply(A,1,function(x)SampleEntropy(x,2L,0.2,length(ts),sd(ts))))
```

``` hljs
##    user  system elapsed 
##   0.084   0.000   0.084
```

The speed up is actually ridiculous. Remember that the pracma code ran
40 seconds. The Rcpp code not even a tenth of a second. This is
definitely good enough for 150,000 time series.

[
Twitter](https://twitter.com/share?text=Sample%20Entropy%20with%20Rcpp&url=http%3a%2f%2fblog.schochastics.net%2fpost%2fsample-entropy-with-rcpp%2f)
[
Facebook](https://www.facebook.com/sharer/sharer.php?u=http%3a%2f%2fblog.schochastics.net%2fpost%2fsample-entropy-with-rcpp%2f)
[
Google+](https://plus.google.com/share?url=http%3a%2f%2fblog.schochastics.net%2fpost%2fsample-entropy-with-rcpp%2f)
[
LinkedIn](https://www.linkedin.com/shareArticle?mini=true&title=Sample%20Entropy%20with%20Rcpp&url=http%3a%2f%2fblog.schochastics.net%2fpost%2fsample-entropy-with-rcpp%2f&summary=)

Please enable JavaScript to view the [comments powered by
Disqus.](https://disqus.com/?ref_noscript)

# [schochastics](http://blog.schochastics.net/ "schochastics")

[](#)

© 2023 / Powered by [Hugo](https://gohugo.io/)

[Ghostwriter theme](https://github.com/roryg/ghostwriter) By
[JollyGoodThemes](http://jollygoodthemes.com/) /
[Ported](https://github.com/jbub/ghostwriter) to Hugo By
[jbub](https://github.com/jbub)
