library(shiny)
library(shinyjs)

# Override the default showNotification function
showNotification <- function(ui, action = NULL, duration = 5, closeButton = TRUE, 
                             id = NULL, type = c("default", "message", "warning", "error"), 
                             session = getDefaultReactiveDomain()) {
  type <- match.arg(type)
  
  # Map Shiny notification types to our custom CSS classes
  type_class <- switch(type,
                       "default" = "info",
                       "message" = "success",
                       "warning" = "warning",
                       "error" = "error")
  
  notification_id <- id %||% paste0("notification-", sample(1:1000000, 1))
  
  notification_html <- tags$div(
    id = notification_id,
    class = paste("custom-notification", type_class),
    ui,
    if (closeButton) tags$button(class = "close", "×")
  )
  
  insertUI(
    selector = "#custom-notification-container",
    where = "beforeEnd",
    ui = notification_html,
    session = session
  )
  
  # Remove the notification after the specified duration
  if (!is.null(duration) && duration > 0) {
    later::later(function() {
      removeUI(
        selector = paste0("#", notification_id),
        session = session
      )
    }, duration)
  }
  
  invisible(notification_id)
}

# Custom progress bar function
custom_progress <- function(message, value = 0, max = 1, session = getDefaultReactiveDomain()) {
  cat("Creating custom progress bar\n")  # Debug print
  notification_id <- paste0("progress-", sample(1:1000000, 1))
  
  progress_html <- tags$div(
    id = notification_id,
    class = "custom-notification info",
    tags$p(message),
    tags$div(
      class = "progress",
      tags$div(
        class = "progress-bar",
        role = "progressbar",
        style = paste0("width: ", (value / max * 100), "%;"),
        "aria-valuenow" = value,
        "aria-valuemin" = 0,
        "aria-valuemax" = max
      )
    )
  )
  
  cat("Inserting progress UI\n")  # Debug print
  insertUI(
    selector = "#custom-notification-container",
    where = "beforeEnd",
    ui = progress_html,
    session = session
  )
  
  list(
    set = function(value, message = NULL) {
      cat("Updating progress bar\n")  # Debug print
      if (!is.null(message)) {
        runjs(sprintf('$("#%s p").text("%s");', notification_id, message))
      }
      runjs(sprintf('$("#%s .progress-bar").css("width", "%s%%").attr("aria-valuenow", %s);',
                    notification_id, value / max * 100, value))
    },
    close = function() {
      cat("Closing progress bar\n")  # Debug print
      removeUI(selector = paste0("#", notification_id))
    }
  )
}

# Helper function to handle NULL values
`%||%` <- function(x, y) if (is.null(x)) y else x