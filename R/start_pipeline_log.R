#' Initialize a Pipeline Log
#'
#' This function initializes a structured log for an ETL pipeline run,
#' capturing key metadata such as the pipeline's name, the user running it,
#' and the start time.
#'
#' @param pipeline_name A character string detailing the name of the pipeline.
#' @param user A character string for the user or service principal running the pipeline.
#'        Defaults to the system's username.
#' @param description A brief character string describing the pipeline's purpose.
#'
#' @return A tibble (a modern data frame) containing the initial pipeline metadata.
#'
#' @export
#' @importFrom tibble tibble
#'
#' @examples
#' # Start a log for a daily sales data pipeline
#' my_log <- start_pipeline_log(
#'   pipeline_name = "Daily Sales ETL",
#'   description = "Loads daily sales data from source to warehouse."
#' )
#' print(my_log)
#'
start_pipeline_log <- function(pipeline_name,
                               user = Sys.getenv("USERNAME"),
                               description = "") {

  tibble::tibble(
    pipeline_name = pipeline_name,
    run_user = user,
    run_description = description,
    run_start_time_utc = Sys.time()
  )


}
