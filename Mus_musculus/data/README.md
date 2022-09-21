## Preparation of proteins

Download vertebrata proteins from OrthoDB

```bash
wget https://v100.orthodb.org/download/odb10_vertebrata_fasta.tar.gz
tar xvf odb10_vertebrata_fasta.tar.gz
rm odb10_vertebrata_fasta.tar.gz
```

Select only mammals

```bash
mkdir -p mammalia/Rawdata
grep -Ff  <(awk 'BEGIN{FS="\t"}{print "\t"$1"\t"}' mammalia.list)  ../../OrthoDB/odb10v0_species.tab | \
    cut -f2 | sed "s/_0/.fs/"  | xargs -I{} bash -c 'cp vertebrate/Rawdata/{} mammalia/Rawdata/'
```



Function for creating a single fasta file with mammalian proteins, excluding
species supplied in a list.

```bash

createProteinFile() {
    excluded=$1
    output=$2

    # Get NCBI ids of species in excluded list
    grep -f <(paste <(yes $'\n'| head -n $(cat $excluded | wc -l)) \
        $excluded <(yes $'\n'| head -n $(cat $excluded | wc -l))) \
        ../../OrthoDB/odb10v0_species.tab | cut -f2 | sed "s/_0//" > ids

    # Create protein file with everything else
    cat $(ls -d mammalia/Rawdata/* | grep -v -f ids) > $output

    # Remove dots from file
    sed -i -E "s/\.//" $output

    rm ids
}
```

Create protein databases with different levels of exclusion. Exclusion lists
correspond to species in taxonomic levels in OrthoDB v10.

```bash
createProteinFile mus_musculus.list species_excluded.fa
createProteinFile rodentia.list order_excluded.fa
```
