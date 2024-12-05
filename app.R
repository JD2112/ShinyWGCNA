library(shiny)
library(bslib)
library(WGCNA)
library(pheatmap)
library(ComplexHeatmap)
library(shinyjs)
library(plotly)
library(doParallel)
library(DT)

# Define UI
ui <- page_fluid(
  useShinyjs(),  # Enable shinyjs
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  tags$head(
    tags$style(HTML("
      body {
        display: flex;
        flex-direction: column;
        min-height: 100vh;
      }
      .footer {
        margin-top: auto;
      }
      .footer-content {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      .footer-section {
        flex: 1;
        text-align: center;
      }
      .footer-left {
        text-align: left;
      }
      .footer-right {
        text-align: right;
      }
      .initially-hidden {
        display: none;
      }
    "))
  ),
  
  # Title
  h1("WGCNA Analysis for RNA-seq and DNA Methylation Data", class = "text-center mb-4"),
  
  # Main layout
  layout_sidebar(
    sidebar = sidebar(
      width = 350,
      
      # File inputs
      fileInput("rnaData", "Upload RNA-seq Data (CSV)", accept = c(".csv")),
      fileInput("methData", "Upload DNA Methylation Data (CSV)", accept = c(".csv")),
      
      # WGCNA parameters
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
      
      # Run button
      actionButton("runWGCNA", "Run WGCNA", class = "btn-primary btn-lg w-100 mb-3"),
      
      # Download options (initially hidden)
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
      )#,
      # Debug output
      #verbatimTextOutput("debugOutput")
    ),
    
    # Main panel
    navset_card_tab(
      nav_panel("Input Preview", 
                card(
                  card_header("RNA-seq Data"),
                  DTOutput("rnaPreview")
                ),
                card(
                  card_header("Methylation Data"),
                  DTOutput("methPreview")
                )
      ),
      nav_panel("Soft Threshold", 
                plotOutput("softThresholdPlot"),
                shinyjs::hidden(downloadButton("downloadSoftThreshold", "Download Plot"))),
      nav_panel("Gene Clustering Dendrogram", 
                plotOutput("geneDendrogramPlot"),
                shinyjs::hidden(downloadButton("downloadGeneDendrogram", "Download Plot"))),
      nav_panel("Module-Trait Correlation", 
                plotOutput("traitCorPlot"),
                shinyjs::hidden(downloadButton("downloadTraitCor", "Download Plot"))),
      nav_panel("Network Heatmap", 
                plotOutput("networkHeatmapPlot"),
                shinyjs::hidden(downloadButton("downloadNetworkHeatmap", "Download Plot"))),
      nav_panel("Scatter Plot", 
                selectInput("moduleSelect", "Select Module", choices = NULL),
                plotlyOutput("scatterPlot"),
                shinyjs::hidden(downloadButton("downloadScatterPlot", "Download Plot")),
                verbatimTextOutput("debugInfo"))
    )
  ),
  
  # Footer
  div(
    class = "footer mt-auto py-3 bg-light",
    div(
      class = "container footer-content",
      div(
        class = "footer-section footer-left",
        "©2024, Jyotirmoy Das"
      ),
      div(
        class = "footer-section",
        a("Documentation", href = "https://horvath.genetics.ucla.edu/html/CoexpressionNetwork/Rpackages/WGCNA/", target = "_blank")
      ),
      div(
        class = "footer-section footer-right",
        "Version 1.0"
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  options(shiny.maxRequestSize=1000000*1024^2)
  rv <- reactiveValues(wgcna_complete = FALSE, debug_messages = character())
  
  # Function to add debug messages
  add_debug_message <- function(message) {
    rv$debug_messages <- c(rv$debug_messages, paste(Sys.time(), "-", message))
  }
  
  # Debug output
  output$debugOutput <- renderPrint({
    cat(paste(rv$debug_messages, collapse = "\n"))
  })

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

  observeEvent(input$runWGCNA, {
    add_debug_message("WGCNA analysis started")
    shinyjs::disable("runWGCNA")
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    
    progress$set(message = "Running WGCNA analysis", value = 0)
    
    # Prepare data
    progress$set(value = 0.1, detail = "Preparing data")
    datExpr <- as.data.frame(t(rnaData()))
    datMeth <- as.data.frame(t(methData()))
    
    # Find common genes
    common_genes <- intersect(colnames(datExpr), colnames(datMeth))
    
    # Subset both datasets to include only common genes
    datExpr <- datExpr[, common_genes]
    datMeth <- datMeth[, common_genes]
    
    # Check for good samples and genes
    gsg <- goodSamplesGenes(datExpr, verbose = 3)
    if (!gsg$allOK) {
      datExpr <- datExpr[gsg$goodSamples, gsg$goodGenes]
      datMeth <- datMeth[gsg$goodSamples, gsg$goodGenes]
    }
    
    # Choose a set of soft-thresholding powers
    progress$set(value = 0.3, detail = "Choosing soft-thresholding power")
    powers <- c(c(1:10), seq(from = 12, to = 20, by = 2))
    
    # Call the network topology analysis function
    sft <- pickSoftThreshold(datExpr, powerVector = powers, verbose = 5)
    
    # Plot the results
    output$softThresholdPlot <- renderPlot({
      par(mfrow = c(1,2))
      cex1 = 0.9
      
      # Scale-free topology fit index as a function of the soft-thresholding power
      plot(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
           xlab="Soft Threshold (power)",ylab="Scale Free Topology Model Fit,signed R^2",type="n",
           main = paste("Scale independence"))
      text(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
           labels=powers,cex=cex1,col="red")
      
      # Mean connectivity as a function of the soft-thresholding power
      plot(sft$fitIndices[,1], sft$fitIndices[,5],
           xlab="Soft Threshold (power)",ylab="Mean Connectivity", type="n",
           main = paste("Mean connectivity"))
      text(sft$fitIndices[,1], sft$fitIndices[,5], labels=powers, cex=cex1,col="red")
    })

    # Get the best power
    power <- input$power
    if (is.na(power)){
      power <- 6  # If power estimation fails, default to 6
    }
    
    # Set up parallel processing
    registerDoParallel(cores = input$nCores)
    
    # Construct the network
    progress$set(value = 0.5, detail = "Constructing network")
    net <- blockwiseModules(datExpr, 
                            power = power,
                            TOMType = input$networkType, 
                            minModuleSize = input$minModuleSize,
                            mergeCutHeight = input$mergeCutHeight,
                            numericLabels = TRUE, 
                            saveTOMs = TRUE, 
                            saveTOMFileBase = "TOM", 
                            verbose = 3,
                            maxBlockSize = 5000,
                            nThreads = input$nCores)

    # Convert labels to colors for easier plotting
    moduleColors <- labels2colors(net$colors)
    
    # Calculate eigengenes
    MEs <- moduleEigengenes(datExpr, colors = moduleColors)$eigengenes
    
    # Calculate module-trait correlations
    progress$set(value = 0.8, detail = "Calculating module-trait correlations")
    moduleTraitCor <- cor(MEs, datMeth, use = "p")
    moduleTraitPvalue <- corPvalueStudent(moduleTraitCor, nrow(datExpr))
    
    # Save results in reactive values
    rv$moduleColors <- moduleColors
    rv$moduleTraitCor <- moduleTraitCor
    rv$MEs <- MEs
    rv$datExpr <- datExpr
    rv$datMeth <- datMeth
    rv$net <- net
    rv$common_genes <- common_genes
    rv$sft <- sft
    rv$powers <- powers
    
    # Update module choices for scatter plot
    updateSelectInput(session, "moduleSelect", choices = unique(moduleColors))
    
    # Plot dendrogram
    output$geneDendrogramPlot <- renderPlot({
      plotDendroAndColors(rv$net$dendrograms[[1]], rv$moduleColors,
                          "Module colors",
                          dendroLabels = FALSE, hang = 0.03,
                          addGuide = TRUE, guideHang = 0.05,
                          main = "Gene Clustering Dendrogram and Module Colors")
    })
    
    # Plot module-trait correlation heatmap
    output$traitCorPlot <- renderPlot({
      pheatmap(rv$moduleTraitCor, cluster_rows = TRUE, cluster_cols = TRUE, 
               display_numbers = TRUE, main = "Module-Trait Correlations")
    })
    
    # Network Heatmap Plot
    output$networkHeatmapPlot <- renderPlot({
      TOM <- TOMsimilarityFromExpr(rv$datExpr, power = power)
      dissTOM <- 1 - TOM
      plotTOM <- dissTOM^7
      TOMplot(plotTOM, rv$net$dendrograms[[1]], rv$moduleColors, 
              main = "Network heatmap plot, all genes")
    })
    
    # After WGCNA analysis is complete
    rv$wgcna_complete <- TRUE
    add_debug_message("WGCNA analysis complete")
    
    # Show download options and buttons
    shinyjs::show("downloadOptions")
    add_debug_message("Showed downloadOptions")
    
    # Show all download buttons
    shinyjs::show("downloadSoftThreshold")
    shinyjs::show("downloadGeneDendrogram")
    shinyjs::show("downloadTraitCor")
    shinyjs::show("downloadNetworkHeatmap")
    shinyjs::show("downloadScatterPlot")
    add_debug_message("Showed all download buttons")
    
    progress$set(value = 1, detail = "Completing analysis")
    shinyjs::enable("runWGCNA")
    showNotification("WGCNA analysis complete!", type = "message")
    add_debug_message("Enabled runWGCNA button and showed completion notification")
  })
  
  output$scatterPlot <- renderPlotly({
    req(rv$wgcna_complete, input$moduleSelect)
    selectedModule <- input$moduleSelect
    
    eigengene <- rv$MEs[, paste0("ME", selectedModule)]
    moduleGenes <- rv$datExpr[, rv$moduleColors == selectedModule, drop = FALSE]
    module_gene_names <- colnames(moduleGenes)
    avgMethylation <- rowMeans(rv$datMeth[, module_gene_names, drop = FALSE])
    
    plot_data <- data.frame(
      Eigengene = eigengene,
      AvgMethylation = avgMethylation,
      Sample = rownames(rv$datExpr)
    )
    
    cor_value <- cor(eigengene, avgMethylation, use = "pairwise.complete.obs")
    
    p <- plot_ly(plot_data, x = ~Eigengene, y = ~AvgMethylation, type = "scatter", mode = "markers",
                 text = ~Sample, hoverinfo = "text+x+y",
                 marker = list(color = selectedModule, size = 10)) %>%
      layout(title = paste("Scatter Plot for Module", selectedModule),
             xaxis = list(title = "Module Eigengene"),
             yaxis = list(title = "Average Methylation Level"),
             annotations = list(
               x = 0.05, y = 0.95, xref = "paper", yref = "paper",
               text = paste("Correlation:", round(cor_value, 3)),
               showarrow = FALSE
             ))
    
    return(p)
  })
  
  output$debugInfo <- renderPrint({
    req(rv$wgcna_complete)
    print(paste("WGCNA complete:", rv$wgcna_complete))
    print(paste("Number of modules:", length(unique(rv$moduleColors))))
    print(paste("Dimensions of MEs:", paste(dim(rv$MEs), collapse = "x")))
    print(paste("Dimensions of datExpr:", paste(dim(rv$datExpr), collapse = "x")))
    print(paste("Dimensions of datMeth:", paste(dim(rv$datMeth), collapse = "x")))
    print(paste("Number of common genes:", length(rv$common_genes)))
    print("First few common genes:")
    print(head(rv$common_genes))
    print("Module sizes:")
    print(table(rv$moduleColors))
    print("Sample names:")
    print(rownames(rv$datExpr))
    print("First few gene names:")
    print(head(colnames(rv$datExpr)))
  })
  
  output$rnaPreview <- renderDT({
    req(input$rnaData)
    data <- read.csv(input$rnaData$datapath, row.names = 1)
    datatable(head(data, n = 50), 
              options = list(scrollX = TRUE, scrollY = "300px", scroller = TRUE),
              rownames = FALSE)
  })
  
  output$methPreview <- renderDT({
    req(input$methData)
    data <- read.csv(input$methData$datapath, row.names = 1)
    datatable(head(data, n = 50), 
              options = list(scrollX = TRUE, scrollY = "300px", scroller = TRUE),
              rownames = FALSE)
  })
  
  output$downloadModules <- downloadHandler(
    filename = "module_genes.csv",
    content = function(file) {
      req(rv$wgcna_complete)
      moduleGenes <- data.frame(Gene = colnames(rv$datExpr), Module = rv$moduleColors)
      write.csv(moduleGenes, file, row.names = FALSE)
    }
  )
  
  output$downloadNetwork <- downloadHandler(
    filename = "network_data.RData",
    content = function(file) {
      req(rv$wgcna_complete)
      TOM <- TOMsimilarityFromExpr(rv$datExpr, power = input$power)
      save(TOM, file = file)
    }
  )
  
  output$downloadModuleDetails <- downloadHandler(
    filename = "module_details.csv",
    content = function(file) {
      req(rv$wgcna_complete)
      moduleDetails <- data.frame(
        Gene = colnames(rv$datExpr),
        Module = rv$moduleColors,
        ModuleMembership = signedKME(rv$datExpr, rv$MEs)
      )
      write.csv(moduleDetails, file, row.names = FALSE)
    }
  )
  
  output$downloadForCytoscape <- downloadHandler(
    filename = "cytoscape_network.txt",
    content = function(file) {
      req(rv$wgcna_complete)
      TOM <- TOMsimilarityFromExpr(rv$datExpr, power = input$power)
      edge_list <- which(TOM > 0.1, arr.ind = TRUE)
      edge_list <- edge_list[edge_list[,1] < edge_list[,2], ]
      edge_data <- data.frame(
        Source = colnames(rv$datExpr)[edge_list[,1]],
        Target = colnames(rv$datExpr)[edge_list[,2]],
        Weight = TOM[edge_list]
      )
      write.table(edge_data, file, sep = "\t", row.names = FALSE, quote = FALSE)
    }
  )

  # Function to create download handler for plots
  createPlotDownloadHandler <- function(plotFunc, filename) {
    downloadHandler(
      filename = function() {
        paste0(filename, ".", input$downloadFormat)
      },
      content = function(file) {
        req(rv$wgcna_complete)
        
        # Open appropriate device based on file type
        switch(input$downloadFormat,
               "png" = png(file, width = 800, height = 600),
               "jpg" = jpeg(file, width = 800, height = 600, quality = 90),
               "svg" = svg(file, width = 10, height = 7.5),
               "pdf" = pdf(file, width = 10, height = 7.5))
        
        # Generate the plot
        plotFunc()
        
        # Close the device
        dev.off()
      }
    )
  }

  # Download handlers for each plot
  output$downloadSoftThreshold <- createPlotDownloadHandler(
    function() {
      par(mfrow = c(1,2))
      plot(rv$sft$fitIndices[,1], -sign(rv$sft$fitIndices[,3])*rv$sft$fitIndices[,2],
           xlab="Soft Threshold (power)",ylab="Scale Free Topology Model Fit,signed R^2",type="n",
           main = paste("Scale independence"))
      text(rv$sft$fitIndices[,1], -sign(rv$sft$fitIndices[,3])*rv$sft$fitIndices[,2],
           labels=rv$powers,cex=0.9,col="red")
      plot(rv$sft$fitIndices[,1], rv$sft$fitIndices[,5],
           xlab="Soft Threshold (power)",ylab="Mean Connectivity", type="n",
           main = paste("Mean connectivity"))
      text(rv$sft$fitIndices[,1], rv$sft$fitIndices[,5], labels=rv$powers, cex=0.9,col="red")
    },
    "soft_threshold_plot"
  )

  output$downloadGeneDendrogram <- createPlotDownloadHandler(
    function() {
      plotDendroAndColors(rv$net$dendrograms[[1]], rv$moduleColors,
                          "Module colors", dendroLabels = FALSE, hang = 0.03,
                          addGuide = TRUE, guideHang = 0.05,
                          main = "Gene Clustering Dendrogram and Module Colors")
    },
    "gene_dendrogram"
  )

  output$downloadTraitCor <- createPlotDownloadHandler(
    function() {
      pheatmap(rv$moduleTraitCor, cluster_rows = TRUE, cluster_cols = TRUE, 
               display_numbers = TRUE, main = "Module-Trait Correlations")
    },
    "module_trait_correlation"
  )

  output$downloadNetworkHeatmap <- createPlotDownloadHandler(
    function() {
      TOM <- TOMsimilarityFromExpr(rv$datExpr, power = input$power)
      dissTOM <- 1 - TOM
      plotTOM <- dissTOM^7
      TOMplot(plotTOM, rv$net$dendrograms[[1]], rv$moduleColors, 
              main = "Network heatmap plot, all genes")
    },
    "network_heatmap"
  )

  output$downloadScatterPlot <- createPlotDownloadHandler(
    function() {
      selectedModule <- input$moduleSelect
      eigengene <- rv$MEs[, paste0("ME", selectedModule)]
      moduleGenes <- rv$datExpr[, rv$moduleColors == selectedModule, drop = FALSE]
      module_gene_names <- colnames(moduleGenes)
      avgMethylation <- rowMeans(rv$datMeth[, module_gene_names, drop = FALSE])
      
      plot(eigengene, avgMethylation,
           main = paste("Scatter Plot for Module", selectedModule),
           xlab = "Module Eigengene", ylab = "Average Methylation Level",
           col = selectedModule, pch = 19)
      
      cor_value <- cor(eigengene, avgMethylation, use = "pairwise.complete.obs")
      legend("topright", legend = paste("Correlation:", round(cor_value, 3)), bty = "n")
    },
    "scatter_plot"
  )
}

# Run App
shinyApp(ui, server)