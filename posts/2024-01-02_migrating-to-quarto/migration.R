library(rvest)
library(tidyverse)

links <- map(1:5, \(x)
read_html(paste0("http://blog.schochastics.net/page/", x)) |>
    html_nodes("ol li a") |>
    html_attr("href"))

links[[1]] <- read_html("http://blog.schochastics.net") |>
    html_nodes("ol li a") |>
    html_attr("href")
links <- unlist(links)
folder_title <- word(links, -2, sep = "/")

pubdates <- map(1:5, \(x)
read_html(paste0("http://blog.schochastics.net/page/", x)) |>
    html_nodes(".post-stub-date") |>
    html_text())

pubdates[[1]] <- read_html("http://blog.schochastics.net") |>
    html_nodes(".post-stub-date") |>
    html_text()

pubdates <- unlist(pubdates)
pubdates <- as.Date(str_remove_all(pubdates, "^Published [A-Za-z]{3,3}\\,\\s"),
    format = "%b %d, %Y"
)

posts <- tibble(
    pub_date = pubdates,
    old_link = links,
    old_folder = folder_title,
    new_folder = paste0(pub_date, "_", old_folder),
    post_title = ""
)

for (i in seq_len(nrow(posts))) {
    cat(i, "\r")
    odir <- paste0("posts/", posts$new_folder[i])
    dir.create(odir)
}

# download all posts
# needed to be done manually, saving via firefox
# get post title
for (i in seq_len(nrow(posts))) {
    posts$post_title[i] <- tryCatch(read_html(fs::path("posts", posts$new_folder[i], "post.html")) |>
        html_node(".post-title") |> html_text(), error = function(e) "")
}

write_csv(posts, "posts/2024-01-02_migrating-to-quarto/posts.csv")
# manually add categories
posts <- read_csv("posts/2024-01-02_migrating-to-quarto/posts.csv")

# convert html to md and clean up
wd <- here::here()
for (i in seq_len(nrow(posts))) {
    pdir <- fs::path("posts", posts$new_folder[i])
    setwd(pdir)
    system("pandoc post.html --lua-filter ../2024-01-02_migrating-to-quarto/remove-tags.lua  -t gfm-raw_html -o index.md")
    system("sed -i '/^Tagged/,$d' index.md")
    system("sed -i '1,10d' index.md")
    system("sed -i '1,6d' index.md")
    setwd(wd)
}

# add yaml header
for (i in seq_len(nrow(posts))[-31]) {
    file_md <- fs::path("posts", posts$new_folder[i], "index.md")
    post <- readLines(file_md)
    addendum <- c(
        "",
        paste0("*This post was semi automatically converted from blogdown to Quarto and may contain errors. The original can be found in the [archive](", str_replace(posts$old_link[i], "blog.", "archive."), ").*"),
        ""
    )
    post <- c(post[1], addendum, post[-1])
    header <- tibble(
        author = list(name = "David Schoch", orcid = "0000-0003-2952-4812")
    ) |>
        yaml::as.yaml() |>
        paste0("title: \"", posts$post_title[i], "\"\n", ... = _) |>
        paste0(... = _, "date: ", posts$pub_date[i], "\n") |>
        paste0(... = _, "categories: [", posts$category[i], "]\n") |>
        paste0("---\n", ... = _, "---\n") |>
        str_replace("name:", "- name:") |>
        str_replace("orcid:", "  orcid:") |>
        str_split("\n")
    writeLines(c(header[[1]], post), file_md)
}

# fix images
for (i in seq_len(nrow(posts))[-31]) {
    pdir <- fs::path("posts", posts$new_folder[i])
    setwd(pdir)
    file_md <- "index.md"
    post <- readLines(file_md)
    idx <- str_which(post, "!\\[\\]\\(post_files/")
    for (j in seq_along(idx)) {
        img_path <- str_extract(post[idx[j]], "(?<=\\()[^)]+(?=\\))")
        if (str_detect(img_path, "404.html")) {
            post[idx[j]] <- ""
        } else {
            system(paste0("cp ", img_path, " ."))
            post[idx[j]] <- str_remove(post[idx[j]], "post_files/")
        }
    }
    writeLines(post, file_md)
    setwd(wd)
}
