---
title: "A suite of tools to scrape and parse search engine results"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2023-03-22
categories: [R, package]
---



*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/a-suite-of-tools-to-scrape-and-parse-search-engine-results/).*

My posts are usually R only. But in this post, I want to talk about a
suite of tools developed by [my
colleagues](https://www.gesis.org/en/institute/departments/computational-social-science)
and me that goes beyond R only. This suite of tools helps to gather
results from different search engines and includes a [browser
extension](https://github.com/gesiscss/WebBot) to scrape the results,
and a [Python library](https://github.com/gesiscss/WebBot-tutorials) and
an [R package](https://github.com/schochastics/webbotparseR) to parse
the results.

# The browser extension

The core tool is a [browser
extension](http://blog.schochastics.net/post/a-suite-of-tools-to-scrape-and-parse-search-engine-results/(https://github.com/gesiscss/WebBot))
for Mozilla and Chrome that simulates a user searching (at least) 50-top
main, news, images and videos search results of up to 8 different search
engines.

![](demo.webp)

The repository is well documented and walks you through the steps of
setting up the extension to scrape data. Always make sure to deactivate
the extension once you are done since it interferes with your normal
browsing.

The extension can store local snapshots of the html files of the search
results for later analysis. This is done via the web extension
[SingleFile](https://github.com/gildas-lormeau/SingleFile). To parse
these html files efficiently for important information, we a Python
library as well as an R package.

# The Python library

To use the [Python
library](https://github.com/gesiscss/WebBot-tutorials), simply clone the
repository and either add `webbotparser/webbotparser.py` to your working
directory or navigate to the folder, and run

``` bash
pip install -e .
```

The `webbotparser` is then available in your Python installation.

*(The following is an excerpt of the repository README)*

## Usage

For the search engines and result types supported out of the box, simply
run

``` hljs
from webbotparser import WebBotParser
```

and initialize the WebBotParser for the search engine and result type
your are investigating, for example

``` hljs
parser = WebBotParser(engine = 'DuckDuckGo News')
```

Then, you can obtain the search results as a pandas DataFrame and
metadata as a Python dictionary with

``` hljs
metadata, results = parser.get_results(file='path/to/the/result_page.html')
```

Furthermore, `parser.get_metadata(file)` can be used to only extract the
metadata. `parser.get_results_from_dir(dir)` allows to directly extract
search results spread over multiple pages, as Google text result are
provided for instance. For examples also see
[`example.ipynb`](https://github.com/gesiscss/WebBot-tutorials/blob/main/example.ipynb).

## Extracting images

WebBot archives images inline in the html file of the search results,
i.e., they are neither external files on your drive nor fetched from the
original source on viewing the downloaded search results page. This
allows us to extract the images directly from the html file for further
analysis. The engines and result types supported out of the box with
WebBotParser allow for extracting images as well. Simply initialize
`WebBotParser` as follows:

``` hljs
parser = WebBotParser(engine = 'Google Video', extract_images=True)
```

You can optionally specify `extract_images_prefix`,
`extract_images_format`, and `extract_images_to_dir`. See
`example.ipynb` for more details, including preview in Jupyter
Notebooks.

## Custom result types

WebBotParser out of the box only provides support for some search
engines and result types. Even these parsers might stop working if the
search engine providers decide to change their layout. However,
WebBotParser can still be used in these cases by defining a custom
`result_selector`, `queries`, and optionally a `metadata_extractor`
function. In this case, a WebBotParser is initiated with these instead
of with the `engine` attribute

``` hljs
parser = WebBotParser(queries, result_selector, metadata_extractor)
```

Under the hood, WebBotParser uses
[BeautifulSoup](https://beautiful-soup-4.readthedocs.io/en/latest/index.html)
to

1.  Parse the search result page’s HTML via LXML
2.  Disciminate the individual results on each page using a [CSS
    selector](https://beautiful-soup-4.readthedocs.io/en/latest/index.html#css-selectors)
    called `result_selector` that matches a list of search results
3.  For each of those results, extract available information through a
    list of queries

See the below example for available types of queries and their usage

``` hljs
queries = [
    # extract the text from inside a matched element, getting all the text over all its children
    {'name': 'abc', 'type': 'text', 'selector': 'h3'},
    
    # extract the value of an attribute of a matched element
    {'name': 'def', 'type': 'attribute', 'selector': 'a', 'attribute': 'href'},
    
    # whether or not a CSS selector matches, returns a Boolean
    {'name': 'ghi', 'type': 'exists', 'selector': 'ul'},

    # extract inline images and name them by a title
    {'name': 'jkl', 'type': 'image', 'selector': 'g-img > img', 'title_selector': 'h3'}
    
    # pass a custom query function
    {'name': 'mno', 'type': 'custom', 'function': my_function},
]
```

You can optionally provide a `metadata_extractor(soup, file)` function
to extract metadata alongside the search results, or import one of the
existing extractors, e.g. with

``` hljs
from webbotparser import GoogleParser
metadata_extractor = GoogleParser.google_metadata
```

# The R package

The [R package](https://github.com/schochastics/webbotparseR) can be
installed from GitHub

``` r
remotes::install_github("schochastics/webbotparseR")
```

``` r
library(webbotparseR)
```

The package contains an example html from a google search on climate
change.

``` r
ex_file <- system.file("www.google.com_climatechange_text_2023-03-16_08_16_11.html", package = "webbotparseR")
```

Such search results can be parsed via the function
`parse_search_results()`. The parameter `engine` is used to specify the
search engine and the search type.

``` r
output <- parse_search_results(path = ex_file,engine = "google text")
output
```

``` hljs
## # A tibble: 10 × 10
##    title link  text  image page  posit…¹ searc…² type  query date               
##    <chr> <chr> <chr> <chr> <chr>   <int> <chr>   <chr> <chr> <dttm>             
##  1 What… http… Clim… data… 1           1 www.go… text  clim… 2023-03-16 08:16:11
##  2 Home… http… Vita… data… 1           2 www.go… text  clim… 2023-03-16 08:16:11
##  3 Vita… http… “Cli… data… 1           3 www.go… text  clim… 2023-03-16 08:16:11
##  4 Clim… http… In c… data… 1           4 www.go… text  clim… 2023-03-16 08:16:11
##  5 IPCC… http… The … data… 1           5 www.go… text  clim… 2023-03-16 08:16:11
##  6 Clim… http… Comp… data… 1           6 www.go… text  clim… 2023-03-16 08:16:11
##  7 Clim… http… Clim… <NA>  1           7 www.go… text  clim… 2023-03-16 08:16:11
##  8 UNFC… http… What… data… 1           8 www.go… text  clim… 2023-03-16 08:16:11
##  9 Clim… http… Clim… data… 1           9 www.go… text  clim… 2023-03-16 08:16:11
## 10 Caus… http… This… data… 1          10 www.go… text  clim… 2023-03-16 08:16:11
## # … with abbreviated variable names ¹​position, ²​search_engine
```

Note that images are always returned base64 encoded.

``` r
output$image[1]
```

``` hljs
## [1] "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAABnRSTlMAAAAAAABupgeRAAAAMklEQVR4AWMAgYYG4hEdNJAHGoCIABvBJayhgcYaIAwaakCwydUA52MKYeeSCgZh4gMAXrJ9ASggqqAAAAAASUVORK5CYII="
```

The function `base64_to_img()` can be used to decode the image and save
it in an appropriate format.

# Caveats

Given that search engines change their frontpage from time to time, the
extension can break and needs to be adjusted. As of writing
(22/03/2022), the search engine Bing is not supported due to some
changes on their frontpage.

Both the Python and R library rely on css selectors to extract the
relevant information from the html files. This is even more fragile than
what the browser extension does and may require more frequent updates.
Both libraries though offer the possibility to use custom selectors.
This can be useful in cases where search engines updated their css
classes and those changes have not yet been incorporated into the
libraries.

