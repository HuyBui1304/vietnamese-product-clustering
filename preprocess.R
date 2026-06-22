# Dependencies
load_packages <- function(pkgs) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop(
      "Thiếu package: ", paste(missing, collapse = ", "),
      ". Cài dependency trong requirements-r.txt trước khi chạy."
    )
  }
  invisible(lapply(pkgs, library, character.only = TRUE))
}

load_packages(c("readr", "dplyr", "purrr"))

# Load and merge source files
files <- sprintf("mota%d.csv", 1:14)
stopifnot(all(file.exists(files)))
rows_info <- do.call(rbind, lapply(files, function(fp) {
  data.frame(file = basename(fp), n_rows = nrow(readr::read_csv(fp, show_col_types = FALSE)))
}))
print(rows_info)

needed <- c("category_name","product_name","product_url","description")
read_one <- function(fp){
  df <- readr::read_csv(fp, show_col_types = FALSE)
  miss <- setdiff(needed, names(df)); if (length(miss)) df[, miss] <- NA_character_
  dplyr::select(df, dplyr::any_of(needed)) |>
    dplyr::mutate(source_file = basename(fp))
}
mota_all <- purrr::map_dfr(files, read_one)
readr::write_csv(mota_all, "mota_all.csv")

df_all   <- readr::read_csv("mota_all.csv", show_col_types = FALSE)
df_small <- dplyr::select(df_all, category_name, description)
readr::write_csv(df_small, "description.csv")

n_missing <- sum(is.na(df_small$description) | trimws(df_small$description) == "")
cat("Tổng dòng:", nrow(df_small), " | Thiếu mô tả:", n_missing, "\n")

missing_by_label <- df_small |>
  dplyr::mutate(is_missing = is.na(description) | trimws(description) == "") |>
  dplyr::group_by(category_name) |>
  dplyr::summarise(total = dplyr::n(), missing = sum(is_missing),
                   pct_missing = round(100*missing/total,2), .groups="drop") |>
  dplyr::arrange(dplyr::desc(missing))
print(missing_by_label, n = 50)

df_clean <- df_small |>
  dplyr::filter(!(is.na(description) | trimws(description) == ""))
readr::write_csv(df_clean, "description.csv")
cat("Sau khi xóa thiếu, còn:", nrow(df_clean), "dòng\n")

clean_by_label <- df_clean |>
  dplyr::group_by(category_name) |>
  dplyr::summarise(total = dplyr::n(), .groups="drop") |>
  dplyr::arrange(dplyr::desc(total))
print(clean_by_label, n = 50)

# Shared text normalization
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringi)
})

normalize_units <- function(txt) {
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*(\"|”|“|''|inches|inch)\\b", "\\1inch", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*inch\\b", "\\1inch", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+)\\s*m\\s*a\\s*h\\b", "\\1mah", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*w\\b",  "\\1w",  txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*hz\\b", "\\1hz", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*mp\\b", "\\1mp", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*gb\\b", "\\1gb", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*tb\\b", "\\1tb", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*nm\\b", "\\1nm", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+(?:[\\.,]\\d+)?)\\s*mm\\b", "\\1mm", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+)\\s*fps\\b",               "\\1fps", txt, ignore.case = TRUE)
  txt <- gsub("\\b4\\s*[kK]\\b", "4k", txt)
  txt <- gsub("\\b8\\s*[kK]\\b", "8k", txt)
  txt <- gsub("\\b1080\\s*[pP]\\b", "1080p", txt)
  txt <- gsub("\\b720\\s*[pP]\\b",  "720p",  txt)
  txt <- gsub("(\\d{2,})\\s*(mah)\\b", "\\1\\2", txt, ignore.case = TRUE)
  txt <- gsub("(\\d+),(\\d+)(inch|mm|nm|w|hz|mp|gb|tb)\\b", "\\1.\\2\\3", txt, ignore.case = TRUE)
  txt
}

clean_base <- function(txt) {
  txt <- stri_replace_all_regex(txt, "<[^>]+>", " ")
  txt <- stri_replace_all_regex(txt, "(https?://|ftp://|www\\.)\\S+", " ")
  txt <- stri_replace_all_regex(txt, "[\\p{L}\\p{N}._%+-]+@[\\p{L}\\p{N}.-]+\\.[A-Za-z]{2,}", " ")
  txt <- stri_replace_all_regex(txt, "[\\r\\n\\t]+", " ")
  txt <- stri_trans_nfc(txt)
  txt <- normalize_units(txt)
  txt <- stri_trans_tolower(txt)
  txt <- stri_replace_all_regex(txt, "[\\p{P}\\p{S}]+", " ")
  txt <- stri_replace_all_regex(txt, "\\s+", " ")
  stri_trim_both(txt)
}

suppressPackageStartupMessages({
  library(stopwords)
})

# Multilingual representation retains Vietnamese and English stopwords.
df_multilingual <- df_clean %>%
  mutate(
    description = clean_base(description)
  ) %>%
  select(category_name, description)

dir.create("social_networking/multilingual", recursive = TRUE, showWarnings = FALSE)
multilingual_path <- "social_networking/multilingual/description_multilingual.csv"
readr::write_csv(df_multilingual, multilingual_path)
cat("[OK] Đã ghi:", multilingual_path, "(đa ngôn ngữ, giữ stopwords)\n")

# Traditional representation removes stopwords but retains technical tokens.
vi_sw <- stopwords::stopwords("vi", source = "stopwords-iso")
en_sw <- stopwords::stopwords("en", source = "stopwords-iso")
all_sw <- unique(c(vi_sw, en_sw))

remove_sw_keep_tech <- function(text_line) {
  if (is.na(text_line) || !nzchar(text_line)) return("")
  toks <- unlist(strsplit(text_line, "\\s+"))
  keep_tech <- grepl("^\\d+(?:\\.\\d+)?(mah|hz|mp|gb|tb|inch|mm|nm|fps)$", toks) |
    grepl("^(4k|8k|1080p|720p)$", toks) |
    grepl("^\\d+$", toks)
  keep_model <- grepl("^(?:[a-z]*\\d+[a-z\\d]*|[a-z]{2,}\\d{2,})$", toks)
  is_sw <- toks %in% all_sw
  keep <- keep_tech | keep_model | (!is_sw)
  kept <- toks[keep]
  kept <- kept[ nchar(kept) > 1 | grepl("^\\d$", kept) ]
  if (!length(kept)) return("")
  out <- paste(kept, collapse = " ")
  out <- gsub("\\s+", " ", out)
  trimws(out)
}

df_traditional <- df_clean %>%
  mutate(
    description = clean_base(description),
    description = vapply(description, remove_sw_keep_tech, FUN.VALUE = "")
  ) %>%
  select(category_name, description)

dir.create("social_networking/traditional", recursive = TRUE, showWarnings = FALSE)
traditional_path <- "social_networking/traditional/description_clean.csv"
readr::write_csv(df_traditional, traditional_path)
cat("[OK] Đã ghi:", traditional_path, "(truyền thống – bỏ stopwords VI+EN, GIỮ token kỹ thuật/model)\n")

head_idx <- 1L:min(10L, nrow(df_clean))

cat("\n--- Mẫu Multilingual ---\n")
print(head(df_multilingual[head_idx, ], 10))

cat("\n--- Mẫu Traditional (no-stopwords, GIỮ kỹ thuật/model) ---\n")
print(head(df_traditional[head_idx, ], 10))
