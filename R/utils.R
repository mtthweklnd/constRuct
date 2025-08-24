#' @title Check a named list of environment variables
#' @description This function iterates through a named list of values, checks if any are
#'   invalid (NULL, NA, or an empty string), and throws a descriptive error if any
#'   are found.
#' @param env_vars A named list where names are the environment variable names and
#'   values are their retrieved values.
#' @importFrom purrr keep
#' @importFrom assertthat assert_that
#' @return Returns `invisible(TRUE)` if all variables are valid.
check_env_vars <- function(env_vars) {
  invalid_vars_list <- purrr::keep(env_vars, ~ is.null(.x) || is.na(.x) || !nzchar(.x))
  invalid_var_names <- names(invalid_vars_list)
  
  assertthat::assert_that(
    length(invalid_var_names) == 0,
    msg = paste0(
      "Invalid or unset environment variables: ",
      paste(invalid_var_names, collapse = ", ")
    )
  )
  
  return(invisible(TRUE))
}
#' @title Snapshot the system information
#' @return A list with `config`, `sysname`, `user`, `node`
.system_snapshot <- function() {
  system <- list(
    config = Sys.getenv("R_CONFIG_ACTIVE", unset = "default"),
    sysname = Sys.info()[["sysname"]],
    user = Sys.info()[["user"]],
    node = Sys.info()[["nodename"]]
  )
  return(system)
}
