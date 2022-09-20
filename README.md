# Experiments for the GeneMark-ETP+ project

Tomas Bruna, Alexandre Lomsadze, Mark Borodovsky

Georgia Institute of Technology, Atlanta, Georgia, USA

Reference: TODO


## Overview

This repository contains documentation of experiments, data and results for
the GeneMark-ETP+ project.

### Genome sequences 

All genome sequences were downloaded from RefSeq section of NCBI. For each genome we parsed out unique sequence identifiers [accession.version](https://www.ncbi.nlm.nih.gov/genbank/sequenceids/) from FASTA definition lines. New, simplified sequence IDs were introduced. Information about original and new IDs was saved as a table into file `$SPECIES/data/chr.names`.

An example of such table for the genome of A.thaliana is shown below:

| original ID | new ID |
| --- | --- |
| NC_003070.9 | 1 |
| NC_003071.7 | 2 |
| NC_003074.8 | 3 |
| NC_003075.7 | 4 |
| NC_003076.8 | 5 |

Only genome sequences from nuclear DNA were used in ETP project. Also, we limited the analysis to chromosomes (sequences with prefix "NC_") and main genomic contigs (sequences with prefix "NT_"). 

### Reference annotations

To prepare the reference annotations, follow the species-specific instructions
in each species folder.

All annotation statistics were collected with the `bin/analyze_annot.py` scipt.

```bash
ls */annot/annot.gtf | xargs -P7 -I {} bash -c 'bin/analyze_annot.py {} > {}.analysis'
ls */annot/reliable.gtf | xargs -P7 -I {} bash -c 'bin/analyze_annot.py {} > {}.analysis'
```