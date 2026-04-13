###READ ME/EDIT ME-----

# Updates in version 10:
# - now updates similarities scoring to include the discontinuation scoring rule:
#   previously the column was called similarities_total and now called similarities_total_corrected
# - csv's created before v10 (9.2.2026) will have slightly different Similarity outcomes:
#   un-comment line 385 to generate the old similarities_total (i.e., as per RedCap)

#Updates in version 9:
# - now supports year 2 and 3 TELE outcomes
# ** NOTE: not all data has been double-entered or checked and may contain errors **

# Updates in version 8:
# - added PSQI sub-scores
# - added PSG Power Spectral analysis (wide format)

# Updates in version 7:
# - now with full biomarker data
# - ! for MRI: old brainvol renamed to brainvol_novent, other brain volumes added
# - bloods now include eGFR
# - now has alternative Mac/Windows paths

# - now includes MRI data for all baseline participants
# - now creates a variable for APOE and AQP4 genetic status
# - now includes Triglyceride-glucose index
# - now includes dyslipidemia diagnosis category (according to AIHW criteria)
# - now includes AB42/40 ratio for plasma and CSF
# - corrected pulse wave velocity (PWV) mean to include subjects with one measurement
# - now includes mean arterial pressure (MAP) from office BP
# - now includes pulse pressure from office BP
# - updated code to make sure NA's are assigned appropriately in new variables
# - now creates TMT B minus A "tmtbminusa"
# - now creates Prose percentage correct (needed due to version A and B having different totals)

# BUG NOTE: Redcap currently has three entries for 0235, you may need to remove the "0235-01" rows if not using subset lists
#       (may be helpful if you get errors with medications)

# Email Ella or Beau for troubleshooting, suggestions or help :)
# ella.rowsthorn@monash.edu, beaudan.campbell-brown@monash.edu

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#INFORMATION AND HOW TO:

#This script will take a raw csv straight from redcap, and output a tidy data file for requested tests/variables.
#The variable names are the same as those specified in the DataDictionary, and only useful variables are kept.
# For more details, please see S Drive > BACH > Data > Data Freeze 1 > DataDictionary.
#Currently, this script is for baseline data only (any later years' data will be left out).

#Download a RAW and a LABELS csv file from Redcap (or use existing ones in S Drive > BACH > Data > Data Freeze 1).
#These must be identical (downloaded at the same time). They can be the entire data set, or a section of the data.
#PSG data will need to also be download separately as it is a separate project in redcap.
#At minimum you must have: ID, session/event name.
#Regardless of what data you downloaded, you will need to tell the script which sections you want it to "do".

#You can create a subset of select participants using a .txt file list.
#For an example, the first 120 (data freeze 1) participants, see S Drive > BACH > Data > Data Freeze 1 > df1_participants.txt
#You can also choose whether you'd like categorical variables to be named (e.g. Male/Female) or numbered (0/1).

#Please complete ALL fields in "EDIT" below and then run the entire script.
#If you wish to make any changes to the code, please make your own copy before doing so.
#As a rule of thumb, don't 'save' this script after use unless its your own copy.

#REQUIRED: This script uses tidyr and dplyr packages. Please install if you haven't already.
# Copy and paste these commands into your console without the # and hit enter:
# install.packages("tidyr")
# install.packages("dplyr")

#TIP: Use Ctrl + Alt + R on windows or Command + Shift + Enter on Mac to run the entire script.

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#EDIT HERE
#indicate whether you are on a Mac or Windows computer with "mac" or "windows"
mac_or_windows <- "mac"

#NOTE: if you get "Error: '\E' is an..." add a "#" in front of line 79
data_folder_mac <- "/Volumes/shared-1/Epi-Dementia/Pase-ED/Studies/BACH/Data"
#data_folder_wind <- file.path("S:", "Epi-Dementia", "Pase-ED", "Studies", "BACH", "Data")

#output file name (will be saved in 1. Data Freeze folder)
output_name <- "NAME.csv"

#participant list file path, change to "No" if you want to keep all participants.
#can choose subset to either be N=120 "120" or N=149 "149" (original biomarkers subset)
create_subset <- "No"
subset_no <- "149"

#do you want named or numbered categorical variables (i.e. "Male"/"Female", or 0/1), use "named" or "numbered"
# NOTE: medications only currently available with "named" format
# NOTE: I recommend "named", R tends to handle this better for categorical variables
catvariables <- "named"

#Edit the below variables to indicate which sections you have downloaded and want cleaned with "Yes" or "No"
do_year2 = "Yes" #in addition to Baseline, can apply to TELE, AD8, Med Hx, Med Tx
do_year3 = "Yes"

do_participantscreening <- "Yes" #has age, sex, education
do_cognitivescreening <- "No"
do_MRIscreening <- "No"
do_LPscreening <- "No"

do_allannualphone <- "No" #if "Yes" will do all annual phone tests regardless of individual Yes/No
do_prose_passages <- "No"
do_similarities <- "Yes"
do_moca <- "No"
do_ad8 <- "No"
do_ucla <- "No" #loneliness questionnaire, requires do_year2 to be "Yes"

do_demographics <- "No" #has race/ethnicity, postcode etc.
do_cesd <- "No"
do_stai <- "No"
do_pss <- "No"
do_cdrisc <- "No"
do_ipaq <- "No"
do_rhhi <- "No"
do_minddiet <- "No"
do_alcohol <- "No"
do_cfi <- "No"
do_globalhealth <- "No"

do_SES <- "No" #requires demographics
do_ARIA <- "No" #requires demographics, SES

do_bloods <- "No"
do_vitals <- "No" #has weight/height/bmi, office BP
do_medhx <- "No"
do_medications <- "No"

do_allneuropsych <- "No" #if "Yes" will do all NP tests regardless of individual Yes/No
do_cdr <- "No"
do_mmse <- "No"
do_sydbat <- "No"
do_logicalmem <- "No"
do_visualrepro <- "No"
do_tmt <- "No"
do_fab <- "No"
do_cowat <- "No"
do_hvot <- "No"
do_tasit <- "No"
do_topf <- "No"

do_dementiastatus <- "No"

do_MRI <- "No" #see MRI_data folder for exclusion recommendations and data dictionary
do_LP <- "No" #info about success/date/time

do_24hBP <- "No"

do_genomics <- "No"

do_biomarkers <- "No"

do_acti_full <- "No" #includes all data from 14 days and summary
do_acti_summary <- "No" #average/total summary acti only

do_psqi_full <- "No" #all test items and sub components
do_psqi_summary <- "No" #date and total score only
do_ess <- "No"
do_isi <- "No"

do_psgscreening <- "No" #includes date of psg and time from acti
do_sleephealth <- "No" #sleep health questionnaire
do_sleepmed <- "No"
do_morningquest <- "No" #sleep morning questionnaire

do_psg_full <- "No" #includes all PSG data
do_psg_summary <- "No" #essential PSG data only
do_psg_powerspec <- "No" #Luna software Power Spectral analysis (Abby's)


# And that's all! You can ignore all of the below code. You're now ready to run the whole script :)
# TIP: Use Ctrl + Alt + R on windows or Command + Shift + Enter on Mac to run the entire script.

###DF SETUP-----
library(tidyr)
library(dplyr)

if (mac_or_windows == "mac") {
  data_freeze_folder <- file.path(data_folder_mac, "1. Data Freeze 1")
  raw_input_file <- file.path(
    data_freeze_folder,
    "BACHStudy_DATA_2026-02-17_1013.csv"
  )
  labels_input_file <- file.path(
    data_freeze_folder,
    "BACHStudy_DATA_LABELS_2026-02-17_1013.csv"
  )
  raw_input_file_PSG <- file.path(
    data_freeze_folder,
    "BACHStudyPSGReadings_DATA_2026-03-02_1107.csv"
  )
  MRI_input_file <- file.path(data_folder_mac, "MRI_data/global_n241.csv")

  ses_file <- file.path(data_freeze_folder, "2016_Census_SES/absdf.csv")
  aria_file <- file.path(data_freeze_folder, "2016_Census_SES/RA_2016_AUST.csv")
  bio_file <- file.path(
    data_folder_mac,
    "Blood biomarkers/all_biomarkers_merged.csv"
  )
  powerspec_file <- file.path(data_freeze_folder, "psd_data_2026-02-17.csv")

  output_file <- file.path(data_freeze_folder, output_name)

  list_file_120 <- file.path(data_freeze_folder, "df1_participants_120.txt")
  list_file_149 <- file.path(data_freeze_folder, "df1_participants_149.txt")
}

if (mac_or_windows == "windows") {
  data_freeze_folder <- file.path(data_folder_wind, "1. Data Freeze 1")
  raw_input_file <- file.path(
    data_freeze_folder,
    "BACHStudy_DATA_2026-02-17_1013.csv"
  )
  labels_input_file <- file.path(
    data_freeze_folder,
    "BACHStudy_DATA_LABELS_2026-02-17_1013.csv"
  )
  raw_input_file_PSG <- file.path(
    data_freeze_folder,
    "BACHStudyPSGReadings_DATA_2026-03-02_1107.csv"
  )
  MRI_input_file <- file.path(data_folder_wind, "MRI_data/global_n241.csv")

  ses_file <- file.path(data_freeze_folder, "2016_Census_SES/absdf.csv")
  aria_file <- file.path(data_freeze_folder, "2016_Census_SES/RA_2016_AUST.csv")
  bio_file <- file.path(
    data_folder_wind,
    "Blood biomarkers/all_biomarkers_merged.csv"
  )
  powerspec_file <- file.path(data_freeze_folder, "psd_data_2026-02-17.csv")

  output_file <- file.path(data_freeze_folder, output_name)

  list_file_120 <- file.path(data_freeze_folder, "df1_participants_120.txt")
  list_file_149 <- file.path(data_freeze_folder, "df1_participants_149.txt")
}

if (catvariables == "named") {
  df_raw <- read.csv(
    file = raw_input_file,
    colClasses = c("idno" = "character")
  )
  df <- read.csv(
    file = labels_input_file,
    colClasses = c("Participant.ID" = "character")
  )

  #take data from df_labels and headings from df_raw
  df <- setNames(df, names(df_raw))
  stopifnot(ncol(df) == ncol(df_raw))
}

if (catvariables == "numbered") {
  df <- read.csv(file = raw_input_file, colClasses = c("idno" = "character"))
}

#remove every line that has "--2" or "-2"
df <- df[!grepl("--2|-2", df$idno), ]

#remove "--1" or "-1" from ID column
df$idno <- gsub("--1", "", df$idno)
df$idno <- gsub("-1", "", df$idno)

#remove IDs greater than 0300
df <- df[!df$idno > "0300", ]

#remove IDs who did not complete baseline
df <- df[!df$participated_assessment_complete == "0", ]
df <- df[!df$participated_assessment_complete == "Incomplete", ]

#subset as included participants from data freeze
if (create_subset == "Yes") {
  if (subset_no == "149") {
    participant_list <- readLines(list_file_149)
    participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
    df <- df[df$idno %in% participant_list, ]
  }
  if (subset_no == "120") {
    participant_list <- readLines(list_file_120)
    participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
    df <- df[df$idno %in% participant_list, ]
  }
}

#separate years
df_year2 <- subset(
  df,
  grepl("Year 2", df$redcap_event_name, ignore.case = TRUE)
)
df_year3 <- subset(
  df,
  grepl("Year 3", df$redcap_event_name, ignore.case = TRUE)
)
df <- subset(df, grepl("baseline", df$redcap_event_name, ignore.case = TRUE))

empty_cols <- colSums(is.na(df_year2) | df_year2 == "") == nrow(df_year2)
df_year2 <- df_year2[, !empty_cols]
rm(empty_cols)

empty_cols <- colSums(is.na(df_year3) | df_year3 == "") == nrow(df_year3)
df_year3 <- df_year3[, !empty_cols]
rm(empty_cols)

empty_cols <- colSums(is.na(df) | df == "") == nrow(df)
df <- df[, !empty_cols]
rm(empty_cols)

#prepare df_new
df_new <- data.frame(matrix(nrow = (nrow(df))))

if (do_year2 == "Yes") {
  df_new2 <- data.frame(matrix(nrow = (nrow(df_year2))))
  df_new2$subject_id <- df_year2$idno
  df_new2 <- dplyr::select(df_new2, -c(1))
}
if (do_year3 == "Yes") {
  df_new3 <- data.frame(matrix(nrow = (nrow(df_year3))))
  df_new3$subject_id <- df_year3$idno
  df_new3 <- dplyr::select(df_new3, -c(1))
}

###RE-NAME/REMOVE-----

#general/minimum
df_new$subject_id <- df$idno
df_new <- dplyr::select(df_new, -c(1))
df_new$session <- df$redcap_event_name

#participant/participated
df_new$session_date <- df$pa_date

#participant screening
if (do_participantscreening == "Yes") {
  df_new$age <- df$age
  df_new$sex <- df$sex
  df_new$education <- df$education
  df_new$education_highest <- df$highest_education
  df_new$education_highest_other_detail <- df$highest_education_other
}

#cognitive screening - TELE
if (do_cognitivescreening == "Yes") {
  df_new$cogscreen_total <- df$tele_total
}

#MRI screening
if (do_MRIscreening == "Yes") {
  df_new$handedness <- df$handedness
}

#LP screening
if (do_LPscreening == "Yes") {
  df_new$LP_interest <- df$lp_interest
}

#Annual Phone Call
if (do_allannualphone == "Yes" | do_prose_passages == "Yes") {
  df_new$tele_prose_version <- df$prose_passage
  df_new$tele_prose_imm_time <- df$prose_time
  df_new$tele_prose_imm_story1 <- df$prose_s1_imm_story
  df_new$tele_prose_imm_theme1 <- df$prose_s1_imm_theme
  df_new$tele_prose_imm_story2 <- df$prose_s2_imm_story
  df_new$tele_prose_imm_theme2 <- df$prose_s2_imm_theme
  df_new$tele_prose_delay_time <- df$prose_del_time
  df_new$tele_prose_delay_mins <- df$prose_timediff
  df_new$tele_prose_delay_story1 <- df$prose_s1_del_story
  df_new$tele_prose_delay_theme1 <- df$prose_s1_del_theme
  df_new$tele_prose_delay_story2 <- df$prose_s2_del_story
  df_new$tele_prose_delay_theme2 <- df$prose_s2_del_theme
}

if (
  do_year2 == "Yes" & (do_allannualphone == "Yes" | do_prose_passages == "Yes")
) {
  match_ids <- match(df_new$subject_id, df_year2$idno)

  df_new$year2_tele_prose_version <- df_year2$prose_passage[match_ids]
  df_new$year2_tele_prose_imm_time <- df_year2$prose_time[match_ids]
  df_new$year2_tele_prose_imm_story1 <- df_year2$prose_s1_imm_story[match_ids]
  df_new$year2_tele_prose_imm_theme1 <- df_year2$prose_s1_imm_theme[match_ids]
  df_new$year2_tele_prose_imm_story2 <- df_year2$prose_s2_imm_story[match_ids]
  df_new$year2_tele_prose_imm_theme2 <- df_year2$prose_s2_imm_theme[match_ids]
  df_new$year2_tele_prose_delay_time <- df_year2$prose_del_time[match_ids]
  df_new$year2_tele_prose_delay_mins <- df_year2$prose_timediff[match_ids]
  df_new$year2_tele_prose_delay_story1 <- df_year2$prose_s1_del_story[match_ids]
  df_new$year2_tele_prose_delay_theme1 <- df_year2$prose_s1_del_theme[match_ids]
  df_new$year2_tele_prose_delay_story2 <- df_year2$prose_s2_del_story[match_ids]
  df_new$year2_tele_prose_delay_theme2 <- df_year2$prose_s2_del_theme[match_ids]
}

if (
  do_year3 == "Yes" & (do_allannualphone == "Yes" | do_prose_passages == "Yes")
) {
  match_ids <- match(df_new$subject_id, df_year3$idno)

  df_new$year3_tele_prose_version <- df_year3$prose_passage[match_ids]
  df_new$year3_tele_prose_imm_time <- df_year3$prose_time[match_ids]
  df_new$year3_tele_prose_imm_story1 <- df_year3$prose_s1_imm_story[match_ids]
  df_new$year3_tele_prose_imm_theme1 <- df_year3$prose_s1_imm_theme[match_ids]
  df_new$year3_tele_prose_imm_story2 <- df_year3$prose_s2_imm_story[match_ids]
  df_new$year3_tele_prose_imm_theme2 <- df_year3$prose_s2_imm_theme[match_ids]
  df_new$year3_tele_prose_delay_time <- df_year3$prose_del_time[match_ids]
  df_new$year3_tele_prose_delay_mins <- df_year3$prose_timediff[match_ids]
  df_new$year3_tele_prose_delay_story1 <- df_year3$prose_s1_del_story[match_ids]
  df_new$year3_tele_prose_delay_theme1 <- df_year3$prose_s1_del_theme[match_ids]
  df_new$year3_tele_prose_delay_story2 <- df_year3$prose_s2_del_story[match_ids]
  df_new$year3_tele_prose_delay_theme2 <- df_year3$prose_s2_del_theme[match_ids]
}

