# Fist pass at working with DRI sensor data
#
# 'Mazama' package documenation
#  * https://mazamascience.github.io/MazamaCoreUtils/
#  * https://mazamascience.github.io/MazamaTimeSeries/
#  * https://mazamascience.github.io/AirMonitor/

# The AirMonitor package must be installed
require(AirMonitor)

# Load dplyr for the '%>%' operator
library(dplyr)

# ----- 1) Get/parse raw data --------------------------------------------------

url <- "https://wrcc.dri.edu/smoke/SmokeMonNV.csv"

# Columns from "AIRNow-1 AQCSV-Final.pdf"
d
col_names = c(
  "site",
  "dataStatus",
  "actionCode",
  "datetime",
  "parameterCode",
  
  "duration",
  "frequency",
  "value",
  "units",
  "qc",
  
  "poc",
  "latitude",
  "longitude",
  "gisDatum",
  "elevation",
  
  "methodCode",
  "mpc",
  "mpcValue",
  "uncertainty",
  "qualifiers"
)

col_types = 
  "ccccc dddcc cddcd ccccc" %>%
  stringr::str_replace_all(" ", "")

raw <- 
  readr::read_csv(
    url, 
    col_names = col_names,
    col_types = col_types
  )

# > dplyr::glimpse(raw, width = 75)
# Rows: 1,232
# Columns: 20
# $ site          <chr> "84000NV3SLOC", "84000NV3SLOC", "84000NV3SLOC", "84…
# $ dataStatus    <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "…
# $ actionCode    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ datetime      <chr> "20221112T0000-0800", "20221112T0000-0800", "202211…
# $ parameterCode <chr> "62101", "62201", "88101", "85101", "62101", "62201…
# $ duration      <dbl> 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60,…
# $ frequency     <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ value         <dbl> -0.6, 54.0, 1.0, 1.0, -0.8, 54.0, 7.0, 8.0, -1.1, 5…
# $ units         <chr> "017", "019", "105", "105", "017", "019", "105", "1…
# $ qc            <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "…
# $ poc           <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "…
# $ latitude      <dbl> 39.50528, 39.50528, 39.50528, 39.50528, 39.50528, 3…
# $ longitude     <dbl> -119.6458, -119.6458, -119.6458, -119.6458, -119.64…
# $ gisDatum      <chr> "NAD83", "NAD83", "NAD83", "NAD83", "NAD83", "NAD83…
# $ elevation     <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ methodCode    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ mpc           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ mpcValue      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ uncertainty   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ qualifiers    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…

# ----- 3) Harmonize data ------------------------------------------------------

# > unique(raw$parameterCode)
# [1] "62101" "62201" "88101" "85101"

# 62101 -- outdoor temperature
# 62201 -- relative humidity
# 88101 -- PM2.5
# 85101 -- PM10

# > unique(raw$unit)
# [1] "017" "019" "105"

# 017 -- degrees C
# 019 -- percent RH
# 105 -- UG/M3

# > unique(raw$dataStatus)
# [1] "0"
# > unique(raw$actionCode)
# [1] NA
# > unique(raw$duration)
# [1] 60
# > unique(raw$frequency)
# [1] NA
# > unique(raw$qc)
# [1] "0"
# > unique(raw$poc)
# [1] "1"
# > unique(raw$gisDatum)
# [1] "NAD83"

df <-
  # start with raw data
  raw %>%
  # pick out columns of interest
  dplyr::select(c(
    "site",
    "datetime",
    "parameterCode",
    "value",
    "units",
    "longitude",
    "latitude",
    "elevation"
  ))

# * datetime -----
df$datetime <- 
  df$datetime %>%
  base::strptime("%Y%m%dT%H%M%z", tz = "UTC") %>%
  base::as.POSIXct()

# * parameterName -----
df$parameterName <-
  dplyr::recode(
    df$parameterCode,
    "62101" = "temperature",
    "62201" = "relativeHumidity",
    "88101" = "PM2.5",
    "85101" = "PM10"
  )

# * units -----
df$units <-
  dplyr::recode(
    df$units,
    "017" = "DEG C",
    "019" = "PCT",
    "105" = "UG/M3"
  )

# * locationID -----
df$locationID <- MazamaCoreUtils::createLocationID(df$longitude, df$latitude)

# * deviceID -----
df$deviceID <- paste0(df$site) ###, "_", df$poc)

# * deviceDeploymentID -----
df$deviceDeploymentID <- paste(df$locationID, "_", df$deviceID)

# * countryCode -----
df$countryCode <- "US"

# * stateCode -----
df$stateCode <- "NV"

# * timezone -----
df$timezone <- "America/Los_Angeles"

# * locationName -----
df$locationName <- df$site

# ----- 4) Split by deviceID ---------------------------------------------------

deviceIDs <- unique(df$deviceID)

