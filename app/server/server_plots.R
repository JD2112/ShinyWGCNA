plots_server <- function(input, output, session, rv) {
  output$softThresholdPlot <- renderPlot({
    req(rv$sft)
    par(mfrow = c(1,2))
    cex1 = 0.9
    
    # Scale-free topology fit index as a function of the soft-thresholding power
    plot(rv$sft$fitIndices[,1], -sign(rv$sft$fitIndices[,3])*rv$sft$fitIndices[,2],
         xlab="Soft Threshold (power)",ylab="Scale Free Topology Model Fit,signed R^2",type="n",
         main = paste("Scale independence"))
    text(rv$sft$fitIndices[,1], -sign(rv$sft$fitIndices[,3])*rv$sft$fitIndices[,2],
         labels=rv$powers,cex=cex1,col="red")
    
    # Mean connectivity as a function of the soft-thresholding power
    plot(rv$sft$fitIndices[,1], rv$sft$fitIndices[,5],
         xlab="Soft Threshold (power)",ylab="Mean Connectivity", type="n",
         main = paste("Mean connectivity"))
    text(rv$sft$fitIndices[,1], rv$sft$fitIndices[,5], labels=rv$powers, cex=cex1,col="red")
  })

  output$geneDendrogramPlot <- renderPlot({
    req(rv$net, rv$moduleColors)
    plotDendroAndColors(rv$net$dendrograms[[1]], rv$moduleColors,
                        "Module colors",
                        dendroLabels = FALSE, hang = 0.03,
                        addGuide = TRUE, guideHang = 0.05,
                        main = "Gene Clustering Dendrogram and Module Colors")
  })

  output$traitCorPlot <- renderPlot({
    req(rv$moduleTraitCor)
    pheatmap(rv$moduleTraitCor, cluster_rows = TRUE, cluster_cols = TRUE, 
             display_numbers = TRUE, main = "Module-Trait Correlations")
  })

  output$networkHeatmapPlot <- renderPlot({
    req(rv$datExpr, rv$net, rv$moduleColors)
    TOM <- TOMsimilarityFromExpr(rv$datExpr, power = input$power)
    dissTOM <- 1 - TOM
    plotTOM <- dissTOM^7
    TOMplot(plotTOM, rv$net$dendrograms[[1]], rv$moduleColors, 
            main = "Network heatmap plot, all genes")
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
}