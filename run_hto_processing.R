library(optparse)

option_list <- list(
  make_option(opt_str = c("-t","--in_type"),
              type = "character",
              default = NULL,
              help = "Type of HTO results. One of: cite, awk, test_cite, or test_awk",
              metavar = "character"),
  make_option(opt_str = c("-i","--in_file"),
              type = "character",
              default = NULL,
              help = "Input HTO result input file",
              metavar = "character"),
  make_option(opt_str = c("-k","--in_key"),
              type = "character",
              default = NULL,
              help = "Input HTO name key file",
              metavar = "character"),
  make_option(opt_str = c("-m","--out_mat"),
              type = "character",
              default = NULL,
              help = "Output HTO count matrix file",
              metavar = "character"),
  make_option(opt_str = c("-c","--out_cat"),
              type = "character",
              default = NULL,
              help = "Output HTO category table file",
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

if(is.null(args$in_key) & args$in_type %in% c("awk","cite")) {
  if(!file.exists(args$in_key)) {
    stop(paste("HTO name key file",args$in_key, "not found. Check file name, or omit -k to use a default file for TotalseqA Human HTOs."))
  }
} else if(!is.null(args$in_key) & args$in_type %in% c("awk","cite")) {
  args$in_key <- system.file("reference/TotalSeqA_human_hto_key.csv", package = "HTOparser")
}

file.copy(system.file("rmarkdown/hto_processing.Rmd", package = "HTOparser"),
          "./hto_processing.Rmd")

rmarkdown::render(
  input = "./hto_processing.Rmd",
  params = list(in_type = args$in_type,
                in_file = args$in_file,
                in_key  = args$in_key,
                out_mat = args$out_mat,
                out_tbl = args$out_cat),
  output_file = args$out_html,
  quiet = TRUE
)

file.remove("./hto_processing.Rmd")
