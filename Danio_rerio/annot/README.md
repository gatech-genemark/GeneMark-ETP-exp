# Instructions for the reference annotation preparation

The annotations come from NCBI and Ensembl. NCBI annotation is used to represent all genes and the intersection of NCBI and Ensembl annotations is used to prepare the reliable subset.

The commands below were used to prepare the main annotation files:

* `annot.gtf`
* `reliable.gtf`
* `pseudo.gff3`

The processing relies on [GenomeTools](http://genometools.org/) which can be installed with, e.g., `apt install genometools`.

```bash
bin=../../../bin

mkdir ensembl; cd ensembl

wget http://ftp.ensembl.org/pub/release-105/gff3/danio_rerio/Danio_rerio.GRCz11.105.chr.gff3.gz
gunzip Danio_rerio.GRCz11.105.chr.gff3.gz

$bin/gff_to_gff_subset.pl  --in Danio_rerio.GRCz11.105.chr.gff3  --out annot.gff3  --list list.tbl  --col 2

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  annot.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3

$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf

cd ..
mkdir refseq; cd refseq
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/035/GCF_000002035.6_GRCz11/GCF_000002035.6_GRCz11_genomic.gff.gz
gunzip GCF_000002035.6_GRCz11_genomic.gff.gz

$bin/gff_to_gff_subset.pl  --in  GCF_000002035.6_GRCz11_genomic.gff  --out annot.gff3  --list list.tbl --col 1  --v --swap

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  annot.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3

sed -i "s/gene-si: /gene-si:/" annot.gff3
$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf

cd ..
bin=../../bin
ln -s refseq/annot.gtf
ln -s refseq/pseudo.gff3
$bin/intersectAnnots.sh refseq/annot.gtf ensembl/annot.gtf > reliable.gtf
```
