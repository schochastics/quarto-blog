---
title: "Preprocessing and analyzing web tracking data with webtrackR"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2023-09-12
categories: []
aliases: ["http://archive.schochastics.net/post/preprocessing-and-analyzing-web-tracking-data-with-webtrackr/"]
---

# Preprocessing and analyzing web tracking data with webtrackR

*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/preprocessing-and-analyzing-web-tracking-data-with-webtrackr/).*


Researchers have relied on free/easy access to APIs from social media
platforms for a very long time. But in the recent past, many prominent
platforms revoked the free access to their API and made accessing the
data almost unaffordable for regular researchers. The need for
alternative data sources to study the online behaviour of individuals is
big. One such alternative are studies that use webtracking to obtain the
web browsing history of participants. This type of data is far richer
than social media data but can also be far more heterogeneous and
complex. Enter the R package
[webtrackR](https://github.com/schochastics/webtrackR), a package to
preprocess and analyze webtracking data.

![](webtrackR.png)

# Installation

You can install the development version of webtrackR from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("schochastics/webtrackR")
```

The CRAN version can be installed with:

``` r
install.packages("webtrackR")
```

The package is still under heavy development and new features are being
added on regular basis. If you are working with webtracking data, feel
free to [reach out](https://github.com/schochastics/webtrackR/issues)
with your feature requests.

# An S3 class for webtracking data

The package defines an S3 class called `wt_dt` which inherits most of
the functionality from `data.table`. Each row in a web tracking data set
represents a visit. Raw data read with the package need to have at least
the following variables:

-   **panelist_id**: the individual from which the data was collected
-   **url**: the URL of the visit
-   **timestamp**: the time of the URL visit

The function `as.wt_dt` assigns the class `wt_dt` to a raw web tracking
data set. It also allows you to specify the name of the raw variables
corresponding to panelist_id, url and timestamp.

All preprocessing functions check if these three variables are present
and an error is thrown if one is not found

# Data Preprocessing

Currently, the main functionality of the package is to preprocess a raw
webtracking dataset and add some more helpful variables for later
analysis:

-   `add_duration()` adds a variable called `duration` based on the
    sequence of timestamps. The basic logic is that the duration of a
    visit is set to the time difference to the subsequent visit, unless
    this difference exceeds a certain value (defined by argument
    `cutoff`), in which case the duration will be replaced by `NA` or
    some user-defined value (defined by `replace_by`).
-   `add_session()` adds a variable called `session`, which groups
    subsequent visits into a session until the difference to the next
    visit exceeds a certain value (defined by `cutoff`).
-   `extract_host()`, `extract_domain()`, `extract_path()` extracts the
    host, domain and path of the raw URL and adds variables named
    accordingly. See function descriptions for definitions of these
    terms. `drop_query()` lets you drop the query and fragment
    components of the raw URL.
-   `add_next_visit()` and `add_previous_visit()` adds the previous or
    the next URL, domain, or host (defined by `level`) as a new
    variable.
-   `add_referral()` adds a new variable indicating whether a visit was
    referred by a social media platform. Follows the logic of Schmidt et
    al., [(2023)](https://doi.org/10.31235/osf.io/cks68).
-   `add_title()` downloads the title of a website (the text within the
    `<title>` tag of a web site’s `<head>`) and adds it as a new
    variable.
-   `add_panelist_data()`. Joins a data set containing information about
    participants such as a survey.

## Classification

So far, one function, `classify_visits()`, is implemented which is used
to categorize website visits by either extracting the URL’s domain or
host and matching them to a list of domains or hosts, or by matching a
list of regular expressions against the visit URL. Currently, some
precompiled lists are included in the package, but these will move to a
dedicated package
[domainator](https://github.com/schochastics/domainator) at a later
stage.

## Summarizing and aggregating

-   `deduplicate()` flags or drops (as defined by argument `method`)
    consecutive visits to the same URL within a user-defined time frame
    (as set by argument `within`). Alternatively to dropping or flagging
    visits, the function aggregates the durations of such duplicate
    visits.
-   `sum_visits()` and `sum_durations()` aggregate the number or the
    durations of visits, by participant and by a time period (as set by
    argument `timeframe`). Optionally, the function aggregates the
    number / duration of visits to a certain class of visits.
-   `sum_activity()` counts the number of active time periods (defined
    by `timeframe`) by participant.

## Example code

A typical workflow including preprocessing, classifying and aggregating
web tracking data looks like this (using the in-built example data):

``` r
library(webtrackR)

# load example data and turn it into wt_dt
data("testdt_tracking")
wt <- as.wt_dt(testdt_tracking)

# add duration
wt <- add_duration(wt)

# extract domains
wt <- extract_domain(wt)

# drop duplicates (consecutive visits to the same URL within one second)
wt <- deduplicate(wt, within = 1, method = "drop")

# load example domain classification and classify domains
data("domain_list")
wt <- classify_visits(wt, classes = domain_list, match_by = "domain")

# load example survey data and join with web tracking data
data("testdt_survey_w")
wt <- add_panelist_data(wt, testdt_survey_w)

# aggregate number of visits by day and panelist, and by domain class
wt_summ <- sum_visits(wt, timeframe = "date", visit_class = "type")
```

[
Twitter](https://twitter.com/share?text=Preprocessing%20and%20analyzing%20web%20tracking%20data%20with%20webtrackR&url=http%3a%2f%2fblog.schochastics.net%2fpost%2fpreprocessing-and-analyzing-web-tracking-data-with-webtrackr%2f)
[
Facebook](https://www.facebook.com/sharer/sharer.php?u=http%3a%2f%2fblog.schochastics.net%2fpost%2fpreprocessing-and-analyzing-web-tracking-data-with-webtrackr%2f)
[
Google+](https://plus.google.com/share?url=http%3a%2f%2fblog.schochastics.net%2fpost%2fpreprocessing-and-analyzing-web-tracking-data-with-webtrackr%2f)
[
LinkedIn](https://www.linkedin.com/shareArticle?mini=true&title=Preprocessing%20and%20analyzing%20web%20tracking%20data%20with%20webtrackR&url=http%3a%2f%2fblog.schochastics.net%2fpost%2fpreprocessing-and-analyzing-web-tracking-data-with-webtrackr%2f&summary=)

Please enable JavaScript to view the [comments powered by
Disqus.](https://disqus.com/?ref_noscript)

# [schochastics](http://blog.schochastics.net/ "schochastics")

[](#)

© 2023 / Powered by [Hugo](https://gohugo.io/)

[Ghostwriter theme](https://github.com/roryg/ghostwriter) By
[JollyGoodThemes](http://jollygoodthemes.com/) /
[Ported](https://github.com/jbub/ghostwriter) to Hugo By
[jbub](https://github.com/jbub)
