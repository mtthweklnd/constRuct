#' Setup a Pipeline Environment
#'
#' Initializes all necessary components for an ETL pipeline run. This includes
#' creating a metadata log, a detailed file/console logger, a database
#' connection, and connecting to a pins board.
#'
#' @details
#' This function relies heavily on environment variables for securely handling
#' credentials for production services like Azure and Posit Connect.
#'
#' @param pipeline_name A character string for the name of the pipeline.
#' @param description A brief character string describing the pipeline's purpose.
#' @param db_type A character string specifying the database backend.
#'        Either `"azure_sql"` (default) or `"sqlite"`.
#' @param sqlite_db_path A character string path to the SQLite database file.
#'        Only used if `db_type = "sqlite"`. Defaults to "local_db.sqlite".
#' @param log_file_path The path where the detailed log file should be saved.
#'        Defaults to creating a timestamped log file in the current directory.
#'
#' @return A named list serving as the "pipeline context" object.
#'
#' @export
#' @importFrom DBI dbConnect dbDisconnect
#' @importFrom odbc odbc
#' @importFrom RSQLite SQLite
#' @importFrom pins board_connect
#' @importFrom log4r logger console_appender file_appender level info
#' @importFrom rlang inform abort
#'
#' @examples
#' \dontrun{
#' # To connect to SQLite for local development:
#' # First, create and seed the database using the helper script.
#' context_sqlite <- setup_pipeline(
#'   pipeline_name = "local-dev-pipeline",
#'   description = "A test run using the local SQLite database.",
#'   db_type = "sqlite"
#' )
#' DBI::dbDisconnect(context_sqlite$db_con)
#' }
setup_pipeline <- function(pipeline_name,
                           description,
                           db_type = c("azure_sql", "sqlite"),
                           sqlite_db_path = "local_db.sqlite",
                           log_file_path = NULL) {

  # --- 0. Argument Matching ---
  db_type <- match.arg(db_type)

  # --- 1. Initialize Metadata Log ---
  log_meta <- start_pipeline_log(
    pipeline_name = pipeline_name,
    description = description
  )
  rlang::inform(paste("Started metadata log for pipeline:", pipeline_name))

  # --- 2. Configure log4r Logger ---
  if (is.null(log_file_path)) {
    timestamp <- format(log_meta$run_start_time_utc, "%Y%m%d_%H%M%S")
    log_file_path <- paste0(pipeline_name, "_", timestamp, ".log")
  }

  file_appender <- log4r::file_appender(log_file_path, append = TRUE)
  console_appender <- log4r::console_appender()
  pipeline_logger <- log4r::logger(
    threshold = "INFO",
    appenders = list(console_appender, file_appender)
  )
  log4r::info(pipeline_logger, "File and console logger initialized.")

  # --- 3. Establish Database Connection (Conditional) ---
  db_con <- NULL
  if (db_type == "azure_sql") {
    log4r::info(pipeline_logger, "Attempting to connect to Azure SQL...")
    db_con <- tryCatch({
      con <- DBI::dbConnect(
        drv = odbc::odbc(),
        Driver = "ODBC Driver 17 for SQL Server",
        Server = Sys.getenv("AZURE_SQL_SERVER"),
        Database = Sys.getenv("AZURE_SQL_DB"),
        UID = Sys.getenv("AZURE_SQL_USER"),
        PWD = Sys.getenv("AZURE_SQL_PWD"),
        Port = 1433
      )
      log4r::info(pipeline_logger, "Successfully connected to Azure SQL database.")
      con
    }, error = function(e) {
      rlang::abort("Azure SQL connection failed. Check credentials and VPN.", parent = e)
    })
  } else if (db_type == "sqlite") {
    log4r::info(pipeline_logger, paste("Attempting to connect to SQLite DB at:", sqlite_db_path))
    db_con <- tryCatch({
      con <- DBI::dbConnect(RSQLite::SQLite(), dbname = sqlite_db_path)
      log4r::info(pipeline_logger, "Successfully connected to local SQLite database.")
      con
    }, error = function(e) {
      rlang::abort(paste("SQLite connection failed for file:", sqlite_db_path), parent = e)
    })
  }

  # --- 4. Connect to Pins Board (optional, for this example) ---
  pins_board <- tryCatch({
    board <- pins::board_connect()
    log4r::info(pipeline_logger, paste("Successfully connected to pins board:", board$name))
    board
  }, error = function(e) {
    log4r::info(pipeline_logger, "Skipping pins board connection: Not configured.")
    NULL # Don't abort, just allow it to fail gracefully for local dev
  })

  # --- 5. Return the Context Object ---
  rlang::inform("Pipeline setup complete. Returning context object.")
  list(
    log_meta = log_meta,
    logger = pipeline_logger,
    db_con = db_con,
    pins_board = pins_board
  )
}
