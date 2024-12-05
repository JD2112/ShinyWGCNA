# Example data generation for WGCNA data

# Load required packages
library(MASS) # For multivariate normal simulation

# Set parameters
set.seed(123)  # For reproducibility
nGenes <- 500 # Number of genes
nSamples <- 30 # Number of samples

# Simulate RNA-seq data
simulateRNAseq <- function(nGenes, nSamples, nClusters = 5) {
  clusterSize <- nGenes / nClusters
  exprData <- matrix(0, nrow = nGenes, ncol = nSamples)
  for (i in 1:nClusters) {
    startIdx <- (i - 1) * clusterSize + 1
    endIdx <- i * clusterSize
    # Simulate correlated expression within clusters
    clusterMean <- runif(nSamples, min = 5, max = 15)
    clusterData <- mvrnorm(n = clusterSize, mu = clusterMean, Sigma = diag(0.5, nSamples))
    exprData[startIdx:endIdx, ] <- clusterData
  }
  rownames(exprData) <- paste0("Gene", 1:nGenes)
  colnames(exprData) <- paste0("Sample", 1:nSamples)
  exprData <- abs(exprData)  # Ensure non-negative values (RNA-seq-like)
  return(exprData)
}

# Simulate DNA methylation data
simulateMethylation <- function(exprData, correlationRate = 0.2) {
  nGenes <- nrow(exprData)
  nSamples <- ncol(exprData)
  methData <- matrix(0, nrow = nGenes, ncol = nSamples)
  for (i in 1:nGenes) {
    # Some genes are correlated with RNA expression
    if (runif(1) < correlationRate) {
      methData[i, ] <- scale(exprData[i, ]) / 10 + rnorm(nSamples, mean = 0.5, sd = 0.1)
    } else {
      # Random methylation patterns
      methData[i, ] <- rnorm(nSamples, mean = 0.5, sd = 0.1)
    }
  }
  rownames(methData) <- rownames(exprData)
  colnames(methData) <- colnames(exprData)
  # Bound methylation values between 0 and 1
  methData <- pmax(pmin(methData, 1), 0)
  return(methData)
}

# Generate datasets
exprData <- simulateRNAseq(nGenes, nSamples)
methData <- simulateMethylation(exprData)

# Save to CSV files
write.csv(exprData, file = "RNAseq_large_test.csv", row.names = TRUE)
write.csv(methData, file = "Methylation_large_test.csv", row.names = TRUE)

# Output summary
cat("Generated RNA-seq data with", nGenes, "genes and", nSamples, "samples.\n")
cat("Generated DNA methylation data with", nGenes, "genes and", nSamples, "samples.\n")

