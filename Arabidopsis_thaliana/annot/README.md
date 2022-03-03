# Instructions for the reference annotation preparation

The annotation comes from TAIR. NCBI RefSeq is using the TAIR annotation.

The commands below were used to prepare the main annotation files:

* `annot.gtf`
* `pseudo.gff3`

The processing relies on [GenomeTools](http://genometools.org/) which can be installed with, e.g., `apt install genometools`.

```bash
bin=../../bin

wget https://www.arabidopsis.org/download_files/Genes/Araport11_genome_release/archived/Araport11_GFF3_genes_transposons.Mar92021.gff.gz
gunzip Araport11_GFF3_genes_transposons.Mar92021.gff.gz
$bin/gff_to_gff_subset.pl --in Araport11_GFF3_genes_transposons.Mar92021.gff --out annot.gff3 --list list.tbl --col 2

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  annot.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3

$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf
```
