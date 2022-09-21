#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Make the GeneMark copmarison table
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
    echo -e "\t\tES\tET\tOrder-excluded\t\tSpecies-excluded\t"
    echo -e "\t\t\t\tEP+\tETP+\tEP+\tETP+"
}

shortName() {
    paste -d "." <(echo "$1" | cut -b1) <(echo "$1" | cut -f2 -d "_") | sed "s/\./\. /"
}

singleFile() {
    cut -f2 $1 | head -6
}

singleSpecies() {
    remote=order_excluded.fa
    if [ -d "$1/rnaseq/hints/species_excluded.fa" ]
    then
        closer=species_excluded.fa
    else
        closer=genus_excluded.fa
    fi

    if [[ $2 == "no" ]]
    then
        file="genemark.gtf.acc"
    else
        file="supported/genemark_supported.gtf.acc"
    fi

    paste <(echo -e "$(shortName $1)") \
        <(echo -e "Gene Sn\nGene Sp\nGene F1\nExon Sn\nExon Sp\nExon F1") \
        <(singleFile $1/other/es/genemark.gtf.acc) \
        <(singleFile $1/other/et/genemark.gtf.acc) \
        <(singleFile $1/other/ep_${remote}/genemark.gtf.acc) \
        <(singleFile $1/${remote}/${file}) \
        <(singleFile $1/other/ep_${closer}/genemark.gtf.acc) \
        <(singleFile $1/${closer}/${file})
}

export -f singleSpecies
export -f shortName
export -f singleFile

header
echo $full | tr " " "\n" | xargs -I {} bash -c "singleSpecies {} no"
echo $supported | tr " " "\n" | xargs -I {} bash -c "singleSpecies {} yes"