if (do_allannualphone == "Yes" | do_similarities == "Yes") {
  df_new$tele_date <- df$pp_date
  sum_until_three_zeros <- function(row) {
    if (all(is.na(row))) {
      return(NA)
    }
    if (is.character(row)) {
      row <- ifelse(row == "Yes", 1, 0)
    }
    row[is.na(row)] <- 0
    r <- rle(row)
    zero_runs <- which(r$values == 0 & r$lengths >= 3)
    if (length(zero_runs) == 0) {
      return(sum(row))
    }
    end_pos <- cumsum(r$lengths)[zero_runs[1]] - r$lengths[zero_runs[1]] + 3
    sum(row[1:end_pos])
  }
  sim_mat <- df[, paste0("similarities", 1:18)]
  df_new$tele_similarities_corrected <- apply(sim_mat, 1, sum_until_three_zeros)
  #df_new$tele_similarities_uncorrected <- df$similarities_total
  #df_new$tele_sim_change <- ifelse(df_new$tele_similarities_corrected == df_new$tele_similarities_uncorrected, "No", "Yes")
}

if (
  do_year2 == "Yes" & (do_allannualphone == "Yes" | do_similarities == "Yes")
) {
  match_ids <- match(df_new$subject_id, df_year2$idno)
  df_new$year2_tele_date <- df_year2$pp_date[match_ids]

  sim_mat <- df_year2[, paste0("similarities", 1:18)]
  sim_year2_scores <- apply(sim_mat, 1, sum_until_three_zeros)
  df_new$year2_tele_similarities_corrected <- sim_year2_scores[match_ids]
  #df_new$year2_tele_similarities_uncorrected <- df_year2$similarities_total[match_ids]
  #df_new$tele_sim_change_year2 <- ifelse(df_new$year2_tele_similarities_corrected == df_new$year2_tele_similarities_uncorrected, "No", "Yes")
}

if (
  do_year3 == "Yes" & (do_allannualphone == "Yes" | do_similarities == "Yes")
) {
  match_ids <- match(df_new$subject_id, df_year3$idno)
  df_new$year3_tele_date <- df_year3$pp_date[match_ids]

  sim_mat <- df_year3[, paste0("similarities", 1:18)]
  sim_year3_scores <- apply(sim_mat, 1, sum_until_three_zeros)
  df_new$year3_tele_similarities_corrected <- sim_year3_scores[match_ids]
  #df_new$year3_tele_similarities_uncorrected <- df_year3$similarities_total[match_ids]
  #df_new$tele_sim_change_year3 <- ifelse(df_new$year3_tele_similarities_corrected == df_new$year3_tele_similarities_uncorrected, "No", "Yes")
}

if (do_allannualphone == "Yes" | do_moca == "Yes") {
  df_new$tele_date <- df$pp_date
  df_new$moca_total <- df$moca_total
}

if (do_year2 == "Yes" & (do_allannualphone == "Yes" | do_moca == "Yes")) {
  match_ids <- match(df_new$subject_id, df_year2$idno)

  df_new$year2_tele_date <- df_year2$pp_date[match_ids]
  df_new$year2_moca_total <- df_year2$moca_total[match_ids]
}

if (do_year3 == "Yes" & (do_allannualphone == "Yes" | do_moca == "Yes")) {
  match_ids <- match(df_new$subject_id, df_year3$idno)

  df_new$year3_tele_date <- df_year3$pp_date[match_ids]
  df_new$year3_moca_total <- df_year3$moca_total[match_ids]
}

if (do_allannualphone == "Yes" | do_ad8 == "Yes") {
  df_new$tele_date <- df$pp_date
  df_new$ad8_person <- df$ad8_who
  df_new$ad8_date <- df$ad8_date
  df_new$ad8_total <- df$ad8_total
}

if (do_year2 == "Yes" & (do_allannualphone == "Yes" | do_ad8 == "Yes")) {
  match_ids <- match(df_new$subject_id, df_year2$idno)

  df_new$year2_tele_date <- df_year2$pp_date[match_ids]
  df_new$year2_ad8_person <- df_year2$ad8_who[match_ids]
  df_new$year2_ad8_date <- df_year2$ad8_date[match_ids]
  df_new$year2_ad8_total <- df_year2$ad8_total[match_ids]
}

if (do_year3 == "Yes" & (do_allannualphone == "Yes" | do_ad8 == "Yes")) {
  match_ids <- match(df_new$subject_id, df_year3$idno)

  df_new$year3_tele_date <- df_year3$pp_date[match_ids]
  df_new$year3_ad8_person <- df_year3$ad8_who[match_ids]
  df_new$year3_ad8_date <- df_year3$ad8_date[match_ids]
  df_new$year3_ad8_total <- df_year3$ad8_total[match_ids]
}
if (do_year2 == "Yes" & (do_allannualphone == "Yes" | do_ucla == "Yes")) {
  match_ids <- match(df_new$subject_id, df_year2$idno)

  df_new$year2_ucla_q1 <- df_year2$ucla1_v2[match_ids]
  df_new$year2_ucla_q2 <- df_year2$ucla2_v2[match_ids]
  df_new$year2_ucla_q3 <- df_year2$ucla3_v2[match_ids]
  df_new$year2_ucla_total <- df_year2$ucla_total_v2[match_ids]
}

#survey demographics
if (do_demographics == "Yes") {
  df_new$demographics_date <- df$demographics_date
  df_new$race <- df$race
  df_new$race_other <- df$race_other
  df_new$ethnicity <- df$ethnicity
  df_new$lang_first_english <- df$english_first
  df_new$lang_english_age <- df$english_first_n
  df_new$lang_first_other <- df$first_language
  df_new$empolyment_status <- df$employment
  df_new$retire_age <- df$retire_age
  df_new$occupation <- df$occupation
  df_new$income_personal <- df$personal_income
  df_new$income_household <- df$household_income
  df_new$postcode_current <- df$current_postcode
  df_new$postcode_longest <- df$postcode_longest
  df_new$postcode_longest_time <- df$postcode_longest_length
  df_new$living_arrange <- df$living_arrangements
  df_new$living_arrange_other <- df$living_arrangements_other
  df_new$living_household_n <- df$number_household
  df_new$relationship_status <- df$relationship_status
  df_new$childhood_ses <- df$ses_family
  df_new$fathers_occupation_childhood <- df$father_occ
  df_new$fathers_occupation_recent <- df$father_recent_occ
}

#survey CES-D
if (do_cesd == "Yes") {
  df_new$cesd_date <- df$cesd_date
  df_new$cesd_total <- df$cesd_total
}

#survey STAI
if (do_stai == "Yes") {
  df_new$stai_date <- df$stai_date
  df_new$stai_total_state <- df$stai_y1_tot
  df_new$stai_total_trait <- df$stai_y2_tot
}

#survey PSS
if (do_pss == "Yes") {
  df_new$pss_date <- df$pss_date
  df_new$pss_total <- df$pss_total
}

#CD-RISC 10
if (do_cdrisc == "Yes") {
  df_new$cdrisc_date <- df$cd_risc_date
  df_new$cdrisc_total <- df$cd_risc_total
}

#IPAQ
if (do_ipaq == "Yes") {
  df_new$ipaq_date <- df$ipaq_date
  df_new$ipaq_vigorous_met <- df$ipaq_vig_met
  df_new$ipaq_moderate_met <- df$ipaq_mod_met
  df_new$ipaq_walking_met <- df$ipaq_walk_met
  df_new$ipaq_total_met <- df$ipaq_tot_pa
  df_new$ipaq_category <- df$ipaq_category
}

#RHHI
if (do_rhhi == "Yes") {
  df_new$rhhi_date <- df$rhhi_date
  df_new$rhhi_total <- df$rhhi_total
}

#MIND Diet
if (do_minddiet == "Yes") {
  df_new$minddiet_date <- df$mind_date
  df_new$minddiet_total <- df$mind_total
}

#Alcohol Questionnaire
if (do_alcohol == "Yes") {
  df_new$alcoholq_date <- df$alcohol_date
  df_new$alcoholq_12mo_freq <- df$alcohol1
  df_new$alcoholq_lifetime_24hmax <- df$alcohol1a
  df_new$alcoholq_12mo_daily <- df$alcohol2
  df_new$alcoholq_12mo_binge_freq <- df$alcohol3
}

#CFI
if (do_cfi == "Yes") {
  df_new$cfi_date <- df$cfi_date
  df_new$cfi_total <- df$cfi_total
}

#Euro QoL Index
if (do_globalhealth == "Yes") {
  df_new$globhealth_date <- df$global_date
  df_new$globhealth_physical <- df$global_tot_physical
  df_new$globhealth_mental <- df$global_tot_mental
  df_new$globhealth_index <- df$euro_qol
}

#Bloods/Pathology
if (do_bloods == "Yes") {
  df_new$bloods_success <- df$bloods_successful
  df_new$bloods_date <- df$bloods_date
  df_new$bloods_time <- df$bloods_time
  df_new$bloods_drawnby <- df$bloods_who
  df_new$bloods_drawnby_detail <- df$bloods_ra
  df_new$bloods_notes <- df$bloods_notes
  df_new$bloods_notes_detail <- df$bloods_notes_y
  df_new$bloods_glucose_fasting <- df$bloods_glucose
  df_new$bloods_chol <- df$bloods_chol
  df_new$bloods_chol_hdl <- df$bloods_chol_hdl
  df_new$bloods_chol_nonhdl <- df$bloods_non_hdl
  df_new$bloods_chol_ldl <- df$bloods_ldl
  df_new$bloods_triglyc <- df$bloods_trigly
  df_new$bloods_hemoglob <- df$bloods_hb
  df_new$bloods_wbc <- df$bloods_wbc
  df_new$bloods_platelets <- df$bloods_platelets
  df_new$bloods_hct <- df$bloods_hematocrit
  df_new$bloods_mcv <- df$bloods_mcv
  df_new$bloods_mch <- df$bloods_mch
  df_new$bloods_mchc <- df$bloods_mchc
  df_new$bloods_rbc <- df$bloods_rbc
  df_new$bloods_rdw <- df$bloods_rdw
  df_new$bloods_neutrophils <- df$bloods_neutrophils
  df_new$bloods_lymphocytes <- df$bloods_lymphocytes
  df_new$bloods_monocytes <- df$bloods_monocytes
  df_new$bloods_eosinophils <- df$bloods_eosinophils
  df_new$bloods_basophils <- df$bloods_basophils
  df_new$bloods_inr <- df$bloods_inr
  df_new$bloods_egfr <- df$bloods_egfr
}

#Vitals
if (do_vitals == "Yes") {
  df_new$vitals_date <- df$vitals_date
  df_new$vitals_time <- df$vitals_time
  df_new$vitals_breakfast_before <- df$vitals_breakfast
  df_new$vitals_breakfast_before_caffiene <- df$vitals_breakfast_caff
  df_new$vitals_breakfast_before_food <- df$vitals_breakfast_f
  df_new$vitals_breakfast_before_drink <- df$vitals_breakfast_d
  df_new$height <- df$height
  df_new$weight <- df$weight
  df_new$bmi <- df$bmi
  df_new$waist_circum <- df$waist_circ
  df_new$vitals_lying_1_hr <- df$lying_hr1
  df_new$vitals_lying_1_sys <- df$lying_systolic_bp1
  df_new$vitals_lying_1_dia <- df$lying_diastolic_bp1
  df_new$vitals_lying_2_hr <- df$lying_hr2
  df_new$vitals_lying_2_sys <- df$lying_systolic_bp2
  df_new$vitals_lying_2_dia <- df$lying_diastolic_bp2
  df_new$vitals_lying_3_hr <- df$lying_hr3
  df_new$vitals_lying_3_sys <- df$lying_systolic_bp3
  df_new$vitals_lying_3_dia <- df$lying_diastolic_bp3
  df_new$vitals_lying_mean_hr <- df$lying_hr_av
  df_new$vitals_lying_mean_sys <- df$lying_systolic_bp_av
  df_new$vitals_lying_mean_dia <- df$lying_diastolic_bp_av
  df_new$vitals_stand_1min_hr <- df$standing_hr_1m
  df_new$vitals_stand_1min_sys <- df$standing_systolic_bp_1m
  df_new$vitals_stand_1min_dia <- df$standing_diastolic_bp_1m
  df_new$vitals_stand_3min_hr <- df$standing_hr_3m
  df_new$vitals_stand_3min_sys <- df$standing_systolic_bp_3m
  df_new$vitals_stand_3min_dia <- df$standing_diastolic_bp_3m
  df_new$vitals_pwv_1 <- df$pwv
  df_new$vitals_pwv_2 <- df$pwv2
  df_new$vitals_pwv_mean <- df$pwv_mean
  df_new$vitals_pwv_3 <- df$pwv3
  df_new$vitals_pwv_median <- df$pwv_median
}

#Medical History Interview
if (do_medhx == "Yes") {
  df_new$medhx_date <- df$medical_history_date
  df_new$smoking_current <- df$smoked_recent
  df_new$smoking_100cigs <- df$smoked_lifetime
  df_new$smoking_totalyears <- df$smoked_years
  df_new$smoking_avgpackperday <- df$smoked_number
  df_new$smoking_agelastsmoke <- df$smoked_agequit
  df_new$medhx_mi <- df$cvd_heartattack
  df_new$medhx_mi_multi <- df$heartattack_more
  df_new$medhx_mi_age <- df$heartattack_age
  df_new$medhx_af <- df$cvd_atrialfibrillation
  df_new$medhx_cardiacsurgery <- df$cvd_heartsurgury
  df_new$medhx_bypass <- df$cvd_cardiacbypass
  df_new$medhx_pace_defib <- df$cvd_pacemaker
  df_new$medhx_chf <- df$cvd_congestiveheartfailure
  df_new$medhx_angina <- df$cvd_angina
  df_new$medhx_heartvalve <- df$cvd_heartvalve
  df_new$medhx_pad <- df$cvd_periopheralarterial
  df_new$medhx_other_heart <- df$cvd_other
  df_new$medhx_other_heart_detail <- df$cvd_other_other
  df_new$medhx_stroke <- df$cva_stroke
  df_new$medhx_stroke1_age <- df$stroke_first_age
  df_new$medhx_stroke1_type <- df$stroke_first_type
  df_new$medhx_stroke1_cog <- df$stroke_first_cognition
  df_new$medhx_stroke2 <- df$cva_stroke_second
  df_new$medhx_stroke2_age <- df$stroke_second_age
  df_new$medhx_stroke2_type <- df$stroke_second_type
  df_new$medhx_stroke2_cog <- df$stroke_second_cognition
  df_new$medhx_stroke3 <- df$cva_stroke_third
  df_new$medhx_stroke3_age <- df$stroke_third_age
  df_new$medhx_stroke3_type <- df$stroke_third_type
  df_new$medhx_stroke3_cog <- df$stroke_third_cognition
  df_new$medhx_seizure <- df$neuro_seizures
  df_new$medhx_tbi <- df$neuro_tbi
  df_new$medhx_tbi_age <- df$tbi_age_recent
  df_new$medhx_tbi_consc <- df$tbi_lossconsc
  df_new$medhx_tbi_consc_5min <- df$tbi_lossconsc_five
  df_new$medhx_migraine <- df$migraines
  df_new$medhx_other_neuro <- df$neuro_other
  df_new$medhx_other_neuro_detail <- df$neuro_other_y
  df_new$medhx_diabetes <- df$medical_diabetes
  df_new$medhx_diabetes_type <- df$diabetes_type
  df_new$medhx_diabetes_age <- df$diabetes_age
  df_new$medhx_htn <- df$medical_hypertension
  df_new$medhx_htn_age <- df$hypertension_age
  df_new$medhx_hyperchol <- df$medical_hypercholesterolemia
  df_new$medhx_hyperchol_age <- df$hypercholesterolemia_age
  df_new$medhx_b12 <- df$medical_btwelve
  df_new$medhx_thyroid <- df$medical_thyroid
  df_new$medhx_arthritis <- df$medical_arthritis
  df_new$medhx_arthritis_rheu <- df$arthritis_type___1
  df_new$medhx_arthritis_osteo <- df$arthritis_type___2
  df_new$medhx_arthritis_unknowntype <- df$arthritis_type___3
  df_new$medhx_arthritis_othertype <- df$arthritis_type___4
  df_new$medhx_arthritis_upper <- df$arthritis_regions___1
  df_new$medhx_arthritis_lower <- df$arthritis_regions___2
  df_new$medhx_arthritis_spine <- df$arthritis_regions___3
  df_new$medhx_arthritis_unknownarea <- df$arthritis_regions___4
  df_new$medhx_arthritis_otherarea <- df$arthritis_regions___5
  df_new$medhx_arthritis_otherarea_detail <- df$arthritis_regions_other
  df_new$medhx_urinaryincont <- df$medical_urinary_incont
  df_new$medhx_bowelincont <- df$medical_bowel_incont
  df_new$medhx_osa <- df$medical_apnoea
  df_new$medhx_osa_age <- df$apnoea_age
  df_new$medhx_rem_disorder <- df$medical_remsleepdisorder
  df_new$medhx_rem_disorder_actdreams <- df$medical_dreams
  df_new$medhx_insom_hyposom <- df$medical_insomnia
  df_new$medhx_sleepother <- df$medical_sleep_other
  df_new$medhx_sleepother_detail <- df$medical_sleep_other_y
  df_new$medhx_cancer <- df$medical_cancer
  df_new$medhx_cancer_detail <- df$medical_cancer_y
  df_new$medhx_ptsd <- df$psych_ptsd
  df_new$medhx_dep <- df$psych_depression
  df_new$medhx_anx <- df$psych_anxiety
  df_new$medhx_ocd <- df$psych_ocd
  df_new$medhx_dev_disorder <- df$psych_develop
  df_new$medhx_dev_disorder_detail <- df$psych_develop_disorders
  df_new$medhx_otherpsych <- df$psych_other
  df_new$medhx_otherpsych_detail <- df$psych_other_disorders
  df_new$medhx_covid <- df$covid_infected
  df_new$medhx_covid_labtest <- df$covid_swabtest
  df_new$medhx_covid_hosp <- df$covid_hospitalised
  df_new$medhx_covid_anosmia <- df$covid_neurological___1
  df_new$medhx_covid_headache <- df$covid_neurological___2
  df_new$medhx_covid_delirium <- df$covid_neurological___3
  df_new$medhx_covid_intubation <- df$covid_treatment___1
  df_new$medhx_covid_oxygen <- df$covid_treatment___2
  df_new$medhx_covid_sedation <- df$covid_treatment___3
  df_new$medhx_covid_othertx <- df$covid_treatment___4
  df_new$medhx_covid_othertx_detail <- df$covid_treatment_other
  df_new$medhx_covid_recovered <- df$covid_recovered
  df_new$medhx_covid_fatigue <- df$covid_fatigue
  df_new$famhx_stroke <- df$family_tia
  df_new$famhx_stroke_age55 <- df$family_tia_agefiftyfive
  df_new$famhx_stroke_genetic <- df$family_tia_geneticdom
  df_new$famhx_cogimpair <- df$family_cogimpairment
  df_new$famhx_dementia <- df$family_dementia
  df_new$famhx_dementia_mother <- df$family_dementia_who___1
  df_new$famhx_dementia_father <- df$family_dementia_who___2
  df_new$famhx_dementia_sibling <- df$family_dementia_who___3
  df_new$famhx_dementia_maternal <- df$family_dementia_who___4
  df_new$famhx_dementia_paternal <- df$family_dementia_who___5
  df_new$famhx_cvd <- df$family_cvd
  df_new$green_menopause <- df$menopause_period_stop
  df_new$green_psych <- df$greeneclim_psych
  df_new$green_somatic <- df$greeneclim_somatic
  df_new$green_vasomotor <- df$greeneclim_vaso
  df_new$green_total <- df$greeneclim_total
  df_new$medhx_notes <- df$mh_notes
  df_new$medhx_notes_detail <- df$mh_notes_y
}

