## Genome reference

The genome was downloaded from https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/188/115/GCF_000188115.4_SL3.0/GCF_000188115.4_SL3.0_genomic.fna.gz

See the main [README](../../README.md) for genome processing details.

## Preparation of proteins

Download plants proteins from OrthoDB

```bash
wget https://v100.orthodb.org/download/odb10_plants_fasta.tar.gz
tar xvf odb10_plants_fasta.tar.gz
rm odb10_plants_fasta.tar.gz
```

Function for creating a single fasta file with arthropda proteins, excluding
species supplied in a list.

```bash
createProteinFile() {
    excluded=$1
    output=$2

    # Get NCBI ids of species in excluded list
    grep -f <(paste <(yes $'\n'| head -n $(cat $excluded | wc -l)) \
       	$excluded <(yes $'\n'| head -n $(cat $excluded | wc -l))) \
       	../../OrthoDB/odb10v0_species.tab | cut -f2 > ids

    # Create protein file with everything else
    cat $(ls -d plants/Rawdata/* | grep -v -f ids) > $output

    # Remove dots from file
    sed -i -E "s/\.//" $output

    rm ids
}
```

Create protein databases with different levels of exclusion. Exclusion lists
correspond to species in taxonomic levels in OrthoDB v10.

```bash
createProteinFile solanum.txt genus_excluded.fa
createProteinFile solanales.txt order_excluded.fa
```
