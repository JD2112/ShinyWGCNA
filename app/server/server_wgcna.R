wgcna_server <- function(input, output, session, rv, data) {
  observeEvent(input$runWGCNA, {
    add_debug_message(rv, "WGCNA analysis started")
    shinyjs::disable("runWGCNA")
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    
    progress$set(message = "Running WGCNA analysis", value = 0)
    
    # Prepare data
    progress$set(value = 0.1, detail = "Preparing data")
    datExpr <- as.data.frame(t(data$rnaData()))
    datMeth <- as.data.frame(t(data$methData()))
    
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
    
   # After WGCNA analysis is complete
    rv$wgcna_complete <- TRUE
    add_debug_message(rv, "WGCNA analysis complete")
    
    # Show download options and buttons
    shinyjs::show("downloadOptions")
    add_debug_message(rv, "Showed downloadOptions")
    
    # Show all download buttons
    shinyjs::show("downloadSoftThreshold")
    shinyjs::show("downloadGeneDendrogram")
    shinyjs::show("downloadTraitCor")
    shinyjs::show("downloadNetworkHeatmap")
    shinyjs::show("downloadScatterPlot")
    add_debug_message(rv, "Showed all download buttons")
    
    progress$set(value = 1, detail = "Completing analysis")
    shinyjs::enable("runWGCNA")
    showNotification("WGCNA analysis complete!", type = "message")
    add_debug_message(rv, "Enabled runWGCNA button and showed completion notification")
  })
}