data_processing_server <- function(input, output, session, rv) {
  validate_input_data <- function(data, data_type) {
    if (any(is.na(data))) {
      stop(paste(data_type, "contains missing values. Please remove or impute them before analysis."))
    }
    if (nrow(data) < 15) {
      warning(paste(data_type, "has fewer than 15 samples. WGCNA results may not be reliable."))
    }
    if (ncol(data) < 1000) {
      warning(paste(data_type, "has fewer than 1000 genes. Consider using more genes for better network construction."))
    }
  }

  rnaData <- reactive({
    req(input$rnaData)
    data <- read.csv(input$rnaData$datapath, row.names = 1)
    validate_input_data(data, "RNA-seq data")
    return(data)
  })
  
  methData <- reactive({
    req(input$methData)
    data <- read.csv(input$methData$datapath, row.names = 1)
    validate_input_data(data, "Methylation data")
    return(data)
  })

  output$rnaPreview <- renderDT({
    req(input$rnaData)
    datatable(head(rnaData(), n = 50), 
              options = list(scrollX = TRUE, scrollY = "300px", scroller = TRUE),
              rownames = FALSE)
  })
  
  output$methPreview <- renderDT({
    req(input$methData)
    datatable(head(methData(), n = 50), 
              options = list(scrollX = TRUE, scrollY = "300px", scroller = TRUE),
              rownames = FALSE)
  })

  return(list(rnaData = rnaData, methData = methData))
}