sidebar_ui <- function() {
  sidebar(
    width = 350,
    
    tags$head(
      tags$style(HTML("
        .example-links {
          margin-top: -10px;
          margin-bottom: 10px;
          font-size: 0.9em;
        }
        .example-links hr {
          margin-top: 5px;
          margin-bottom: 5px;
        }
      "))
    ),
    
    fileInput("rnaData", "Upload RNA-seq Data (CSV)", accept = c(".csv")),
    fileInput("methData", "Upload DNA Methylation Data (CSV)", accept = c(".csv")),
    
    div(class = "example-links",
      HTML("
        <a href='RNAseq_large_test.csv' target='_blank'><i class='fa fa-download'></i> RNA_data</a> | 
        <a href='Methylation_large_test.csv' target='_blank'><i class='fa fa-download'></i> DNAmeth_data</a>
      ")
    ),
    
    accordion(
      accordion_panel(
        "WGCNA Parameters",
        numericInput("power", "Soft Threshold Power", value = 6, min = 1, max = 20),
        numericInput("minModuleSize", "Minimum Module Size", value = 30, min = 10, max = 100),
        numericInput("mergeCutHeight", "Merge Cut Height", value = 0.25, min = 0.1, max = 1, step = 0.05),
        selectInput("networkType", "Network Type", choices = c("unsigned", "signed", "signed hybrid")),
        numericInput("nCores", "Number of Cores", value = 1, min = 1, max = 16)
      )
    ),
    
    actionButton("runWGCNA", "Run WGCNA", class = "btn-primary btn-lg w-100 mb-3"),
    
    div(
      id = "downloadOptions",
      style = "display: none;",
      accordion(
        accordion_panel(
          "Download Options",
          downloadButton("downloadModules", "Module Genes", class = "btn-secondary w-100 mb-2"),
          downloadButton("downloadNetwork", "Network Data", class = "btn-secondary w-100 mb-2"),
          downloadButton("downloadModuleDetails", "Module Details", class = "btn-secondary w-100 mb-2"),
          downloadButton("downloadForCytoscape", "Cytoscape Format", class = "btn-secondary w-100")
        )
      ),
      selectInput("downloadFormat", "Download Format", 
                  choices = c("png", "jpg", "svg", "pdf"),
                  selected = "png")
    )
  )
}