#Medical History Interview Year 2
if (do_year2 == "Yes" & do_medhx == "Yes") {
  match_ids <- match(df_new$subject_id, df_year2$idno)

  df_new$year2_medhx_cogimpair <- df_year2$mh_follow_cogimpair_v2[match_ids]
  df_new$year2_medhx_cogimpair_details <- df_year2$mh_follow_cogimpair_y_v2[
    match_ids
  ]
  df_new$year2_medhx_cvd <- df_year2$mh_follow_cd_v2[match_ids]
  df_new$year2_medhx_myocard <- df_year2$mh_follow_mycardial_v2[match_ids]
  df_new$year2_medhx_stroke <- df_year2$mh_follow_stroke_v2[match_ids]
  df_new$year2_medhx_stroke_type <- df_year2$mh_follow_stroke_t_v2[match_ids]
  df_new$year2_medhx_tia <- df_year2$mh_follow_tia_v2[match_ids]
  df_new$year2_medhx_heartfail <- df_year2$mh_follow_hf_v2[match_ids]
  df_new$year2_medhx_atrialfib <- df_year2$mh_follow_af_v2[match_ids]
  df_new$year2_medhx_cvd_other <- df_year2$mh_follow_cvd_other_v2[match_ids]
  df_new$year2_medhx_cancer <- df_year2$mh_follow_cancer_v2[match_ids]
  df_new$year2_medhx_cancer_details <- df_year2$mh_follow_cancer_y_v2[match_ids]
  df_new$year2_medhx_sleep <- df_year2$mh_follow_sleep_v2[match_ids]
  df_new$year2_medhx_sleep_details <- df_year2$mh_follow_sleep_y_v2[match_ids]
  df_new$year2_medhx_psych <- df_year2$mh_follow_psych_v2[match_ids]
  df_new$year2_medhx_psych_details <- df_year2$mh_follow_psych_y_v2[match_ids]
  df_new$year2_medhx_hosp <- df_year2$mh_follow_hosp_v2[match_ids]
  df_new$year2_medhx_hosp_details <- df_year2$mh_follow_hosp_y_v2[match_ids]
  df_new$year2_medhx_notes <- df_year2$mh_follow_notes[match_ids]
}

#Medical History Interview Year 3
if (do_year3 == "Yes" & do_medhx == "Yes") {
  match_ids <- match(df_new$subject_id, df_year3$idno)

  df_new$year3_medhx_cogimpair <- df_year3$mh_follow_cogimpair_v2[match_ids]
  df_new$year3_medhx_cogimpair_details <- df_year3$mh_follow_cogimpair_y_v2[
    match_ids
  ]
  df_new$year3_medhx_cvd <- df_year3$mh_follow_cd_v2[match_ids]
  df_new$year3_medhx_myocard <- df_year3$mh_follow_mycardial_v2[match_ids]
  df_new$year3_medhx_stroke <- df_year3$mh_follow_stroke_v2[match_ids]
  df_new$year3_medhx_stroke_type <- df_year3$mh_follow_stroke_t_v2[match_ids]
  df_new$year3_medhx_tia <- df_year3$mh_follow_tia_v2[match_ids]
  df_new$year3_medhx_heartfail <- df_year3$mh_follow_hf_v2[match_ids]
  df_new$year3_medhx_atrialfib <- df_year3$mh_follow_af_v2[match_ids]
  df_new$year3_medhx_cvd_other <- df_year3$mh_follow_cvd_other_v2[match_ids]
  df_new$year3_medhx_cancer <- df_year3$mh_follow_cancer_v2[match_ids]
  df_new$year3_medhx_cancer_details <- df_year3$mh_follow_cancer_y_v2[match_ids]
  df_new$year3_medhx_sleep <- df_year3$mh_follow_sleep_v2[match_ids]
  df_new$year3_medhx_sleep_details <- df_year3$mh_follow_sleep_y_v2[match_ids]
  df_new$year3_medhx_psych <- df_year3$mh_follow_psych_v2[match_ids]
  df_new$year3_medhx_psych_details <- df_year3$mh_follow_psych_y_v2[match_ids]
  df_new$year3_medhx_hosp <- df_year3$mh_follow_hosp_v2[match_ids]
  df_new$year3_medhx_hosp_details <- df_year3$mh_follow_hosp_y_v2[match_ids]
  df_new$year3_medhx_notes <- df_year3$mh_follow_notes[match_ids]
}

#Medications
if (do_medications == "Yes") {
  df_new$repeat_meds <- df$redcap_repeat_instrument
  df_new$repeat_instance <- df$redcap_repeat_instance
  df_new$medication <- df$med
  df_new$medication_name <- df$med_name
  df_new$medication_dose <- df$med_strength
  df_new$medication_freq <- df$med_freq
  df_new$medication_dosenumber <- df$med_times
  df_new$medication_reason <- df$med_reason
  df_new$medication_reason_detail <- df$med_reas
  df_new$medication_prescribed <- df$med_pres
  df_new$medication_atc <- df$med_atc
}

#Neuropscyh
if (do_allneuropsych == "Yes" | do_cdr == "Yes") {
  df_new$neuropsych_date <- df$neuropsych_date
  df_new$cdr_memory <- df$cdr_memory
  df_new$cdr_orientation <- df$cdr_orient
  df_new$cdr_judgement <- df$cdr_judgment
  df_new$cdr_community <- df$cdr_community
  df_new$cdr_hobbies <- df$cdr_hobbies
  df_new$cdr_personal <- df$cdr_personal
  df_new$cdr_sobscore <- df$cdr_sob
  df_new$cdr_globalscore <- df$cdr_global
}

if (do_allneuropsych == "Yes" | do_mmse == "Yes") {
  df_new$neuropsych_date <- df$neuropsych_date
  df_new$mmse_total <- df$mmse_tot
  df_new$mmse_notes <- df$mmse_comment
  df_new$mmse_notes_detail <- df$mmse_comment_y
}

if (do_allneuropsych == "Yes" | do_sydbat == "Yes") {
  df_new$sydbat_date <- df$sydbat_date
  df_new$sydbat_naming <- df$sydbat_naming_total
  df_new$sydbat_repeat <- df$sydbat_repetition_total
  df_new$sydbat_comprehend <- df$sydbat_comprehension_total
  df_new$sydbat_semantic <- df$sydbat_semantic_total
}

if (do_allneuropsych == "Yes" | do_logicalmem == "Yes") {
  df_new$logicalmem_imm_time <- df$lmi_time
  df_new$logicalmem_imm_storyb <- df$lmi_b_total
  df_new$logicalmem_imm_storyc <- df$lmi_c_total
  df_new$logicalmem_imm_total <- df$lmi_total_raw
  df_new$logicalmem_delay_time <- df$lmii_time
  df_new$logicalmem_delay_mins <- df$lmii_timediff
  df_new$logicalmem_delay_storyb_cue <- df$lmii_bcue
  df_new$logicalmem_delay_storyb <- df$lmii_b_total
  df_new$logicalmem_delay_storyc_cue <- df$lmii_ccue
  df_new$logicalmem_delay_storyc <- df$lmii_c_total
  df_new$logicalmem_delay_total <- df$lmii_total_raw
}

if (do_allneuropsych == "Yes" | do_visualrepro == "Yes") {
  df_new$visualrepro1_time <- df$vri_time
  df_new$visualrepro1_total <- df$vri_total_raw
  df_new$visualrepro2_time <- df$vrii_time
  df_new$visualrepro2_mins <- df$vrii_timediff
  df_new$visualrepro2_total <- df$vrii_total_raw
}

if (do_allneuropsych == "Yes" | do_tmt == "Yes") {
  df_new$tmt_date <- df$tmt_date
  df_new$tmt_a_time <- df$tmt_a_total_sec
  df_new$tmt_a_error <- df$tmt_a_err
  df_new$tmt_b_time <- df$tmt_b_total_sec
  df_new$tmt_b_error <- df$tmt_b_err
}

if (do_allneuropsych == "Yes" | do_fab == "Yes") {
  df_new$fab_date <- df$fab_date
  df_new$fab_similarities <- df$fab_similarities
  df_new$fab_lexical <- df$fab_lexical_fluency
  df_new$fab_motor <- df$fab_motor
  df_new$fab_interference <- df$fab_conflicting_instrx
  df_new$fab_inhib <- df$fab_go_nogo
  df_new$fab_autonomy <- df$fab_prehension
  df_new$fab_total <- df$fab_total
}

if (do_allneuropsych == "Yes" | do_cowat == "Yes") {
  df_new$cowat_date <- df$cowat_date
  df_new$cowat_f_score <- df$cowat_f_total
  df_new$cowat_a_score <- df$cowat_a_total
  df_new$cowat_s_score <- df$cowat_s_total
  df_new$cowat_total <- df$cowat_fas_total
  df_new$cowat_animal <- df$cowat_animals_total
}

if (do_allneuropsych == "Yes" | do_hvot == "Yes") {
  df_new$hvot_date <- df$hvot_date
  df_new$hvot_total <- df$hvot_total
}

if (do_allneuropsych == "Yes" | do_tasit == "Yes") {
  df_new$tasit_date <- df$tasit_date
  df_new$tasit_sincere <- df$tasit_p2_sin
  df_new$tasit_sarcastic <- df$tasit_p2_sar
  df_new$tasit_total <- df$tasit_p2_total
}

if (do_allneuropsych == "Yes" | do_topf == "Yes") {
  sum_until_three_zeros <- function(row) {
    if (is.character(row)) {
      row <- ifelse(row == "Yes", 1, 0)
    }
    row[is.na(row)] <- 0
    r <- rle(row)
    zero_runs <- which(r$values == 0 & r$lengths >= 3)
    if (length(zero_runs) == 0) {
      return(sum(row))
    }
    end_pos <- cumsum(r$lengths)[zero_runs[1]] - r$lengths[zero_runs[1]] + 3
    sum(row[1:end_pos])
  }
  df_new$topf_date <- df$topf_date
  topf_mat <- df[, paste0("topf", 1:70)]
  df_new$topf_total_corrected <- apply(topf_mat, 1, sum_until_three_zeros)
}

if (do_allneuropsych == "Yes") {
  df_new$neuropsych_notes <- df$neuropsych_notes
  df_new$neuropsych_notes_details <- df$neuropsych_notes_y
}

#Dementia Status
if (do_dementiastatus == "Yes") {
  df_new$demreview_date <- df$ds_adju_date
  df_new$demreview_status <- df$ds_status
  df_new$demreview_onset <- df$ds_onset_date
  df_new$demreview_intactdate <- df$ds_cog_int_date
  df_new$demreview_notes <- df$ds_notes
}

#MRI
if (do_MRI == "Yes") {
  #df_new$mri_complete <- df$mri_successful
  df_new$mri_date <- df$mri_date
  df_new$mri_time <- df$mri_time
  #df_new$mri_fail_reason <- df$mri_successful_n
  #df_new$mri_fail_reason_other <- df$mri_successful_n_other
  #df_new$mri_notes <- df$mri_notes
  #df_new$mri_notes_detail <- df$mri_notes_y

  df_mri <- read.csv(
    file = MRI_input_file,
    colClasses = c("subject_id" = "character")
  )
  df_mri$subject_id <- gsub("sub-BACH", "", df_mri$subject_id) #removes "sub-BACH" at the start of IDs

  if (create_subset == "Yes") {
    if (subset_no == "149") {
      participant_list <- readLines(list_file_149)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_bio <- df_bio[df_bio$Sample.no %in% participant_list, ]
    }
    if (subset_no == "120") {
      participant_list <- readLines(list_file_120)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_bio <- df_bio[df_bio$Sample.no %in% participant_list, ]
    }
  }
  df_new <- merge(df_new, df_mri, all.x = TRUE)
}

#LP
if (do_LP == "Yes") {
  df_new$lp_complete <- df$lp_successful
  df_new$lp_date <- df$lp_date
  df_new$lp_time <- df$lp_time
  df_new$lp_fail_reason <- df$lp_successful_n
  df_new$lp_fail_other <- df$lp_successful_n_other
  df_new$lp_notes <- df$lp_notes
  df_new$lp_notes_detail <- df$lp_notes_y
}

