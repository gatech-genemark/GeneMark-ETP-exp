#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Make the main HC classification table
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0"
    exit
fi

level=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

full="Caenorhabditis_elegans Arabidopsis_thaliana Drosophila_melanogaster"
supported="Solanum_lycopersicum Danio_rerio Gallus_gallus  Mus_musculus"

header() {
    echo -e "\t\tBRAKER1\tOrder-excluded\t\t\tSpecies-excluded"
    echo -e "\t\t\tBRAKER2\tTSEBRA\tETP+\tBRAKER2\tTSEBRA\tETP+"
}

shortName() {
    paste -d "." <(echo "$1" | cut -b1) <(echo "$1" | cut -f2 -d "_") | sed "s/\./\. /"
}

singleFile() {
    cut -f2 $1 | head -6
}

singleSpecies() {
    remote=order_excluded.fa
    remoteb=order_excluded
    if [ -d "$1/rnaseq/hints/species_excluded.fa" ]
    then
        closer=species_excluded.fa
        closerb=species_excluded
    else
        closer=genus_excluded.fa
        closerb=genus_excluded
    fi

    if [[ $2 == "no" ]]
    then
        file="genemark.gtf.acc"
    else
        file="supported/genemark_supported.gtf.acc"
    fi

    paste <(echo -e "$(shortName $1)") \
        <(echo -e "Gene Sn\nGene Sp\nGene F1\nExon Sn\nExon Sp\nExon F1") \
        <(singleFile $1/other/braker1/braker/augustus.hints.gtf.acc) \
        <(singleFile $1/other/braker2/$remoteb/braker/augustus.hints.gtf.acc) \
        <(singleFile $1/other/tsebra/$remoteb/tsebra.gtf.acc) \
        <(singleFile $1/${remote}/${file}) \
        <(singleFile $1/other/braker2/$closerb/braker/augustus.hints.gtf.acc) \
        <(singleFile $1/other/tsebra/$closerb/tsebra.gtf.acc) \
        <(singleFile $1/${closer}/${file})
}

export -f singleSpecies
export -f shortName
export -f singleFile

header
echo $full | tr " " "\n" | xargs -I {} bash -c "singleSpecies {} no"
echo $supported | tr " " "\n" | xargs -I {} bash -c "singleSpecies {} yes"
