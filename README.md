# cell-hashing-pipeline

Scripts for processing cell hashing/Hash Tag Oligo (HTO) data

### Processing HTO FASTQ files

`cell-hashing-pipeline` is compatible with results from the Python tool [`CITE-seq-Count`](https://github.com/Hoohm/CITE-seq-Count) and with a simple, `awk/sort/uniq` driven processing script.

The latter can be performed directly from the R1 and R2 HTO FASTQ files using:
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

### Interpreting/parsing HTO results

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


