# Experiments for the GeneMark-ETP project

Tomas Bruna, Alexandre Lomsadze, Mark Borodovsky

Georgia Institute of Technology, Atlanta, Georgia, USA

Reference: TODO

This repository contains documentation of experiments, data and results for the GeneMark-ETP project.

## Input data preparation

### Genome sequences 

All genome sequences were downloaded from RefSeq section of NCBI (the links are saved in `$SPECIES/data/README.md`). For each genome we parsed out unique sequence identifiers [accession.version](https://www.ncbi.nlm.nih.gov/genbank/sequenceids/) from FASTA definition lines. New, simplified sequence IDs were introduced. Information about original and new IDs was saved as a table into file `$SPECIES/data/chr.names`.

An example of such table for the genome of A.thaliana is shown below:

| original ID | new ID |
| --- | --- |
| NC_003070.9 | 1 |
| NC_003071.7 | 2 |
| NC_003074.8 | 3 |
| NC_003075.7 | 4 |
| NC_003076.8 | 5 |

Only genome sequences from nuclear DNA were used in ETP project. Also, we limited the analysis to chromosomes (sequences with prefix "NC_") and main genomic contigs (sequences with prefix "NT_"). The processed sequences were saved into `$SPECIES/data/genome.fasta`.

### Repeat masking

Each genome was _de novo_ masked by RepeatModeler2 (v2.0.1) and RepeatMasker (v4.1.0) as follows:

```bash
BuildDatabase -name genome genome.fasta
RepeatModeler -database genome -srand 1 -pa 16 -LTRStruct > rmodeler.out
RepeatMasker -pa 16 -lib genome-families.fa -xsmall genome.fasta > rmasker.out
```

### Protein database preparation

Input protein sets were downloaded from [OrthoDB](https://www.orthodb.org/) (v10.1) and processed as described for each species in `$SPECIES/data/README.md`.

### Reference annotations

To prepare the reference annotations, follow the species-specific instructions
in each species folder.

All annotation statistics were collected with the `bin/analyze_annot.py` scipt.

```bash
ls */annot/annot.gtf | xargs -P7 -I {} bash -c 'bin/analyze_annot.py {} > {}.analysis'
ls */annot/reliable.gtf | xargs -P7 -I {} bash -c 'bin/analyze_annot.py {} > {}.analysis'
```


## Evaluation

The `bin` folder contains scripts for generating all tables and figures presented in the paper.

First, the following script computes the accuracy of all gene prediction results (including intermediate results) made for the genome of a species `$SPECIES`.

```
cd $SPECIES
../bin/predictionAnalysis/collectAllAcc.sh
```

Then, the scripts in `bin/accFigures` and `bin/predictionAnalysis` can be used to collect the accuracy results and generate any of the figures and tables. See the documentation of each script for details. For example, the following command generates all the main accuracy figures (which are also saved in this repository in `$SPECIES/acc_figures`):

```bash
bin/accFigures/makeAllFigures.sh
```

### Repeat masking experiments

The following commands generate the figure showing the prediction accuracy with respect to the masking penalty value.

```bash
cd $SPECIES/$etp_prediction_folder
../../bin/repeatExperiments/predictWithPenalties.sh
cd maskingExperiments/penaltyPredictions/
../../../../bin/repeatExperiments/penaltiesAccTables.sh
# Adjust ymin and ymax as needed
../../../../bin/repeatExperiments/penaltiesGraph.py gene.acc gene.acc.pdf --ymin 60 --ymax 85 --selected $penalty_value_predicted_by_ETP
../../../../bin/repeatExperiments/penaltiesGraph.py cds.acc cds.acc.pdf --ymin 60 --ymax 85 --selected $penalty_value_predicted_by_ETP
```

Run the "gc" versions of these scripts for GC-heterogeneous genomes (_M. musculus_ and _G. gallus_).

To make the figure showing the masking training behavior, run the estimate masking script in the scan mode and visualize the results as follows:

```bash
cd $SPECIES/$etp_prediction_folder/scan
../../../../bin/estimateMaskingPenalty.py --GMES_PATH $path_to_gmes --scan $predicted_hc_genes ../../../data/genome.softmasked.fasta $etp_model --threads 64 --startingStep 0.01 --minStep 0.01
../../../../bin/repeatExperiments/scanGraph.py out scanGraph.png
```
