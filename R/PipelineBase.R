#' @title ETL Pipeline R6 Class
#' @description
#' A base R6 class for creating and managing stateful ETL pipelines. It handles
#' parameter validation, dataset storage, and logging.
#' @importFrom glue glue
#' @importFrom R6 R6Class
#' @export
PipelineBase <- R6::R6Class(
  "PipelineBase",
  public = list(
    # --- PUBLIC FIELDS ---
    #' @field pipeline_name (`character()`)\cr
    #' A title case name for the pipeline e.g. 'Pipeline Name'
    pipeline_name = NULL,

    #' @field pipeline_id (`character()`)\cr
    #' Unique Identifier for this pipeline e.g. 'pipeline-id'
    pipeline_id = NULL,

    #' @field metadata (`list()`)\cr
    #' A list to hold arbitrary user-defined pipeline attributes or identifiers.
    metadata = NULL,

    #' @field datasets (`list()`)\cr
    #' A list to store datasets (e.g., data frames) used or created.
    datasets = NULL,

    # --- PUBLIC METHODS ---
    #' @description constructor
    #' @param pipeline_name (`character()`)\cr
    #'   Name of this pipeline.
    #' @param pipeline_id (`character()`)\cr
    #'   Identifier for this pipeline
    #' @param metadata (`list()`)\cr
    #' An optional named list of attributes to add
    #' @return A new `PipelineBase` object.
    initialize = function(pipeline_name, pipeline_id, metadata) {
      if (!is.list(metadata) ||
          is.null(names(metadata)) && length(metadata) > 0) {
        stop("metadata must be a named list.")
      }
      self$pipeline_name <- pipeline_name
      self$pipeline_id <- pipeline_id
      self$metadata <- metadata
      self$datasets <- list()

      private$.run_id <- glue("run-{pipeline_id}-{format(Sys.time(), '%Y%m%d')}")
      private$capture_environment()

      self$add_log(glue("Pipeline '{self$pipeline_name}' initialized."))

      invisible(self)
    },

    #' @description
    #' Add or update a single piece of metadata.
    #' @param key A character string for the metadata name (the key).
    #' @param value The value to be stored. Can be any R object.
    set_meta = function(key, value) {
      if (!is.character(key) || length(key) != 1) {
        stop("Key must be a single character string.")
      }
      self$metadata[[key]] <- value
      invisible(self)
    },
    #' @description
    #' Retrieve a metadata value for a given key.
    #' @param key The name of the metadata attribute to retrieve.
    #' @param default The value to return if the key is not found.
    #' @return The metadata value, or the default value if not found.
    get_meta = function(key, default = NULL) {
      if (!is.character(key) || length(key) != 1) {
        stop("Key must be a single character string.")
      }
      if (exists(key, where = self$metadata)) {
        return(self$metadata[[key]])
      } else {
        return(default)
      }
    },
    #' @description
    #' Add a dataset to the pipeline's internal storage.
    #' @param name The name to assign to the dataset (character).
    #' @param data The dataset object to store (e.g., a data frame).
    add_dataset = function(name, data) {
      self$datasets[[name]] <- data

      self$add_log(glue("Dataset '{name}' added."))
      self$add_log(glue("'{name}' dimensions: [ {nrow(data)} rows x {ncol(data)} cols ]\n"))
    },

    #' @description
    #' Retrieve a dataset from the pipeline's storage.
    #' @param name The name of the dataset to retrieve.
    #' @return The dataset object associated with the given name.
    get_dataset = function(name) {
      self$datasets[[name]]
    },

    #' @description
    #' Add a timestamped message to the pipeline's log.
    #' @param message The message string to add to the log.
    add_log = function(message) {
      log_entry <- private$format_log_message(message)
      private$.log[[length(private$.log) + 1]] <- log_entry
      cat(log_entry, "\n")
    },

    #' @description
    #' Retrieve all log messages.
    #' @param formatted Logical. Whether to format logs.
    #' @return A character vector of all log entries.
    get_logs = function(formatted = TRUE) {
      # Retrieve all log messages
      logs <- unlist(private$.log)

      # Handle case with no logs
      if (length(logs) == 0) {
        cat("No logs recorded.\n")
        return(invisible(self))
      }

      if (formatted) {
        # If formatted = TRUE, print a nice summary
        cat("---- Pipeline Logs ----\n")
        for (i in seq_along(logs)) {
          cat(sprintf("[%d] %s\n", i, logs[i]))
        }

      } else {
        # If formatted = FALSE, return the raw vector (original behavior)
        return(logs)
      }
    },

    #' @description
    #' Ends the pipeline run and writes the log to a local file
    #' @returns Returns the path to the log file.
    end_pipeline = function() {
      self$add_log(glue("Pipeline {self$pipeline_id} ended. Writing logs to file."))

      if (!dir.exists("_logs")) {
        dir.create(path = "_logs", showWarnings = FALSE)
      }

      log_file <- glue("_logs/{private$.run_id}.log")

      content <- self$get_logs(formatted = FALSE)
      writeLines(content, log_file)
      return(log_file)
    },

    #' @description Overrides default print method. Prints the Pipeline Name and Metadata
    #' @param ... Further arguments passed to or from other methods. (Currently not used).
    print = function(...) {
      cat("----", self$pipeline_name, "----\n")
      cat("   ID:", self$pipeline_id, "\n")
      cat("   Date:", format(Sys.time(), '%Y-%m-%d'), "\n")

      if (length(self$metadata) > 0) {
        cat("   Metadata:\n")
        # Loop through and print each key-value pair
        for (key in names(self$metadata)) {
          # Use sprintf for clean, aligned formatting
          cat(sprintf("      - %-15s: %s\n", key, self$get_meta(key)))
        }
      } else {
        cat("   Metadata: [None]\n")
      }

      if (length(self$datasets) > 0) {
        cat("   Datasets:\n")
        for (nm in names(self$datasets)) {
          # Get the specific dataset to make the code cleaner
          dataset <- self$datasets[[nm]]

          # Use sprintf with placeholders for the name, row count, and column count
          cat(sprintf("      - %-15s: [ %d rows x %d cols ]\n",
                      nm,
                      nrow(dataset),
                      ncol(dataset)))
        }
      } else {
        cat("    Datasets: [None]\n")
      }
      invisible(self)
    }
  ),

  private = list(
    .env = NULL,
    .run_id = NULL,
    .log = list(),
    # Helper function to format log messages
    format_log_message = function(message) {
      timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      paste0("[", timestamp, "] ", message)
    },
    capture_environment = function() {
      private$.env <- list(
        config = Sys.getenv("R_CONFIG_ACTIVE", unset = "default"),
        sysname = Sys.info()[["sysname"]],
        user = Sys.info()[["user"]],
        node = Sys.info()[["nodename"]]
      )
    }
  )
)
