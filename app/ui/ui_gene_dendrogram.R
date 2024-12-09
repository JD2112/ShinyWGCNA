gene_dendrogram_ui <- function() {
  tagList(
    plotOutput("geneDendrogramPlot"),
    shinyjs::hidden(downloadButton("downloadGeneDendrogram", "Download Plot"))
  )
}