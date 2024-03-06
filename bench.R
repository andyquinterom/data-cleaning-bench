n_sensors <- 1
n_iterations <- 1

prelude <- function() {
  # Create Data Directory
  if (!dir.exists("data")) {
    dir.create("data")
  }

  # Install R Packages
  required_packages <- c("dplyr", "purrr", "readr", "tidyr", "tibble", "microbenchmark")
  new_packages <- required_packages |>
    setdiff(installed.packages()[, "Package"])

  if (length(new_packages) > 0) {
    install.packages(new_packages)
  }

  # Compile Rust Code
  system2(
    "cargo",
    args = c("build", "--release", "--manifest-path", "rust_limpieza/Cargo.toml"),
    stderr = NULL,
    stdin = "",
    stdout = NULL
  )

  # Generate Fake Data
  system2(
    "Rscript",
    args = c("fake_airquality.R", as.character(n_sensors)),
    stderr = NULL,
    stdin = "",
    stdout = NULL
  )
}

prelude()

library(microbenchmark)

r_tidyverse <- function() {
  if (file.exists("data/air_quality_r_tidy.csv")) {
    file.remove("data/air_quality_r_tidy.csv")
  }
  system2("Rscript", "r_tidyverse/r_tidyverse.R", stderr = NULL, stdin = "", stdout = NULL)
}

rust_polars <- function() {
  if (file.exists("data/air_quality_rust.csv")) {
    file.remove("data/air_quality_rust.csv")
  }
  system2("./rust_limpieza/target/release/rust_limpieza", stderr = NULL, stdin = "", stdout = NULL)
}

results <- microbenchmark(
  r_tidyverse(),
  rust_polars(),
  unit = "seconds",
  times = n_iterations
)

summary(results)

write.csv(results, "data/results.csv")
