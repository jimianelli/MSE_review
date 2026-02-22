pm_rep <- "/Users/jim/_mymods/noaa-afsc/EBS_pollock/runs/lastyr/pm.rep"
index_dat <- "/Users/jim/_mymods/noaa-afsc/EBS_pollock/runs/data/pm_24_loo_bts_index.dat"

extract_series <- function(lines, label) {
  idx <- which(trimws(lines) == label)
  if (length(idx) == 0) return(data.frame())
  start <- idx[1] + 1
  out <- list()
  i <- start
  while (i <= length(lines)) {
    line <- trimws(lines[i])
    if (!nzchar(line)) { i <- i + 1; next }
    if (!grepl("^\\d{4}\\s", line)) break
    parts <- strsplit(line, "\\s+")[[1]]
    yr <- as.integer(parts[1])
    val <- as.numeric(parts[2])
    out[[length(out) + 1]] <- c(yr, val)
    i <- i + 1
  }
  if (length(out) == 0) return(data.frame())
  mat <- do.call(rbind, out)
  data.frame(year = mat[, 1], value = mat[, 2])
}

extract_vector <- function(lines, label) {
  idx <- which(trimws(lines) == label)
  if (length(idx) == 0) return(numeric())
  i <- idx[1] + 1
  vals <- c()
  while (i <= length(lines)) {
    line <- trimws(lines[i])
    if (!nzchar(line)) { i <- i + 1; next }
    if (!grepl("^[-+0-9.]", line)) break
    nums <- as.numeric(unlist(strsplit(line, "\\s+")))
    vals <- c(vals, nums)
    i <- i + 1
  }
  vals
}

get_section <- function(lines, key) {
  tag <- paste0("#", key)
  i <- which(trimws(lines) == tag)
  if (length(i) == 0) return(numeric())
  i <- i[1] + 1
  vals <- c()
  while (i <= length(lines)) {
    line <- trimws(lines[i])
    if (!nzchar(line)) { i <- i + 1; next }
    if (startsWith(line, "#")) break
    nums <- as.numeric(unlist(strsplit(line, "\\s+")))
    vals <- c(vals, nums)
    i <- i + 1
  }
  vals
}

roc_curve <- function(scores, labels) {
  if (length(scores) == 0) return(list(fpr = c(0, 1), tpr = c(0, 1), auc = NA))
  uniq <- sort(unique(scores), decreasing = TRUE)
  thresholds <- c(max(uniq) + 1e-9, uniq, min(uniq) - 1e-9)
  P <- sum(labels == 1)
  N <- sum(labels == 0)
  tpr <- numeric(length(thresholds))
  fpr <- numeric(length(thresholds))
  for (i in seq_along(thresholds)) {
    preds <- ifelse(scores >= thresholds[i], 1, 0)
    tp <- sum(preds == 1 & labels == 1)
    fp <- sum(preds == 1 & labels == 0)
    tpr[i] <- ifelse(P > 0, tp / P, 0)
    fpr[i] <- ifelse(N > 0, fp / N, 0)
  }
  ord <- order(fpr, tpr)
  fpr <- fpr[ord]
  tpr <- tpr[ord]
  auc <- sum(diff(fpr) * (head(tpr, -1) + tail(tpr, -1)) / 2)
  list(fpr = fpr, tpr = tpr, auc = auc)
}

lines <- readLines(pm_rep, warn = FALSE)
ssb_df <- extract_series(lines, "SSB")
rec_df <- extract_series(lines, "R")
catch_obs <- extract_vector(lines, "obs_catch")

# SSB in pm.rep is total; convert to female SSB assuming 50:50 sex ratio.
# Units: thousand t.
ssb_female <- setNames(0.5 * ssb_df$value, ssb_df$year)
rec <- setNames(rec_df$value, rec_df$year)

