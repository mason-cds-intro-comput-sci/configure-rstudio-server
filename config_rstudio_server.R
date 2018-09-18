#!/usr/bin/env Rscript

configure_rstudio <- function(threads = 4) {
  setup_mode <- choose_setup_mode()
  if (setup_mode == 1) {
    user_info <- get_user_info()
    install_usethis_and_remotes_pkgs(threads = threads)
    configure_renviron()
    configure_git(user_info$user_name, user_info$user_email)
    tell_user_to_restart_session()
  } else if (setup_mode == 2) {
    install_course_dependencies(threads = threads)
  }
}

choose_setup_mode <- function() {
  setup_mode <- NA
  while(is.na(setup_mode)) {
    cat(
      paste0(
        "\nRStudio Server setup options\n\n",
        "  1. First-time setup\n",
        "  2. Install packages for CDS 101\n\n"
      )
    )
    setup_mode <- readline("Enter setup option: ")
    setup_mode <- ifelse(grepl("[^12]", setup_mode), NA, as.numeric(setup_mode))
  }

  setup_mode
}

get_user_info <- function() {
  user_info_correct <- FALSE
  while(!user_info_correct) {
    first_name <- ask_for_user_info("first name")
    last_name <- ask_for_user_info("last name")
    email_address <- ask_for_user_info("email address")
    cat(
      paste0(
        "You entered the following information:\n",
        "Name: ",
        first_name,
        " ",
        last_name,
        "\n",
        "Email: ",
        email_address
      )
    )
    user_info_correct <- ask_yes_no("Is this correct?")
  }

  list(
    user_name = paste(first_name, last_name),
    user_email = email_address
  )
}

ask_yes_no <- function(yes_no_question_text) {
  response <- NA
  while(is.na(response)) {
    response <- tolower(as.character(readline(paste(yes_no_question_text, "[y/n] "))))
    response <- ifelse(grepl("[^yn]", response), NA, response)
  }

  ifelse(grepl("y", response), TRUE, FALSE)
}

ask_for_user_info <- function(info_type) {
  info <- -1
  while(is.na(info) | is.numeric(info)) {
    info <- readline(paste0("Enter your ", info_type, ": "))
    info <- ifelse(grepl("[[:alpha:]]", info), as.character(info), -1)
  }

  info
}

configure_renviron <- function() {
  env_path <- fs::path(
    "/opt/texlive/2018/bin/x86_64-linux:",
    "/usr/local/sbin:",
    "/usr/local/bin:",
    "/usr/sbin:",
    "/usr/bin"
  )
  env_path_attribute <- paste(
    "PATH",
    env_path,
    sep = "="
  )

  env_r_libs_site <- fs::path("/usr/lib64/R/library")
  env_r_libs_site_attribute <- paste(
    "R_LIBS_SITE",
    env_r_libs_site,
    sep = "="
  )

  renviron_file <- fs::path(fs::path_home(), ".Renviron")
  fs::file_create(path = renviron_file)
  fs::file_chmod(path = renviron_file, mode = "600")
  usethis::write_union(
    path = renviron_file,
    lines = c(env_path_attribute, env_r_libs_site_attribute)
  )
}

configure_git <- function(user_name, user_email) {
  usethis::use_git_config(
    scope = "user",
    user.name = user_name,
    user.email = user_email
  )
}

install_usethis_and_remotes_pkgs <- function(threads) {
  install.packages(
    pkgs = c("usethis", "remotes"),
    repos = "https://cran.rstudio.com",
    Ncpus = threads
  )
}

tell_user_to_restart_session <- function() {
  todo(
    "Restart RStudio Server session by clicking the Red Button in the ",
    "upper right-hand corner."
  )
  todo(
    "Resume setup after the restart by reloading the ",
    "configure-rstudio-server project, and then sourcing the ",
    "config_rstudio_server.R file:"
  )
  code_block("source(\"config_rstudio_server.R\")", copy = FALSE)
  todo(
    "Select setup option {value(2)} to install packages needed for ",
    "CDS 101."
  )
}

install_course_dependencies <- function(threads) {
  remotes::install_deps(threads = threads)
}

# Helpers --------------------------------------------------------------------

## Source code from R/style.R in r-lib/usethis
## URL: https://github.com/r-lib/usethis/blob/master/R/style.R
##
## anticipates usage where the `...` bits make up one line
##
## 'usethis.quiet' is an undocumented option; anticipated usage:
##   * eliminate `capture_output()` calls in usethis tests
##   * other packages, e.g., devtools can call usethis functions quietly
cat_line <- function(..., quiet = getOption("usethis.quiet", default = FALSE)) {
  if (quiet) return(invisible())
  cat(..., "\n", sep = "")
}

todo_bullet <- function() crayon::red(clisymbols::symbol$bullet)
done_bullet <- function() crayon::green(clisymbols::symbol$tick)

## adds a leading bullet
bulletize <- function(line, bullet = "*") {
  paste0(bullet, " ", line)
}

collapse <- function(x, sep = ", ", width = Inf, last = "") {
  if (utils::packageVersion("glue") > "1.2.0") {
    utils::getFromNamespace("glue_collapse", "glue")(x, sep = sep, width = Inf, last = last)
  } else {
    utils::getFromNamespace("collapse", "glue")(x = x, sep = sep, width = width, last = last)
  }
}

## glue into lines stored as character vector
glue_lines <- function(lines, .envir = parent.frame()) {
  unlist(lapply(lines, glue::glue, .envir = .envir))
}


# Functions designed for a single line ----------------------------------------
todo <- function(..., .envir = parent.frame()) {
  out <- glue::glue(..., .envir = .envir)
  cat_line(bulletize(out, bullet = todo_bullet()))
}

done <- function(..., .envir = parent.frame()) {
  out <- glue::glue(..., .envir = .envir)
  cat_line(bulletize(out, bullet = done_bullet()))
}


# Function designed for several lines -------------------------------------

## ALERT: each individual bit of `...` is destined to be a line
code_block <- function(..., copy = interactive(), .envir = parent.frame()) {
  lines <- glue_lines(c(...), .envir = .envir)
  block <- paste0("  ", lines, collapse = "\n")
  if (copy && clipr::clipr_available()) {
    clipr::write_clip(collapse(lines, sep = "\n"))
    message("Copying code to clipboard:")
  }
  cat_line(crayon::make_style("darkgrey")(block))
}


# Inline styling functions ------------------------------------------------

## use these inside todo(), done(), and code_block()
## ^^ and let these functions handle any glue()ing ^^
field <- function(...) {
  x <- paste0(...)
  crayon::green(x)
}

value <- function(...) {
  x <- paste0(...)
  crayon::blue(encodeString(x, quote = "'"))
}

code <- function(...) {
  x <- paste0(...)
  crayon::make_style("darkgrey")(encodeString(x, quote = "`"))
}

unset <- function(...) {
  x <- paste0(...)
  crayon::make_style("lightgrey")(x)
}
