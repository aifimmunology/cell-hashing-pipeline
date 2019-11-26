# cell-hashing-pipeline

Scripts for processing cell hashing/Hash Tag Oligo (HTO) data

## Dependencies

This repository requires that `pandoc` and `libhdf5-devel` libraries are installed:
```
sudo apt-get install pandoc libhdf5-devel
```

It also depends on the `H5weaver`, `HTOparser`, `rmarkdown`, and `optparse` libraries.

`rmarkdown` and `optparse` are available from CRAN, and can be installed in R using:
```
install.packages("rmarkdown")
install.packages("optparse")
```

`HTOparser` is one of our own packages found in the aifimmunology Github repositories. Because it is a private repository, you may need to provided a [Github Personal Access Token](https://github.com/settings/tokens) for installation:
```
Sys.setenv(GITHUB_PAT = "[your_PAT_here]")
devtools::install_github("aifimmunology/HTOparser")
```

`H5weaver` is also found in the aifimmunology Github repositories. Install with:
```
Sys.setenv(GITHUB_PAT = "[your_PAT_here]")
devtools::install_github("aifimmunology/H5weaver")
```

## Processing HTO FASTQ files

`cell-hashing-pipeline` is compatible with results from the Python tool [`CITE-seq-Count`](https://github.com/Hoohm/CITE-seq-Count) and with a simple, `awk/sort/uniq` driven processing script.

For `CITE-seq-Count`, this repository includes a tag list that should be used for TotalSeqA Human HTOs:
```
git clone https://github.com/aifimmunology/cell-hashing-pipeline.git

CITE-seq-Count \
  -R1 Pool-16-HTO_S5_L001_R1_001.fastq.gz \
  -R2 Pool-16-HTO_S5_L001_R2_001.fastq.gz \
  -t cell-hashing-pipeline/cite-seq-count_taglist.csv \
  -cbf 1 \
  -cbl 16 \
  -umif 17 \
  -umil 26 \
  -cells 50000 \
  -o /shared/lucasg/pipeline_cellhashing_tests/data/pool16/
```

The `awk/sort/uniq` analysis version can be performed directly from the R1 and R2 HTO FASTQ files using:
```
paste <(zcat Pool-16-HTO_S5_L001_R1_001.fastq.gz) <(zcat Pool-16-HTO_S5_L001_R2_001.fastq.gz) | \
  awk '{if((NR+2)%4==0) {print substr($1,1,16) " " substr($2,1,15) " " substr($1,17,10)}}' | \
  sort | \
  uniq -u | \
  awk '{print $1 " " $2}' | \
  uniq -c | \
  awk '{if($1>10) {print $0}}' \
  > unfiltered_hto_counts_gt10.txt
```

## Interpreting/parsing HTO results

The tools above provide counts for each combination of cell and hash barcode. To convert these from counts to singlet/multiplet calls, these scripts use the [`HTOparser`](https://github.com/aifimmunology/HTOparser) R package, installed with:
```
devtools::install_github("aifimmunology/HTOparser")
```

Once installed, this repository can serve as a bridge to actually run the HTO interpretation, output files, and generate a summary report using the `run_hto_processing.R` wrapper script.

There are 6 parameters for this script:  
 - `-t or --in_type`: Either 'cite' or 'awk'  
 - `-i or --in_file`: The input file to process. Should be the output from `CITE-seq-Count` or the shell script, above.
 - `-k or --in_key`: A two-column CSV file without headers. The first column is each HTO barcode used, and the second is the name used for each barcode.
 - `-m or --out_mat`: A filename to use to output the count matrix (should end with .csv.gz)
 - `-c or --out_cat`: A filename to use to output the category table (should end with .csv.gz)
 - `-o or --out_html`: A filename to use to output the HTML summary report file
 
An example run for `CITE-seq-Count` results:
```
git clone https://github.com/aifimmunology/cell-hashing-pipeline.git

Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t cite \
  -i /shared/lucasg/pipeline_cellhashing_tests/data/pool16/HTO_umi_count_matrix.csv.gz \
  -k /shared/lucasg/pipeline_cellhashing_tests/data/hashing_pilot_key.csv \
  -m /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_count_matrix.csv.gz \
  -c /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_category_table.csv.gz \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_summary_report.html
```

An example run for awk/shell results:
```
Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t awk \
  -i /shared/lucasg/pipeline_cellhashing_tests/data/pool16/unfiltered_hto_counts_gt10.txt \
  -k /shared/lucasg/pipeline_cellhashing_tests/data/hashing_pilot_key.csv \
  -m /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_count_matrix.csv.gz \
  -c /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_category_table.csv.gz \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_summary_report.html
```

### Tests

Test runs can be performed using datasets provided with the `HTOparser` package using `-t test_cite` or `-t test_awk`. These require only the `-t` and `-o` parameters.

```
Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t test_cite \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/test_cite/hto_summary_report.html

Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t test_awk \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/test_awk/hto_summary_report.html
```

## Splitting cellranger .h5 files by hash

Once raw HTO counts have been processed to singlet/multiplet calls in the hto_category_table.csv.gz file, these results can be used to separate cells with functions in the [`H5weaver`](https://github.com/aifimmunology/H5weaver) R package, installed with:
```
devtools::install_github("aifimmunology/H5weaver")
```

Once installed, the `run_h5_split_by_hash.R` wrapper script can read cellranger filtered_feature_bc_matrix.h5 and use the outputs of the previous step to divide the cells into one .h5 per HTO.

There are 7 parameters for this script:  
 - `-i or --in_h5`: A filtered_feature_bc_matrix.h5 file generated by cellranger
 - `-l or --in_mol`: A molecule_info.h5 file generated by cellranger
 - `-m or --in_mat`: A HTO count matrix file generated by `run_hto_processing.R`
 - `-c or --in_cat`: A HTO category table file generated by `run_hto_processing.R`
 - `-w or --in_well`: A well name to apply to the output files
 - `-d or --out_dir`: A directory path to use to output the split .h5 file results
 - `-o or --out_html`: A filename to use to output the HTML summary report file

An example run for the `run_hto_processing.R` results in the example above:
```
git clone https://github.com/aifimmunology/cell-hashing-pipeline.git

Rscript --vanilla \
  cell-hashing-pipeline/run_h5_split_by_hash.R \
  -i /shared/lucasg/pipeline_cellhashing_tests/data/cellranger/filtered_feature_bc_matrix.h5 \
  -l /shared/lucasg/pipeline_cellhashing_tests/data/cellranger/molecule_info.h5 \
  -m /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_count_matrix.csv.gz \
  -c /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_category_table.csv.gz \
  -w T001-RP1C1W1 \
  -d /shared/lucasg/pipeline_cellhashing_tests/output/split_h5/ \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/split_h5/pool16_split_summary_report.html
```

### Tests

A dry run can be performed using test data stored in the `H5weaver` package by excluding parameters other than `-o`:
```
Rscript --vanilla \
  cell-hashing-pipeline/run_h5_split_by_hash.R \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/split_h5/test_summary_report.html
```

## Merging cellranger .h5 files by hash

After splitting the .h5 data for each well by hash above, samples from each hash can be merged across wells, again using functions in the [`H5weaver`](https://github.com/aifimmunology/H5weaver) R package, installed with:
```
devtools::install_github("aifimmunology/H5weaver")
```

Once installed, the `run_h5_merge_by_hash.R` wrapper script can read the set of split .h5 files generated by `run_h5_split_by_hash.R` and merge the well-based .h5 files into a single file per HTO.

There are 3 parameters for this script:  
 - `-i or --in_dir`: A directory path to use to output the split .h5 file results
 - `-d or --out_dir`: A directory path to use for merged .h5 file results
 - `-o or --out_html`: A filename to use to output the HTML summary report file
 
An example run for the `run_h5_split_by_hash.R` results in the example above:
```
git clone https://github.com/aifimmunology/cell-hashing-pipeline.git

Rscript --vanilla \
  cell-hashing-pipeline/run_h5_merge_by_hash.R \
  -i /shared/lucasg/pipeline_cellhashing_tests/output/split_h5/ \
  -d /shared/lucasg/pipeline_cellhashing_tests/output/merged_h5/ \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/merged_h5/hto_merge_summary_report.html
```

### Tests

A dry run can be performed using test data stored in the `H5weaver` package by excluding parameters other than `-o`:
```
Rscript --vanilla \
  cell-hashing-pipeline/run_h5_merge_by_hash.R \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/merge_h5/test_summary_report.html
```

