month_to_num <- function(x) {
  dplyr::case_when(
    x %in% c("Jan", "January", "01", "1") ~ 1,
    x %in% c("Feb", "February", "02", "2") ~ 2,
    x %in% c("Mar", "March", "03", "3") ~ 3,
    x %in% c("Apr", "April", "04", "4") ~ 4,
    x %in% c("May", "05", "5") ~ 5,
    x %in% c("Jun", "June", "06", "6") ~ 6,
    x %in% c("Jul", "July", "07", "7") ~ 7,
    x %in% c("Aug", "August", "08", "8") ~ 8,
    x %in% c("Sep", "September", "09", "9") ~ 9,
    x %in% c("Oct", "October", "10") ~ 10,
    x %in% c("Nov", "November", "11") ~ 11,
    x %in% c("Dec", "December", "12") ~ 12
  )
}

combine_datetime <- function(year, month, day, hour, minute) {
  paste(year, month, day, hour, minute, sep = "-") |>
    as.POSIXct(format = "%Y-%m-%d-%H-%M", tz = "UTC")
}


# Load the data
schema <- readr::cols(
  month = readr::col_character(),
  day = readr::col_integer(),
  year = readr::col_integer(),
  hour = readr::col_integer(),
  minute = readr::col_integer(),
  ozone = readr::col_integer(),
  solar_R = readr::col_integer(),
  wind = readr::col_double(),
  temp = readr::col_integer(),
  sensor_id = readr::col_character()
)

air_quality <- readr::read_csv("data/air_quality.csv", col_types = schema)

air_quality |>
  dplyr::mutate(
    month = month_to_num(month),
    datetime = combine_datetime(year, month, day, hour, minute)
  ) |>
  dplyr::select(ozone, solar_R, wind, temp, datetime, sensor_id) |>
  dplyr::arrange(datetime) |>
  dplyr::group_by(sensor_id) |>
  tidyr::fill(ozone, solar_R, wind, temp, .direction = "downup") |>
  dplyr::ungroup() |>
  dplyr::mutate(
    airport = substr(sensor_id, 1, 3),
    sensor_number = substr(sensor_id, 4, 6)
  ) |>
  readr::write_csv("data/air_quality_r_tidy.csv")
