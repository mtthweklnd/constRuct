' Write a Log Object to Azure Blob Storage
#'
#' This function serializes a log object (like one from `start_pipeline_log`)
#' and uploads it to a specified container in Azure Blob Storage. It is
#' configured to connect to a local Azurite emulator by default.
#'
#' @param log_object The R object (e.g., a tibble or list) to be saved.
#' @param container_name A character string for the name of the blob container.
#' @param blob_name A character string for the name of the blob. A default name
#'        is generated using the pipeline name and timestamp if not provided.
#' @param connection_string The connection string for Azure Storage. It is
#'        highly recommended to use the default, which pulls from the
#'        `AZURE_STORAGE_CONNECTION_STRING` environment variable.
#'
#' @return Invisibly returns the path to the uploaded blob.
#'
#' @export
#' @importFrom AzureStor blob_container upload_blob
#' @importFrom rlang inform
#'
#' @examples
#' \dontrun{
#' # First, set your environment variable for Azurite
#' Sys.setenv(
#'   AZURE_STORAGE_CONNECTION_STRING = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;
#'   AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;
#'   BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
#' )
#'
#' # Create a log
#' pipeline_log <- start_pipeline_log(
#'   pipeline_name = "Local Test ETL",
#'   description = "Testing the full logging workflow with Azurite."
#' )
#'
#' # Write the log to a container named "logs"
#' write_log_to_blob(pipeline_log, container_name = "logs")
#' }
write_log_to_blob <- function(blob_container,
                              log_object,
                              blob_name = NULL) {

  # if (connection_string == "") {
  #   stop("Connection string not found. Please set the 'AZURE_STORAGE_CONNECTION_STRING' environment variable.", call. = FALSE)
  # }

  # Generate a default blob name if one isn't provided
  # if (is.null(blob_name)) {
  #   # Assumes 'pipeline_name' and 'run_start_time_utc' exist in the log object
  #   run_timestamp <- format(log_object$run_start_time_utc, "%Y%m%d_%H%M%S")
  #   blob_name <- glue::glue("{log_object$pipeline_name}/{run_timestamp}_log.rds")
  # }
  # Get a client for the blob container
  # container_client <- AzureStor::blob_container(
  #   name = container_name,
  #   connection_string = connection_string
  # )

  # Save the R object to a temporary file in RDS format
  temp_file <- tempfile(fileext = ".rds")
  saveRDS(log_object, file = temp_file)
  on.exit(unlink(temp_file)) # Ensure temp file is deleted even if function errors

  # Upload the temporary file to the blob
  AzureStor::upload_blob(container = blob_container,
    src = temp_file,
    dest = blob_name
  )


  # Provide a confirmation message to the user
  rlang::inform(paste("Log successfully written to:", blob_name))

  # I've added a dependency on `glue` here for easier string creation
  # and `rlang` for better messages. Let's add them to the DESCRIPTION file.
  # Run `usethis::use_package("glue")` and `usethis::use_package("rlang")`

  invisible(blob_name)
}