# Catch check (thousand t); expected range ~800–2000.
idx_lines <- readLines(index_dat, warn = FALSE)
yrs_avo <- as.integer(get_section(idx_lines, "yrs_avo"))
ob_avo <- get_section(idx_lines, "ob_avo")
yrs_bts <- as.integer(get_section(idx_lines, "yrs_bts_data"))
ob_bts <- get_section(idx_lines, "ob_bts")
yrs_ats <- as.integer(get_section(idx_lines, "yrs_ats_data"))
ob_ats <- get_section(idx_lines, "ob_ats")

# BTS event: female SSB decline vs previous year.
bts_scores <- c()
bts_labels <- c()
for (i in seq_along(yrs_bts)) {
  y <- yrs_bts[i]
  if (!is.na(ssb_female[as.character(y)]) && !is.na(ssb_female[as.character(y - 1)])) {
    event <- ifelse(ssb_female[as.character(y)] < ssb_female[as.character(y - 1)], 1, 0)
    bts_scores <- c(bts_scores, -ob_bts[i])
    bts_labels <- c(bts_labels, event)
  }
}

# ATS event: recruitment below trailing 5-year average.
ats_scores <- c()
ats_labels <- c()
for (i in seq_along(yrs_ats)) {
  y <- yrs_ats[i]
  yrs_needed <- (y - 1):(y - 5)
  if (all(!is.na(rec[as.character(yrs_needed)])) && !is.na(rec[as.character(y)])) {
    avg5 <- mean(rec[as.character(yrs_needed)])
    event <- ifelse(rec[as.character(y)] < avg5, 1, 0)
    ats_scores <- c(ats_scores, -ob_ats[i])
    ats_labels <- c(ats_labels, event)
  }
}

# AVO event: recruitment below trailing 5-year average.
avo_scores <- c()
avo_labels <- c()
for (i in seq_along(yrs_avo)) {
  y <- yrs_avo[i]
  yrs_needed <- (y - 1):(y - 5)
  if (all(!is.na(rec[as.character(yrs_needed)])) && !is.na(rec[as.character(y)])) {
    avg5 <- mean(rec[as.character(yrs_needed)])
    event <- ifelse(rec[as.character(y)] < avg5, 1, 0)
    avo_scores <- c(avo_scores, -ob_avo[i])
    avo_labels <- c(avo_labels, event)
  }
}

bts_roc <- roc_curve(bts_scores, bts_labels)
ats_roc <- roc_curve(ats_scores, ats_labels)
avo_roc <- roc_curve(avo_scores, avo_labels)

out_dir <- "/Users/jim/_mymods/MSE_review/doc/figures"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
out_path <- file.path(out_dir, "roc_ebs_pollock_indices.png")

png(out_path, width = 1800, height = 1600, res = 300)
plot(bts_roc$fpr, bts_roc$tpr, type = "l", lwd = 2, col = "#1b9e77",
     xlab = "False Positive Rate", ylab = "True Positive Rate",
     main = "ROC Curves: EBS Pollock Indices")
lines(ats_roc$fpr, ats_roc$tpr, lwd = 2, col = "#d95f02")
lines(avo_roc$fpr, avo_roc$tpr, lwd = 2, col = "#7570b3")
abline(0, 1, lty = 2, col = "gray50")
legend("bottomright", bty = "n",
       legend = c(sprintf("BTS (AUC=%.2f)", bts_roc$auc),
                  sprintf("ATS (AUC=%.2f)", ats_roc$auc),
                  sprintf("AVO (AUC=%.2f)", avo_roc$auc)),
       col = c("#1b9e77", "#d95f02", "#7570b3"), lwd = 2)
dev.off()

cat("Saved", out_path, "\n")
cat("Points used: BTS", length(bts_scores), "ATS", length(ats_scores), "AVO", length(avo_scores), "\n")
cat("Observed catch range (thousand t):", round(min(catch_obs), 1), "-", round(max(catch_obs), 1), "\n")
