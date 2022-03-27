# Instructions for the reference annotation preparation

The annotations come from NCBI and ITAG. NCBI annotation is used to represent all genes and the intersection of NCBI and ITAG annotations is used to prepare the reliable subset.

Ensembl is using the ITAG annotation. 

The commands below were used to prepare the main annotation files:

* `annot.gtf`
* `reliable.gtf`
* `pseudo.gff3`

The processing relies on [GenomeTools](http://genometools.org/) which can be installed with, e.g., `apt install genometools`.

### ITAG annotation

```bash
bin=../../../bin
mkdir itag; cd itag

wget ftp://ftp.solgenomics.net/tomato_genome/annotation/ITAG3.2_release/ITAG3.2_gene_models.gff

$bin/gff_to_gff_subset.pl  --in ITAG3.2_gene_models.gff  --out annot.gff3  --list list.tbl --col 1  --v --swap

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  annot.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3

$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf
```

### NCBI annotation

```bash
bin=../../../bin
mkdir refseq; cd refseq
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/188/115/GCF_000188115.4_SL3.0/GCF_000188115.4_SL3.0_genomic.gff.gz
gunzip GCF_000188115.4_SL3.0_genomic.gff.gz

$bin/gff_to_gff_subset.pl  --in  GCF_000188115.4_SL3.0_genomic.gff  --out annot.gff3  --list list.tbl --col 1  --v --swap

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  annot.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3
sed -i "s/Curated Genomic/Curaged_Genomic/" pseudo.gff3

$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf
```

### Reliable subset

```bash
bin=../../bin
ln -s refseq/annot.gtf
ln -s refseq/pseudo.gff3
$bin/intersectAnnots.sh refseq/annot.gtf itag/annot.gtf > reliable.gtf
```
