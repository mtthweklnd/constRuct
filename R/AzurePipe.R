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
    #' @field pipeline_name Proper name of the pipeline
    pipeline_name = NULL,

    #' @field pipeline_id Unique Identifier for this pipeline
    pipeline_id = NULL,

    #' @field params A list to store parameters used by the pipeline.
    params = NULL,

    #' @field datasets A list to store datasets (e.g., data frames) used or created.
    datasets = NULL,

    # --- PUBLIC METHODS ---
    #' @description constructor
    #' @param pipeline_name Name of this pipeline.
    #' @param pipeline_id Identifier for this pipeline
    #' @param division The division this data belongs to.
    #' @param program The program subset this data is for.
    #' @return A new `PipelineBase` object.
    initialize = function(pipeline_name,
                          pipeline_id,
                          division = NULL,
                          program = NULL) {
      self$pipeline_name <- pipeline_name
      self$pipeline_id <- pipeline_id
      private$.run_id <- glue("run-{pipeline_id}-{format(Sys.time(), '%Y%m%d')}")

      private$capture_environment()
      self$params <- list(division = division, program = program)
      self$datasets <- list()
      self$add_log(glue("Pipeline '{self$pipeline_name}' initialized."))

    },

    #' @description
    #' Add a dataset to the pipeline's internal storage.
    #' @param name The name to assign to the dataset (character).
    #' @param data The dataset object to store (e.g., a data frame).
    add_dataset = function(name, data) {
      self$datasets[[name]] <- data
      self$add_log(glue("Dataset '{name}' added."))
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
    #' @return A character vector of all log entries.
    get_logs = function() {
      unlist(private$.log)
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

#' @title Azure Blob Storage Pipeline R6 Class
#' @description
#' Extends `PipelineBase` to provide methods for interacting with Azure
#' Blob Storage. Inherits parameter handling and logging.
#' @importFrom R6 R6Class
#' @importFrom AzureStor blob_endpoint blob_container list_blob_containers create_blob_container list_blobs get_storage_metadata upload_blob
#' @importFrom glue glue
#' @export
AzurePipe <- R6::R6Class(
  "AzurePipe",
  inherit = PipelineBase,
  public = list(
    # --- PUBLIC METHODS ---
    #' @description constructor
    #' @param pipeline_name Name of this pipeline.
    #' @param pipeline_id Identifier for this pipeline
    #' @param division The division this data belongs to.
    #' @param program The program subset this data is for.
    #' @return A new `AzurePipe` object.
    initialize = function(pipeline_name,
                          pipeline_id,
                          division = NULL,
                          program = NULL) {
      super$initialize(pipeline_name = pipeline_name,
                       pipeline_id = pipeline_id,
                       division = division,
                       program = program)

      azure_endpoint <- Sys.getenv("AZURE_BLOB_ENDPOINT")
      azure_key <- Sys.getenv("AZURE_KEY")

      if (azure_endpoint == "") {
        stop("AZURE_BLOB_ENDPOINT not set in environment variables.",
             call. = FALSE)
      }
      if (azure_key == "") {
        stop("AZURE_KEY not set in environment variables.", call. = FALSE)
      }

      private$.endp <- AzureStor::blob_endpoint(endpoint = azure_endpoint, key = azure_key)
      self$add_log(glue("Connected to Azure Blob endpoint: {private$.endp$url}"))

      all_containers <- self$get_containers
      container_names <- sapply(all_containers, function(c)
        c$name)
      if (!("logs" %in% container_names)) {
        self$add_log("Creating 'logs' container as it does not exist.")
        AzureStor::create_blob_container(private$.endp, "logs")
      }

      private$.log_container <- AzureStor::blob_container(private$.endp, "logs")
    },

    #' @description
    #' Lists blobs in a specified Azure container.
    #' @param container_name The name of the container (character).
    #' @return A data frame of blob properties from `AzureStor::list_blobs`.
    list_blobs = function(container_name) {
      cont <- AzureStor::blob_container(private$.endp, container_name)
      AzureStor::list_blobs(cont)
    },

    #' @description
    #' Gets the user-defined metadata for a specific blob.
    #' @param container_name The name of the container where the blob resides.
    #' @param blob_name The name of the blob.
    #' @return A named list of metadata key-value pairs.
    get_blob_metadata = function(container_name, blob_name) {
      self$add_log(glue("Getting metadata for blob: '{blob_name}'"))
      cont <- AzureStor::blob_container(private$.endp, container_name)
      AzureStor::get_storage_metadata(cont, blob_name)
    },


    #' @description
    #' Uploads text content as a log file to a specified container.
    #' @param file_content A character vector containing the text to upload.
    upload_log_file = function(file_content) {
      log_file <- glue("{private$.run_id}.log")
      self$add_log(
        glue(
          "Uploading log file to container '{private$.log_container$name}' as '{log_file}'"
        )
      )

      temp_file <- tempfile(fileext = ".log")
      on.exit(unlink(temp_file))

      writeLines(file_content, temp_file)
      AzureStor::upload_blob(private$.log_container, src = temp_file, dest = log_file)

    }
  ),
  active = list(
    #' @field get_containers
    #' List of available container objects for the active endpoint. Read-only.
    #' @returns A list of `blob_container` objects
    get_containers = function() {
      if (is.null(private$.endp))
        return(list())
      tryCatch({
        AzureStor::list_blob_containers(private$.endp)
      }, error = function(e) {
        warning("Could not connect to Azure to list containers. Returning empty list.")
        return(list())
      })
    }

  ),
  private = list(.endp = NULL, .log_container = NULL)
)
