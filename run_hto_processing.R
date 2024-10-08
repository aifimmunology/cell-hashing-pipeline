library(optparse)

option_list <- list(
  make_option(opt_str = c("-t","--in_type"),
              type = "character",
              default = NULL,
              help = "Type of HTO results. One of: barcounter, cite, awk, test_cite, or test_awk",
              metavar = "character"),
  make_option(opt_str = c("-i","--in_file"),
              type = "character",
              default = NULL,
              help = "Input HTO result input file",
              metavar = "character"),
  make_option(opt_str = c("-k","--in_key"),
              type = "character",
              default = NULL,
              help = "Input Sample HTO name key file",
              metavar = "character"),
  make_option(opt_str = c("-s","--hash_key"),
              type = "character",
              default = NULL,
              help = "Input HTO ID and HTO barcode key file",
              metavar = "character"),
  make_option(opt_str = c("-w","--in_well"),
              type = "character",
              default = NULL,
              help = "Input WellID",
              metavar = "character"),
  make_option(opt_str = c("-c","--in_min_cutoff"),
              type = "character",
              default = "auto",
              help = "(Optional) Min. Cutoff value",
              metavar = "character"),
  make_option(opt_str = c("-e","--in_eel"),
              type = "character",
              default = "TRUE",
              help = "(Optional) Expect equal loading (TRUE/FALSE)",
              metavar = "character"),
  make_option(opt_str = c("-d","--out_dir"),
              type = "character",
              default = NULL,
              help = "Output Directory",
              metavar = "character"),
  make_option(opt_str = c("-o","--out_html"),
              type = "character",
              default = NULL,
              help = "Output HTML run summary file",
              metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)

args <- parse_args(opt_parser)

if(is.null(args$in_type)) {
  print_help(opt_parser)
  stop("No parameters supplied.")
}

if(!is.null(args$in_key) & args$in_type %in% c("barcounter","awk","cite")) {
  if(!file.exists(args$in_key)) {
    stop(paste("HTO name key file",args$in_key, "not found. Check file name, or omit -k to use a default file for TotalseqA Human HTOs."))
  }
} else if(is.null(args$in_key) & args$in_type %in% c("barcounter","awk","cite")) {
  args$in_key <- system.file("reference/SampleSheet_fallback.csv", package = "HTOparser")
}

if(!dir.exists(args$out_dir)) {
  dir.create(args$out_dir)
}

rmd_path <- file.path(args$out_dir,
                      paste0(args$in_well,
                             "_hto_processing.Rmd"))

file.copy(system.file("rmarkdown/hto_processing.Rmd", package = "HTOparser"),
          rmd_path,
          overwrite = TRUE)

rmarkdown::render(
  input = rmd_path,
  params = list(in_type = args$in_type,
                in_file = args$in_file,
                in_key  = args$in_key,
                hash_key  = args$hash_key,
                in_well = args$in_well,
                in_min_cutoff = args$in_min_cutoff,
                in_eel = args$in_eel,
                out_dir = args$out_dir),
  output_file = args$out_html,
  quiet = TRUE
)

file.remove(rmd_path)
