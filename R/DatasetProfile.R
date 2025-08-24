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
    
    #' @field status The current processing status of the dataset (e.g., "raw", "cleaned", "transformed").
    status = NULL,

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
      self$status <- "initialized"
    },

    #' @description Adds or updates a metadata entry.
    #' @param key Character. The metadata key.
    #' @param value Any type. The metadata value.
    add_metadata = function(key, value) {
      if (!is.character(key) || length(key) != 1 || nchar(key) == 0) {
        stop("Metadata 'key' must be a non-empty character string.")
      }
      self$metadata[[key]] <- value
    },

    #' @description Retrieves all metadata or a specific entry.
    #' @param key Character. Optional. If provided, returns the value for that key.
    #' @return A list of metadata or a specific metadata value.
    get_metadata = function(key = NULL) {
      if (is.null(key)) {
        return(self$metadata)
      }
      self$metadata[[key]]
    },

    #' @description Sets the processing status of the dataset.
    #' @param new_status Character. The new status.
    set_status = function(new_status) {
      self$status <- new_status
    }
  ),
  private = list(
   
    .pipeline_logger = NULL, 
    
    add_log = function(message) {
      cat(glue::glue("[DatasetProfile:{Sys.time()}] {message} \n"))
    }
  )
)
