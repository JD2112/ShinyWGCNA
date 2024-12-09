downloads_server <- function(input, output, session, rv) {
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