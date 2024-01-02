---
title: "adaR: An accurate, fast and WHATWG-compliant URL parser"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2023-10-01
categories: [R, package]
---



*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/adar-an-accurate-fast-and-whatwg-compliant-url-parser/).*

The other week, I found an interesting looking library on GitHub.
[ada-url](https://github.com/ada-url/ada), a
[WHATWG](https://url.spec.whatwg.org/#url-parsing)-compliant and fast
URL parser written in modern C++. Since we need such a thing at work to
analyze
[webtracking](http://blog.schochastics.net/post/preprocessing-and-analyzing-web-tracking-data-with-webtrackr/)
data, and I recently successfully wrapped [my first C++
library](http://blog.schochastics.net/post/fast-creation-of-lfr-benchmark-graphs-in-r/)
into an R package, I thought I could do the same with ada-url. Little
did I know, that wrapping the library will be the least tricky part of
this endeavor.

![](adaR.png)

## Installation

You can install the development version of adaR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("schochastics/adaR")
```

The version on CRAN can be installed with

``` r
install.packages("adaR")
```

# Parsing URLs with adaR

I have never dealt with anything that had so many corner-cases to
consider than parsing URLs. Here are a few that drove me crazy along the
way.

``` r
readLines("https://raw.githubusercontent.com/schochastics/adaR/main/data-raw/corner.txt")
```

``` hljs
##  [1] "https://example.com:8080"                                               
##  [2] "http://user:password@example.com"                                       
##  [3] "http://[2001:0db8:85a3:0000:0000:8a2e:0370:7334]:8080"                  
##  [4] "https://example.com/path/to/resource?query=value&another=thing#fragment"
##  [5] "http://sub.sub.example.com"                                             
##  [6] "ftp://files.example.com:2121/download/file.txt"                         
##  [7] "http://example.com/path with spaces/and&special=characters?"            
##  [8] "https://user:pa%40ssword@example.com/path"                              
##  [9] "http://example.com/..//a/b/../c/./d.html"                               
## [10] "https://example.com:8080/over/under?query=param#and-a-fragment"         
## [11] "http://192.168.0.1/path/to/resource"                                    
## [12] "http://3com.com/path/to/resource"                                       
## [13] "http://example.com/%7Eusername/"                                        
## [14] "https://example.com/a?query=value&query=value2"                         
## [15] "https://example.com/a/b/c/.."                                           
## [16] "ws://websocket.example.com:9000/chat"                                   
## [17] "https://example.com:65535/edge-case-port"                               
## [18] "file:///home/user/file.txt"                                             
## [19] "http://example.com/a/b/c/%2F%2F"                                        
## [20] "http://example.com/a/../a/../a/../a/"                                   
## [21] "https://example.com/./././a/"                                           
## [22] "http://example.com:8080/a;b?c=d#e"                                      
## [23] "http://@example.com"                                                    
## [24] "http://example.com/@test"                                               
## [25] "http://example.com/@@@/a/b"                                             
## [26] "https://example.com:0/"                                                 
## [27] "http://example.com/%25path%20with%20encoded%20chars"                    
## [28] "https://example.com/path?query=%26%3D%3F%23"                            
## [29] "http://example.com:8080/?query=value#fragment#fragment2"                
## [30] "https://example.xn--80akhbyknj4f/path/to/resource"                      
## [31] "https://example.co.uk/path/to/resource"                                 
## [32] "http://username:pass%23word@example.net"                                
## [33] "ftp://downloads.example.edu:3030/files/archive.zip"                     
## [34] "https://example.com:8080/this/is/a/deeply/nested/path/to/a/resource"    
## [35] "http://another-example.com/..//test/./demo.html"                        
## [36] "https://sub2.sub1.example.org:5000/login?user=test#section2"            
## [37] "ws://chat.example.biz:5050/livechat"                                    
## [38] "http://192.168.1.100/a/b/c/d"                                           
## [39] "https://secure.example.shop/cart?item=123&quantity=5"                   
## [40] "http://example.travel/%60%21%40%23%24%25%5E%26*()"                      
## [41] "https://example.museum/path/to/artifact?search=ancient"                 
## [42] "ftp://secure-files.example.co:4040/files/document.docx"                 
## [43] "https://test.example.aero/booking?flight=abc123"                        
## [44] "http://example.asia/%E2%82%AC%E2%82%AC/path"                            
## [45] "http://subdomain.example.tel/contact?name=john"                         
## [46] "ws://game-server.example.jobs:2020/match?id=xyz"                        
## [47] "http://example.mobi/path/with/mobile/content"                           
## [48] "https://example.name/family/tree?name=smith"                            
## [49] "http://192.168.2.2/path?query1=value1&query2=value2"                    
## [50] "http://example.pro/professional/services"                               
## [51] "https://example.info/information/page"                                  
## [52] "http://example.int/internal/systems/login"                              
## [53] "https://example.post/postal/services"                                   
## [54] "http://example.xxx/age/verification"                                    
## [55] "https://example.xxx/another/edge/case/path?with=query#and-fragment"
```

One corner case that actually made me get interested in URL parsing was
something like `http://example.com/@test`, because the “@” makes the
established parser
[`urltools`](https://cran.r-project.org/web/packages/urltools/index.html)
fold.

``` r
urltools::url_parse("http://example.com/@test")
```

``` hljs
##   scheme domain port path parameter fragment
## 1   http   test <NA> <NA>      <NA>     <NA>
```

Unfortunately, “@” is quite common in URLs these days, thanks to Social
Media and thus appears quite frequently in webtracking data. `adaR` is
able to handle these type of URLs.

``` r
adaR::ada_url_parse("http://example.com/@test")
```

``` hljs
##                       href protocol username password        host    hostname
## 1 http://example.com/@test    http:                   example.com example.com
##   port pathname search hash
## 1        /@test
```

What you can see is that `adaR` follows a different naming scheme and
returns more components than `urltools`. These terms and a more general
introduction to URL parsing can be found in the introductory vignette
via `vignette("adaR")`.

Here is one complete example of a URL that contains all components.

``` r
adaR::ada_url_parse("https://user_1:password_1@example.org:8080/dir/../api?q=1#frag")
```

``` hljs
##                                                      href protocol username
## 1 https://user_1:password_1@example.org:8080/api?q=1#frag   https:   user_1
##     password             host    hostname port pathname search  hash
## 1 password_1 example.org:8080 example.org 8080     /api   ?q=1 #frag
```

`ada_url_parse()` is the power horse of `adaR` which always returns all
components of a URL. An important difference to `urltools` is that
`adaR` only return something, if the input is a valid URL. `urltools`
parses any type of input.

``` r
urltools::url_parse("I am not a URL")
```

``` hljs
##   scheme         domain port path parameter fragment
## 1   <NA> i am not a url <NA> <NA>      <NA>     <NA>
```

``` r
adaR::ada_url_parse("I am not a URL")
```

``` hljs
##             href protocol username password host hostname port pathname search
## 1 I am not a URL     <NA>     <NA>     <NA> <NA>     <NA> <NA>     <NA>   <NA>
##   hash
## 1 <NA>
```

A downside of this strict rule is that URLS without a protocol are not
parsed.

``` r
adaR::ada_url_parse("domain.de/path/to/file") 
```

``` hljs
##                     href protocol username password host hostname port pathname
## 1 domain.de/path/to/file     <NA>     <NA>     <NA> <NA>     <NA> <NA>     <NA>
##   search hash
## 1   <NA> <NA>
```

One can argue if this is either a [bug or a
feature](https://github.com/schochastics/adaR/issues/36), but for the
time being, we remain conform with the underlying c++ library in this
case.

If you only need one specific component of a URL, you can use the
specialized `ada_get_*()` functions. To check if a component is present,
use `ada_has_*()`.

## Benchmark

We conducted a series of Benchmark tests with hard to parse URLs. The
result can be found on
[GitHub](https://github.com/schochastics/adaR/blob/main/data-raw/benchmark.md).
Here I will just summarize some of the runtime results.

``` r
bench::mark(
    urltools = urltools::url_parse("https://user_1:password_1@example.org:8080/dir/../api?q=1#frag"),
    ada = adaR::ada_url_parse("https://user_1:password_1@example.org:8080/dir/../api?q=1#frag", decode = FALSE), iterations = 1000, check = FALSE
)
```

``` hljs
## # A tibble: 2 × 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 urltools      344µs    371µs     2685.    2.49KB     16.2
## 2 ada           513µs    556µs     1778.    2.49KB     16.1
```

``` r
# crawl of the top visited 100 websites (98000 unique URLs)
top100 <- readLines("https://raw.githubusercontent.com/ada-url/url-various-datasets/main/top100/top100.txt")
bench::mark(
    urltools = urltools::url_parse(top100),
    ada = adaR::ada_url_parse(top100, decode = FALSE), iterations = 1, check = FALSE
)
```

``` hljs
## # A tibble: 2 × 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 urltools      182ms    182ms      5.49    8.08MB        0
## 2 ada           217ms    217ms      4.62    9.18MB        0
```

`ada-url` is a really fast parser but to bring this performance to R was
not that easy. While the runtime is still slightly slower, the added
accuracy makes up for this (at least in our use case).

## Public Suffix parsing

The package also implements a public suffix extractor `public_suffix()`,
based on a lookup of the [Public Suffix
List](https://publicsuffix.org/). Note that from this list, we only
include registry suffixes (e.g., com, co.uk), which are those controlled
by a domain name registry and governed by ICANN. We do not include
“private” suffixes (e.g., blogspot.com) that allow people to register
subdomains. Hence, we use the term domain in the sense of “top domain
under a registry suffix”.

``` r
urls <- c(
    "https://subsub.sub.domain.co.uk",
    "https://domain.api.gov.uk",
    "https://thisisnotpart.butthisispartoftheps.kawasaki.jp"
)
adaR::public_suffix(urls)
```

``` hljs
## [1] "co.uk"                            "gov.uk"                          
## [3] "butthisispartoftheps.kawasaki.jp"
```

If you are wondering about the last url. The list also contains wildcard
suffixes such as `*.kawasaki.jp` which need to be matched. *(THIS
specifically was one of the trickier things to implement…)*

As a benchmark, we compare `adaR` with `urltools` and additionally with
[`psl`](https://github.com/hrbrmstr/psl), a wrapper for a C library to
extract public suffix.

``` r
bench::mark(
    urltools = urltools::suffix_extract("https://user_1:password_1@example.org:8080/dir/../api?q=1#frag"),
    ada = adaR::public_suffix("https://user_1:password_1@example.org:8080/dir/../api?q=1#frag"),
    psl = psl::public_suffix("https://user_1:password_1@example.org:8080/dir/../api?q=1#frag"),iterations = 1000, check = FALSE
)
```

``` hljs
## # A tibble: 3 × 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 urltools    329.2µs 371.37µs     2616.   97.16KB     7.87
## 2 ada          18.8µs  19.93µs    49084.    5.17KB     0   
## 3 psl           3.5µs   3.73µs   260571.   17.62KB     0
```

(*This comparison is not fair for `urltools` since the function
`suffix_extract` does more than just extracting the public suffix.*)

psl is clearly the fastest, which is not surprising given that it is
based on extremely efficient C code. Our implementation is quite similar
to how urltools handles suffixes and is not too far behind psl.

So, while psl is clearly favored in terms of runtime, it comes with the
drawback that it is only available via GitHub (which is not optimal if
you want to depend on it) and has a system requirement that (according
to GitHub) is not available on Windows. If those two things do not
matter to you and you need to process an enormous amount of URLs, then
you should use psl.

## Summary

I am not from the marketing department, so I say how it is: adaR does
not bring much new to the table, beside a little more robust URL
parsing. However, this accuracy can be important as when dealing with
webtracking data which is a big deal for us at the moment.

## Addendum

`adaR` is part of a series of R packages to analyse webtracking data:

-   [webtrackR](https://github.com/schochastics/webtrackR): preprocess
    raw webtracking data
-   [domainator](https://github.com/schochastics/domainator): classify
    domains
-   [adaR](https://github.com/schochastics/adaR): parse urls

Huge thanks to my colleague Chung-hong Chan, who greatly improved the
package and alsotaught me one or two things on C++ in R code. He also
wrote a [blog
post](https://chainsawriot.com/postmannheim/2023/10/01/cppqa.html) about
the dev process.

The logo is created from [this
portrait](https://commons.wikimedia.org/wiki/File:Ada_Lovelace_portrait.jpg)
of [Ada Lovelace](https://de.wikipedia.org/wiki/Ada_Lovelace), a very
early pioneer in Computer Science.