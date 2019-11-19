library(optparse)

option_list <- list(
  make_option(opt_str = c("-i","--in_dir"),
              type = "character",
              default = NULL,
              help = "Input directory containing HDF5 files",
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

if(is.null(args$in_dir)) {
  print_help(opt_parser)
  stop("No parameters supplied.")
}

file.copy(system.file("rmarkdown/merge_h5_by_hash.Rmd", package = "H5weaver"),
          "./merge_h5_by_hash.Rmd")

rmarkdown::render(
  input = "./merge_h5_by_hash.Rmd",
  params = list(in_dir = args$in_dir,
                out_dir = args$out_dir),
  output_file = args$out_html,
  quiet = TRUE
)

file.remove("./merge_h5_by_hash.Rmd")