#24h BP
if (do_24hBP == "Yes") {
  df_new$BP24h_start <- df$twenty4bp_start_datetime
  df_new$BP24h_end <- df$twenty4bp_end_datetime
  df_new$BP24h_records <- df$twenty4bp_overall_count
  df_new$BP24h_awake_sys_threshcount <- df$twenty4bp_awake_sys_ab_threshold
  df_new$BP24h_awake_dia_threshcount <- df$twenty4bp_asleep_sys_ab_threshold
  df_new$BP24h_awake_sys_load <- df$twenty4bp_awake_dia_ab_threshold
  df_new$BP24h_awake_dia_load <- df$twenty4bp_asleep_dia_ab_threshold
  df_new$BP24h_asleep_sys_threshcount <- df$twenty4bp_awake_sys_load
  df_new$BP24h_asleep_dia_threshcount <- df$twenty4bp_asleep_sys_load
  df_new$BP24h_asleep_sys_load <- df$twenty4bp_awake_dia_load
  df_new$BP24h_asleep_dia_load <- df$twenty4bp_asleep_dia_load
  df_new$BP24h_total_sys_load <- df$twenty4bp_total_sys_load
  df_new$BP24h_total_dia_load <- df$twenty4bp_total_dia_load
  df_new$BP24h_awake_sys_mean <- df$twenty4bp_awake_sys_mean
  df_new$BP24h_awake_sys_max <- df$twenty4bp_awake_sys_max
  df_new$BP24h_awake_sys_min <- df$twenty4bp_awake_sys_min
  df_new$BP24h_awake_sys_sd <- df$twenty4bp_awake_sys_sd
  df_new$BP24h_asleep_sys_mean <- df$twenty4bp_asleep_sys_mean
  df_new$BP24h_asleep_sys_max <- df$twenty4bp_asleep_sys_max
  df_new$BP24h_asleep_sys_min <- df$twenty4bp_asleep_sys_min
  df_new$BP24h_asleep_sys_sd <- df$twenty4bp_asleep_sys_sd
  df_new$BP24h_total_sys_mean <- df$twenty4bp_total_sys_mean
  df_new$BP24h_total_sys_max <- df$twenty4bp_total_sys_max
  df_new$BP24h_total_sys_min <- df$twenty4bp_total_sys_min
  df_new$BP24h_total_sys_sd <- df$twenty4bp_total_sys_sd
  df_new$BP24h_awake_dia_mean <- df$twenty4bp_awake_dia_mean
  df_new$BP24h_awake_dia_max <- df$twenty4bp_awake_dia_max
  df_new$BP24h_awake_dia_min <- df$twenty4bp_awake_dia_min
  df_new$BP24h_awake_dia_sd <- df$twenty4bp_awake_dia_sd
  df_new$BP24h_asleep_dia_mean <- df$twenty4bp_asleep_dia_mean
  df_new$BP24h_asleep_dia_max <- df$twenty4bp_asleep_dia_max
  df_new$BP24h_asleep_dia_min <- df$twenty4bp_asleep_dia_min
  df_new$BP24h_asleep_dia_sd <- df$twenty4bp_asleep_dia_sd
  df_new$BP24h_total_dia_mean <- df$twenty4bp_total_dia_mean
  df_new$BP24h_total_dia_max <- df$twenty4bp_total_dia_max
  df_new$BP24h_total_dia_min <- df$twenty4bp_total_dia_min
  df_new$BP24h_total_dia_sd <- df$twenty4bp_total_dia_sd
  df_new$BP24h_awake_hr_mean <- df$twenty4bp_awake_hr_mean
  df_new$BP24h_awake_hr_max <- df$twenty4bp_awake_hr_max
  df_new$BP24h_awake_hr_min <- df$twenty4bp_awake_hr_min
  df_new$BP24h_awake_hr_sd <- df$twenty4bp_awake_hr_sd
  df_new$BP24h_asleep_hr_mean <- df$twenty4bp_asleep_hr_mean
  df_new$BP24h_asleep_hr_max <- df$twenty4bp_asleep_hr_max
  df_new$BP24h_asleep_hr_min <- df$twenty4bp_asleep_hr_min
  df_new$BP24h_asleep_hr_sd <- df$twenty4bp_asleep_hr_sd
  df_new$BP24h_total_hr_mean <- df$twenty4bp_total_hr_mean
  df_new$BP24h_total_hr_max <- df$twenty4bp_total_hr_max
  df_new$BP24h_total_hr_min <- df$twenty4bp_total_hr_min
  df_new$BP24h_total_hr_sd <- df$twenty4bp_total_hr_sd
  df_new$BP24h_awake_map_mean <- df$twenty4bp_awake_map_mean
  df_new$BP24h_awake_map_max <- df$twenty4bp_awake_map_max
  df_new$BP24h_awake_map_min <- df$twenty4bp_awake_map_min
  df_new$BP24h_awake_map_sd <- df$twenty4bp_awake_map_sd
  df_new$BP24h_asleep_map_mean <- df$twenty4bp_asleep_map_mean
  df_new$BP24h_asleep_map_max <- df$twenty4bp_asleep_map_max
  df_new$BP24h_asleep_map_min <- df$twenty4bp_asleep_map_min
  df_new$BP24h_asleep_map_sd <- df$twenty4bp_asleep_map_sd
  df_new$BP24h_total_map_mean <- df$twenty4bp_total_map_mean
  df_new$BP24h_total_map_max <- df$twenty4bp_total_map_max
  df_new$BP24h_total_map_min <- df$twenty4bp_total_map_min
  df_new$BP24h_total_map_sd <- df$twenty4bp_total_map_sd
  df_new$BP24h_awake_pp_mean <- df$twenty4bp_awake_pulse_mean
  df_new$BP24h_awake_pp_max <- df$twenty4bp_awake_pulse_max
  df_new$BP24h_awake_pp_min <- df$twenty4bp_awake_pulse_min
  df_new$BP24h_awake_pp_sd <- df$twenty4bp_awake_pulse_sd
  df_new$BP24h_asleep_pp_mean <- df$twenty4bp_asleep_pulse_mean
  df_new$BP24h_asleep_pp_max <- df$twenty4bp_asleep_pulse_max
  df_new$BP24h_asleep_pp_min <- df$twenty4bp_asleep_pulse_min
  df_new$BP24h_asleep_pp_sd <- df$twenty4bp_asleep_pulse_sd
  df_new$BP24h_total_pp_mean <- df$twenty4bp_total_pulse_mean
  df_new$BP24h_total_pp_max <- df$twenty4bp_total_pulse_max
  df_new$BP24h_total_pp_min <- df$twenty4bp_total_pulse_min
  df_new$BP24h_total_pp_sd <- df$twenty4bp_total_pulse_sd
  df_new$BP24h_asleep_sys_dip_percent <- df$twenty4bp_sys_asleep_dip
  df_new$BP24h_asleep_dia_dip_percent <- df$twenty4bp_dia_asleep_dip
}

#PQSI
if (do_psqi_summary == "Yes" | do_psqi_full == "Yes") {
  df_new$psqi_date <- df$psqi_date
  df_new$psqi_total <- df$psqi_tot
}

if (do_psqi_full == "Yes") {
  df_new$psqi_q1_bedtime <- df$psqi_bed_tim
  df_new$psqi_q2_fallasleep <- df$psqi_f_aslp_m
  df_new$psqi_q3_gotup <- df$psqi_tim_wake
  df_new$psqi_q4_totalhrsleep <- df$psqi_tot_slp_h

  df_new$psqi_q5a_30m <- df$psqi_not30m
  df_new$psqi_q5b_midnight <- df$psqi_midnight
  df_new$psqi_q5c_bathroom <- df$psqi_bathroom
  df_new$psqi_q5d_breathe <- df$psqi_breathe
  df_new$psqi_q5e_cough <- df$psqi_cough
  df_new$psqi_q5f_cold <- df$psqi_cold
  df_new$psqi_q5g_hot <- df$psqi_hot
  df_new$psqi_q5h_dreams <- df$psqi_dreams
  df_new$psqi_q5i_pain <- df$psqi_pain
  df_new$psqi_q5j_other <- df$psqi_oth
  df_new$psqi_q5j_other_detail <- df$psqi_oth_sp

  df_new$psqi_q6_sleepmed <- df$psqi_slp_med
  df_new$psqi_q7_stayawake <- df$psqi_tro_awk
  df_new$psqi_q8_enthusi <- df$psqi_enthusi
  df_new$psqi_q9_quality <- df$psqi_slp_qual

  df_new$psqi_comp1 <- df$psqi_c1
  df_new$psqi_comp2 <- df$psqi_c2
  df_new$psqi_comp2_sub <- df$psqi_c2_sub
  df_new$psqi_comp3 <- df$psqi_c3
  df_new$psqi_comp4 <- df$psqi_c4
  df_new$psqi_comp4_sub <- df$psqi_c4_sub
  df_new$psqi_comp5 <- df$psqi_c5
  df_new$psqi_comp5_sub <- df$psqi_c5_sub
  df_new$psqi_comp6 <- df$psqi_c6
  df_new$psqi_comp7 <- df$psqi_c7
}

#ESS
if (do_ess == "Yes") {
  df_new$ess_date <- df$ess_date
  df_new$ess_total <- df$ess_tot
}

#ISI
if (do_isi == "Yes") {
  df_new$isi_date <- df$isi_date
  df_new$isi_cont_score <- df$isi_tot_co
  df_new$isi_cat_score <- df$isi_tot_ca
}

#Genomics
if (do_genomics == "Yes") {
  df_new$aqp4_allele1 <- df$aqp4_allele1
  df_new$aqp4_dosage1 <- df$aqp4_dosage1
  df_new$aqp4_allele2 <- df$aqp4_allele2
  df_new$aqp4_dosage2 <- df$aqp4_dosage2
  df_new$aqp4_allele3 <- df$aqp4_allele3
  df_new$aqp4_dosage3 <- df$aqp4_dosage3
  df_new$apoe_allele1 <- df$apoe_allele1
  df_new$apoe_dosage1 <- df$apoe_dosage1
  df_new$apoe_allele2 <- df$apoe_allele2
  df_new$apoe_dosage2 <- df$apoe_dosage2
}

#ACTI Full
if (do_acti_full == "Yes") {
  df_new$acti_night1_daytype <- df$acti_type1
  df_new$acti_night1_bedtime <- df$acti_slp1
  df_new$acti_night1_onset <- df$acti_sot1
  df_new$acti_night1_onset_latency <- df$acti_aslp1
  df_new$acti_night1_no_awakenings <- df$acti_awk1
  df_new$acti_night1_WASO <- df$acti_awkd1
  df_new$acti_night1_offset <- df$acti_fin1
  df_new$acti_night1_timeoutbed <- df$acti_outb1
  df_new$acti_night1_TST <- df$acti_tot_slp1
  df_new$acti_night1_SE <- df$acti_slp_eff1
  df_new$acti_night2_daytype <- df$acti_type2
  df_new$acti_night2_bedtime <- df$acti_slp2
  df_new$acti_night2_onset <- df$acti_sot2
  df_new$acti_night2_onset_latency <- df$acti_aslp2
  df_new$acti_night2_no_awakenings <- df$acti_awk2
  df_new$acti_night2_WASO <- df$acti_awkd2
  df_new$acti_night2_offset <- df$acti_fin2
  df_new$acti_night2_timeoutbed <- df$acti_outb2
  df_new$acti_night2_TST <- df$acti_tot_slp2
  df_new$acti_night2_SE <- df$acti_slp_eff2
  df_new$acti_night3_daytype <- df$acti_type3
  df_new$acti_night3_bedtime <- df$acti_slp3
  df_new$acti_night3_onset <- df$acti_sot3
  df_new$acti_night3_onset_latency <- df$acti_aslp3
  df_new$acti_night3_no_awakenings <- df$acti_awk3
  df_new$acti_night3_WASO <- df$acti_awkd3
  df_new$acti_night3_offset <- df$acti_fin3
  df_new$acti_night3_timeoutbed <- df$acti_outb3
  df_new$acti_night3_TST <- df$acti_tot_slp3
  df_new$acti_night3_SE <- df$acti_slp_eff3
  df_new$acti_night4_daytype <- df$acti_type4
  df_new$acti_night4_bedtime <- df$acti_slp4
  df_new$acti_night4_onset <- df$acti_sot4
  df_new$acti_night4_onset_latency <- df$acti_aslp4
  df_new$acti_night4_no_awakenings <- df$acti_awk4
  df_new$acti_night4_WASO <- df$acti_awkd4
  df_new$acti_night4_offset <- df$acti_fin4
  df_new$acti_night4_timeoutbed <- df$acti_outb4
  df_new$acti_night4_TST <- df$acti_tot_slp4
  df_new$acti_night4_SE <- df$acti_slp_eff4
  df_new$acti_night5_daytype <- df$acti_type5
  df_new$acti_night5_bedtime <- df$acti_slp5
  df_new$acti_night5_onset <- df$acti_sot5
  df_new$acti_night5_onset_latency <- df$acti_aslp5
  df_new$acti_night5_no_awakenings <- df$acti_awk5
  df_new$acti_night5_WASO <- df$acti_awkd5
  df_new$acti_night5_offset <- df$acti_fin5
  df_new$acti_night5_timeoutbed <- df$acti_outb5
  df_new$acti_night5_TST <- df$acti_tot_slp5
  df_new$acti_night5_SE <- df$acti_slp_eff5
  df_new$acti_night6_daytype <- df$acti_type6
  df_new$acti_night6_bedtime <- df$acti_slp6
  df_new$acti_night6_onset <- df$acti_sot6
  df_new$acti_night6_onset_latency <- df$acti_aslp6
  df_new$acti_night6_no_awakenings <- df$acti_awk6
  df_new$acti_night6_WASO <- df$acti_awkd6
  df_new$acti_night6_offset <- df$acti_fin6
  df_new$acti_night6_timeoutbed <- df$acti_outb6
  df_new$acti_night6_TST <- df$acti_tot_slp6
  df_new$acti_night6_SE <- df$acti_slp_eff6
  df_new$acti_night7_daytype <- df$acti_type7
  df_new$acti_night7_bedtime <- df$acti_slp7
  df_new$acti_night7_onset <- df$acti_sot7
  df_new$acti_night7_onset_latency <- df$acti_aslp7
  df_new$acti_night7_no_awakenings <- df$acti_awk7
  df_new$acti_night7_WASO <- df$acti_awkd7
  df_new$acti_night7_offset <- df$acti_fin7
  df_new$acti_night7_timeoutbed <- df$acti_outb7
  df_new$acti_night7_TST <- df$acti_tot_slp7
  df_new$acti_night7_SE <- df$acti_slp_eff7
  df_new$acti_night8_daytype <- df$acti_type8
  df_new$acti_night8_bedtime <- df$acti_slp8
  df_new$acti_night8_onset <- df$acti_sot8
  df_new$acti_night8_onset_latency <- df$acti_aslp8
  df_new$acti_night8_no_awakenings <- df$acti_awk8
  df_new$acti_night8_WASO <- df$acti_awkd8
  df_new$acti_night8_offset <- df$acti_fin8
  df_new$acti_night8_timeoutbed <- df$acti_outb8
  df_new$acti_night8_TST <- df$acti_tot_slp8
  df_new$acti_night8_SE <- df$acti_slp_eff8
  df_new$acti_night9_daytype <- df$acti_type9
  df_new$acti_night9_bedtime <- df$acti_slp9
  df_new$acti_night9_onset <- df$acti_sot9
  df_new$acti_night9_onset_latency <- df$acti_aslp9
  df_new$acti_night9_no_awakenings <- df$acti_awk9
  df_new$acti_night9_WASO <- df$acti_awkd9
  df_new$acti_night9_offset <- df$acti_fin9
  df_new$acti_night9_timeoutbed <- df$acti_outb9
  df_new$acti_night9_TST <- df$acti_tot_slp9
  df_new$acti_night9_SE <- df$acti_slp_eff9
  df_new$acti_night10_daytype <- df$acti_type10
  df_new$acti_night10_bedtime <- df$acti_slp10
  df_new$acti_night10_onset <- df$acti_sot10
  df_new$acti_night10_onset_latency <- df$acti_aslp10
  df_new$acti_night10_no_awakenings <- df$acti_awk10
  df_new$acti_night10_WASO <- df$acti_awkd10
  df_new$acti_night10_offset <- df$acti_fin10
  df_new$acti_night10_timeoutbed <- df$acti_outb10
  df_new$acti_night10_TST <- df$acti_tot_slp10
  df_new$acti_night10_SE <- df$acti_slp_eff10
  df_new$acti_night11_daytype <- df$acti_type11
  df_new$acti_night11_bedtime <- df$acti_slp11
  df_new$acti_night11_onset <- df$acti_sot11
  df_new$acti_night11_onset_latency <- df$acti_aslp11
  df_new$acti_night11_no_awakenings <- df$acti_awk11
  df_new$acti_night11_WASO <- df$acti_awkd11
  df_new$acti_night11_offset <- df$acti_fin11
  df_new$acti_night11_timeoutbed <- df$acti_outb11
  df_new$acti_night11_TST <- df$acti_tot_slp11
  df_new$acti_night11_SE <- df$acti_slp_eff11
  df_new$acti_night12_daytype <- df$acti_type12
  df_new$acti_night12_bedtime <- df$acti_slp12
  df_new$acti_night12_onset <- df$acti_sot12
  df_new$acti_night12_onset_latency <- df$acti_aslp12
  df_new$acti_night12_no_awakenings <- df$acti_awk12
  df_new$acti_night12_WASO <- df$acti_awkd12
  df_new$acti_night12_offset <- df$acti_fin12
  df_new$acti_night12_timeoutbed <- df$acti_outb12
  df_new$acti_night12_TST <- df$acti_tot_slp12
  df_new$acti_night12_SE <- df$acti_slp_eff12
  df_new$acti_night13_daytype <- df$acti_type13
  df_new$acti_night13_bedtime <- df$acti_slp13
  df_new$acti_night13_onset <- df$acti_sot13
  df_new$acti_night13_onset_latency <- df$acti_aslp13
  df_new$acti_night13_no_awakenings <- df$acti_awk13
  df_new$acti_night13_WASO <- df$acti_awkd13
  df_new$acti_night13_offset <- df$acti_fin13
  df_new$acti_night13_timeoutbed <- df$acti_outb13
  df_new$acti_night13_TST <- df$acti_tot_slp13
  df_new$acti_night13_SE <- df$acti_slp_eff13
  df_new$acti_night14_daytype <- df$acti_type14
  df_new$acti_night14_bedtime <- df$acti_slp14
  df_new$acti_night14_onset <- df$acti_sot14
  df_new$acti_night14_onset_latency <- df$acti_aslp14
  df_new$acti_night14_no_awakenings <- df$acti_awk14
  df_new$acti_night14_WASO <- df$acti_awkd14
  df_new$acti_night14_offset <- df$acti_fin14
  df_new$acti_night14_timeoutbed <- df$acti_outb14
  df_new$acti_night14_TST <- df$acti_tot_slp14
  df_new$acti_night14_SE <- df$acti_slp_eff14
  df_new$acti_nightsrecorded <- df$acti_watch_num #NEW
  df_new$acti_avg_bedtime <- df$acti_av_slp
  df_new$acti_avg_onset <- df$acti_av_sot
  df_new$acti_avg_onset_latency <- df$acti_av_aslp
  df_new$acti_total_awakenings <- df$acti_av_awk
  df_new$acti_total_WASO <- df$acti_av_awkd
  df_new$acti_avg_offset <- df$acti_av_fin
  df_new$acti_avg_timeoutbed <- df$acti_av_outb
  df_new$acti_avg_TST <- df$acti_av_tot_slp
  df_new$acti_avg_SE <- df$acti_av_slp_eff
  df_new$acti_weekday_avg_bedtime <- df$acti_wd_slp
  df_new$acti_weekday_avg_onset <- df$acti_wd_sot
  df_new$acti_weekday_avg_onset_latency <- df$acti_wd_aslp
  df_new$acti_weekday_total_no_awakenings <- df$acti_wd_awk
  df_new$acti_weekday_total_WASO <- df$acti_wd_awkd
  df_new$acti_weekday_avg_offset <- df$acti_wd_fin
  df_new$acti_weekday_avg_timeoutbed <- df$acti_wd_outb
  df_new$acti_weekday_avg_TST <- df$acti_wd_tot_slp
  df_new$acti_weekday_avg_SE <- df$acti_wd_slp_eff
  df_new$acti_weekend_avg_bedtime <- df$acti_we_slp
  df_new$acti_weekend_avg_onset <- df$acti_we_sot
  df_new$acti_weekend_avg_onset_latency <- df$acti_we_aslp
  df_new$acti_weekend_total_no_awakenings <- df$acti_we_awk
  df_new$acti_weekend_total_WASO <- df$acti_we_awkd
  df_new$acti_weekend_avg_offset <- df$acti_we_fin
  df_new$acti_weekend_avg_timeoutbed <- df$acti_we_outb
  df_new$acti_weekend_avg_TST <- df$acti_we_tot_slp
  df_new$acti_weekend_avg_SE <- df$acti_we_slp_eff
}

