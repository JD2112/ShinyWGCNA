source("ui/ui_sidebar.R")
source("ui/ui_input_preview.R")
source("ui/ui_soft_threshold.R")
source("ui/ui_gene_dendrogram.R")
source("ui/ui_trait_correlation.R")
source("ui/ui_network_heatmap.R")
source("ui/ui_scatter_plot.R")

ui <- page_fluid(
  useShinyjs(),
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
      #custom-notification-container {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        z-index: 9999;
      }
      .custom-notification {
        padding: 15px;
        margin-bottom: 10px;
        border-radius: 5px;
        color: #fff;
        opacity: 0.9;
        transition: opacity 0.5s ease-in-out;
      }
      .custom-notification.success {
        background-color: #28a745;
      }
      .custom-notification.error {
        background-color: #dc3545;
      }
      .custom-notification.warning {
        background-color: #ffc107;
        color: #000;
      }
      .custom-notification.info {
        background-color: #17a2b8;
      }
      .custom-notification .close {
        float: right;
        font-size: 20px;
        font-weight: bold;
        line-height: 18px;
        color: #000;
        text-shadow: 0 1px 0 #fff;
        opacity: 0.2;
        background: none;
        border: none;
        padding: 0;
        margin-left: 10px;
      }
      .custom-notification .close:hover {
        opacity: 0.5;
      }
      .progress {
      height: 20px;
      margin-bottom: 20px;
      overflow: hidden;
      background-color: #f5f5f5;
      border-radius: 4px;
      -webkit-box-shadow: inset 0 1px 2px rgba(0,0,0,.1);
      box-shadow: inset 0 1px 2px rgba(0,0,0,.1);
    }
    .progress-bar {
      float: left;
      width: 0%;
      height: 100%;
      font-size: 12px;
      line-height: 20px;
      color: #fff;
      text-align: center;
      background-color: #337ab7;
      -webkit-box-shadow: inset 0 -1px 0 rgba(0,0,0,.15);
      box-shadow: inset 0 -1px 0 rgba(0,0,0,.15);
      -webkit-transition: width .6s ease;
      -o-transition: width .6s ease;
      transition: width .6s ease;
    }
    "))
  ),
  div(id = "custom-notification-container"),

  h1("ShinyWGCNA: WGCNA Analysis for RNA-seq and DNA Methylation Data", class = "text-center mb-4"),
  
  layout_sidebar(
    sidebar = sidebar_ui(),
    
    navset_card_tab(
      nav_panel("Input Preview", input_preview_ui()),
      nav_panel("Soft Threshold", soft_threshold_ui()),
      nav_panel("Gene Clustering Dendrogram", gene_dendrogram_ui()),
      nav_panel("Module-Trait Correlation", trait_correlation_ui()),
      nav_panel("Network Heatmap", network_heatmap_ui()),
      nav_panel("Scatter Plot", scatter_plot_ui())
    )
  ),
  
  div(
    class = "footer mt-auto py-3 bg-light",
    div(
      class = "container footer-content",
      div(
        class = "footer-section footer-left",
        "©2024, Jyotirmoy Das, Bioinformactics Unit, Core Facility & Clinical Genomics Linköping, Linköping University"
      ),
      div(
        class = "footer-section",
        a("GitHub", href = "https://github.com/JD2112/ShinyWGCNA", target = "_blank")
      ),
      div(
        class = "footer-section footer-right",
        "Version 1.1"
      )
    )
  )
)