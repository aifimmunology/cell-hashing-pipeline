# cell-hashing-pipeline
#

Scripts for processing cell hashing/Hash Tag Oligo (HTO) data

<a id="contents"></a>

## Contents

#### [Dependencies](#dependencies)

#### [HTO Counting](#hto)

#### [HTO Parsing: run_hto_parsing.R](#hto_parse)
- [Sample Sheet Guidelines](#sample_sheet)
- [Parameters](#hto_parse_param)
- [Outputs](#hto_parse_out)
- [Tests](#hto_parse_test)

#### [Split by Hash: run_h5_split_by_hash.R](#split)
- [Parameters](#split_param)
- [Outputs](#split_out)
- [Tests](#split_test)

#### [Merge by Hash: run_h5_merge_by_hash.R](#merge)
- [Parameters](#merge_param)
- [Outputs](#merge_out)
- [Tests](#merge_test)

<a id="dependencies"></a>

## Dependencies

This repository requires that `pandoc` and `libhdf5-devel` libraries are installed:
```
sudo apt-get install pandoc libhdf5-devel
```

It also depends on the `H5weaver`, `HTOparser`,`jsonlite`, `rmarkdown`, and `optparse` libraries.

`jsonlite`, `rmarkdown`, and `optparse` are available from CRAN, and can be installed in R using:
```
install.packages("jsonlite")
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

[Return to Contents](#contents)

<a id="hto"></a>

## Processing HTO FASTQ files

`cell-hashing-pipeline` is compatible with results from the C tool [`BarCounter`](https://github.com/aifimmunology/BarCounter), Python tool [`CITE-seq-Count`](https://github.com/Hoohm/CITE-seq-Count), and with a simple, `awk/sort/uniq` driven processing script.

For `BarCounter`, this repository includes a tag list that should be used for TotalSeqA HTO barcodes. `BarCounter` also utilizes a cell barcode whitelist, which can be obtained from 10x CellRanger outputs (outs/filtered_feature_bc_matrix/barcodes.tsv.gz) or from the 10x CellRanger software files ():
```
git clone https://github.com/aifimmunology/cell-hashing-pipeline.git

Bar_Count \
  -1 Pool-16-HTO_S5_L001_R1_001.fastq.gz \
  -2 Pool-16-HTO_S5_L001_R2_001.fastq.gz \
  -t cell-hashing-pipeline/cite-seq-count_taglist.csv \
  -w barcodes.tsv.gz \
  -o /shared/lucasg/pipeline_cellhashing_tests/data/pool16/HTO/
```

For `CITE-seq-Count v1.4.3`, this repository includes a tag list that should be used for TotalSeqA Human HTOs:
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
  -o /shared/lucasg/pipeline_cellhashing_tests/data/pool16/HTO/
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

[Return to Contents](#contents)

<a id="hto_parse"></a>

## Interpreting/parsing HTO results

The tools above provide counts for each combination of cell and hash barcode. To convert these from counts to singlet/multiplet calls, these scripts use the [`HTOparser`](https://github.com/aifimmunology/HTOparser) R package, installed with:
```
devtools::install_github("aifimmunology/HTOparser")
```

Once installed, this repository can serve as a bridge to actually run the HTO interpretation, output files, and generate a summary report using the `run_hto_processing.R` wrapper script.

<a id="sample_sheet"></a>

`run_hto_processing.R` requires a **Sample Sheet**, provided as the -k parameter, which has 4 comma-separated columns: SampleID, BatchID, HashTag, and PoolID.  

For example:
```
SampleID,BatchID,HashTag,PoolID
PB5206W2,P001,HT1,P1
PB5206W3,P001,HT2,P1
PB5206W4,P001,HT3,P1
PB5206W5,P001,HT4,P1
PB5206W6,P001,HT5,P1
PB5206W7,P001,HT6,P1
PB7626W2,P001,HT7,P1
PB7626W3,P001,HT8,P1
PB7626W4,P001,HT9,P1
PB7626W5,P001,HT10,P1
PB7626W6,P001,HT12,P1
PB7626W7,P001,HT13,P1
IMM19-711,P001,HT14,P1
```
<a id="hto_parse_param"></a>

If you are running this script without a **Sample Sheet**, the -k parameter can be omitted, which will use a fall-back built into `HTOparser`.

There are 6 parameters for this script:  
* `-t or --in_type`:  
    * 'barcounter' for Elliott Swanson's `BarCounter`  
    * 'cite' for `CITE-seq-Count >= 1.4.3`  
    * 'cite-old' for `CITE-seq-Count 1.4.2` 
    * 'awk' for the shell script, above  
* `-i or --in_file`: The input file or directory to process.  
    * For `BarCounter`, this should be the output .csv file generated by `BarCounter`.
    * For `CITE-seq-Count >= 1.4.3` with -t 'cite', this should be the base output directory
    * For `CITE-seq-Count 1.4.2` with -t 'cite-old', this should be the single umi count file generated by `CITE-seq-Count`.
    * For the shell script with -t 'awk', this should be the output .txt file (see above).
* `-k or --in_key`: A 4-column Sample Sheet (see above).
* `-w or --in_well`: A well name to apply to the output files
* `-d or --out_dir`: A directory path to use to output the HTO Processing results
* `-o or --out_html`: A filename to use to output the HTML summary report file

An example run for 

An example run for `CITE-seq-Count v1.4.3` results, as shown in the section above:
```
git clone https://github.com/aifimmunology/cell-hashing-pipeline.git

Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t cite \
  -i /shared/lucasg/pipeline_cellhashing_tests/data/pool16/HTO/ \
  -k /shared/lucasg/pipeline_cellhashing_tests/data/SampleSheet.csv \
  -w T001-P1C1W1 \ 
  -d /shared/lucasg/pipeline_cellhashing_tests/output/pool16/ \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/pool16/T001-RP1C1W1_hto_report.html
```

An example run for `CITE-seq-Count v1.4.2` results:
```
git clone https://github.com/aifimmunology/cell-hashing-pipeline.git

Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t cite \
  -i /shared/lucasg/pipeline_cellhashing_tests/data/pool16/HTO_umi_count_matrix \
  -k /shared/lucasg/pipeline_cellhashing_tests/data/SampleSheet.csv \
  -w T001-P1C1W1 \ 
  -d /shared/lucasg/pipeline_cellhashing_tests/output/pool16/ \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/pool16/T001-RP1C1W1_hto_report.html
```

An example run for awk/shell results:
```
Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t awk \
  -i /shared/lucasg/pipeline_cellhashing_tests/data/pool16/unfiltered_hto_counts_gt10.txt \
  -k /shared/lucasg/pipeline_cellhashing_tests/data/SampleSheet.csv \
  -w T001-P1C1W1 \ 
  -d /shared/lucasg/pipeline_cellhashing_tests/output/pool16/ \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/pool16/T001-P1C1W1_hto_processing_report.html
```
[Return to Contents](#contents)

<a id="hto_parse_out"></a>

### Output Files

`run_hto_processing.R` will generate two .csv.gz files and a JSON metrics report file as well as the HTML reporting file. 

.csv.gz files are named based on WellID : [WellID]_hto_count_matrix.csv.gz and [WellID]_hto_category.csv.gz
.json files are named based on WellID: [WellID]_hto_processing_metrics.json

For example, using the run above, we would get the following outputs in out_dir:
```
T001-P1C1W1_hto_category.csv.gz
T001-P1C1W1_hto_count_matrix.csv.gz
T001-P1C1W1_hto_processing_metrics.json
T001-P1C1W1_hto_processing_report.html
```

[Return to Contents](#contents)

<a id="hto_parse_test"></a>

### Tests

Test runs can be performed using datasets provided with the `HTOparser` package using `-t test_cite` or `-t test_awk`. These require only the `-t` and `-o` parameters.

```
Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t test_cite \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/test_cite/hto_processing_report.html

Rscript --vanilla \
  cell-hashing-pipeline/run_hto_processing.R \
  -t test_awk \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/test_awk/hto_processing_report.html
```

[Return to Contents](#contents)

<a id="split"></a>

## Splitting .h5 files by hash

Once raw HTO counts have been processed to singlet/multiplet calls in the hto_category_table.csv.gz file, these results can be used to separate cells with functions in the [`H5weaver`](https://github.com/aifimmunology/H5weaver) R package, installed with:
```
devtools::install_github("aifimmunology/H5weaver")
```

Once installed, the `run_h5_split_by_hash.R` wrapper script can read .h5 files generated by [`tenx-rnaseq-pipeline`](https://github.com/aifimmunology/tenx-rnaseq-pipeline) and use the outputs of the previous step to divide the cells into one .h5 per HTO.

<a id="split_params"></a>

There are 6 parameters for this script:  
 - `-i or --in_h5`: A .h5 file generated by [`tenx-rnaseq-pipeline`](https://github.com/aifimmunology/tenx-rnaseq-pipeline)
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
  -m /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_count_matrix.csv.gz \
  -c /shared/lucasg/pipeline_cellhashing_tests/output/pool16/hto_category_table.csv.gz \
  -w T001-RP1C1W1 \
  -d /shared/lucasg/pipeline_cellhashing_tests/output/split_h5/ \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/split_h5/T001-RP1C1W1_split_h5_report.html
```
[Return to Contents](#contents)

<a id="split_out"></a>

### Output Files

`run_h5_split_by_hash.R` will generate one .h5 file for each detected hash, one for multiplets, and a JSON metrics report file. 

.h5 files are named based on WellID and HashTag: [WellID]_[HashSequence].h5.
.json files are named based on WellID: [WellID]_split_h5_metrics.json

For example, using the run above, we would get the following outputs in out_dir:
```
T001-RP1C1W1_TTCCGCCTCTCTTTG.h5
T001-RP1C1W1_CTGTATGTCCGATTG.h5
T001-RP1C1W1_TGATGGCCTATTGGG.h5
T001-RP1C1W1_ATTGACCCGCGTTAG.h5
T001-RP1C1W1_AGTAAGTTCAGCGTA.h5
T001-RP1C1W1_TAACGACCAGCCATA.h5
T001-RP1C1W1_AAGTATCGTTTCGCA.h5
T001-RP1C1W1_CAGTAGTCACGGTCA.h5
T001-RP1C1W1_AAATCTCTCAGGCTC.h5
T001-RP1C1W1_CTCCTCTGCAATTAC.h5
T001-RP1C1W1_TGTCTTTCCTGCCAG.h5
T001-RP1C1W1_GTCAACTCTTTAGCG.h5
T001-RP1C1W1_GGTTGCCAGATGTCA.h5
T001-RP1C1W1_multiplet.h5
T001-RP1C1W1_split_h5_metrics.json
T001-RP1C1W1_split_h5_report.html
```

[Return to Contents](#contents)

<a id="split_test"></a>

### Tests

A dry run can be performed using test data stored in the `H5weaver` package by excluding parameters other than `-o`:
```
Rscript --vanilla \
  cell-hashing-pipeline/run_h5_split_by_hash.R \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/split_h5/test_summary_report.html
```

[Return to Contents](#contents)

<a id="merge"></a>

## Merging cellranger .h5 files by hash

After splitting the .h5 data for each well by hash above, samples from each hash can be merged across wells, again using functions in the [`H5weaver`](https://github.com/aifimmunology/H5weaver) R package, installed with:
```
devtools::install_github("aifimmunology/H5weaver")
```

Once installed, the `run_h5_merge_by_hash.R` wrapper script can read the set of split .h5 files generated by `run_h5_split_by_hash.R` and merge the well-based .h5 files into a single file per HTO.

<a id="merge_param"></a>

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
  -o /shared/lucasg/pipeline_cellhashing_tests/output/merged_h5/P001-P1_merge_h5_report.html
```

[Return to Contents](#contents)

<a id="merge_out"></a>

### Output Files

`run_h5_merge_by_hash.R` will generate one .h5 file for each SampleID and a JSON metrics report file. 

.h5 files are named based on PoolID and SampleID: [PoolID]_[SampleID].h5.
.json files are named based on PoolID: [PoolID]_merge_h5_metrics.json

For example, using the run above, we would get the following outputs in out_dir:
```
P001-P1_PB5206W2.h5
P001-P1_PB5206W3.h5
P001-P1_PB5206W4.h5
P001-P1_PB5206W5.h5
P001-P1_PB5206W6.h5
P001-P1_PB5206W7.h5
P001-P1_PB7626W2.h5
P001-P1_PB7626W3.h5
P001-P1_PB7626W4.h5
P001-P1_PB7626W5.h5
P001-P1_PB7626W6.h5
P001-P1_PB7626W7.h5
P001-P1_IMM19-711.h5
P001-P1_multiplet.h5
P001-P1_merge_h5_metrics.json
P001-P1_merge_h5_report.html
```

[Return to Contents](#contents)

<a id="merge_test"></a>

### Tests

A dry run can be performed using test data stored in the `H5weaver` package by excluding parameters other than `-o`:
```
Rscript --vanilla \
  cell-hashing-pipeline/run_h5_merge_by_hash.R \
  -o /shared/lucasg/pipeline_cellhashing_tests/output/merge_h5/test_summary_report.html
```

