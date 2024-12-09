scatter_plot_ui <- function() {
  tagList(
    selectInput("moduleSelect", "Select Module", choices = NULL),
    plotlyOutput("scatterPlot"),
    shinyjs::hidden(downloadButton("downloadScatterPlot", "Download Plot")),
    verbatimTextOutput("debugInfo")
  )
}