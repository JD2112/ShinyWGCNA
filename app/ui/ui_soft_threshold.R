soft_threshold_ui <- function() {
  tagList(
    plotOutput("softThresholdPlot"),
    shinyjs::hidden(downloadButton("downloadSoftThreshold", "Download Plot"))
  )
}