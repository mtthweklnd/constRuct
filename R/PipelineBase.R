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
    initialize = function(
      pipeline_name,
      pipeline_id,
      division = NULL,
      program = NULL
    ) {
      self$pipeline_name <- pipeline_name
      self$pipeline_id <- pipeline_id
      private$.run_id <- glue::glue(
        "run-{pipeline_id}-{format(Sys.time(), '%Y%m%d')}"
      )

      private$.start_logger()
      private$capture_environment()
      self$params <- list(division = division, program = program)

      log_info("Pipeline '{self$pipeline_name}' initialized.")
    },
    read_log = function() {
      readLines(private$.log_file)
    }
  ),
  private = list(
    .env = NULL,
    .run_id = NULL,
    .log_file = NULL,
    .start_logger = function() {
      private$.log_file <- tempfile(fileext = ".log")
      log_threshold(INFO)
      log_appender(appender_tee(private$.log_file))
      log_layout(layout_glue_generator(
        format = '{level} [{format(Sys.time(), "%Y-%m-%d %H:%M:%S")}]: {msg}'
      ))
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
pipe <- PipelineBase$new("pipeline_name",
                          "pipeline_id",
                          division = "NULL",
                          program = "NULL")
pipe$read_log()

logger::get_logger_meta_variables()
