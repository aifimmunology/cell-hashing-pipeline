args <- commandArgs(trailingOnly = TRUE)

rmarkdown::render(
  input = "hto_processing.Rmd",
  output_file = args[6],
  params = list(in_type = args[1],
                in_file = args[2],
                in_key  = args[3],
                out_mat = args[4],
                out_tbl = args[5])
)