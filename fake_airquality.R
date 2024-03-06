# GET THE TOTAL NUMBER OF SENSORS
# FROM THE FIRST ARGUMENT PASSED TO THE SCRIPT
TOTAL_SENSORS <- as.numeric(commandArgs(trailingOnly = TRUE)[1])

cat("Generating fake airquality dataset for", TOTAL_SENSORS, "sensors\n")

random_na <- function(x, p = 0.1) {
  n <- length(x)
  idx <- sample(seq_len(n), size = round(n * p))
  x[idx] <- NA
  x
}

month_to_char <- function(x) {
  dplyr::case_when(
    x == 1 ~ sample(c("Jan", "January", "01", "1"), 1),
    x == 2 ~ sample(c("Feb", "February", "02", "2"), 1),
    x == 3 ~ sample(c("Mar", "March", "03", "3"), 1),
    x == 4 ~ sample(c("Apr", "April", "04", "4"), 1),
    x == 5 ~ sample(c("May", "05", "5"), 1),
    x == 6 ~ sample(c("Jun", "June", "06", "6"), 1),
    x == 7 ~ sample(c("Jul", "July", "07", "7"), 1),
    x == 8 ~ sample(c("Aug", "August", "08", "8"), 1),
    x == 9 ~ sample(c("Sep", "September", "09", "9"), 1),
    x == 10 ~ sample(c("Oct", "October", "10"), 1),
    x == 11 ~ sample(c("Nov", "November", "11"), 1),
    x == 12 ~ sample(c("Dec", "December", "12"), 1)
  )
}

build_fake_air_quality <- function(from, to) {
  dates <- seq.POSIXt(from = as.POSIXct(from), to = as.POSIXct(to), by = "min")
  n <- length(dates)
  data.frame(
    ozone = rnorm(n, mean = 50, sd = 20) |> abs() |> round(0) |> random_na(p = 0.2),
    solar_R = rnorm(n, mean = 200, sd = 50) |> abs() |> round(0) |> random_na(p = 0.1),
    wind = rnorm(n, mean = 10, sd = 5) |> abs() |> round(1) |> random_na(p = 0.1),
    temp = rnorm(n, mean = 70, sd = 10) |> abs() |> round(0) |> random_na(p = 0.1),
    month = as.numeric(format(dates, "%m")) |> month_to_char(),
    day = as.numeric(format(dates, "%d")),
    year = as.numeric(format(dates, "%Y")),
    hour = as.numeric(format(dates, "%H")),
    minute = as.numeric(format(dates, "%M"))
  )
}

build_fake_air_quality_with_sensor <- function(from, to, n_sensors = 1000) {
  airports <- c(
    # List of airport ids
    "JFK", "LAX", "ORD", "DFW", "ATL", "DEN", "SFO", "SEA", "LAS", "MCO", "EWR", "CLT", "PHX", "IAH", "MIA", "MSP", "DTW", "BOS", "PHL", "LGA",
    "FLL", "BWI", "SLC", "SAN", "IAD", "DCA", "MDW", "TPA", "PDX", "HNL", "STL", "BNA", "OAK", "DAL", "AUS", "SMF", "MSY", "SJC", "RDU", "PIT",
    "MCI", "CLE", "SNA", "SDF", "IND", "SAT", "CVG", "RSW", "JAX", "BHM", "OMA", "OKC", "BUF", "ABQ", "PBI", "RIC", "GRR", "TUL", "ROC", "SYR",
    "CHS", "GSO", "CRP", "GSP", "DAY", "HSV", "CAE", "SAV", "AVL", "ILM", "MYR", "FAY", "EWN", "OAJ", "PGV", "EWN", "OAJ", "PGV", "ILM", "MYR"
  )
  sensor_id <- sample(airports, n_sensors, replace = TRUE) |>
    paste0(sample(100:999, n_sensors, replace = TRUE))

  purrr::map_dfr(sensor_id, ~ build_fake_air_quality(from, to) |> dplyr::mutate(sensor_id = .x))
}

fake_data <- build_fake_air_quality_with_sensor("2018-01-01", "2019-01-01", TOTAL_SENSORS)

fake_data |>
  readr::write_csv("data/air_quality.csv")

# Print the size of the file
size <- file.size("data/air_quality.csv")
# Convert to MB
size <- size / 1024 / 1024

cat("The file size for the dataset is", size, "MB\n")
