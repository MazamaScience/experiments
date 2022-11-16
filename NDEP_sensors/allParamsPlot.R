# Fist pass plot for looking at raw instrument data in 'sts' format

allParamsPlot <- function(
  sts = NULL
) {

  timeInfo <- 
    MazamaTimeSeries::timeInfo(
      sts$data$datetime,
      sts$meta$longitude,
      sts$meta$latitude,
      sts$meta$timezone
    )
  
  localTime <- lubridate::with_tz(sts$data$datetime, sts$meta$timezone)
  
  plot(
    localTime, 
    sts$data$temperature, 
    ylim = c(-40, 120),
    type = 'b',
    cex = 0.5,
    las = 1,
    xlab = "local time",
    ylab = "\u00b5g/m\u00b3, % humidity, \u00b0C"
  ) 
  
  AirMonitor::addShadedNight(timeInfo)
  
  points(
    localTime, 
    sts$data$relativeHumidity,
    type = 'b',
    col = "lightblue",
    cex = 0.5
  )
  
  points(
    localTime, 
    sts$data$PM2.5,
    pch = 15,
    col = "black",
    cex = 1.0
  )
  
  points(
    localTime, 
    sts$data$PM10,
    pch = 0,
    col = "black",
    cex = 1.5
  )
  
  legend(
    "topright",
    legend = c("temperature", "relative humidity", "PM 2.5", "PM 10"),
    pch = c(1,1,15,0),
    pt.cex = c(0.5, 0.5, 1, 1.5),
    col = c("black", "lightblue", "black", "black")
  )
  
  # Copied from 
  width = 0.01
  usr <- par("usr")
  r <- usr[1] + width*(usr[2] - usr[1])
  
  AirMonitor::addAQIStackedBar()
  AirMonitor::addAQILegend(x = r, y = usr[4])
  
  title(meta$locationName)
  
}