deviceList <- list()

for ( deviceID in deviceIDs ) {
  
  # TODO:  Handle any errors
  
  deviceList[[deviceID]] <-
    df %>%
    dplyr::filter(deviceID == !!deviceID)
  
}

# ----- 5) Create sts_timeseries objects ---------------------------------------

stsList <- list()

for ( deviceID in names(deviceList) ) {
  
  # TODO:  Handle any errors
  
  data <-
    deviceList[[deviceID]] %>%
    dplyr::select(c("datetime", "parameterName", "value")) %>%
    tidyr::pivot_wider(names_from = parameterName, values_from = value)
  
  meta <-
    deviceList[[deviceID]] %>%
    dplyr::select(c(
      "deviceDeploymentID",
      "deviceID",
      "locationID",
      "locationName",
      "longitude",
      "latitude",
      "elevation",
      "countryCode",
      "stateCode",
      "timezone"
    )) %>%
    dplyr::distinct()
  
  # Create the sts object
  sts <- list(meta = meta, data = data)
  class(sts) <- c("sts", class(sts))
  
  MazamaTimeSeries::sts_check(sts)
  
  stsList[[deviceID]] <- sts
  
}

# TODO:  Opportunity to write out raw data files

# Review

allParamsPlot(stsList[[1]])

# ----- 6) Create mts_monitor objects ------------------------------------------

monitorList <- list()

for ( deviceID in names(stsList) ) {
  
  sts <- stsList[[deviceID]]
  id <- sts$meta$deviceDeploymentID
  
  # * create 'data' -----
  
  data <-
    sts$data %>%
    dplyr::select(c("datetime", "PM2.5"))
  
  # Create a tibble with a regular time axis covering data and nowcastData
  hourlyTbl <-
    dplyr::tibble(
      datetime = seq(
        min(data$datetime, na.rm = TRUE),
        max(data$datetime, na.rm = TRUE),
        by = "hours"
      )
    )
  
  # Merge the two dataframes together with a left join
  data <- dplyr::left_join(hourlyTbl, data, by = "datetime")
  names(data) <- c("datetime", sts$meta$deviceDeploymentID)

  # * create 'meta' -----
  
  meta <- 
    sts$meta %>%
    dplyr::mutate(
      #deviceDeploymentID = as.character(NA),
      #deviceID = as.character(NA),
      deviceType = as.character(NA),
      deviceDescription = as.character(NA),
      deviceExtra = as.character(NA),
      pollutant = "PM2.5",
      units = "UG/M3",
      dataIngestSource = "DRI internal",
      dataIngestURL = as.character(NA),
      dataIngestUnitID = as.character(NA),
      dataIngestExtra = as.character(NA),
      dataIngestDescription = as.character(NA),
      #locationID = as.character(NA),
      #locationName = as.character(NA),
      #longitude = as.character(NA),
      #latitude = as.character(NA),
      #elevation = as.numeric(NA),
      #countryCode = "US",
      #stateCode = "NV",
      countyName = as.character(NA),
      #timezone = "America/Los_Angeles",
      houseNumber = as.character(NA),
      street = as.character(NA),
      city = as.character(NA),
      zip = as.character(NA),
      AQSID = .data$deviceID,
      fullAQSID = .data$deviceID
    )

  monitor <- list(meta = meta, data = data)
  monitor <- structure(monitor, class = c("mts_monitor", "mts", class(monitor)))
  AirMonitor::monitor_check(monitor)
  
  monitorList[[deviceID]] <- monitor  
  
}
  
################################################################################
################################################################################

# NOTE:  Below here has not been run but shows how to create NowCast and AQI 
# NOTE:  versions of a monitr object and then assemble a 'fullData' tibble that 
# NOTE:  could be written out as a CSV.
# NOTE:
# NOTE:  The chund of code below would need to be inside a loop over all monitors.


# 

if ( FALSE ) {
  
  # Create NowCast version
  nowcast <- AirMonitor::monitor_nowcast(monitor, includeShortTerm = TRUE)

  # Create AQI version
  aqi <- AirMonitor::monitor_aqi(monitor, includeShortTerm = TRUE)
  
  # Assemble data from the 'mts_monitor' objects
  fullData <- monitor$data
  names(fullData) <- c("datetime", "PM2.5")
  fullData$PM2.5_nowcast <- nowcast$data %>% dplyr::pull(2)
  fullData$PM2.5_AQI <- aqi$data %>% dplyr::pull(2)

  # Get other timeseries data from the 'sts' object (may not have all timesteps)
  otherData <- 
    sts$data %>%
    dplyr::select(c("datetime", "temperature", "relativeHumidity", "PM10"))
  
  # Assemble full timeseries dataframe with no missing hours
  fullData <-
    dplyr::left_join(
    fullData,
    otherData,
    by = "datetime"
  )
  
  
}