#ACTI Summary
if (do_acti_summary == "Yes") {
  df_new$acti_nightsrecorded <- df$acti_watch_num #NEW
  df_new$acti_avg_bedtime <- df$acti_av_slp
  df_new$acti_avg_onset <- df$acti_av_sot
  df_new$acti_avg_onset_latency <- df$acti_av_aslp
  df_new$acti_total_awakenings <- df$acti_av_awk
  df_new$acti_total_WASO <- df$acti_av_awkd
  df_new$acti_avg_offset <- df$acti_av_fin
  df_new$acti_avg_timeoutbed <- df$acti_av_outb
  df_new$acti_avg_TST <- df$acti_av_tot_slp
  df_new$acti_avg_SE <- df$acti_av_slp_eff
  df_new$acti_weekday_avg_bedtime <- df$acti_wd_slp
  df_new$acti_weekday_avg_onset <- df$acti_wd_sot
  df_new$acti_weekday_avg_onset_latency <- df$acti_wd_aslp
  df_new$acti_weekday_total_no_awakenings <- df$acti_wd_awk
  df_new$acti_weekday_total_WASO <- df$acti_wd_awkd
  df_new$acti_weekday_avg_offset <- df$acti_wd_fin
  df_new$acti_weekday_avg_timeoutbed <- df$acti_wd_outb
  df_new$acti_weekday_avg_TST <- df$acti_wd_tot_slp
  df_new$acti_weekday_avg_SE <- df$acti_wd_slp_eff
  df_new$acti_weekend_avg_bedtime <- df$acti_we_slp
  df_new$acti_weekend_avg_onset <- df$acti_we_sot
  df_new$acti_weekend_avg_onset_latency <- df$acti_we_aslp
  df_new$acti_weekend_total_no_awakenings <- df$acti_we_awk
  df_new$acti_weekend_total_WASO <- df$acti_we_awkd
  df_new$acti_weekend_avg_offset <- df$acti_we_fin
  df_new$acti_weekend_avg_timeoutbed <- df$acti_we_outb
  df_new$acti_weekend_avg_TST <- df$acti_we_tot_slp
  df_new$acti_weekend_avg_SE <- df$acti_we_slp_eff
}

if (do_psg_full == "Yes" | do_psg_summary == "Yes") {
  df_psg <- read.csv(
    file = raw_input_file_PSG,
    colClasses = c("idno" = "character")
  )

  if (create_subset == "Yes") {
    if (subset_no == "149") {
      participant_list <- readLines(list_file_149)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_psg <- df_psg[df_psg$idno %in% participant_list, ]
    }
    if (subset_no == "120") {
      participant_list <- readLines(list_file_120)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_psg <- df_psg[df_psg$idno %in% participant_list, ]
    }
  }
  df_psg <- subset(df_psg, idno != "10000") #remove test case
  match_ids <- match(df_new$subject_id, df_psg$idno)
}

#PSG Screening, etc.
if (do_psgscreening == "Yes") {
  df_new$psg_collected <- df$pp_status_sleep
  df_new$psg_ineligible_detail <- df$pp_status_sleep_in
  df_new$psg_date <- df$pp_date_sleep
  df_new$psg_acti_diff <- df$pp_time
  df_new$psg_screen_1week_date <- df$scr_1w_date
  df_new$psg_shiftwork <- df$scr_1w_shi_work
  df_new$psg_osa_treat <- df$scr_1w_treat_ap
}

if (do_sleephealth == "Yes") {
  df_new$psg_sleephealth_date <- df$sleephealth_date
  df_new$psg_sleephealth_site <- df$sleephealth_site_adm
  df_new$psg_sleephealth_total <- df$sleephealth_ess_tot
}

if (do_sleepmed == "Yes") {
  df_new$psg_medication_name <- df$m2w_med_name
  df_new$psg_medication_dose <- df$m2w_med_streng_pres
  df_new$psg_medication_freq_presc <- df$m2w_med_dose_pres
  df_new$psg_medication_dosenumber_presc <- df$m2w_med_freq_pres
  df_new$psg_medication_freq_taken <- df$m2w_med_dose_taken
  df_new$psg_medication_dosenumber_taken <- df$m2w_med_freq_taken
  df_new$psg_medication_atc <- df$m2w_med_atc
}

if (do_morningquest == "Yes") {
  df_new$psg_morningquest_date <- df$ms_date
  df_new$psg_morningquest_bed_time <- df$ms_bed_time
  df_new$psg_morningquest_lights_out <- df$ms_lights_out
  df_new$psg_morningquest_sleeponset <- df$ms_slp_time
  df_new$psg_morningquest_sleepoffset <- df$ms_wake_time
  df_new$psg_morningquest_lights_on <- df$ms_lights_on
  df_new$psg_morningquest_duration_hr <- df$ms_slp_dur_hr
  df_new$psg_morningquest_duration_minutes <- df$ms_slp_dur_min
  df_new$psg_morningquest_compare_normal_dur <- df$ms_compare_slp_dur
  df_new$psg_morningquest_sleep_depth <- df$ms_light_deep
  df_new$psg_morningquest_sleep_length <- df$ms_short_long
  df_new$psg_morningquest_sleep_restfulness <- df$ms_restless_restful
  df_new$psg_morningquest_compare_normal_qual <- df$ms_compare_slp
  df_new$psg_morningquest_difficulty_fall_asleep <- df$ms_diff_fall_aslp
  df_new$psg_morningquest_minutes_fall_asleep <- df$ms_min_fall_aslp
  df_new$psg_morningquest_compare_normal_fall_asleep <- df$ms_compare_fall_dur
  df_new$psg_morningquest_alcohol <- df$ms_alc
  df_new$psg_morningquest_alcohol_beer <- df$ms_alc_beer
  df_new$psg_morningquest_alcohol_wine <- df$ms_alc_wine
  df_new$psg_morningquest_alcohol_mixed <- df$ms_alc_mixed
  df_new$psg_morningquest_caffeine <- df$ms_caffeine
  df_new$psg_morningquest_caffiene_coffee <- df$ms_caff_coff
  df_new$psg_morningquest_caffiene_tea <- df$ms_caff_tea
  df_new$psg_morningquest_caffiene_soda <- df$ms_caff_soda
  df_new$psg_morningquest_smoke <- df$ms_smk
  df_new$psg_morningquest_smoke_freq <- df$ms_smk_freq
  df_new$psg_morningquest_discomfort <- df$ms_discomfort
  df_new$psg_morningquest_time <- df$ms_time_finish
}

###RE-FORMAT AND MERGE-----
##BASELINE ONLY
if (do_medications == "Yes" & do_sleepmed == "No") {
  df_new$repeat_meds <- ifelse(
    df_new$repeat_meds == "Medications",
    "med",
    ifelse(
      df_new$repeat_meds == "Sleep Medications In Last Two Weeks",
      "med_psg",
      ifelse(
        df_new$repeat_meds == "Sleep Other Mental Illness",
        "med_mental",
        NA
      )
    )
  )
  df_nopsg <- subset(
    df_new,
    (df_new$repeat_meds == "med") |
      (is.null(df_new$repeat_meds)) |
      (is.na(df_new$repeat_meds))
  )
  medsnum <- group_size(group_by(df_nopsg, subject_id))
  maxmeds <- (max(medsnum) - 1)
  df_med <- pivot_wider(
    df_nopsg,
    id_cols = subject_id,
    names_from = c(repeat_meds, repeat_instance),
    values_from = c(
      medication_name,
      medication_dose,
      medication_freq,
      medication_dosenumber,
      medication_reason,
      medication_reason_detail,
      medication_prescribed,
      medication_atc
    )
  )
  df_nomedc <- subset(df_new, (is.na(repeat_instance)))
  df_new <- merge(df_nomedc, df_med, all = TRUE)
  df_new <- dplyr::select(df_new, -c("repeat_instance", "repeat_meds", ))
  df_new <- dplyr::select(
    df_new,
    -c(
      "medication_name",
      "medication_dose",
      "medication_freq",
      "medication_dosenumber",
      "medication_reason",
      "medication_reason_detail",
      "medication_prescribed",
      "medication_atc"
    )
  )

  df_new <- dplyr::select(
    df_new,
    -c(
      "medication_name_NA_NA",
      "medication_dose_NA_NA",
      "medication_freq_NA_NA",
      "medication_dosenumber_NA_NA",
      "medication_reason_NA_NA",
      "medication_reason_detail_NA_NA",
      "medication_prescribed_NA_NA",
      "medication_atc_NA_NA"
    )
  )
}

if (do_medications == "Yes" & do_sleepmed == "Yes") {
  df_nomed <- subset(df_new, (is.na(repeat_instance)))
  df_new$repeat_meds <- ifelse(
    df_new$repeat_meds == "Medications",
    "med",
    ifelse(
      df_new$repeat_meds == "Sleep Medications In Last Two Weeks",
      "med_psg",
      ifelse(
        df_new$repeat_meds == "Sleep Other Mental Illness",
        "med_mental",
        NA
      )
    )
  )
  df_med <- subset(
    df_new,
    (df_new$repeat_meds == "med") |
      (is.null(df_new$repeat_meds)) |
      (is.na(df_new$repeat_meds))
  )
  medsnum <- group_size(group_by(df_med, subject_id))
  maxmeds <- (max(medsnum) - 1)
  df_med_psg <- subset(
    df_new,
    (df_new$repeat_meds == "med_psg") |
      (is.null(df_new$repeat_meds)) |
      (is.na(df_new$repeat_meds))
  )
  medsnum_psg <- group_size(group_by(df_med_psg, subject_id))
  maxmeds_psg <- (max(medsnum) - 1)

  df_med_wide <- pivot_wider(
    df_med,
    id_cols = subject_id,
    names_from = c(repeat_meds, repeat_instance),
    values_from = c(
      medication_name,
      medication_dose,
      medication_freq,
      medication_dosenumber,
      medication_reason,
      medication_reason_detail,
      medication_prescribed,
      medication_atc
    )
  )
  df_med_psg_wide <- pivot_wider(
    df_med_psg,
    id_cols = subject_id,
    names_from = c(repeat_meds, repeat_instance),
    values_from = c(
      psg_medication_name,
      psg_medication_dose,
      psg_medication_freq_presc,
      psg_medication_dosenumber_presc,
      psg_medication_freq_taken,
      psg_medication_dosenumber_taken,
      psg_medication_atc
    )
  )

  df_new <- merge(df_nomed, df_med_wide, all = TRUE)
  df_new <- merge(df_new, df_med_psg_wide, all = TRUE)
  df_new <- dplyr::select(df_new, -c("repeat_instance", "repeat_meds", ))
  df_new <- dplyr::select(
    df_new,
    -c(
      "medication_name",
      "medication_dose",
      "medication_freq",
      "medication_dosenumber",
      "medication_reason",
      "medication_reason_detail",
      "medication_prescribed",
      "medication_atc"
    )
  )
  df_new <- dplyr::select(
    df_new,
    -c(
      "psg_medication_name",
      "psg_medication_dose",
      "psg_medication_freq_presc",
      "psg_medication_dosenumber_presc",
      "psg_medication_freq_taken",
      "psg_medication_dosenumber_taken",
      "psg_medication_atc"
    )
  )

  df_new <- dplyr::select(
    df_new,
    -c(
      "medication_name_NA_NA",
      "medication_dose_NA_NA",
      "medication_freq_NA_NA",
      "medication_dosenumber_NA_NA",
      "medication_reason_NA_NA",
      "medication_reason_detail_NA_NA",
      "medication_prescribed_NA_NA",
      "medication_atc_NA_NA"
    )
  )
}

if (do_medications == "No" & do_sleepmed == "Yes") {
  df_nomed <- subset(df_new, (is.na(repeat_instance)))
  df_new$repeat_meds <- ifelse(
    df_new$repeat_meds == "Medications",
    "med",
    ifelse(
      df_new$repeat_meds == "Sleep Medications In Last Two Weeks",
      "med_psg",
      ifelse(
        df_new$repeat_meds == "Sleep Other Mental Illness",
        "med_mental",
        NA
      )
    )
  )
  df_med_psg <- subset(
    df_new,
    (df_new$repeat_meds == "med_psg") |
      (is.null(df_new$repeat_meds)) |
      (is.na(df_new$repeat_meds))
  )
  medsnum_psg <- group_size(group_by(df_med_psg, subject_id))
  maxmeds_psg <- (max(medsnum) - 1)

  df_med_psg_wide <- pivot_wider(
    df_med_psg,
    id_cols = subject_id,
    names_from = c(repeat_meds, repeat_instance),
    values_from = c(
      psg_medication_name,
      psg_medication_dose,
      psg_medication_freq_presc,
      psg_medication_dosenumber_presc,
      psg_medication_freq_taken,
      psg_medication_dosenumber_taken,
      psg_medication_atc
    )
  )
  df_new <- merge(df_nomed, df_med_psg_wide, all = TRUE)
  df_new <- dplyr::select(df_new, -c("repeat_instance", "repeat_meds", ))
  df_new <- dplyr::select(
    df_new,
    -c(
      "psg_medication_name",
      "psg_medication_dose",
      "psg_medication_freq_presc",
      "psg_medication_dosenumber_presc",
      "psg_medication_freq_taken",
      "psg_medication_dosenumber_taken",
      "psg_medication_atc"
    )
  )
}

if (do_medications == "No" & do_sleepmed == "No") {
  df_new <- df_new[match(unique(df_new$subject_id), df_new$subject_id), ]
}

#YEAR 2
if (do_medications == "Yes" & do_year2 == "Yes") {
  match_ids <- match(df_new$subject_id, df_year2$idno)
  df_new$year2_medchange <- df_year2$mh_follow_meds_v2[match_ids]

  df_new2 <- subset(df_year2, redcap_repeat_instrument == "Medication Follow")
  df_new2$redcap_repeat_instrument <- ifelse(
    df_new2$redcap_repeat_instrument == "Medication Follow",
    "med",
    NA
  )

  df_new2 <- dplyr::rename(df_new2, subject_id = idno)
  df_new2 <- dplyr::rename(df_new2, year2_medchange = mh_follow_meds_v2) #just one move back
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medchange_startstop = mh_follow_meds_startstop_v2
  )

  df_new2 <- dplyr::rename(df_new2, year2_medication_name = mh_follow_meds_n_v2)
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medication_dose = mh_follow_meds_str_v2
  )
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medication_freq = mh_follow_meds_freq_v2
  )
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medication_dosenumber = mh_follow_meds_times_v2
  )
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medication_reason = mh_follow_meds_why_v2
  )
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medication_reason_detail = mh_follow_meds_why_y_v2
  )
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medication_prescribed = mh_follow_meds_presc_v2
  )
  df_new2 <- dplyr::rename(
    df_new2,
    year2_medication_atc = mh_follow_meds_atc_v2
  )

  medsnum <- group_size(group_by(df_new2, subject_id))
  maxmeds <- (max(medsnum) - 1)
  df_med <- pivot_wider(
    df_new2,
    id_cols = subject_id,
    names_from = c(redcap_repeat_instrument, redcap_repeat_instance),
    values_from = c(
      year2_medication_name,
      year2_medication_dose,
      year2_medication_freq,
      year2_medication_dosenumber,
      year2_medication_reason,
      year2_medication_reason_detail,
      year2_medication_prescribed,
      year2_medication_atc
    )
  )
  df_med[] <- lapply(df_med, function(x) {
    x <- trimws(x)
    x[x == ""] <- NA
    x
  })

  df_new <- merge(df_new, df_med, all = TRUE)
}

