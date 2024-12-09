# Shiny for WGCNA
(Under active development)


[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14283132.svg)](https://doi.org/10.5281/zenodo.14283132)
[![GitHub Invite Collaborators](https://img.shields.io/badge/Invite-Collaborators-blue?style=for-the-badge&logo=github)](https://github.com/JD2112/ShinyWGCNA/settings/access)

This Shiny app provides a user-friendly interface for performing **Weighted Gene Co-expression Network Analysis (WGCNA)** on **RNA-seq/Microarray** and **DNA methylation** (Array/Sequencing) data. It allows for data upload, parameter customization, visualization of results, and exporting of analysis outputs.

## Input Data
RNA-seq Data: Upload a CSV file with genes as columns and samples as rows. The first column should contain sample names.
DNA Methylation Data: Upload a CSV file with the same structure as the RNA-seq data, containing methylation values.

## How to run locally
```
R # laod R >= 4.3.1
library(shiny)
shiny::runApp("app.R")
```

### Online webserver

[https://jyotirmoydas.shinyapps.io/ShinyWGCNA/](https://jyotirmoydas.shinyapps.io/ShinyWGCNA/)

## Parameters

### WGCNA Parameters
Soft Threshold Power:
Range: 1-20
Default: 6
Description: Determines the scale-free topology of the network. Higher values lead to more stringent co-expression relationships.

### Minimum Module Size:
Range: 10-100
Default: 30
Description: The minimum number of genes required to form a module.

### Merge Cut Height:
Range: 0.1-1
Step: 0.05
Default: 0.25
Description: The height at which the dendrogram tree is cut to merge similar modules. Lower values result in more modules.

### Network Type:
Options: "unsigned", "signed", "signed hybrid"
Default: "unsigned"
Description: Determines how the correlation between genes is treated in the network construction.

### Number of Cores:
Range: 1-16 (adjust based on your system's capabilities)
Default: 1
Description: Number of CPU cores to use for parallel processing. Higher values can speed up calculations for large datasets.

## Functionality
### Analysis
Click "Run WGCNA" to start the analysis after setting parameters and uploading data.
The app will validate input data, perform WGCNA analysis, and generate visualizations.

### Visualizations
- Soft Threshold Plot: Shows the scale-free topology fit and mean connectivity for different soft threshold powers.
- Network Dendrogram: Displays the hierarchical clustering of genes and module colors.
- Module-Trait Correlation: Heatmap showing correlations between module eigengenes and traits (methylation data).
- Gene Dendrogram: Detailed dendrogram of genes with module color assignments.
- Network Heatmap: Visualizes the Topological Overlap Matrix (TOM) of the gene network.
- Scatter Plot: Interactive plot of module eigengene vs. average methylation for selected modules.

### Export Options
- Download Module Genes: CSV file containing gene-to-module assignments.
- Download Network Data: RData file containing the Topological Overlap Matrix.
- Download Module Details: CSV file with detailed module membership information.
- Download for Cytoscape: Text file compatible with Cytoscape for external network visualization.

### Debug Information
The app provides detailed debug information, including:
- Confirmation of WGCNA completion
- Number of identified modules
- Dimensions of key data structures
- Number of common genes between RNA-seq and methylation data
- Module sizes
- Sample and gene names

## Notes
- The app performs data validation to ensure input data meets WGCNA requirements.
- For large datasets, increase the number of cores to improve performance.
- Adjust parameters based on your specific dataset and research questions.
- The app uses parallel processing for improved performance on multi-core systems.

## Troubleshooting
- If the app crashes or produces unexpected results, check the console for error messages.
- Ensure your input data is properly formatted and contains no missing values.
- For very large datasets, you may need to increase R's memory limit or use a more powerful computer.

## References
Langfelder, P., & Horvath, S. (2008). WGCNA: an R package for weighted correlation network analysis. BMC bioinformatics, 9(1), 559.
For more information on WGCNA, visit: https://horvath.genetics.ucla.edu/html/CoexpressionNetwork/Rpackages/WGCNA/

## Credits
- Main Author: 
    - Jyotirmoy Das ([@JD2112](https://github.com/JD2112))

- Collaborators: ()

## Citation

Das, J. (2024). ShinyWGCNA (v1.1). Zenodo. https://doi.org/10.5281/zenodo.14283132

## Acknowledgement

We would like to acknowledge the **Core Facility, Faculty of Medicine and Health Sciences, Linköping University, Linköping, Sweden** and **Clinical Genomics Linköping, Science for Life Laboratory, Sweden** for their support.