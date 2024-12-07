input_preview_ui <- function() {
  tagList(
    card(
      card_header("RNA-seq Data"),
      DTOutput("rnaPreview")
    ),
    card(
      card_header("Methylation Data"),
      DTOutput("methPreview")
    )
  )
}