#Year 3
if (do_medications == "Yes" & do_year3 == "Yes") {
  match_ids <- match(df_new$subject_id, df_year3$idno)
  df_new$year3_medchange <- df_year3$mh_follow_meds_v2[match_ids]

  df_new3 <- subset(df_year3, redcap_repeat_instrument == "Medication Follow")
  df_new3$redcap_repeat_instrument <- ifelse(
    df_new3$redcap_repeat_instrument == "Medication Follow",
    "med",
    NA
  )

  df_new3 <- dplyr::rename(df_new3, subject_id = idno)
  df_new3 <- dplyr::rename(df_new3, year3_medchange = mh_follow_meds_v2) #just one move back
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medchange_startstop = mh_follow_meds_startstop_v2
  )

  df_new3 <- dplyr::rename(df_new3, year3_medication_name = mh_follow_meds_n_v2)
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medication_dose = mh_follow_meds_str_v2
  )
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medication_freq = mh_follow_meds_freq_v2
  )
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medication_dosenumber = mh_follow_meds_times_v2
  )
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medication_reason = mh_follow_meds_why_v2
  )
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medication_reason_detail = mh_follow_meds_why_y_v2
  )
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medication_prescribed = mh_follow_meds_presc_v2
  )
  df_new3 <- dplyr::rename(
    df_new3,
    year3_medication_atc = mh_follow_meds_atc_v2
  )

  medsnum <- group_size(group_by(df_new3, subject_id))
  maxmeds <- (max(medsnum) - 1)
  df_med <- pivot_wider(
    df_new3,
    id_cols = subject_id,
    names_from = c(redcap_repeat_instrument, redcap_repeat_instance),
    values_from = c(
      year3_medication_name,
      year3_medication_dose,
      year3_medication_freq,
      year3_medication_dosenumber,
      year3_medication_reason,
      year3_medication_reason_detail,
      year3_medication_prescribed,
      year3_medication_atc
    )
  )
  df_med[] <- lapply(df_med, function(x) {
    x <- trimws(x)
    x[x == ""] <- NA
    x
  })

  df_new <- merge(df_new, df_med, all = TRUE)
}

#SES
if (do_SES == "Yes" & do_demographics == "Yes") {
  df_ses <- read.csv(file = ses_file)
  match_postcodes <- match(df_new$postcode_current, df_ses$POA_CODE_2016)
  df_new$ses_MB_CODE_2016 <- df_ses$MB_CODE_2016[match_postcodes]
  df_new$ses_decile_aus <- df_ses$decile_aus[match_postcodes]
  df_new$ses_percentile_aus <- df_ses$percentile_aus[match_postcodes]
  df_new$ses_decile_state <- df_ses$decile_state[match_postcodes]
  df_new$ses_percentile_aus <- df_ses$percentile_state[match_postcodes]
}

if (do_ARIA == "Yes" & do_SES == "Yes" & do_demographics == "Yes") {
  df_ARIA <- read.csv(file = aria_file)
  match_MBcode <- match(df_new$ses_MB_CODE_2016, df_ARIA$MB_CODE_2016)
  df_new$RAname <- df_ARIA$RA_NAME_2016[match_MBcode]
  df_new$RAstate <- df_ARIA$STATE_NAME_2016[match_MBcode]
  df_new$RAcategory <- ifelse(
    df_new$RAname == "Major Cities of Australia",
    "Urban",
    ifelse(
      df_new$RAname == "Inner Regional Australia",
      "Rural",
      ifelse(
        df_new$RAname == "Outer Regional Australia",
        "Rural",
        ifelse(
          df_new$RAname == "Remote Australia",
          "Rural",
          ifelse(df_new$RAname == "Very Remote Australia", "Rural", "NA")
        )
      )
    )
  )
}

if (do_biomarkers == "Yes") {
  df_bio <- read.csv(file = bio_file, colClasses = c("Sample.ID" = "character"))
  df_bio$Sample.ID <- sprintf("%04d", as.numeric(df_bio$Sample.ID))

  if (create_subset == "Yes") {
    if (subset_no == "149") {
      participant_list <- readLines(list_file_149)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_bio <- df_bio[df_bio$ID %in% participant_list, ]
    }
    if (subset_no == "120") {
      participant_list <- readLines(list_file_120)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_bio <- df_bio[df_bio$ID %in% participant_list, ]
    }
  }

  df_bio <- dplyr::select(df_bio, -c("SIMOA.ID"))
  df_bio <- dplyr::select(df_bio, -c("Notes"))
  df_bio <- rename(df_bio, subject_id = Sample.ID)
  df_bio <- rename(df_bio, sampletype = Sample.Type)
  df_bio <- rename(df_bio, ab40_mean_conc = AB40_mean_conc)
  df_bio <- rename(df_bio, ab40_cv = AB40_cv)
  df_bio <- rename(df_bio, ab42_mean_conc = AB42_mean_conc)
  df_bio <- rename(df_bio, ab42_cv = AB42_cv)
  df_bio <- rename(df_bio, gfap_mean_conc = GFAP_mean_conc)
  df_bio <- rename(df_bio, gfap_cv = GFAP_cv)
  df_bio <- rename(df_bio, nfl_mean_conc = NfL_mean_conc)
  df_bio <- rename(df_bio, nfl_cv = NfL_cv)
  df_bio <- rename(df_bio, ptau181_mean_conc = pTau181_mean_conc)
  df_bio <- rename(df_bio, ptau181_cv = pTau181_cv)
  df_bio <- rename(df_bio, ptau217_mean_conc = pTau217_mean_conc)
  df_bio <- rename(df_bio, ptau217_cv = pTau217_cv)

  df_bio$sampletype <- ifelse(
    df_bio$sampletype == "Plasma",
    "plasma",
    ifelse(
      df_bio$sampletype == "CSF",
      "csf",
      ifelse(df_bio$sampletype == "DBS", "dbs", NA)
    )
  )

  df_bio_wide <- pivot_wider(
    df_bio,
    id_cols = subject_id,
    names_from = c(sampletype),
    values_from = c(
      ab40_mean_conc,
      ab40_cv,
      ab42_mean_conc,
      ab42_cv,
      gfap_mean_conc,
      gfap_cv,
      nfl_mean_conc,
      nfl_cv,
      ptau181_mean_conc,
      ptau181_cv,
      ptau217_mean_conc,
      ptau217_cv
    )
  )
  df_new <- merge(df_new, df_bio_wide, all = TRUE)
}

if (do_psg_full == "Yes" | do_psg_summary == "Yes") {
  df_psg <- read.csv(
    file = raw_input_file_PSG,
    colClasses = c("idno" = "character")
  )

  if (create_subset == "Yes") {
    if (subset_no == "149") {
      participant_list <- readLines(list_file_149)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_psg <- df_psg[df_psg$idno %in% participant_list, ]
    }
    if (subset_no == "120") {
      participant_list <- readLines(list_file_120)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_psg <- df_psg[df_psg$idno %in% participant_list, ]
    }
  }

  df_psg <- subset(df_psg, idno != "10000") #remove test case
  match_ids <- match(df_new$subject_id, df_psg$idno)
}

if (do_psg_full == "Yes") {
  df_new$psg_location <- df_psg$psg_locationsetup[match_ids]
  df_new$psg_ess <- df_psg$psg_ess[match_ids]
  df_new$psg_height <- df_psg$psg_height[match_ids]
  df_new$psg_weight <- df_psg$psg_weight[match_ids]
  df_new$psg_bmi <- df_psg$psg_bmi[match_ids]
  df_new$psg_neck_circ <- df_psg$psg_neck_circ[match_ids]
  df_new$psg_hips_circ <- df_psg$psg_hips_circ[match_ids]
  df_new$psg_waist_circ <- df_psg$psg_waist_circ[match_ids]
  df_new$psg_lights_out <- df_psg$psg_lights_out[match_ids]
  df_new$psg_lights_on <- df_psg$psg_lights_on[match_ids]
  df_new$psg_time_avail_sleep <- df_psg$psg_time_avail_sleep[match_ids]
  df_new$psg_sleep_period <- df_psg$psg_tot_sleep_per[match_ids]
  df_new$psg_report_period <- df_psg$psg_tot_report_time[match_ids]
  df_new$psg_sol <- df_psg$psg_sleep_lat[match_ids]
  df_new$psg_sol_rem <- df_psg$psg_rem_sleep_lat[match_ids]
  df_new$psg_tst <- df_psg$psg_tot_sleep_time[match_ids]
  df_new$psg_waso <- df_psg$psg_waso[match_ids]
  df_new$psg_se <- df_psg$psg_sleep_effic[match_ids]
  df_new$psg_nrem_dur <- df_psg$psg_nrem_sleep_dur[match_ids]
  df_new$psg_n1_dur <- df_psg$psg_n1_sleep_dur[match_ids]
  df_new$psg_n2_dur <- df_psg$psg_n2_sleep_dur[match_ids]
  df_new$psg_n3_dur <- df_psg$psg_n3_sleep_dur[match_ids]
  df_new$psg_rem_dur <- df_psg$psg_rem_sleep_dur[match_ids]
  df_new$psg_nrem_per <- df_psg$psg_nrem_sleep_per[match_ids]
  df_new$psg_n1_per <- df_psg$psg_n1_sleep_per[match_ids]
  df_new$psg_n2_per <- df_psg$psg_n2_sleep_per[match_ids]
  df_new$psg_n3_per <- df_psg$psg_n3_sleep_per[match_ids]
  df_new$psg_rem_per <- df_psg$psg_rem_sleep_per[match_ids]
  df_new$psg_arous_spont_nrem <- df_psg$psg_nrem_aro_spont[match_ids]
  df_new$psg_arous_spont_rem <- df_psg$psg_rem_aro_spont[match_ids]
  df_new$psg_arous_spont_total <- df_psg$psg_overall_aro_spont[match_ids]
  df_new$psg_arous_res_nrem <- df_psg$psg_nrem_aro_res[match_ids]
  df_new$psg_arous_res_rem <- df_psg$psg_rem_aro_res[match_ids]
  df_new$psg_arous_res_total <- df_psg$psg_overall_aro_res[match_ids]
  df_new$psg_arous_plmindex_nrem <- df_psg$psg_nrem_aro_limb[match_ids]
  df_new$psg_arous_plmindex_rem <- df_psg$psg_rem_aro_limb[match_ids]
  df_new$psg_arous_plmindex_total <- df_psg$psg_overall_aro_limb[match_ids]
  df_new$psg_arous_total_nrem <- df_psg$psg_nrem_aro_tot[match_ids]
  df_new$psg_arous_total_rem <- df_psg$psg_rem_aro_tot[match_ids]
  df_new$psg_arous_total_all <- df_psg$psg_overall_aro_tot[match_ids]
  df_new$psg_pos_supine_dur_nrem <- df_psg$psg_nrem_res_slpsup[match_ids]
  df_new$psg_pos_other_dur_nrem <- df_psg$psg_nrem_res_slpoth[match_ids]
  df_new$psg_pos_total_dur_nrem <- df_psg$psg_nrem_res_slpall[match_ids]
  df_new$psg_spo2_sup_avg_nrem <- df_psg$psg_nrem_av_spo2sup[match_ids]
  df_new$psg_spo2_other_avg_nrem <- df_psg$psg_nrem_av_spo2oth[match_ids]
  df_new$psg_spo2_total_avg_nrem <- df_psg$psg_nrem_av_spo2all[match_ids]
  df_new$psg_spo2_sup_nadir_per_nrem <- df_psg$psg_nrem_nad_spo2sup[match_ids]
  df_new$psg_spo2_other_nadir_per_nrem <- df_psg$psg_nrem_nad_spo2oth[match_ids]
  df_new$psg_spo2_total_nadir_per_nrem <- df_psg$psg_nrem_nad_spo2all[match_ids]
  df_new$psg_central_event_sup_nrem <- df_psg$psg_nrem_cent_evsup[match_ids]
  df_new$psg_central_event_other_nrem <- df_psg$psg_nrem_cent_evoth[match_ids]
  df_new$psg_central_event_total_nrem <- df_psg$psg_nrem_cent_evall[match_ids]
  df_new$psg_obstruct_event_sup_nrem <- df_psg$psg_nrem_obst_evsup[match_ids]
  df_new$psg_obstruct_event_other_nrem <- df_psg$psg_nrem_obst_evoth[match_ids]
  df_new$psg_obstruct_event_total_nrem <- df_psg$psg_nrem_obst_evall[match_ids]
  df_new$psg_mix_event_sup_nrem <- df_psg$psg_nrem_mix_evsup[match_ids]
  df_new$psg_mix_event_other_nrem <- df_psg$psg_nrem_mix_evoth[match_ids]
  df_new$psg_mix_event_total_nrem <- df_psg$psg_nrem_mix_evall[match_ids]
  df_new$psg_hypop_event_sup_nrem <- df_psg$psg_nrem_hypop_evsup[match_ids]
  df_new$psg_hypop_event_other_nrem <- df_psg$psg_nrem_hypop_evoth[match_ids]
  df_new$psg_hypop_event_total_nrem <- df_psg$psg_nrem_hypop_evall[match_ids]
  df_new$psg_rera_sup_nrem <- df_psg$psg_nrem_rera_evsup[match_ids]
  df_new$psg_rera_other_nrem <- df_psg$psg_nrem_rera_evoth[match_ids]
  df_new$psg_rera_total_nrem <- df_psg$psg_nrem_rera_evall[match_ids]
  df_new$psg_rdi_sup_nrem <- df_psg$psg_nrem_rds_sup[match_ids]
  df_new$psg_rdi_other_nrem <- df_psg$psg_nrem_rdi_oth[match_ids]
  df_new$psg_rdi_total_nrem <- df_psg$psg_nrem_rdi_all[match_ids]
  df_new$psg_ahi_sup_nrem <- df_psg$psg_nrem_ahi_sup[match_ids]
  df_new$psg_ahi_other_nrem <- df_psg$psg_nrem_ahi_oth[match_ids]
  df_new$psg_ahi_total_nrem <- df_psg$psg_nrem_ahi_all[match_ids]
  df_new$psg_pos_supine_dur_rem <- df_psg$psg_rem_res_slpsup[match_ids]
  df_new$psg_pos_other_dur_rem <- df_psg$psg_rem_res_slpoth[match_ids]
  df_new$psg_pos_total_dur_rem <- df_psg$psg_rem_res_slpall[match_ids]
  df_new$psg_spo2_sup_avg_rem <- df_psg$psg_rem_av_spo2sup[match_ids]
  df_new$psg_spo2_other_avg_rem <- df_psg$psg_rem_av_spo2oth[match_ids]
  df_new$psg_spo2_total_avg_rem <- df_psg$psg_rem_av_spo2all[match_ids]
  df_new$psg_spo2_sup_nadir_per_rem <- df_psg$psg_rem_nad_spo2sup[match_ids]
  df_new$psg_spo2_other_nadir_per_rem <- df_psg$psg_rem_nad_spo2oth[match_ids]
  df_new$psg_spo2_total_nadir_per_rem <- df_psg$psg_rem_nad_spo2all[match_ids]
  df_new$psg_central_event_sup_rem <- df_psg$psg_rem_cent_evsup[match_ids]
  df_new$psg_central_event_other_rem <- df_psg$psg_rem_cent_evoth[match_ids]
  df_new$psg_central_event_total_rem <- df_psg$psg_rem_cent_evall[match_ids]
  df_new$psg_obstruct_event_sup_rem <- df_psg$psg_rem_obst_evsup[match_ids]
  df_new$psg_obstruct_event_other_rem <- df_psg$psg_rem_obst_evoth[match_ids]
  df_new$psg_obstruct_event_total_rem <- df_psg$psg_rem_obst_evall[match_ids]
  df_new$psg_mix_event_sup_rem <- df_psg$psg_rem_mix_evsup[match_ids]
  df_new$psg_mix_event_other_rem <- df_psg$psg_rem_mix_evoth[match_ids]
  df_new$psg_mix_event_total_rem <- df_psg$psg_rem_mix_evall[match_ids]
  df_new$psg_hypop_event_sup_rem <- df_psg$psg_rem_hypop_evsup[match_ids]
  df_new$psg_hypop_event_other_rem <- df_psg$psg_rem_hypop_evoth[match_ids]
  df_new$psg_hypop_event_total_rem <- df_psg$psg_rem_hypop_evall[match_ids]
  df_new$psg_rera_sup_rem <- df_psg$psg_rem_rera_evsup[match_ids]
  df_new$psg_rera_other_rem <- df_psg$psg_rem_rera_evoth[match_ids]
  df_new$psg_rera_total_rem <- df_psg$psg_rem_rera_evall[match_ids]
  df_new$psg_rdi_sup_rem <- df_psg$psg_rem_rdi_sup[match_ids]
  df_new$psg_rdi_other_rem <- df_psg$psg_rem_rdi_oth[match_ids]
  df_new$psg_rdi_total_rem <- df_psg$psg_rem_rdi_all[match_ids]
  df_new$psg_ahi_sup_rem <- df_psg$psg_rem_ahi_sup[match_ids]
  df_new$psg_ahi_other_rem <- df_psg$psg_rem_ahi_oth[match_ids]
  df_new$psg_ahi_total_rem <- df_psg$psg_rem_ahi_all[match_ids]
  df_new$psg_pos_supine_dur_all <- df_psg$psg_overall_res_slpsup[match_ids]
  df_new$psg_pos_other_dur_all <- df_psg$psg_overall_res_slpoth[match_ids]
  df_new$psg_pos_total_dur_all <- df_psg$psg_overall_res_slpall[match_ids]
  df_new$psg_spo2_sup_avg_all <- df_psg$psg_overall_av_spo2sup[match_ids]
  df_new$psg_spo2_other_avg_all <- df_psg$psg_overall_av_spo2oth[match_ids]
  df_new$psg_spo2_total_avg_all <- df_psg$psg_overall_av_spo2all[match_ids]
  df_new$psg_spo2_sup_nadir_per_all <- df_psg$psg_overall_nad_spo2sup[match_ids]
  df_new$psg_spo2_other_nadir_per_all <- df_psg$psg_overall_nad_spo2oth[
    match_ids
  ]
  df_new$psg_spo2_total_nadir_per_all <- df_psg$psg_overall_nad_spo2all[
    match_ids
  ]
  df_new$psg_central_event_sup_all <- df_psg$psg_overall_cent_evsup[match_ids]
  df_new$psg_central_event_other_all <- df_psg$psg_overall_cent_evoth[match_ids]
  df_new$psg_central_event_total_all <- df_psg$psg_overall_cent_evall[match_ids]
  df_new$psg_obstruct_event_sup_all <- df_psg$psg_overall_obst_evsup[match_ids]
  df_new$psg_obstruct_event_other_all <- df_psg$psg_overall_obst_evoth[
    match_ids
  ]
  df_new$psg_obstruct_event_total_all <- df_psg$psg_overall_obst_evall[
    match_ids
  ]
  df_new$psg_mix_event_sup_all <- df_psg$psg_overall_mix_evsup[match_ids]
  df_new$psg_mix_event_other_all <- df_psg$psg_overall_mix_evoth[match_ids]
  df_new$psg_mix_event_total_all <- df_psg$psg_overall_mix_evall[match_ids]
  df_new$psg_hypop_event_sup_all <- df_psg$psg_overall_hypop_evsup[match_ids]
  df_new$psg_hypop_event_other_all <- df_psg$psg_overall_hypop_evoth[match_ids]
  df_new$psg_hypop_event_total_all <- df_psg$psg_overall_hypop_evall[match_ids]
  df_new$psg_rera_sup_all <- df_psg$psg_overall_rera_evsup[match_ids]
  df_new$psg_rera_other_all <- df_psg$psg_overall_rera_evoth[match_ids]
  df_new$psg_rera_total_all <- df_psg$psg_overall_rera_evall[match_ids]
  df_new$psg_rdi_sup_all <- df_psg$psg_overall_rdi_sup[match_ids]
  df_new$psg_rdi_other_all <- df_psg$psg_overall_rdi_oth[match_ids]
  df_new$psg_rdi_total_all <- df_psg$psg_overall_rdi_all[match_ids]
  df_new$psg_ahi_sup_all <- df_psg$psg_overall_ahi_sup[match_ids]
  df_new$psg_ahi_other_all <- df_psg$psg_overall_ahi_oth[match_ids]
  df_new$psg_ahi_total_all <- df_psg$psg_overall_ahi_all[match_ids]
  df_new$psg_spo2_wake_avg <- df_psg$psg_av_spo2_wake[match_ids]
  df_new$psg_spo2_desat_avg <- df_psg$psg_av_spo2_desat[match_ids]
  df_new$psg_spo2_less89per <- df_psg$psg_slp_spo2_less89per[match_ids]
  df_new$psg_spo2_less85per <- df_psg$psg_slp_spo2_less85per[match_ids]
  df_new$psg_odi_3per <- df_psg$psg_odi3_per[match_ids]
  df_new$psg_odi_4per <- df_psg$psg_odi4_per[match_ids]
  df_new$psg_apn_hypop_dur_mean <- df_psg$psg_av_apn_hypop_dur[match_ids]
  df_new$psg_hypop_longest <- df_psg$psg_longest_hypop[match_ids]
  df_new$psg_apn_longest <- df_psg$psg_longest_apn[match_ids]
  df_new$psg_plmindex_nrem <- df_psg$psg_nrem_plmi[match_ids]
  df_new$psg_plmindex_rem <- df_psg$psg_rem_plmi[match_ids]
  df_new$psg_plmindex_all <- df_psg$psg_total_plmi[match_ids]
  df_new$psg_hr_avg <- df_psg$psg_av_slp_hr[match_ids]
  df_new$psg_hr_highest <- df_psg$psg_highest_sleep_hr[match_ids]
  df_new$psg_rswa <- df_psg$psg_rswa[match_ids]
  df_new$psg_rswa <- ifelse(
    (grepl("yes", df_new$psg_rswa, ignore.case = TRUE)) &
      (catvariables == "named"),
    "Yes",
    ifelse(
      (grepl("no", df_new$psg_rswa, ignore.case = TRUE)) &
        (catvariables == "named"),
      "No",
      ifelse(
        (grepl("yes", df_new$psg_rswa, ignore.case = TRUE)) &
          (catvariables == "numbered"),
        1,
        ifelse(
          (grepl("no", df_new$psg_rswa, ignore.case = TRUE)) &
            (catvariables == "numbered"),
          0,
          NA
        )
      )
    )
  )
}

