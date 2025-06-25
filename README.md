constRuct
================

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`constRuct` provides a simple yet powerful object-oriented framework for
creating stateful and reusable ETL (Extract, Transform, Load) pipelines
in R. It uses R6 classes to encapsulate parameters, data sets, and logs
for each pipeline run, promoting code that is clean, modular, and easy
to maintain. It includes a base class for core functionality and an
example of an inherited class for interacting with Microsoft Azure Blob
Storage.

## Features

- **Stateful Objects**: Each pipeline run is an object that holds its
  own parameters, datasets, and logs.
- **Built-in Logging**: Automatically timestamped logging is available
  for every step of your process.
- **Parameter Management**: Easily pass and store parameters for a
  pipeline run.
- **Extensible by Design**: Inherit from `PipelineBase` to create
  specialized pipelines for different data sources or services (e.g.,
  databases, other cloud providers, APIs).
- **Azure Integration**: The `AzurePipe` class provides ready-to-use
  methods for connecting to Azure Blob Storage to list containers and
  upload files.

## Installation

You can install the development version of `constRuct` from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("mtthweklnd/constRuct")
```

## Setup for Azure Integration

To use the `AzurePipe` class, you must provide storage credentials as
environment variables. The recommended way to do this is by adding them
to an `.Renviron` file in your project’s root directory.

***NOTE***: These examples utilize the Azurite emulator for local
development:
[MicrosoftDocs/azure-docs](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/storage/common/storage-use-emulator.md)

Your `.Renviron` file should contain:

``` r
# 'Azurite' emaulator endpoint details
AZURE_BLOB_ENDPOINT="http://127.0.0.1:10000/devstoreaccount1"
AZURE_KEY="Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
```

## Core Concepts: `PipelineBase`

The foundation of the package is `PipelineBase`. It provides the core
functionality for logging and managing datasets within a pipeline
object.

1.  Initialize a pipeline object

``` r
library(constRuct)
library(glue)

# After loading the package, the R6 class generator is available directly.
local_pipeline <- constRuct::PipelineBase$new(
  pipeline_name = "Office Data Processing",
  pipeline_id = "data-processing",
  metadata = list(Office = "Carlsbad", Department = "Underwriting")
)
#> [2025-06-24 19:21:13] Pipeline 'Office Data Processing' initialized.
```

2.  Add and retrieve datasets from the object’s internal state

``` r

project_sites <- data.frame(
  site_id = c("A-1", "B-2", "C-3"),
  location = c("San Diego", "New York", "Chicago")
)

local_pipeline$add_dataset(name = "sites", data = project_sites)
#> [2025-06-24 19:21:13] Dataset 'sites' added. 
#> [2025-06-24 19:21:13] 'sites' dimensions: [ 3 rows x 2 cols ]

retrieved_data <- local_pipeline$get_dataset("sites")

print(head(retrieved_data))
#>   site_id  location
#> 1     A-1 San Diego
#> 2     B-2  New York
#> 3     C-3   Chicago
```

3.  View the execution log at any time

``` r
# All steps are automatically logged with timestamps.
local_pipeline$get_logs()
#> ---- Pipeline Logs ----
#> [1] [2025-06-24 19:21:13] Pipeline 'Office Data Processing' initialized.
#> [2] [2025-06-24 19:21:13] Dataset 'sites' added.
#> [3] [2025-06-24 19:21:13] 'sites' dimensions: [ 3 rows x 2 cols ]
```

4.  Custom print method

``` r
print(local_pipeline)
#> ---- Office Data Processing ----
#>    ID: data-processing 
#>    Date: 2025-06-24 
#>    Metadata:
#>       • Office         : Carlsbad
#>       • Department     : Underwriting
#>    Datasets:
#>       • sites          : [ 3 rows x 2 cols ]
```

## Extending the Framework: AzurePipe

`AzurePipe` inherits all the methods of `PipelineBase` and adds new
capabilities for interacting with Azure Blob Storage. This example
demonstrates how to initialize the pipeline, interact with Azure, and
upload the pipeline’s own log file.

1.  Initialize the Azure-aware pipeline

``` r

# The constructor automatically connects to your Azure endpoint.
azure_pipeline <- AzurePipe$new(
  pipeline_name = "Daily Report to Azure",
  pipeline_id = "daily-azure-report",
  metadata = list(division = "Finance", program = "Expenses")
)
#> [2025-06-24 19:21:13] Pipeline 'Daily Report to Azure' initialized. 
#> [2025-06-24 19:21:13] Connected to Azure Blob endpoint: http://127.0.0.1:10000/my-test-account
```

2.  List available containers using the `get_containers` active binding

``` r
containers <- azure_pipeline$get_containers

print(sapply(containers, function(c) c$name))
#>   database       logs    targets 
#> "database"     "logs"  "targets"
```

3.  Run a process using inherited methods from `PipelineBase`

``` r
azure_pipeline$add_log("Generating daily summary data.")
#> [2025-06-24 19:21:13] Generating daily summary data.

daily_summary <- data.frame(
  date = Sys.Date(),
  vendor = "VendCo INC",
  amount_due = round(runif(1, 100, 500),2)
)

azure_pipeline$add_dataset("summary_data", daily_summary)
#> [2025-06-24 19:21:13] Dataset 'summary_data' added. 
#> [2025-06-24 19:21:13] 'summary_data' dimensions: [ 1 rows x 3 cols ]
azure_pipeline$get_dataset("summary_data")
#>         date     vendor amount_due
#> 1 2025-06-24 VendCo INC     207.48
azure_pipeline$add_dataset("mtcars_data", mtcars)
#> [2025-06-24 19:21:13] Dataset 'mtcars_data' added. 
#> [2025-06-24 19:21:13] 'mtcars_data' dimensions: [ 32 rows x 11 cols ]
```

4.  Use a specialized method to upload the log to Azure

``` r
azure_pipeline$end_pipeline()
#> [2025-06-24 19:21:13] Pipeline daily-azure-report ended. Writing logs to file. 
#> [2025-06-24 19:21:13] Uploading log file 'run-daily-azure-report-20250624.log' to container 'logs'. 
#> [2025-06-24 19:21:13] Log file successfully uploaded.
```

5.  Verify the upload by listing blobs

``` r
print(azure_pipeline$list_blobs("logs"))
#>                                  name size isdir  blobtype
#> 1                            log_test  253 FALSE BlockBlob
#> 2             run-20250622-124752.log  405 FALSE BlockBlob
#> 3             run-20250622-125707.log  405 FALSE BlockBlob
#> 4             run-20250622-130321.log  405 FALSE BlockBlob
#> 5             run-20250622-133546.log  364 FALSE BlockBlob
#> 6 run-daily-azure-report-20250622.log  407 FALSE BlockBlob
#> 7 run-daily-azure-report-20250624.log  545 FALSE BlockBlob
#> 8          run-test-name-20250622.log  430 FALSE BlockBlob
```
