## Genome reference

The genome was downloaded from https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/985/GCF_000002985.6_WBcel235/GCF_000002985.6_WBcel235_genomic.fna.gz

See the main [README](../../README.md) for genome processing details.

## Preparation of proteins

Download metazoa proteins from OrthoDB

```bash
wget https://v100.orthodb.org/download/odb10_metazoa_fasta.tar.gz
tar xvf odb10_metazoa_fasta.tar.gz
rm odb10_metazoa_fasta.tar.gz
```

Function for creating a single fasta file with metazoa proteins, excluding
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
    cat $(ls -d metazoa/Rawdata/* | grep -v -f ids) > $output

    # Remove dots from file
    sed -i -E "s/\.//" $output

    rm ids
}
```

Create protein databases with different levels of exclusion. Exclusion lists
correspond to species in taxonomic levels in OrthoDB v10.

```bash
createProteinFile caenorhabditis_elegans.txt species_excluded.fa
createProteinFile rhabditida.txt order_excluded.fa
```

