# Load necessary libraries
library(tidyverse)
library(stringi)
library(lubridate)

# Set a seed for reproducibility
set.seed(42)

# Generate the dataset
insurance_data <- tibble(
  policy_id = stri_rand_strings(100, 8, pattern = "[A-Z0-9]"),
  claimant_id = 1:100,
  claim_amount = round(rlnorm(100, meanlog = 7, sdlog = 1.5), 2),
  deductible = sample(c(500, 1000, 1500, 2000), 100, replace = TRUE),
  claim_date = sample(seq(as.Date('2022-01-01'), as.Date('2023-12-31'), by = "day"), 100),
  coverage_type = sample(c("Auto", "Home", "auto", "Renters", "Life"), 100, replace = TRUE),
  status = sample(c("Open", "Closed", "Pending", "In Review"), 100, replace = TRUE),
  incident_zip_code = stri_rand_strings(100, 5, pattern = "[0-9]")
)

# --- Introduce Anomalies for Testing ---

# 1. Introduce missing values (NA)
insurance_data <- insurance_data |>
  mutate(
    claim_amount = if_else(runif(100) < 0.05, NA_real_, claim_amount),
    coverage_type = if_else(runif(100) < 0.1, NA_character_, coverage_type)
  )

# 2. Add some outliers to claim_amount
insurance_data <- insurance_data |>
  add_row(
    policy_id = "OUTLIER1",
    claimant_id = 101,
    claim_amount = 500000,
    deductible = 1000,
    claim_date = as.Date("2023-05-15"),
    coverage_type = "Auto",
    status = "Closed",
    incident_zip_code = "90210"
  )

# 3. Add a duplicate record
insurance_data <- insurance_data |>
  add_row(insurance_data[10, ])

usethis::use_data(insurance_data, overwrite = TRUE)
