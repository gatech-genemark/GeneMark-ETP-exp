# Instruction for the reference annotation preparation

The annotation comes from FlyBase. NCBI RefSeq is using the FlyBase annotation.

The following commands were used to prepare the main annotation files:

* `annot.gtf`
* `pseudo.gff3`

The processing relies on [GenomeTools](http://genometools.org/) which can be installed with, e.g, `apt install genometools`.

```bash
bin=../../bin

wget http://ftp.flybase.net/genomes/Drosophila_melanogaster/dmel_r6.44_FB2022_01/gff/dmel-all-no-analysis-r6.44.gff.gz
gunzip  dmel-all-no-analysis-*.gff.gz

$bin/gff_to_gff_subset.pl  --in dmel-all-no-analysis-r6.44.gff  --out annot.gff3  --list list.tbl  --col 2

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  annot.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3

$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf
```
