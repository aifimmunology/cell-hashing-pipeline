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
  make_option(opt_str = c("-t","--out_tbl"),
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

args <- parse_args(OptionParser(option_list = option_list))

rmarkdown::render(
  input = "hto_processing.Rmd",
  params = list(in_type = args$in_type,
                in_file = args$in_file,
                in_key  = args$in_key,
                out_mat = args$out_mat,
                out_tbl = args$out_tbl),
  output_file = args$out_html,
  quiet = TRUE
)