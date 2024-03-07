library(data.table)

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
air_quality <- fread("data/air_quality.csv")

# Set column types as required
setnames(air_quality, old = names(air_quality), new = c("month", "day", "year", "hour", "minute", "ozone", "solar_R", "wind", "temp", "sensor_id"))
air_quality[, c("month", "day", "year", "hour", "minute") := .(as.character(month), as.integer(day), as.integer(year), as.integer(hour), as.integer(minute))]

# Convert month to numeric
air_quality[, month := month_to_num(month)]

# Combine date and time into datetime
air_quality[, datetime := combine_datetime(year, month, day, hour, minute)]

# Order by datetime
setorder(air_quality, datetime)

# Fill missing values within each sensor group
air_quality[, c("ozone", "solar_R", "wind", "temp") := lapply(.SD, nafill, type = "locf"), by = sensor_id, .SDcols = c("ozone", "solar_R", "wind", "temp")]
air_quality[, c("ozone", "solar_R", "wind", "temp") := lapply(.SD, nafill, type = "nocb"), by = sensor_id, .SDcols = c("ozone", "solar_R", "wind", "temp")]

# Extract airport code and sensor number
air_quality[, `:=`(airport = substr(sensor_id, 1, 3), sensor_number = substr(sensor_id, 4, 6))]

# Write the cleaned and processed data to a new CSV file
fwrite(air_quality, "data/air_quality_r_datatable.csv")
