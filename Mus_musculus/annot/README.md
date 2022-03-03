# Instructions for the reference annotation preparation

The annotations comes from Gencode. A reliable subset of the annotation is prepared by selecting transcripts with the following attributes:

* `transcript_support_level=1` - All splice junctions of the transcript are supported by at least one non-suspect mRNA
* `basic` - Prioritises full-length protein coding transcripts over partial or non-protein coding transcripts within the same gene, and intends to highlight those transcripts that will be useful to the majority of users
* `CCDS` - Agreement with RefSeq annotation

The commands below were used to prepare the main annotation files:

* `annot.gtf`
* `reliable.gtf`
* `pseudo.gff3`

The processing relies on [GenomeTools](http://genometools.org/) which can be installed with, e.g., `apt install genometools`.


```bash
bin=../../bin
wget http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M28/gencode.vM28.annotation.gff3.gz
gunzip gencode.vM28.annotation.gff3.gz

$bin/gff_to_gff_subset.pl --in gencode.vM28.annotation.gff3 --out subset.gff3 --list list.tbl --col 1 --v --swap

gt  gff3  -force  -tidy  -sort  -retainids  -checkids  -o tmp_annot.gff3  subset.gff3
mv tmp_annot.gff3  annot.gff3

$bin/select_pseudo_from_nice_gff3.pl annot.gff3 pseudo.gff3

$bin/enrich_gff.pl --in annot.gff3 --out tmp_annot.gff3 --cds --v --warnings
mv tmp_annot.gff3  annot.gff3

$bin/gff3_to_gtf.pl annot.gff3 annot.gtf
```

### Reliable subset selection

```bash
grep CCDS subset.gff3 | grep basic | grep transcript_support_level=1 | \
    grep -Po "transcript_id=[^;]+" | sed "s/transcript_id=//" | sort | uniq | \
    awk '{print "\""$1"\""}' > ids
grep -Ff ids annot.gtf > reliable.gtf
rm ids
```