if (do_psg_summary == "Yes") {
  df_new$psg_location <- df_psg$psg_locationsetup[match_ids]
  df_new$psg_ess <- df_psg$psg_ess[match_ids]
  df_new$psg_height <- df_psg$psg_height[match_ids]
  df_new$psg_weight <- df_psg$psg_weight[match_ids]
  df_new$psg_bmi <- df_psg$psg_bmi[match_ids]
  df_new$psg_neck_circ <- df_psg$psg_neck_circ[match_ids]
  df_new$psg_hips_circ <- df_psg$psg_hips_circ[match_ids]
  df_new$psg_waist_circ <- df_psg$psg_waist_circ[match_ids]
  df_new$psg_lights_out <- df_psg$psg_lights_out[match_ids]
  df_new$psg_lights_on <- df_psg$psg_lights_on[match_ids]
  df_new$psg_time_avail_sleep <- df_psg$psg_time_avail_sleep[match_ids]
  df_new$psg_sleep_period <- df_psg$psg_tot_sleep_per[match_ids]
  df_new$psg_report_period <- df_psg$psg_tot_report_time[match_ids]
  df_new$psg_sol <- df_psg$psg_sleep_lat[match_ids]
  df_new$psg_sol_rem <- df_psg$psg_rem_sleep_lat[match_ids]
  df_new$psg_tst <- df_psg$psg_tot_sleep_time[match_ids]
  df_new$psg_waso <- df_psg$psg_waso[match_ids]
  df_new$psg_se <- df_psg$psg_sleep_effic[match_ids]
  df_new$psg_nrem_dur <- df_psg$psg_nrem_sleep_dur[match_ids]
  df_new$psg_n1_dur <- df_psg$psg_n1_sleep_dur[match_ids]
  df_new$psg_n2_dur <- df_psg$psg_n2_sleep_dur[match_ids]
  df_new$psg_n3_dur <- df_psg$psg_n3_sleep_dur[match_ids]
  df_new$psg_rem_dur <- df_psg$psg_rem_sleep_dur[match_ids]
  df_new$psg_nrem_per <- df_psg$psg_nrem_sleep_per[match_ids]
  df_new$psg_n1_per <- df_psg$psg_n1_sleep_per[match_ids]
  df_new$psg_n2_per <- df_psg$psg_n2_sleep_per[match_ids]
  df_new$psg_n3_per <- df_psg$psg_n3_sleep_per[match_ids]
  df_new$psg_rem_per <- df_psg$psg_rem_sleep_per[match_ids]
  df_new$psg_arous_spont_nrem <- df_psg$psg_nrem_aro_spont[match_ids]
  df_new$psg_arous_spont_rem <- df_psg$psg_rem_aro_spont[match_ids]
  df_new$psg_arous_spont_total <- df_psg$psg_overall_aro_spont[match_ids]
  df_new$psg_arous_res_nrem <- df_psg$psg_nrem_aro_res[match_ids]
  df_new$psg_arous_res_rem <- df_psg$psg_rem_aro_res[match_ids]
  df_new$psg_arous_res_total <- df_psg$psg_overall_aro_res[match_ids]
  df_new$psg_arous_plmindex_nrem <- df_psg$psg_nrem_aro_limb[match_ids]
  df_new$psg_arous_plmindex_rem <- df_psg$psg_rem_aro_limb[match_ids]
  df_new$psg_arous_plmindex_total <- df_psg$psg_overall_aro_limb[match_ids]
  df_new$psg_arous_total_nrem <- df_psg$psg_nrem_aro_tot[match_ids]
  df_new$psg_arous_total_rem <- df_psg$psg_rem_aro_tot[match_ids]
  df_new$psg_arous_total_all <- df_psg$psg_overall_aro_tot[match_ids]
  df_new$psg_pos_supine_dur_nrem <- df_psg$psg_nrem_res_slpsup[match_ids]
  df_new$psg_pos_other_dur_nrem <- df_psg$psg_nrem_res_slpoth[match_ids]
  df_new$psg_pos_total_dur_nrem <- df_psg$psg_nrem_res_slpall[match_ids]
  df_new$psg_spo2_sup_avg_nrem <- df_psg$psg_nrem_av_spo2sup[match_ids]
  df_new$psg_spo2_other_avg_nrem <- df_psg$psg_nrem_av_spo2oth[match_ids]
  df_new$psg_spo2_total_avg_nrem <- df_psg$psg_nrem_av_spo2all[match_ids]
  df_new$psg_spo2_sup_nadir_per_nrem <- df_psg$psg_nrem_nad_spo2sup[match_ids]
  df_new$psg_spo2_other_nadir_per_nrem <- df_psg$psg_nrem_nad_spo2oth[match_ids]
  df_new$psg_spo2_total_nadir_per_nrem <- df_psg$psg_nrem_nad_spo2all[match_ids]
  df_new$psg_central_event_sup_nrem <- df_psg$psg_nrem_cent_evsup[match_ids]
  df_new$psg_central_event_other_nrem <- df_psg$psg_nrem_cent_evoth[match_ids]
  df_new$psg_central_event_total_nrem <- df_psg$psg_nrem_cent_evall[match_ids]
  df_new$psg_obstruct_event_sup_nrem <- df_psg$psg_nrem_obst_evsup[match_ids]
  df_new$psg_obstruct_event_other_nrem <- df_psg$psg_nrem_obst_evoth[match_ids]
  df_new$psg_obstruct_event_total_nrem <- df_psg$psg_nrem_obst_evall[match_ids]
  df_new$psg_mix_event_sup_nrem <- df_psg$psg_nrem_mix_evsup[match_ids]
  df_new$psg_mix_event_other_nrem <- df_psg$psg_nrem_mix_evoth[match_ids]
  df_new$psg_mix_event_total_nrem <- df_psg$psg_nrem_mix_evall[match_ids]
  df_new$psg_hypop_event_sup_nrem <- df_psg$psg_nrem_hypop_evsup[match_ids]
  df_new$psg_hypop_event_other_nrem <- df_psg$psg_nrem_hypop_evoth[match_ids]
  df_new$psg_hypop_event_total_nrem <- df_psg$psg_nrem_hypop_evall[match_ids]
  df_new$psg_rera_sup_nrem <- df_psg$psg_nrem_rera_evsup[match_ids]
  df_new$psg_rera_other_nrem <- df_psg$psg_nrem_rera_evoth[match_ids]
  df_new$psg_rera_total_nrem <- df_psg$psg_nrem_rera_evall[match_ids]
  df_new$psg_rdi_sup_nrem <- df_psg$psg_nrem_rds_sup[match_ids]
  df_new$psg_rdi_other_nrem <- df_psg$psg_nrem_rdi_oth[match_ids]
  df_new$psg_rdi_total_nrem <- df_psg$psg_nrem_rdi_all[match_ids]
  df_new$psg_ahi_sup_nrem <- df_psg$psg_nrem_ahi_sup[match_ids]
  df_new$psg_ahi_other_nrem <- df_psg$psg_nrem_ahi_oth[match_ids]
  df_new$psg_ahi_total_nrem <- df_psg$psg_nrem_ahi_all[match_ids]
  df_new$psg_pos_supine_dur_rem <- df_psg$psg_rem_res_slpsup[match_ids]
  df_new$psg_pos_other_dur_rem <- df_psg$psg_rem_res_slpoth[match_ids]
  df_new$psg_pos_total_dur_rem <- df_psg$psg_rem_res_slpall[match_ids]
  df_new$psg_spo2_sup_avg_rem <- df_psg$psg_rem_av_spo2sup[match_ids]
  df_new$psg_spo2_other_avg_rem <- df_psg$psg_rem_av_spo2oth[match_ids]
  df_new$psg_spo2_total_avg_rem <- df_psg$psg_rem_av_spo2all[match_ids]
  df_new$psg_spo2_sup_nadir_per_rem <- df_psg$psg_rem_nad_spo2sup[match_ids]
  df_new$psg_spo2_other_nadir_per_rem <- df_psg$psg_rem_nad_spo2oth[match_ids]
  df_new$psg_spo2_total_nadir_per_rem <- df_psg$psg_rem_nad_spo2all[match_ids]
  df_new$psg_central_event_sup_rem <- df_psg$psg_rem_cent_evsup[match_ids]
  df_new$psg_central_event_other_rem <- df_psg$psg_rem_cent_evoth[match_ids]
  df_new$psg_central_event_total_rem <- df_psg$psg_rem_cent_evall[match_ids]
  df_new$psg_obstruct_event_sup_rem <- df_psg$psg_rem_obst_evsup[match_ids]
  df_new$psg_obstruct_event_other_rem <- df_psg$psg_rem_obst_evoth[match_ids]
  df_new$psg_obstruct_event_total_rem <- df_psg$psg_rem_obst_evall[match_ids]
  df_new$psg_mix_event_sup_rem <- df_psg$psg_rem_mix_evsup[match_ids]
  df_new$psg_mix_event_other_rem <- df_psg$psg_rem_mix_evoth[match_ids]
  df_new$psg_mix_event_total_rem <- df_psg$psg_rem_mix_evall[match_ids]
  df_new$psg_hypop_event_sup_rem <- df_psg$psg_rem_hypop_evsup[match_ids]
  df_new$psg_hypop_event_other_rem <- df_psg$psg_rem_hypop_evoth[match_ids]
  df_new$psg_hypop_event_total_rem <- df_psg$psg_rem_hypop_evall[match_ids]
  df_new$psg_rera_sup_rem <- df_psg$psg_rem_rera_evsup[match_ids]
  df_new$psg_rera_other_rem <- df_psg$psg_rem_rera_evoth[match_ids]
  df_new$psg_rera_total_rem <- df_psg$psg_rem_rera_evall[match_ids]
  df_new$psg_rdi_sup_rem <- df_psg$psg_rem_rdi_sup[match_ids]
  df_new$psg_rdi_other_rem <- df_psg$psg_rem_rdi_oth[match_ids]
  df_new$psg_rdi_total_rem <- df_psg$psg_rem_rdi_all[match_ids]
  df_new$psg_ahi_sup_rem <- df_psg$psg_rem_ahi_sup[match_ids]
  df_new$psg_ahi_other_rem <- df_psg$psg_rem_ahi_oth[match_ids]
  df_new$psg_ahi_total_rem <- df_psg$psg_rem_ahi_all[match_ids]
  df_new$psg_pos_supine_dur_all <- df_psg$psg_overall_res_slpsup[match_ids]
  df_new$psg_pos_other_dur_all <- df_psg$psg_overall_res_slpoth[match_ids]
  df_new$psg_pos_total_dur_all <- df_psg$psg_overall_res_slpall[match_ids]
  df_new$psg_spo2_sup_avg_all <- df_psg$psg_overall_av_spo2sup[match_ids]
  df_new$psg_spo2_other_avg_all <- df_psg$psg_overall_av_spo2oth[match_ids]
  df_new$psg_spo2_total_avg_all <- df_psg$psg_overall_av_spo2all[match_ids]
  df_new$psg_spo2_sup_nadir_per_all <- df_psg$psg_overall_nad_spo2sup[match_ids]
  df_new$psg_spo2_other_nadir_per_all <- df_psg$psg_overall_nad_spo2oth[
    match_ids
  ]
  df_new$psg_spo2_total_nadir_per_all <- df_psg$psg_overall_nad_spo2all[
    match_ids
  ]
  df_new$psg_central_event_sup_all <- df_psg$psg_overall_cent_evsup[match_ids]
  df_new$psg_central_event_other_all <- df_psg$psg_overall_cent_evoth[match_ids]
  df_new$psg_central_event_total_all <- df_psg$psg_overall_cent_evall[match_ids]
  df_new$psg_obstruct_event_sup_all <- df_psg$psg_overall_obst_evsup[match_ids]
  df_new$psg_obstruct_event_other_all <- df_psg$psg_overall_obst_evoth[
    match_ids
  ]
  df_new$psg_obstruct_event_total_all <- df_psg$psg_overall_obst_evall[
    match_ids
  ]
  df_new$psg_mix_event_sup_all <- df_psg$psg_overall_mix_evsup[match_ids]
  df_new$psg_mix_event_other_all <- df_psg$psg_overall_mix_evoth[match_ids]
  df_new$psg_mix_event_total_all <- df_psg$psg_overall_mix_evall[match_ids]
  df_new$psg_hypop_event_sup_all <- df_psg$psg_overall_hypop_evsup[match_ids]
  df_new$psg_hypop_event_other_all <- df_psg$psg_overall_hypop_evoth[match_ids]
  df_new$psg_hypop_event_total_all <- df_psg$psg_overall_hypop_evall[match_ids]
  df_new$psg_rera_sup_all <- df_psg$psg_overall_rera_evsup[match_ids]
  df_new$psg_rera_other_all <- df_psg$psg_overall_rera_evoth[match_ids]
  df_new$psg_rera_total_all <- df_psg$psg_overall_rera_evall[match_ids]
  df_new$psg_rdi_sup_all <- df_psg$psg_overall_rdi_sup[match_ids]
  df_new$psg_rdi_other_all <- df_psg$psg_overall_rdi_oth[match_ids]
  df_new$psg_rdi_total_all <- df_psg$psg_overall_rdi_all[match_ids]
  df_new$psg_ahi_sup_all <- df_psg$psg_overall_ahi_sup[match_ids]
  df_new$psg_ahi_other_all <- df_psg$psg_overall_ahi_oth[match_ids]
  df_new$psg_ahi_total_all <- df_psg$psg_overall_ahi_all[match_ids]
  df_new$psg_spo2_wake_avg <- df_psg$psg_av_spo2_wake[match_ids]
  df_new$psg_spo2_desat_avg <- df_psg$psg_av_spo2_desat[match_ids]
  df_new$psg_spo2_less89per <- df_psg$psg_slp_spo2_less89per[match_ids]
  df_new$psg_spo2_less85per <- df_psg$psg_slp_spo2_less85per[match_ids]
  df_new$psg_odi_3per <- df_psg$psg_odi3_per[match_ids]
  df_new$psg_odi_4per <- df_psg$psg_odi4_per[match_ids]
  df_new$psg_apn_hypop_dur_mean <- df_psg$psg_av_apn_hypop_dur[match_ids]
  df_new$psg_hypop_longest <- df_psg$psg_longest_hypop[match_ids]
  df_new$psg_apn_longest <- df_psg$psg_longest_apn[match_ids]
  df_new$psg_plmindex_nrem <- df_psg$psg_nrem_plmi[match_ids]
  df_new$psg_plmindex_rem <- df_psg$psg_rem_plmi[match_ids]
  df_new$psg_plmindex_all <- df_psg$psg_total_plmi[match_ids]
}

