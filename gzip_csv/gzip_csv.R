# Exploring access of gzipped csv files

library(PWFSLSmoke)

daily <- airnow_loadDaily()

daily_meta <- daily$meta
daily_data <- daily$data

readr::write_csv(daily_meta, file = "meta.csv")
readr::write_csv(daily_data, file = "data.csv")

readr::write_csv(daily_meta, file = "meta.csv.gz")
readr::write_csv(daily_data, file = "data.csv.gz")


bop_meta <- readr::read_csv("meta.csv.gz")

bop_data <- readr::read_csv(
  "data.csv.gz",
  col_types = readr::cols(datetime = readr::col_datetime(), .default = readr::col_double())
)

# WORKS!
