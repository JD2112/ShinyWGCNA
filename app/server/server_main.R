source("server/server_data_processing.R")
source("server/server_wgcna.R")
source("server/server_plots.R")
source("server/server_downloads.R")
source("helpers.R")

server <- function(input, output, session) {
  rv <- reactiveValues(wgcna_complete = FALSE, debug_messages = character())
  
  data <- data_processing_server(input, output, session, rv)
  wgcna_server(input, output, session, rv, data)
  plots_server(input, output, session, rv)
  downloads_server(input, output, session, rv)
}