##power spec
if (do_psg_powerspec == "Yes") {
  df_powerspec <- read.csv(
    file = powerspec_file,
    colClasses = c("ID" = "character")
  )
  df_powerspec$ID <- gsub("BACH", "", df_powerspec$ID)
  df_powerspec$ID <- gsub("_07082023", "", df_powerspec$ID)
  df_powerspec$ID <- gsub("_23082023", "", df_powerspec$ID)
  df_powerspec$CH <- as.character(df_powerspec$CH)
  df_powerspec$CH <- gsub("_", "", df_powerspec$CH)

  df_powerspec <- pivot_wider(
    df_powerspec,
    id_cols = ID,
    names_from = c(B, CH, stage),
    values_from = c(PSD, RELPSD)
  )

  if (create_subset == "Yes") {
    if (subset_no == "149") {
      participant_list <- readLines(list_file_149)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_powerspec <- df_powerspec[df_powerspec$ID %in% participant_list, ]
    }
    if (subset_no == "120") {
      participant_list <- readLines(list_file_120)
      participant_list <- gsub("BACH", "", participant_list) #removes "BACH" at the start of IDs
      df_powerspec <- df_powerspec[df_powerspec$ID %in% participant_list, ]
    }
  }

  df_new <- merge(
    df_new,
    df_powerspec,
    by.x = "subject_id",
    by.y = "ID",
    all.x = TRUE
  )
}

###CREATE VARIABLES-----

#24H DP DIPPERS
if (do_24hBP == "Yes") {
  df_new$BP24h_dipper <- ifelse(
    is.na(df_new$BP24h_asleep_sys_dip_per),
    NA,
    ifelse(df_new$BP24h_asleep_sys_dip_per >= 10, "Yes", "No")
  )
}

#PWV MEAN CORRECTION (RedCap format misses subjects with only one value)
if (do_vitals == "Yes") {
  df_new$vitals_pwv_mean <- ifelse(
    !is.na(df_new$vitals_pwv_mean),
    df_new$vitals_pwv_mean,
    ifelse(
      !is.na(df_new$vitals_pwv_3),
      ((df_new$vitals_pwv_1 + df_new$vitals_pwv_2 + df_new$vitals_pwv_3) / 3),
      ifelse(
        !is.na(df_new$vitals_pwv_2),
        ((df_new$vitals_pwv_1 + df_new$vitals_pwv_2) / 2),
        ifelse(!is.na(df_new$vitals_pwv_1), df_new$vitals_pwv_1, NA)
      )
    )
  )
}

#OFFICE BP OUTCOMES
if (do_vitals == "Yes") {
  df_new$vitals_map <- df_new$vitals_lying_mean_dia +
    ((1 / 3) * (df_new$vitals_lying_mean_sys - df_new$vitals_lying_mean_dia))
  df_new$vitals_pulsepressure <- (df_new$vitals_lying_mean_sys -
    df_new$vitals_lying_mean_dia)
}

#CHOLESTEROL OUTCOMES
if (do_bloods == "Yes") {
  df_new$bloods_cholratio <- (df_new$bloods_chol / df_new$bloods_chol_hdl)

  df_new$bloods_triglyc_mgdL <- df_new$bloods_triglyc * 88.545 #to get mg/dL units
  df_new$bloods_glucose_fasting_mgdL <- df_new$bloods_glucose_fasting * 18.0 #to get mg/dL units
  df_new$bloods_tygindex <- (log(
    (df_new$bloods_triglyc_mgdL * df_new$bloods_glucose_fasting_mgdL) / 2
  ))
  df_new <- df_new[,
    !names(df_new) %in% c("bloods_triglyc_mgdL", "bloods_glucose_fasting_mgdL")
  ]
}

#MEDICATION CATEGORIES --- ##BROKEN
if (do_medications == "Yes") {
  df_med <- subset(df, redcap_repeat_instrument == "Medications")
  medsnum <- group_size(group_by(df_med, idno))
  maxmeds <- (max(medsnum))
  medications <- paste("medication_atc_med", seq(1, maxmeds), sep = "_")

  #df_new$all_meds <- apply(as.data.frame(df_new)[medications], 1, function(row) {
  #	as.vector(Filter(Negate(is.null), row))
  #})

  df_new$all_meds <- apply(df_new[medications], 1, function(row) {
    vals <- as.vector(row)
    vals <- vals[!(is.na(vals) | vals == "")]
    vals
  })

  has_meds <- function(medications, prefixes) {
    any(sapply(medications, function(med) {
      any(sapply(prefixes, function(prefix) startsWith(med, prefix)))
    }))
  }

  df_new$depression_meds <- ifelse(
    sapply(df_new$all_meds, has_meds, prefixes = c("N06A")),
    "Yes",
    "No"
  )
  df_new$hypertensive_meds <- ifelse(
    sapply(
      df_new$all_meds,
      has_meds,
      prefixes = c("C02", "C03", "C07", "C08", "C09")
    ),
    "Yes",
    "No"
  )
  df_new$lipid_meds <- ifelse(
    sapply(df_new$all_meds, has_meds, prefixes = c("C10")),
    "Yes",
    "No"
  )
  df_new$statin_meds <- ifelse(
    sapply(df_new$all_meds, has_meds, prefixes = c("C10AA")),
    "Yes",
    "No"
  )
  df_new$anxiety_meds <- ifelse(
    sapply(df_new$all_meds, has_meds, prefixes = c("N05B")),
    "Yes",
    "No"
  )
  df_new$diabetes_meds <- ifelse(
    sapply(df_new$all_meds, has_meds, prefixes = c("A10")),
    "Yes",
    "No"
  )
  df_new$sedative_meds <- ifelse(
    sapply(df_new$all_meds, has_meds, prefixes = c("N05C")),
    "Yes",
    "No"
  )

  df_new <- dplyr::select(df_new, -c(all_meds))

  #probably will need to do a 'change' variable instead
  #if (do_year2 == "Yes") {
  #  medsnum <- group_size(group_by(df_year2, idno))
  #  maxmeds <- (max(medsnum) -1 )
  #  medications <- paste("year2_medication_atc_med", seq(1, maxmeds), sep = "_")

  #  df_new$year2_all_meds <- apply(df_new[medications], 1, function(row) {
  #    vals <- as.vector(row)
  #    vals <- vals[!is.na(vals) & !sapply(vals, is.null)]  # Remove NA and NULL values
  #    vals
  #  })

  #  has_meds <- function(medications, prefixes) {
  #    any(sapply(medications, function(med) any(sapply(prefixes, function(prefix) startsWith(med, prefix)))))
  #  }
  #  df_new$year2_depression_meds <- ifelse(sapply(df_new$year2_all_meds, has_meds, prefixes = c("N06A")), "Yes", "No")
  #  df_new$year2_hypertensive_meds <- ifelse(sapply(df_new$year2_all_meds, has_meds, prefixes = c("C02", "C03", "C07", "C08", "C09")), "Yes", "No")
  #  df_new$year2_lipid_meds <- ifelse(sapply(df_new$year2_all_meds, has_meds, prefixes = c("C10")), "Yes", "No")
  #  df_new$year2_statin_meds <- ifelse(sapply(df_new$year2_all_meds, has_meds, prefixes = c("C10AA")), "Yes", "No")
  #  df_new$year2_anxiety_meds <- ifelse(sapply(df_new$year2_all_meds, has_meds, prefixes = c("N05B")), "Yes", "No")
  #  df_new$year2_diabetes_meds <- ifelse(sapply(df_new$year2_all_meds, has_meds, prefixes = c("A10")), "Yes", "No")
  #  df_new$year2_sedative_meds <- ifelse(sapply(df_new$year2_all_meds, has_meds, prefixes = c("N05C")), "Yes", "No")
  #}
}

#HYPERTERNSIVE
if (do_medications == "Yes" & do_vitals == "Yes") {
  df_new$hypertension <- ifelse(
    (is.na(df_new$vitals_lying_mean_sys) |
      is.na(df_new$vitals_lying_mean_dia) |
      is.na(df_new$hypertensive_meds)),
    NA,
    ifelse(
      df_new$vitals_lying_mean_sys >= 140 |
        df_new$vitals_lying_mean_dia >= 90 |
        df_new$hypertensive_meds == "Yes",
      "Yes",
      "No"
    )
  )
}

#DYSLIPIDEMIA
if (do_medications == "Yes" & do_bloods == "Yes") {
  df_new$dyslipidemia <- ifelse(
    (is.na(df_new$bloods_chol) |
      is.na(df_new$bloods_chol_hdl) |
      is.na(df_new$bloods_chol_ldl) |
      is.na(df_new$bloods_triglyc) |
      is.na(df_new$lipid_meds)),
    NA,
    ifelse(
      (df_new$bloods_chol_hdl < 1.0 & df_new$sex == "Male") |
        (df_new$bloods_chol_hdl < 1.3 & df_new$sex == "Female") |
        df_new$bloods_chol >= 5.5 |
        df_new$bloods_chol_ldl >= 3.5 |
        df_new$bloods_triglyc >= 2.0 |
        df_new$lipid_meds == "Yes",
      "Yes",
      "No"
    )
  )
}

#COGNITION TOTALS
if (do_allneuropsych == "Yes" | do_tmt == "Yes") {
  df_new$tmt_bminusa_time <- (df_new$tmt_b_time - df_new$tmt_a_time)
}

if (do_allannualphone == "Yes" | do_prose_passages == "Yes") {
  df_new$tele_prose_imm_percorrect <- ifelse(
    df_new$tele_prose_version == "Passage A",
    ((df_new$tele_prose_imm_story1 + df_new$tele_prose_imm_story2) / 51),
    ifelse(
      df_new$tele_prose_version == "Passage B",
      ((df_new$tele_prose_imm_story1 + df_new$tele_prose_imm_story2) / 50),
      NA
    )
  )
  df_new$tele_prose_del_percorrect <- ifelse(
    df_new$tele_prose_version == "Passage A",
    ((df_new$tele_prose_delay_story1 + df_new$tele_prose_delay_story2) / 51),
    ifelse(
      df_new$tele_prose_version == "Passage B",
      ((df_new$tele_prose_delay_story1 + df_new$tele_prose_delay_story2) / 50),
      NA
    )
  )
}

if (
  do_year2 == "Yes" & (do_allannualphone == "Yes" | do_prose_passages == "Yes")
) {
  df_new$year2_tele_prose_imm_percorrect <- ifelse(
    df_new$year2_tele_prose_version == "Passage A",
    ((df_new$year2_tele_prose_imm_story1 + df_new$year2_tele_prose_imm_story2) /
      51),
    ifelse(
      df_new$year2_tele_prose_version == "Passage B",
      ((df_new$year2_tele_prose_imm_story1 +
        df_new$year2_tele_prose_imm_story2) /
        50),
      NA
    )
  )
  df_new$year2_tele_prose_del_percorrect <- ifelse(
    df_new$year2_tele_prose_version == "Passage A",
    ((df_new$year2_tele_prose_delay_story1 +
      df_new$year2_tele_prose_delay_story2) /
      51),
    ifelse(
      df_new$year2_tele_prose_version == "Passage B",
      ((df_new$year2_tele_prose_delay_story1 +
        df_new$year2_tele_prose_delay_story2) /
        50),
      NA
    )
  )
}

if (
  do_year3 == "Yes" & (do_allannualphone == "Yes" | do_prose_passages == "Yes")
) {
  df_new$year3_tele_prose_imm_percorrect <- ifelse(
    df_new$year3_tele_prose_version == "Passage A",
    ((df_new$year3_tele_prose_imm_story1 + df_new$year3_tele_prose_imm_story2) /
      51),
    ifelse(
      df_new$year3_tele_prose_version == "Passage B",
      ((df_new$year3_tele_prose_imm_story1 +
        df_new$year3_tele_prose_imm_story2) /
        50),
      NA
    )
  )
  df_new$year3_tele_prose_del_percorrect <- ifelse(
    df_new$year3_tele_prose_version == "Passage A",
    ((df_new$year3_tele_prose_delay_story1 +
      df_new$year3_tele_prose_delay_story2) /
      51),
    ifelse(
      df_new$year3_tele_prose_version == "Passage B",
      ((df_new$year3_tele_prose_delay_story1 +
        df_new$year3_tele_prose_delay_story2) /
        50),
      NA
    )
  )
}

#BIOMARKER RATIOS
if (do_biomarkers == "Yes") {
  df_new$ab4240ratio_plasma <- (df_new$ab42_mean_conc_plasma /
    df_new$ab40_mean_conc_plasma)
  df_new$ab4240ratio_plasma <- as.numeric(df_new$ab4240ratio_plasma)
  df_new$ab4240ratio_csf <- (df_new$ab42_mean_conc_csf /
    df_new$ab40_mean_conc_csf)
  df_new$ab4240ratio_csf <- as.numeric(df_new$ab4240ratio_csf)
}

#GENETICS
#note aqp4_allele1 = rs335931, aqp4_allele2 = rs335929, aqp4_allele3 = rs16942851
#note apoe_allele1 = rs7412, apoe_allele2 = rs429358
if (do_genomics == "Yes") {
  df_new$aqp4_genotype <- ifelse(
    is.na(df_new$aqp4_allele1) |
      is.na(df_new$aqp4_allele2) |
      df_new$aqp4_allele3 == "",
    NA,
    ifelse(
      grepl("AA", df_new$aqp4_allele1) &
        grepl("AA", df_new$aqp4_allele2) &
        grepl("TT", df_new$aqp4_allele3),
      "homozygous_major",
      ifelse(
        grepl("AG", df_new$aqp4_allele1) &
          grepl("AC", df_new$aqp4_allele2) &
          grepl("TG", df_new$aqp4_allele3),
        "heterozygous",
        ifelse(
          grepl("GG", df_new$aqp4_allele1) &
            grepl("CC", df_new$aqp4_allele2) &
            grepl("GG", df_new$aqp4_allele3),
          "homozygous_minor",
          "mixed"
        )
      )
    )
  )

  df_new$apoe_genotype <- ifelse(
    is.na(df_new$apoe_allele1) |
      is.na(df_new$apoe_allele2) |
      df_new$apoe_allele1 == "" |
      df_new$apoe_allele2 == "",
    NA,
    ifelse(
      grepl("CC", df_new$apoe_allele2) & grepl("TT", df_new$apoe_allele1),
      "e1e1",
      ifelse(
        grepl("TC", df_new$apoe_allele2) & grepl("TT", df_new$apoe_allele1),
        "e1e2",
        ifelse(
          grepl("CC", df_new$apoe_allele2) & grepl("TC", df_new$apoe_allele1),
          "e1e4",
          ifelse(
            grepl("TT", df_new$apoe_allele2) & grepl("TT", df_new$apoe_allele1),
            "e2e2",
            ifelse(
              grepl("TT", df_new$apoe_allele2) &
                grepl("CT", df_new$apoe_allele1),
              "e2e3",
              ifelse(
                grepl("TC", df_new$apoe_allele2) &
                  grepl("CT", df_new$apoe_allele1),
                "e2e4",
                ifelse(
                  grepl("TT", df_new$apoe_allele2) &
                    grepl("CC", df_new$apoe_allele1),
                  "e3e3",
                  ifelse(
                    grepl("TC", df_new$apoe_allele2) &
                      grepl("CC", df_new$apoe_allele1),
                    "e3e4",
                    ifelse(
                      grepl("CC", df_new$apoe_allele2) &
                        grepl("CC", df_new$apoe_allele1),
                      "e4e4",
                      NA
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  df_new$apoe_e4_status <- ifelse(
    is.na(df_new$apoe_genotype),
    NA,
    ifelse(grepl("e4", df_new$apoe_genotype), "carrier", "noncarrier")
  )
}

#final tidy
columns_with_lists <- sapply(df_new, is.list)
df_new <- df_new[, !columns_with_lists]

###WRITE CSV-----
write.csv(df_new, file = output_file, row.names = FALSE)
