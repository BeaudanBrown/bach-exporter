be_sum_until_three_zeros <- function(row) {
  if (is.character(row)) {
    row <- ifelse(
      row == "Yes",
      1,
      ifelse(
        row == "No",
        0,
        suppressWarnings(as.numeric(row))
      )
    )
  }

  row <- suppressWarnings(as.numeric(row))
  row[is.na(row)] <- 0

  runs <- rle(row)
  zero_runs <- which(runs$values == 0 & runs$lengths >= 3)
  if (!length(zero_runs)) {
    return(sum(row))
  }

  end_pos <- cumsum(runs$lengths)[zero_runs[[1]]] -
    runs$lengths[[zero_runs[[1]]]] +
    3
  sum(row[seq_len(end_pos)])
}

be_compute_tmt_b_minus_a <- function(tmt_b_time, tmt_a_time) {
  be_safe_numeric(tmt_b_time) - be_safe_numeric(tmt_a_time)
}

be_compute_topf_total_corrected <- function(item_values) {
  be_sum_until_three_zeros(item_values)
}
