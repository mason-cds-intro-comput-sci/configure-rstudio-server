#!/usr/bin/env Rscript

configure_rstudio <- function(threads = 4) {
  user_info <- get_user_info()
  install_usethis_and_remotes_pkgs(threads = threads)
  configure_renviron()
  configure_git(user_info$user_name, user_info$user_email)
  install_course_dependencies(threads = threads)
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

install_course_dependencies <- function(threads) {
  remotes::install_deps(threads = threads)
}
