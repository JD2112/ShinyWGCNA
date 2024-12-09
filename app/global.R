source("helpers.R")
options(shiny.maxRequestSize=1000000*1024^2)

# Add any global functions here
add_debug_message <- function(rv, message) {
  rv$debug_messages <- c(rv$debug_messages, paste(Sys.time(), "-", message))
}