be_safe_numeric <- function(x) {
  suppressWarnings(as.numeric(x))
}

be_compute_ratio <- function(numerator, denominator) {
  numerator <- be_safe_numeric(numerator)
  denominator <- be_safe_numeric(denominator)

  ifelse(
    !is.na(denominator) & denominator != 0,
    numerator / denominator,
    NA_real_
  )
}

be_compute_tyg_index <- function(triglycerides_mmol_l, glucose_mmol_l) {
  trig_mgdl <- be_safe_numeric(triglycerides_mmol_l) * 88.545
  glucose_mgdl <- be_safe_numeric(glucose_mmol_l) * 18.0

  ifelse(
    !is.na(trig_mgdl) & !is.na(glucose_mgdl),
    log((trig_mgdl * glucose_mgdl) / 2),
    NA_real_
  )
}

be_compute_pwv_mean <- function(
  pwv1,
  pwv2 = NA,
  pwv3 = NA,
  existing_mean = NA
) {
  pwv1 <- be_safe_numeric(pwv1)
  pwv2 <- be_safe_numeric(pwv2)
  pwv3 <- be_safe_numeric(pwv3)
  existing_mean <- be_safe_numeric(existing_mean)

  computed_mean <- ifelse(
    !is.na(pwv3),
    (pwv1 + pwv2 + pwv3) / 3,
    ifelse(!is.na(pwv2), (pwv1 + pwv2) / 2, pwv1)
  )

  ifelse(is.na(existing_mean), computed_mean, existing_mean)
}

be_compute_mean_arterial_pressure <- function(mean_sys, mean_dia) {
  mean_sys <- be_safe_numeric(mean_sys)
  mean_dia <- be_safe_numeric(mean_dia)

  ifelse(
    !is.na(mean_sys) & !is.na(mean_dia),
    mean_dia + ((1 / 3) * (mean_sys - mean_dia)),
    NA_real_
  )
}

be_compute_pulse_pressure <- function(mean_sys, mean_dia) {
  mean_sys <- be_safe_numeric(mean_sys)
  mean_dia <- be_safe_numeric(mean_dia)

  ifelse(!is.na(mean_sys) & !is.na(mean_dia), mean_sys - mean_dia, NA_real_)
}
