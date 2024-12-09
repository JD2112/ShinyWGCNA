trait_correlation_ui <- function() {
  tagList(
    plotOutput("traitCorPlot"),
    shinyjs::hidden(downloadButton("downloadTraitCor", "Download Plot"))
  )
}