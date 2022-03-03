# Instructions for the reference annotation preparation

The annotation comes from WormBase. NCBI RefSeq is using the WormBase annotation.

The commands below were used to prepare the main annotation files:

* `annot.gtf`
* `pseudo.gff3`

The processing relies on [GenomeTools](http://genometools.org/) which can be installed with, e.g., `apt install genometools`.

```bash
bin=../../bin

wget ftp://ftp.wormbase.org/pub/wormbase/releases/WS284/species/c_elegans/PRJNA13758/c_elegans.PRJNA13758.WS284.annotations.gff3.gz
gunzip c_elegans.PRJNA13758.WS284.annotations.gff3.gz

$bin/gff_to_gff_subset.pl  --in c_elegans.PRJNA13758.WS284.annotations.gff3  --out annot.gff3  --list list.tbl  --col 2

grep -P '\tWormBase\t' annot.gff3 >> tmp_annot.gff3
mv tmp_annot.gff3  annot.gff3

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  annot.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3

$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf
```
