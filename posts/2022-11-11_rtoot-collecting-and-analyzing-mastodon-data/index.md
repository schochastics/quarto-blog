---
title: "rtoot: Collecting and Analyzing Mastodon Data"
author:
  - name: David Schoch
    orcid: 0000-0003-2952-4812
date: 2022-11-11
categories: [R, package]
---



*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](http://archive.schochastics.net/post/rtoot-collecting-and-analyzing-mastodon-data/).*

![](rtoot.png)

It has been a wild few days on Twitter after Elon Musk took over. The
future of the platform is unclear and many users are looking for
alternatives, a popular one being [mastodon](https://fedi.tips/). I also
decided to give it a try and [signed
up](https://fosstodon.org/@schochastics). I quite quickly became
interested in its [API](https://docs.joinmastodon.org/) and realized
that there is only a seemingly unmaintained R package on
[github](https://github.com/ThomasChln/mastodon). So I decided to write
a new one. Fast forward a week(!!!!) and the package `rtoot` was
accepted by CRAN. In this post I will introduce some of the
functionality of the package and a roadmap for the future. (*The name of
the package derives from “toot”, the equivalent of a “tweet”*)

``` r
# developer version
remotes::install_github("schochastics/rtoot")

# CRAN version
install.packages("rtoot")
```

``` r
library(rtoot)
```

## Authenticate

Before doing anything you should setup credentials. Once setup, you will
not need to bother with that anymore (hopefully). There is a vignette in
the package (`vignette("auth")`) which explains the process. In brief,
Mastodon has three types of API calls: anonymous, public, and user
based. For anonymous calls you do not need any token. A public token can
be obtained without an account and gives a few more API call options. A
user based grants access to all endpoints but requires an account.

Running the function `auth_setup()` will guide you through a process of
setting up a token.

``` r
auth_setup()
```

## Instances

In contrast to twitter, mastodon is not a single instance, but a
federation of different servers. You sign up at a specific server (say
“mastodon.social”) but can still communicate with others from other
servers (say “fosstodon.org”). The existence of different instances
makes API calls more complex. For example, some calls can only be made
within your own instance (e.g `get_timeline_home()`), others can access
all instances but you need to specify the instance as a parameter
(e.g. `get_timeline_public()`).

A list of active instances can be obtained with `get_fedi_instances()`.
The results are sorted by number of users.

General information about an instance can be obtained with
`get_instance_general()`

``` r
str(get_instance_general(instance = "mastodon.social"))
```

``` hljs
## List of 16
##  $ uri              : chr "mastodon.social"
##  $ title            : chr "Mastodon"
##  $ short_description: chr "The original server operated by the Mastodon gGmbH non-profit"
##  $ description      : chr ""
##  $ email            : chr "staff@mastodon.social"
##  $ version          : chr "4.1.0rc3"
##  $ urls             :List of 1
##   ..$ streaming_api: chr "wss://streaming.mastodon.social"
##  $ stats            :List of 3
##   ..$ user_count  : int 940715
##   ..$ status_count: int 50736571
##   ..$ domain_count: int 51166
##  $ thumbnail        : chr "https://files.mastodon.social/site_uploads/files/000/000/001/@1x/57c12f441d083cde.png"
##  $ languages        :List of 1
##   ..$ : chr "en"
##  $ registrations    : logi TRUE
##  $ approval_required: logi FALSE
##  $ invites_enabled  : logi TRUE
##  $ configuration    :List of 4
##   ..$ accounts         :List of 1
##   .. ..$ max_featured_tags: int 10
##   ..$ statuses         :List of 3
##   .. ..$ max_characters             : int 500
##   .. ..$ max_media_attachments      : int 4
##   .. ..$ characters_reserved_per_url: int 23
##   ..$ media_attachments:List of 6
##   .. ..$ supported_mime_types  :List of 28
##   .. .. ..$ : chr "image/jpeg"
##   .. .. ..$ : chr "image/png"
##   .. .. ..$ : chr "image/gif"
##   .. .. ..$ : chr "image/heic"
##   .. .. ..$ : chr "image/heif"
##   .. .. ..$ : chr "image/webp"
##   .. .. ..$ : chr "image/avif"
##   .. .. ..$ : chr "video/webm"
##   .. .. ..$ : chr "video/mp4"
##   .. .. ..$ : chr "video/quicktime"
##   .. .. ..$ : chr "video/ogg"
##   .. .. ..$ : chr "audio/wave"
##   .. .. ..$ : chr "audio/wav"
##   .. .. ..$ : chr "audio/x-wav"
##   .. .. ..$ : chr "audio/x-pn-wave"
##   .. .. ..$ : chr "audio/vnd.wave"
##   .. .. ..$ : chr "audio/ogg"
##   .. .. ..$ : chr "audio/vorbis"
##   .. .. ..$ : chr "audio/mpeg"
##   .. .. ..$ : chr "audio/mp3"
##   .. .. ..$ : chr "audio/webm"
##   .. .. ..$ : chr "audio/flac"
##   .. .. ..$ : chr "audio/aac"
##   .. .. ..$ : chr "audio/m4a"
##   .. .. ..$ : chr "audio/x-m4a"
##   .. .. ..$ : chr "audio/mp4"
##   .. .. ..$ : chr "audio/3gpp"
##   .. .. ..$ : chr "video/x-ms-asf"
##   .. ..$ image_size_limit      : int 10485760
##   .. ..$ image_matrix_limit    : int 16777216
##   .. ..$ video_size_limit      : int 41943040
##   .. ..$ video_frame_rate_limit: int 60
##   .. ..$ video_matrix_limit    : int 2304000
##   ..$ polls            :List of 4
##   .. ..$ max_options              : int 4
##   .. ..$ max_characters_per_option: int 50
##   .. ..$ min_expiration           : int 300
##   .. ..$ max_expiration           : int 2629746
##  $ contact_account  :List of 23
##   ..$ id             : chr "1"
##   ..$ username       : chr "Gargron"
##   ..$ acct           : chr "Gargron"
##   ..$ display_name   : chr "Eugen Rochko"
##   ..$ locked         : logi FALSE
##   ..$ bot            : logi FALSE
##   ..$ discoverable   : logi TRUE
##   ..$ group          : logi FALSE
##   ..$ created_at     : chr "2016-03-16T00:00:00.000Z"
##   ..$ note           : chr "<p>Founder, CEO and lead developer <span class=\"h-card\"><a href=\"https://mastodon.social/@Mastodon\" class=\"| __truncated__
##   ..$ url            : chr "https://mastodon.social/@Gargron"
##   ..$ avatar         : chr "https://files.mastodon.social/accounts/avatars/000/000/001/original/dc4286ceb8fab734.jpg"
##   ..$ avatar_static  : chr "https://files.mastodon.social/accounts/avatars/000/000/001/original/dc4286ceb8fab734.jpg"
##   ..$ header         : chr "https://files.mastodon.social/accounts/headers/000/000/001/original/3b91c9965d00888b.jpeg"
##   ..$ header_static  : chr "https://files.mastodon.social/accounts/headers/000/000/001/original/3b91c9965d00888b.jpeg"
##   ..$ followers_count: int 295982
##   ..$ following_count: int 371
##   ..$ statuses_count : int 73224
##   ..$ last_status_at : chr "2023-02-16"
##   ..$ noindex        : logi FALSE
##   ..$ emojis         : list()
##   ..$ roles          : list()
##   ..$ fields         :List of 2
##   .. ..$ :List of 3
##   .. .. ..$ name       : chr "Patreon"
##   .. .. ..$ value      : chr "<a href=\"https://www.patreon.com/mastodon\" target=\"_blank\" rel=\"nofollow noopener noreferrer me\"><span cl"| __truncated__
##   .. .. ..$ verified_at: NULL
##   .. ..$ :List of 3
##   .. .. ..$ name       : chr "GitHub"
##   .. .. ..$ value      : chr "<a href=\"https://github.com/Gargron\" target=\"_blank\" rel=\"nofollow noopener noreferrer me\"><span class=\""| __truncated__
##   .. .. ..$ verified_at: chr "2023-02-07T23:24:40.347+00:00"
##  $ rules            :List of 5
##   ..$ :List of 2
##   .. ..$ id  : chr "1"
##   .. ..$ text: chr "Sexually explicit or violent media must be marked as sensitive when posting"
##   ..$ :List of 2
##   .. ..$ id  : chr "2"
##   .. ..$ text: chr "No racism, sexism, homophobia, transphobia, xenophobia, or casteism"
##   ..$ :List of 2
##   .. ..$ id  : chr "3"
##   .. ..$ text: chr "No incitement of violence or promotion of violent ideologies"
##   ..$ :List of 2
##   .. ..$ id  : chr "4"
##   .. ..$ text: chr "No harassment, dogpiling or doxxing of other users"
##   ..$ :List of 2
##   .. ..$ id  : chr "7"
##   .. ..$ text: chr "Do not share intentionally false or misleading information"
##  - attr(*, "headers")= tibble [1 × 3] (S3: tbl_df/tbl/data.frame)
##   ..$ rate_limit    : chr "300"
##   ..$ rate_remaining: chr "299"
##   ..$ rate_reset    : POSIXlt[1:1], format: "2023-02-16 07:30:00"
```

`get_instance_activity()` shows the activity for the last three months
and `get_instance_trends()` the trending hashtags of the week.

``` r
get_instance_activity(instance = "fosstodon.org")
```

``` hljs
## # A tibble: 12 × 4
##    week                statuses logins registrations
##    <dttm>                 <int>  <int>         <int>
##  1 2023-02-15 13:35:51     2720   3874            13
##  2 2023-02-08 13:35:51    38406  12880           254
##  3 2023-02-01 13:35:51    39772  13353           448
##  4 2023-01-25 13:35:51    39577  13282           461
##  5 2023-01-18 13:35:51    40015  13395           399
##  6 2023-01-11 13:35:51    39595  13544           406
##  7 2023-01-04 13:35:51    43042  13913           554
##  8 2022-12-28 13:35:51    45729  14378           575
##  9 2022-12-21 13:35:51    54912  15084           779
## 10 2022-12-14 13:35:51    66725  17186          1731
## 11 2022-12-07 13:35:51    48359  13637           483
## 12 2022-11-30 13:35:51    58198  14343           781
```

``` r
get_instance_trends(instance = "fosstodon.org")
```

``` hljs
## # A tibble: 70 × 5
##    name               url                               day        accou…¹  uses
##    <chr>              <chr>                             <date>       <int> <int>
##  1 nicolasturgeon     https://fosstodon.org/tags/nicol… 2023-02-16       9     9
##  2 nicolasturgeon     https://fosstodon.org/tags/nicol… 2023-02-15     113   141
##  3 nicolasturgeon     https://fosstodon.org/tags/nicol… 2023-02-14       0     0
##  4 nicolasturgeon     https://fosstodon.org/tags/nicol… 2023-02-13       0     0
##  5 nicolasturgeon     https://fosstodon.org/tags/nicol… 2023-02-12       0     0
##  6 nicolasturgeon     https://fosstodon.org/tags/nicol… 2023-02-11       0     0
##  7 nicolasturgeon     https://fosstodon.org/tags/nicol… 2023-02-10       0     0
##  8 waterfallwednesday https://fosstodon.org/tags/water… 2023-02-16      18    19
##  9 waterfallwednesday https://fosstodon.org/tags/water… 2023-02-15      88    95
## 10 waterfallwednesday https://fosstodon.org/tags/water… 2023-02-14       2     2
## # … with 60 more rows, and abbreviated variable name ¹​accounts
```

## Get toots

To get the most recent toots of a specific instance use
`get_timeline_public()`

``` r
get_timeline_public(instance = "mastodon.social")
```

``` r
##    id        uri   created_at          content visib…¹ sensi…² spoil…³ reblo…⁴ favou…⁵ repli…⁶
##    <chr>     <chr> <dttm>              <chr>   <chr>   <lgl>   <chr>     <int>   <int>   <int>
##  1 10931614… http… 2022-11-09 22:12:13 "<p>Vi… public  FALSE   ""            0       0       0
##  2 10931614… http… 2022-11-09 22:04:24 "<p>I … public  FALSE   ""            0       0       0
##  3 10931614… http… 2022-11-09 21:46:36 "<p>Ha… public  FALSE   ""            0       0       0
##  4 10931614… http… 2022-11-09 22:12:11 "<p>To… public  FALSE   ""            0       0       0
##  5 10931614… http… 2022-11-09 22:12:05 "<p>:s… public  FALSE   ""            0       0       0
##  6 10931614… http… 2022-11-09 22:12:05 "<p>We… public  FALSE   ""            0       0       0
##  7 10931614… http… 2022-11-09 22:12:09 "<p>He… public  FALSE   ""            0       0       0
##  8 10931614… http… 2022-11-09 22:12:09 "<p>Et… public  FALSE   ""            0       0       0
##  9 10931614… http… 2022-11-09 22:12:08 "<p>Af… public  FALSE   ""            0       0       0
## 10 10931614… http… 2022-11-09 22:04:19 "<p>I'… public  FALSE   ""            0       0       0
## 11 10931614… http… 2022-11-09 22:12:05 "<p>\"… public  FALSE   ""            0       0       0
## 12 10931614… http… 2022-11-09 22:12:06 "<p>Wh… public  FALSE   ""            0       0       0
## 13 10931614… http… 2022-11-09 22:12:05 "<p>Ev… public  FALSE   ""            0       0       0
## 14 10931614… http… 2022-11-09 22:12:04 "<p>\"… public  FALSE   ""            0       0       0
## 15 10931614… http… 2022-11-09 22:12:00 "<p>Wh… public  FALSE   ""            0       0       0
## 16 10931614… http… 2022-11-09 22:11:13 "<p>Lo… public  FALSE   ""            0       0       0
## 17 10931614… http… 2022-11-09 22:12:04 "<p>Ne… public  FALSE   ""            0       0       0
## 18 10931614… http… 2022-11-09 22:12:02 "<p>Th… public  FALSE   ""            0       0       0
## 19 10931614… http… 2022-11-09 22:11:50 "<p>So… public  FALSE   ""            0       0       0
## 20 10931614… http… 2022-11-09 22:12:01 "<p>Th… public  FALSE   ""            0       0       0
## # … with 19 more variables: url <chr>, in_reply_to_id <chr>, in_reply_to_account_id <chr>,
## #   language <chr>, text <lgl>, application <I<list>>, poll <I<list>>, card <I<list>>,
## #   account <list>, reblog <I<list>>, media_attachments <I<list>>, mentions <I<list>>,
## #   tags <I<list>>, emojis <I<list>>, favourited <lgl>, reblogged <lgl>, muted <lgl>,
## #   bookmarked <lgl>, pinned <lgl>, and abbreviated variable names ¹​visibility, ²​sensitive,
## #   ³​spoiler_text, ⁴​reblogs_count, ⁵​favourites_count, ⁶​replies_count
## # ℹ Use `colnames()` to see all variable names
```

To get the most recent toots containing a specific hashtag use
`get_timeline_hashtag()`

``` r
get_timeline_hashtag(hashtag = "rstats", instance = "fosstodon.org")
```

``` hljs
## # A tibble: 20 × 29
##    id          uri   created_at          content visib…¹ sensi…² spoil…³ reblo…⁴
##    <chr>       <chr> <dttm>              <chr>   <chr>   <lgl>   <chr>     <int>
##  1 1098728706… http… 2023-02-16 05:55:57 "<p>Hi… public  FALSE   ""            0
##  2 1098724233… http… 2023-02-16 04:02:11 "<p>CR… public  FALSE   ""            0
##  3 1098723121… http… 2023-02-16 03:33:54 "<p>An… public  FALSE   ""            1
##  4 1098723057… http… 2023-02-16 03:32:17 "<p>Lo… public  FALSE   ""            7
##  5 1098722766… http… 2023-02-16 03:24:51 "<p><a… public  FALSE   ""            6
##  6 1098722090… http… 2023-02-16 03:07:35 "<p>I … public  FALSE   ""            0
##  7 1098720316… http… 2023-02-16 02:22:33 "<p>Go… public  FALSE   ""            6
##  8 1098719514… http… 2023-02-16 02:02:10 "<p>CR… public  FALSE   ""            0
##  9 1098717155… http… 2023-02-16 01:02:11 "<p>CR… public  FALSE   ""            0
## 10 1098717021… http… 2023-02-16 00:58:46 "<p>In… public  FALSE   ""            0
## 11 1098714795… http… 2023-02-16 00:02:10 "<p>CR… public  FALSE   ""            0
## 12 1098712669… http… 2023-02-15 23:08:05 "<p>Al… public  FALSE   ""            0
## 13 1098712472… http… 2023-02-15 23:03:04 "<p>Ne… public  FALSE   ""            0
## 14 1098712439… http… 2023-02-15 23:02:15 "<p>CR… public  FALSE   ""            0
## 15 1098710104… http… 2023-02-15 22:02:19 "<p>CR… public  FALSE   ""            0
## 16 1098709985… http… 2023-02-15 21:59:49 "<p>We… public  FALSE   ""            0
## 17 1098707722… http… 2023-02-15 21:02:17 "<p>Ex… public  FALSE   ""           25
## 18 1098707719… http… 2023-02-15 21:02:13 "<p>CR… public  FALSE   ""            0
## 19 1098707350… http… 2023-02-15 20:52:49 "<p>I'… public  FALSE   ""            1
## 20 1098706606… http… 2023-02-15 20:33:54 "<p>Ne… public  FALSE   ""            2
## # … with 21 more variables: favourites_count <int>, replies_count <int>,
## #   url <chr>, in_reply_to_id <lgl>, in_reply_to_account_id <lgl>,
## #   language <chr>, text <lgl>, application <I<list>>, poll <I<list>>,
## #   card <I<list>>, account <list>, reblog <I<list>>,
## #   media_attachments <I<list>>, mentions <I<list>>, tags <list>,
## #   emojis <I<list>>, favourited <lgl>, reblogged <lgl>, muted <lgl>,
## #   bookmarked <lgl>, pinned <lgl>, and abbreviated variable names …
```

The function `get_timeline_home()` allows you to get the most recent
toots from your own timeline.

``` r
get_timeline_home()
```

## Get accounts

`rtoot` exposes several account level endpoints. Most require the
account id instead of the username as an input. There is, to our
knowledge, no straightforward way of obtaining the account id. With the
package you can get the id via `search_accounts()`.

``` r
search_accounts("schochastics")
```

``` hljs
## # A tibble: 1 × 21
##   id        usern…¹ acct  displ…² locked bot   disco…³ group created_at         
##   <chr>     <chr>   <chr> <chr>   <lgl>  <lgl> <lgl>   <lgl> <dttm>             
## 1 10930243… schoch… scho… David … FALSE  FALSE FALSE   FALSE 2022-11-07 00:00:00
## # … with 12 more variables: note <chr>, url <chr>, avatar <chr>,
## #   avatar_static <chr>, header <chr>, header_static <chr>,
## #   followers_count <int>, following_count <int>, statuses_count <int>,
## #   last_status_at <dttm>, fields <list>, emojis <I<list>>, and abbreviated
## #   variable names ¹​username, ²​display_name, ³​discoverable
```

*(Future versions will allow to use the username and user id
interchangeably)*

Using the id, you can get the followers and following users with
`get_account_followers()` and `get_account_following()` and statuses
with `get_account_statuses()`.

``` r
id <- "109302436954721982"
get_account_followers(id)
```

``` hljs
## # A tibble: 40 × 21
##    id       usern…¹ acct  displ…² locked bot   disco…³ group created_at         
##    <chr>    <chr>   <chr> <chr>   <lgl>  <lgl> <lgl>   <lgl> <dttm>             
##  1 1095295… irene   iren… "Irene" FALSE  FALSE FALSE   FALSE 2022-12-17 00:00:00
##  2 1096924… feinma… fein… "fm :r… FALSE  FALSE FALSE   FALSE 2023-01-15 00:00:00
##  3 1098626… superh… supe… "Huw R… FALSE  FALSE FALSE   FALSE 2023-02-10 00:00:00
##  4 1098538… TEG     TEG@… ""      FALSE  FALSE TRUE    FALSE 2023-02-12 00:00:00
##  5 235323   ccamara ccam… "Carlo… FALSE  FALSE TRUE    FALSE 2020-05-10 00:00:00
##  6 1096307… SocSci… SocS… "Siobh… TRUE   FALSE TRUE    FALSE 2022-11-05 00:00:00
##  7 1092694… atomas… atom… "Aleks… FALSE  FALSE TRUE    FALSE 2022-10-31 00:00:00
##  8 1093647… Maxime… Maxi… "Maxim… FALSE  FALSE TRUE    FALSE 2022-11-08 00:00:00
##  9 1098228… zsofiz… zsof… "Zsofi… FALSE  FALSE FALSE   FALSE 2023-02-07 00:00:00
## 10 1094556… rattle… ratt… "Micha… FALSE  FALSE TRUE    FALSE 2022-12-01 00:00:00
## # … with 30 more rows, 12 more variables: note <chr>, url <chr>, avatar <chr>,
## #   avatar_static <chr>, header <chr>, header_static <chr>,
## #   followers_count <int>, following_count <int>, statuses_count <int>,
## #   last_status_at <dttm>, fields <I<list>>, emojis <I<list>>, and abbreviated
## #   variable names ¹​username, ²​display_name, ³​discoverable
```

``` r
get_account_following(id)
```

``` hljs
## # A tibble: 40 × 21
##    id       usern…¹ acct  displ…² locked bot   disco…³ group created_at         
##    <chr>    <chr>   <chr> <chr>   <lgl>  <lgl> <lgl>   <lgl> <dttm>             
##  1 1098189… rOpenS… rOpe… rOpenS… FALSE  FALSE TRUE    FALSE 2023-02-06 00:00:00
##  2 1095371… kierisi kier… jesse … FALSE  FALSE TRUE    FALSE 2022-12-16 00:00:00
##  3 1093025… Franci… Fran… Franci… FALSE  FALSE FALSE   FALSE 2022-04-26 00:00:00
##  4 1092696… maelle  mael… Maëlle… FALSE  FALSE TRUE    FALSE 2022-04-26 00:00:00
##  5 1095277… derTob… derT… Tobias… FALSE  FALSE FALSE   FALSE 2022-12-16 00:00:00
##  6 1093429… georgi… geor… Georgi… FALSE  FALSE TRUE    FALSE 2022-11-12 00:00:00
##  7 1092933… charli… char… charli… FALSE  FALSE TRUE    FALSE 2022-10-31 00:00:00
##  8 1093082… terence tere… terence FALSE  FALSE TRUE    FALSE 2022-11-08 00:00:00
##  9 1093088… rachael rach… Rachael FALSE  FALSE TRUE    FALSE 2022-11-08 00:00:00
## 10 1093114… minecr  mine… Mine Ç… FALSE  FALSE FALSE   FALSE 2022-11-09 00:00:00
## # … with 30 more rows, 12 more variables: note <chr>, url <chr>, avatar <chr>,
## #   avatar_static <chr>, header <chr>, header_static <chr>,
## #   followers_count <int>, following_count <int>, statuses_count <int>,
## #   last_status_at <dttm>, fields <I<list>>, emojis <I<list>>, and abbreviated
## #   variable names ¹​username, ²​display_name, ³​discoverable
```

``` r
get_account_statuses(id)
```

``` hljs
## # A tibble: 20 × 29
##    id          uri   created_at          content visib…¹ sensi…² spoil…³ reblo…⁴
##    <chr>       <chr> <dttm>              <chr>   <chr>   <lgl>   <chr>     <int>
##  1 1098707722… http… 2023-02-15 21:02:17 "<p>Ex… public  FALSE   ""           25
##  2 1098314275… http… 2023-02-08 22:16:25 "<p><s… public  FALSE   ""            0
##  3 1098200392… http… 2023-02-06 22:00:14 "<p><s… public  FALSE   ""            0
##  4 1098199558… http… 2023-02-06 21:39:00 "<p>I … public  FALSE   ""            8
##  5 1097858586… http… 2023-01-31 21:07:39 "<p>I … public  FALSE   ""            8
##  6 1097574949… http… 2023-01-26 20:54:23 "<p><s… public  FALSE   ""            0
##  7 1097574906… http… 2023-01-26 20:53:17 "<p><s… unlist… FALSE   ""            0
##  8 1097574538… http… 2023-01-26 20:43:56 "<p>Pr… public  FALSE   ""            0
##  9 1097462208… http… 2023-01-24 21:07:14 "<p><s… public  FALSE   ""            0
## 10 1097444058… http… 2023-01-24 13:25:40 "<p>Ha… public  FALSE   ""            4
## 11 1096861628… http… 2023-01-14 06:33:41 "<p><s… public  FALSE   ""            0
## 12 1096782937… http… 2023-01-12 21:12:28 "<p>Af… public  FALSE   ""            5
## 13 1096782881… http… 2023-01-12 21:11:03 "<p><s… public  FALSE   ""            0
## 14 1096782048… http… 2023-01-12 20:49:52 "<p><s… public  FALSE   ""            0
## 15 1096781945… http… 2023-01-12 20:47:15 "<p><s… public  FALSE   ""            0
## 16 1096647115… http… 2023-01-10 11:38:21 ""      public  FALSE   ""            0
## 17 1096647094… http… 2023-01-10 11:37:49 "<p><s… public  FALSE   ""            0
## 18 1096594498… http… 2023-01-09 13:20:14 "<p>Fo… public  FALSE   ""            0
## 19 1096594375… http… 2023-01-09 13:17:06 "<p><s… public  FALSE   ""            0
## 20 1096594203… http… 2023-01-09 13:12:43 "<p><s… public  FALSE   ""            0
## # … with 21 more variables: favourites_count <int>, replies_count <int>,
## #   url <chr>, in_reply_to_id <chr>, in_reply_to_account_id <chr>,
## #   language <chr>, text <lgl>, application <I<list>>, poll <I<list>>,
## #   card <I<list>>, account <list>, reblog <I<list>>,
## #   media_attachments <I<list>>, mentions <I<list>>, tags <I<list>>,
## #   emojis <I<list>>, favourited <lgl>, reblogged <lgl>, muted <lgl>,
## #   bookmarked <lgl>, pinned <lgl>, and abbreviated variable names …
```

## Posting statuses

You can post toots with:

``` r
post_toot(status = "my first rtoot #rstats")
```

It can also include media and alt_text.

``` r
post_toot(status = "my first rtoot #rstats", media="path/to/media", 
          alt_text = "description of media")
```

You can mark the toot as sensitive by setting `sensitive = TRUE` and add
a spoiler text with `spoiler_text`.

## Pagination

Most functions only return up to 40 results. The current version of
`rtoot` does not support pagination out of the box (but it is planned
for later). there is a workaround which can be found in the
[wiki](https://github.com/schochastics/rtoot/wiki/Pagination)

## Thanks!

This package wouldn’t have been possible without my coauthor
[@chainsawriot](https://github.com/chainsawriot) who contributed a huge
chunk of code, especially all unit tests! Also thanks to
[@JBGruber](https://github.com/JBGruber), who contributed to the
authentication routines, and [@urswilke](https://github.com/urswilke)
for some fixes.

