---
title: "Analyzing NBA Player Data I: Getting Data"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2018-03-03
categories: [R, data analysis, sports]
---



*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/analyzing-nba-player-data-i-getting-data/).*

As a football (soccer) data enthusiast, I have always been jealous of
the amount of available data for American sports. While much of the
interesting football data is proprietary, you can can get virtually
anything of interest for the NBA, MLB, NFL or NHL.

I have decided to move away from football for a moment and write a
little series on *Analyzing NBA player data*. The series will go through
all the major steps in a data analytic pipeline, such as obtaining,
cleaning, exploring and analyzing data, with a rich set of statistics
for NBA players.

In this post, we will learn how to scrape relevant data from
[basketball-reference](http://blog.schochastics.net/post/analyzing-nba-player-data-i-getting-data/basketball-reference.com)
and how to turn the data into a clean usable data frame.

``` r
#used packages
library(tidyverse)  # for data wrangling
library(janitor)  # for data cleaning
library(rvest)      # for web scraping
library(corrplot)   # correlation plots
```

# Data Source

[basketball-reference](http://blog.schochastics.net/post/analyzing-nba-player-data-i-getting-data/basketball-reference.com)
offers a big variety of data for the NBA. But it is not only its data
richness what makes it our source. It is particularly interesting due to
its non-flashy simple format, which is always good if you want to scrape
data (*“The less fancy a page, the easier to scrape”*).

We are specifically interested in the player related stats per season.
The list of available seasons on basketball-reference.com can be found
[here](https://www.basketball-reference.com/leagues/). If you click on a
few, you will notice, that the links all have a similar structure. For
last years season the link looks like this:

> <https://www.basketball-reference.com/leagues/NBA_2017.html>

Simply changing the 2017 to 2016 will bring you to the season 2015/16.
We will use this insight in the next section to build a powerful
scraping function.

If you are familiar enough with scraping, or don’t really care about
that part, you can use the `ballr` package to get player data.

# Scraping Player Data

In this section, we will develop a function which automatically scrapes
all available player stats for a season and puts them in a nice format.
This is gonna be the very basic structure:

``` r
scrape_stats <- function(season){
  #scrape
  #clean
  return(player_stats)
}
```

If you look at the page of a season, you’ll find a section that contains
the six categories
`Per Game, Totals, Per 36 Minutes, Per 100 Possessions, Advanced` for
Player Stats. We here focus on Totals, Per 36 Minutes and Advanced. But
the described procedure also works with the other categories. The links
to the stats for last season look as follows

-   <https://www.basketball-reference.com/leagues/NBA_2017_totals.html>
-   <https://www.basketball-reference.com/leagues/NBA_2017_per_minute.html>
-   <https://www.basketball-reference.com/leagues/NBA_2017_advanced.html>

So we simply have to append the stats we want to our season link and we
are good to go.

Let’s start with getting the total statistics per player. Below is the
basic `rvest` code to get the html table shown on the page.

``` r
url <- "https://www.basketball-reference.com/leagues/NBA_2017_totals.html"
stats <- url %>% 
  read_html() %>% 
  html_table() %>% 
  .[[1]]

str(stats)
```

``` hljs
## 'data.frame':    619 obs. of  30 variables:
##  $ Rk    : chr  "1" "2" "2" "2" ...
##  $ Player: chr  "Alex Abrines" "Quincy Acy" "Quincy Acy" "Quincy Acy" ...
##  $ Pos   : chr  "SG" "PF" "PF" "PF" ...
##  $ Age   : chr  "23" "26" "26" "26" ...
##  $ Tm    : chr  "OKC" "TOT" "DAL" "BRK" ...
##  $ G     : chr  "68" "38" "6" "32" ...
##  $ GS    : chr  "6" "1" "0" "1" ...
##  $ MP    : chr  "1055" "558" "48" "510" ...
##  $ FG    : chr  "134" "70" "5" "65" ...
##  $ FGA   : chr  "341" "170" "17" "153" ...
##  $ FG%   : chr  ".393" ".412" ".294" ".425" ...
##  $ 3P    : chr  "94" "37" "1" "36" ...
##  $ 3PA   : chr  "247" "90" "7" "83" ...
##  $ 3P%   : chr  ".381" ".411" ".143" ".434" ...
##  $ 2P    : chr  "40" "33" "4" "29" ...
##  $ 2PA   : chr  "94" "80" "10" "70" ...
##  $ 2P%   : chr  ".426" ".413" ".400" ".414" ...
##  $ eFG%  : chr  ".531" ".521" ".324" ".542" ...
##  $ FT    : chr  "44" "45" "2" "43" ...
##  $ FTA   : chr  "49" "60" "3" "57" ...
##  $ FT%   : chr  ".898" ".750" ".667" ".754" ...
##  $ ORB   : chr  "18" "20" "2" "18" ...
##  $ DRB   : chr  "68" "95" "6" "89" ...
##  $ TRB   : chr  "86" "115" "8" "107" ...
##  $ AST   : chr  "40" "18" "0" "18" ...
##  $ STL   : chr  "37" "14" "0" "14" ...
##  $ BLK   : chr  "8" "15" "0" "15" ...
##  $ TOV   : chr  "33" "21" "2" "19" ...
##  $ PF    : chr  "114" "67" "9" "58" ...
##  $ PTS   : chr  "406" "222" "13" "209" ...
```

You will notice that all the columns are in a character format. This is
because the html table contains the header every 20 lines. So in the
next step, we will get rid of this lines and also use the `janitor`
package to do some basic cleaning such as fixing the column names.
Additionally, we clean the data by turning the stats to numeric
variables and NA to 0.

``` r
stats <- stats %>% 
  remove_empty_cols() %>%  #if any exist
  clean_names() %>%        # all column names to lower case and removing "%"
  dplyr::filter(!player=="Player") %>%  #delete headers in data frame
  mutate_at(vars(-c(player,tm,pos)),as.numeric) %>% #turn all stat cols to numeric
  mutate_at(vars(-c(player,tm,pos)), funs(replace(., is.na(.), 0))) %>% #turn NA to 0
  as_tibble()
str(stats)
```

``` hljs
## Classes 'tbl_df', 'tbl' and 'data.frame':    595 obs. of  30 variables:
##  $ rk        : num  1 2 2 2 3 4 5 6 7 8 ...
##  $ player    : chr  "Alex Abrines" "Quincy Acy" "Quincy Acy" "Quincy Acy" ...
##  $ pos       : chr  "SG" "PF" "PF" "PF" ...
##  $ age       : num  23 26 26 26 23 31 28 28 31 27 ...
##  $ tm        : chr  "OKC" "TOT" "DAL" "BRK" ...
##  $ g         : num  68 38 6 32 80 61 39 62 72 61 ...
##  $ gs        : num  6 1 0 1 80 45 15 0 72 5 ...
##  $ mp        : num  1055 558 48 510 2389 ...
##  $ fg        : num  134 70 5 65 374 185 89 45 500 77 ...
##  $ fga       : num  341 170 17 153 655 ...
##  $ fgpercent : num  0.393 0.412 0.294 0.425 0.571 0.44 0.5 0.523 0.477 0.458 ...
##  $ x3p       : num  94 37 1 36 0 62 0 0 23 0 ...
##  $ x3pa      : num  247 90 7 83 1 151 4 0 56 1 ...
##  $ x3ppercent: num  0.381 0.411 0.143 0.434 0 0.411 0 0 0.411 0 ...
##  $ x2p       : num  40 33 4 29 374 123 89 45 477 77 ...
##  $ x2pa      : num  94 80 10 70 654 269 174 86 993 167 ...
##  $ x2ppercent: num  0.426 0.413 0.4 0.414 0.572 0.457 0.511 0.523 0.48 0.461 ...
##  $ efgpercent: num  0.531 0.521 0.324 0.542 0.571 0.514 0.5 0.523 0.488 0.458 ...
##  $ ft        : num  44 45 2 43 157 83 29 15 220 23 ...
##  $ fta       : num  49 60 3 57 257 93 40 22 271 33 ...
##  $ ftpercent : num  0.898 0.75 0.667 0.754 0.611 0.892 0.725 0.682 0.812 0.697 ...
##  $ orb       : num  18 20 2 18 281 9 46 51 172 105 ...
##  $ drb       : num  68 95 6 89 332 116 131 107 351 114 ...
##  $ trb       : num  86 115 8 107 613 125 177 158 523 219 ...
##  $ ast       : num  40 18 0 18 86 78 12 25 139 57 ...
##  $ stl       : num  37 14 0 14 89 21 20 25 46 18 ...
##  $ blk       : num  8 15 0 15 78 6 22 23 88 24 ...
##  $ tov       : num  33 21 2 19 146 42 31 17 98 29 ...
##  $ pf        : num  114 67 9 58 195 104 77 85 158 78 ...
##  $ pts       : num  406 222 13 209 905 ...
```

Now we have a relatively clean stats table. If you examine it carefully,
you will notice that some players occur several times, namely those that
switched Franchises. We will only keep their total statistics so we can
do a simple slicing.

``` r
stats <- stats %>% 
  group_by(player) %>% 
  slice(1) %>% 
  ungroup()
```

And we are done. Now we wrap all these steps into our function to obtain
the total stats for any given season, making use of the simple link
structure.

``` r
scrape_stats <- function(season = 2017){
  #scrape
  url <- paste0("https://www.basketball-reference.com/leagues/NBA_",season,"_totals.html")
  stats_tot <- url %>% 
    read_html() %>% 
    html_table() %>% 
    .[[1]]
  
  #clean
  player_stats <- stats_tot %>% 
    remove_empty_cols() %>%
    clean_names() %>% 
    dplyr::filter(!player=="Player") %>%
    mutate_at(vars(-c(player,tm,pos)),as.numeric) %>% 
    mutate_at(vars(-c(player,tm,pos)), funs(replace(., is.na(.), 0))) %>% 
    as_tibble() %>% 
    group_by(player) %>% 
    slice(1) %>% 
    ungroup() %>% 
    select(-rk)
  return(player_stats)
}
```

That’s some major piping going on there. Notice that I added one more
line to delete the column rk, which we do not need.

We can test the function using a different season.

``` r
 scrape_stats(season = 2012)
```

``` hljs
## # A tibble: 478 x 30
##       rk player     pos     age tm        g    gs    mp    fg   fga fgper…
##    <dbl> <chr>      <chr> <dbl> <chr> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>
##  1 357   A.J. Price PG     25.0 IND    44.0  1.00   568  59.0   174  0.339
##  2 177   Aaron Gray C      27.0 TOR    49.0 40.0    813  83.0   161  0.516
##  3 191   Al Harrin… PF     31.0 DEN    64.0  1.00  1761 345     773  0.446
##  4 216   Al Horford C      25.0 ATL    11.0 11.0    348  57.0   103  0.553
##  5 236   Al Jeffer… C      27.0 UTA    61.0 61.0   2075 516    1048  0.492
##  6  11.0 Al-Farouq… SF     21.0 NOH    66.0 21.0   1477 150     365  0.411
##  7  14.0 Alan Ande… SF     29.0 TOR    17.0 12.0    461  55.0   142  0.387
##  8  70.0 Alec Burks SG     20.0 UTA    59.0  0      939 153     357  0.429
##  9 164   Alonzo Gee SG     24.0 CLE    63.0 31.0   1827 227     551  0.412
## 10 407   Amar'e St… PF     29.0 NYK    47.0 47.0   1543 316     654  0.483
## # ... with 468 more rows, and 19 more variables: x3p <dbl>, x3pa <dbl>,
## #   x3ppercent <dbl>, x2p <dbl>, x2pa <dbl>, x2ppercent <dbl>,
## #   efgpercent <dbl>, ft <dbl>, fta <dbl>, ftpercent <dbl>, orb <dbl>,
## #   drb <dbl>, trb <dbl>, ast <dbl>, stl <dbl>, blk <dbl>, tov <dbl>,
## #   pf <dbl>, pts <dbl>
```

Works perfectly!

Now we want to include the additional per minute and advanced stats. The
procedure is very much the same as for the totals. The only thing we
have to check is that we do not produce columns with duplicated names,
since especially the per minute stats are essential the total stats
broken down to 36 minutes. We use the `rename_at()` function to append
"\_pm" to all columns containing stats to differentiate them from the
total stats.

``` r
url <- "https://www.basketball-reference.com/leagues/NBA_2017_per_minute.html"
stats <- url %>% 
  read_html() %>% 
  html_table() %>% 
  .[[1]]

stats_pm <- stats %>% 
  remove_empty_cols() %>%
  clean_names() %>% 
  dplyr::filter(!player=="Player") %>%
  mutate_at(vars(-c(player,tm,pos)),as.numeric) %>% 
  mutate_at(vars(-c(player,tm,pos)), funs(replace(., is.na(.), 0))) %>% 
  as_tibble() %>% 
  group_by(player) %>% 
  slice(1) %>% 
  ungroup() %>% 
  rename_at(vars(9:29),funs(paste0(.,"_pm")))
```

For the advanced stats we do not need to alter the names, since they are
unique. The below function is now the final version to obtain the
desired player data.

``` r
scrape_stats <- function(season = 2017){
  #total stats
  #scrape
  url <- paste0("https://www.basketball-reference.com/leagues/NBA_",season,"_totals.html")
  stats_tot <- url %>% 
    read_html() %>% 
    html_table() %>% 
    .[[1]]
  
  #clean
  player_stats_tot <- stats_tot %>% 
    remove_empty_cols() %>%
    clean_names() %>% 
    dplyr::filter(!player=="Player") %>%
    mutate_at(vars(-c(player,tm,pos)),as.numeric) %>% 
    mutate_at(vars(-c(player,tm,pos)), funs(replace(., is.na(.), 0))) %>% 
    as_tibble() %>% 
    group_by(player) %>% 
    slice(1) %>% 
    ungroup() %>% 
    select(-rk)
  
  #per minute
  url <- paste0("https://www.basketball-reference.com/leagues/NBA_",season,"_per_minute.html")
  stats_pm <- url %>% 
    read_html() %>% 
    html_table() %>% 
    .[[1]]
  
  player_stats_pm <- stats_pm %>% 
    remove_empty_cols() %>%
    clean_names() %>% 
    dplyr::filter(!player=="Player") %>%
    mutate_at(vars(-c(player,tm,pos)),as.numeric) %>% 
    mutate_at(vars(-c(player,tm,pos)), funs(replace(., is.na(.), 0))) %>% 
    as_tibble() %>% 
    group_by(player) %>% 
    slice(1) %>% 
    ungroup() %>% 
    rename_at(vars(9:29),funs(paste0(.,"_pm"))) %>% 
    select(-rk)
  
  #advanced
  url <- paste0("https://www.basketball-reference.com/leagues/NBA_",season,"_advanced.html")
  stats_adv <- url %>% 
    read_html() %>% 
    html_table() %>% 
    .[[1]]
  
  player_stats_adv <- stats_adv %>% 
    remove_empty_cols() %>%
    clean_names() %>% 
    dplyr::filter(!player=="Player") %>%
    mutate_at(vars(-c(player,tm,pos)),as.numeric) %>% 
    mutate_at(vars(-c(player,tm,pos)), funs(replace(., is.na(.), 0))) %>% 
    as_tibble() %>% 
    group_by(player) %>% 
    slice(1) %>% 
    ungroup() %>% 
    select(-rk)
  
  player_stats <- full_join(player_stats_tot,player_stats_pm,
                            by = c("player", "pos", "age", "tm", "g", "gs", "mp")) %>% 
    full_join(player_stats_adv,
              by = c("player", "pos", "age", "tm", "g", "mp"))
  return(player_stats)
}
```

At the end, we are using `full_join()` to merge the three data frames
together. If you are unfamiliar with joins I can recommend the chapter
on *Relational Data*
([Link](http://r4ds.had.co.nz/relational-data.html)) in Hadley’s
fantastic book *R for Data Science*.

Again, test it on a random season.

``` r
scrape_stats(2016)
```

``` hljs
## # A tibble: 476 x 70
##    player  pos     age tm        g    gs     mp     fg    fga fgpe…    x3p
##    <chr>   <chr> <dbl> <chr> <dbl> <dbl>  <dbl>  <dbl>  <dbl> <dbl>  <dbl>
##  1 Aaron … PG     31.0 CHI    69.0  0    1108   188     469   0.401  66.0 
##  2 Aaron … PF     20.0 ORL    78.0 37.0  1863   274     579   0.473  42.0 
##  3 Aaron … SG     21.0 CHO    21.0  0      93.0   5.00   19.0 0.263   3.00
##  4 Adreia… PF     24.0 MIN    52.0  2.00  486    53.0   145   0.366   9.00
##  5 Al Hor… C      29.0 ATL    82.0 82.0  2631   529    1048   0.505  88.0 
##  6 Al Jef… C      31.0 CHO    47.0 18.0  1096   245     505   0.485   0   
##  7 Al-Far… SF     25.0 POR    82.0 82.0  2341   299     719   0.416 126   
##  8 Alan A… SG     33.0 WAS    13.0  0     192    21.0    59.0 0.356  12.0 
##  9 Alan W… PF     23.0 PHO    10.0  0      68.0  10.0    24.0 0.417   0   
## 10 Alec B… SG     24.0 UTA    31.0  3.00  797   137     334   0.410  32.0 
## # ... with 466 more rows, and 59 more variables: x3pa <dbl>,
## #   x3ppercent <dbl>, x2p <dbl>, x2pa <dbl>, x2ppercent <dbl>,
## #   efgpercent <dbl>, ft <dbl>, fta <dbl>, ftpercent <dbl>, orb <dbl>,
## #   drb <dbl>, trb <dbl>, ast <dbl>, stl <dbl>, blk <dbl>, tov <dbl>,
## #   pf <dbl>, pts <dbl>, fg_pm <dbl>, fga_pm <dbl>, fgpercent_pm <dbl>,
## #   x3p_pm <dbl>, x3pa_pm <dbl>, x3ppercent_pm <dbl>, x2p_pm <dbl>,
## #   x2pa_pm <dbl>, x2ppercent_pm <dbl>, ft_pm <dbl>, fta_pm <dbl>,
## #   ftpercent_pm <dbl>, orb_pm <dbl>, drb_pm <dbl>, trb_pm <dbl>,
## #   ast_pm <dbl>, stl_pm <dbl>, blk_pm <dbl>, tov_pm <dbl>, pf_pm <dbl>,
## #   pts_pm <dbl>, per <dbl>, tspercent <dbl>, x3par <dbl>, ftr <dbl>,
## #   orbpercent <dbl>, drbpercent <dbl>, trbpercent <dbl>,
## #   astpercent <dbl>, stlpercent <dbl>, blkpercent <dbl>,
## #   tovpercent <dbl>, usgpercent <dbl>, ows <dbl>, dws <dbl>, ws <dbl>,
## #   ws_48 <dbl>, obpm <dbl>, dbpm <dbl>, bpm <dbl>, vorp <dbl>
```

Now we have a very generic function, which returns as a clean data frame
of 70 NBA player statistics for any season.

In the [next
post](http://blog.schochastics.net/post/analyzing-nba-player-data-ii-clustering),
we will use this data to cluster players according to their stats to
assign positions to players not based on physical traits such as height,
but in terms of their abilities.

