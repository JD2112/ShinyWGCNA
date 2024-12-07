network_heatmap_ui <- function() {
  tagList(
    plotOutput("networkHeatmapPlot"),
    shinyjs::hidden(downloadButton("downloadNetworkHeatmap", "Download Plot"))
  )
}