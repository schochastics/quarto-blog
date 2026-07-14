#!/usr/bin/env Rscript
# Scheduled-publishing gate for the Quarto blog.
#
# For every posts/*/index.qmd this walks the YAML front matter and compares the
# `date:` field to today:
#   * date in the future  -> ensure `draft: true`  (kept out of the rendered site)
#   * date today or past  -> ensure the draft flag is gone (goes live)
# Posts without a parseable date are treated as live and left untouched.
# Files are only rewritten when their draft state actually changes, so re-runs
# produce no spurious git churn once the queue has settled.

today <- Sys.Date()
posts <- list.files("posts", pattern = "^index\\.qmd$",
                    recursive = TRUE, full.names = TRUE)

parse_fm_date <- function(fm) {
  idx <- grep("^date:[[:space:]]*", fm)
  if (length(idx) == 0) return(as.Date(NA))
  val <- sub("^date:[[:space:]]*", "", fm[idx[1]])
  val <- trimws(gsub("[\"']", "", val))
  suppressWarnings(as.Date(val))
}

drafts <- character(0)
live <- character(0)
changed <- character(0)

for (f in posts) {
  lines <- readLines(f, warn = FALSE)
  if (length(lines) < 2 || !grepl("^---[[:space:]]*$", lines[1])) next
  fence <- grep("^---[[:space:]]*$", lines)
  if (length(fence) < 2) next
  fm_end <- fence[2]

  fm <- lines[seq_len(fm_end)]
  body <- if (fm_end < length(lines)) lines[(fm_end + 1):length(lines)] else character(0)

  d <- parse_fm_date(fm)
  draft_idx <- grep("^draft:[[:space:]]*", fm)
  want_draft <- !is.na(d) && d > today

  new_fm <- fm
  if (want_draft) {
    if (length(draft_idx) == 0) {
      new_fm <- append(fm, "draft: true", after = fm_end - 1)  # before closing ---
    } else {
      new_fm[draft_idx] <- "draft: true"
    }
    drafts <- c(drafts, f)
  } else {
    if (length(draft_idx) > 0) new_fm <- fm[-draft_idx]
    live <- c(live, f)
  }

  new_lines <- c(new_fm, body)
  if (!identical(new_lines, lines)) {
    writeLines(new_lines, f)
    changed <- c(changed, f)
  }
}

cat(sprintf("Gate %s  |  live: %d  scheduled(draft): %d  changed: %d\n",
            as.character(today), length(live), length(drafts), length(changed)))
for (f in drafts)  cat("  [scheduled]", f, "\n")
for (f in changed) cat("  [changed]  ", f, "\n")

cat(sprintf("::daggle-output name=published_now::%d\n", length(changed)))
