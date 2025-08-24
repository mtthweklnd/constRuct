#' @title ETL Pipeline R6 Class
#' @description
#' A base R6 class for creating and managing stateful ETL pipelines. It handles
#' parameter validation, dataset storage, and logging.
#' @importFrom glue glue
#' @importFrom R6 R6Class
#' @import logger
#' @export
PipelineBase <- R6::R6Class(
  "PipelineBase",
  public = list(
    # --- PUBLIC FIELDS ---
    #' @field name Proper name of the pipeline
    name = NULL,

    #' @field id Logging identifier for this pipeline.
    id = NULL,

    # --- PUBLIC METHODS ---
    #' @description constructor
    #' @param name Name of this pipeline.
    #' @param id Identifier for this pipeline, used in logging.
    #' @return A new `PipelineBase` object.
    initialize = function(name, id) {
      self$name <- name
      self$id <- id
      private$.env <- .system_snapshot
      private$.start_time <- Sys.time()

      private$.run_id <- glue::glue(
        "run-{id}-{format(Sys.time(), '%Y%m%d')}"
      )

      private$.start_logger()

      log_info("Pipeline initialized.")
    },
    #' @description Retrieves pipeline logs
    #' @return A vector with each log entry
    log_read = function() {
      readLines(private$.log_file)
    }
  ),
  private = list(
    .env = NULL,
    .start_time = NULL,
    .end_time = NULL,
    .run_id = NULL,
    .log_file = NULL,
    .logger_namespace = NULL,

    .start_logger = function() {
      # Create unique namespace for this pipeline
      private$.logger_namespace <- glue("{self$id}")

      # Create log file
      private$.log_file <- file.path(tempdir(), glue("{private$.run_id}.log"))

      # Set logging threshold
      logger::log_threshold(
        logger::DEBUG,
        namespace = private$.logger_namespace
      )

      pipeline_layout <- logger::layout_glue_generator(
        format = '{level} [{format(time, "%Y-%m-%d %H:%M:%S")}] [{ns}]: {msg}'
      )

      logger::log_layout(pipeline_layout, namespace = private$.logger_namespace)

      # Set up file and console appender
      logger::log_appender(
        logger::appender_tee(private$.log_file),
        namespace = private$.logger_namespace
      )
    }
  )
)
