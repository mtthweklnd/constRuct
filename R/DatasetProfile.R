#' DatasetProfile Class
#'
#' @description
#' A container for managing a dataset, its metadata, schema, and status within
#' a data pipeline. This class helps ensure data provenance and facilitates
#' reproducible workflows.
#'
#' @details
#' The class is initialized with a name and data. It can track dependencies,
#' status (e.g., "raw", "cleaned"), and a formal data schema using the
#' `pointblank` package.
#' @importFrom assertthat assert_that
DatasetProfile <- R6::R6Class(
  "DatasetProfile",
  public = list(
    #' @field name A character string for the dataset's name.
    name = NULL,
    
    #' @field source A character string for the data's origin.
    source = NULL,
    
    #' @field schema A pointblank `col_schema` object.
    schema = NULL,
    
    #' @field metadata A list for storing any other attributes.
    metadata = list(),
    
    #' @description
    #' Create a new profile object.
    #' @param name `character`. The name of the dataset.
    #' @param source `character`. The source of the data (e.g., file path).
    #' @param schema A `col_schema` object created with `pointblank::col_schema()`.
    #' @param metadata `list`. An optional list for ancillary metadata.
    initialize = function(name, source, schema, metadata = list()) {
      
      assertthat::assert_that(
        is.character(name) && length(name) == 1 || nchar(name) != 0,
        msg = "Dataset 'name' must be a non-empty character string."
      )
      
      assertthat::assert_that(
        inherits(schema, 'col_schema'),
        msg = 
        "Provided schema is not a pointblank::col_schema object."
      )
      
      assertthat::assert_that(
        is.list(metadata),
        msg = "Provided 'metadata' must be a list."
      )
      
      self$name <- name
      self$source <- source
      self$schema <- schema
      self$metadata <- metadata
      
      private$add_log(glue::glue("Dataset entity '{self$name}' initialized."))
    },
    #' @description
    #' Validate a dataframe against the object's schema.
    #' @param df The dataframe to validate.
    #' @return A pointblank `agent` object containing the validation results.
    validate = function(df) {
      cat("Validating", deparse(substitute(df)), "against the '", self$name, "' spec...\n", sep = "")
      
      # col_validation returns a pointblank agent with the results
      agent <- col_validation(df, self$schema)
      return(agent)
    }
  ),
  private = list(
    # Internal reference to the parent pipeline's logger (optional, but useful)
    .pipeline_logger = NULL, # Would be set by PipelineBase when adding the DatasetProfile
    
    # Helper function to send logs (for demonstration, would ideally use .pipeline_logger)
    add_log = function(message) {
      cat(glue::glue("[DatasetProfile:{Sys.time()}] {message} \n"))
    }
  )
)
