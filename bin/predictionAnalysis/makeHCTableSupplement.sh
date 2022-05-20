#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Make the supplementary HC classification table
# ==============================================================

if  [ "$#" -ne 1 ]; then
    echo "Usage: $0 level"
    exit
fi

level=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

species="Caenorhabditis_elegans Arabidopsis_thaliana Drosophila_melanogaster Solanum_lycopersicum Danio_rerio Gallus_gallus  Mus_musculus"

header() {
    echo -e "\t\tRaw GMS-T\t\t\tFinal HC\t"
    echo -e "\t\t\t\t\t$level-excluded proteins\t"
    echo -e "\t\tComplete\tIncomplete\tCombined\tComplete\tIncomplete\tCombined"
}

shortName() {
    paste -d "." <(echo "$1" | cut -b1) <(echo "$1" | cut -f2 -d "_") | sed "s/\./\. /"
}

singleSpecies() {
    if [[ $level == "species" ]]; then
        if [ -d "$1/rnaseq/hints/species_excluded.fa" ]
        then
            dist=species_excluded.fa
        else
            dist=genus_excluded.fa
        fi
    else
        dist=${level}_excluded.fa
    fi
    paste <(echo -e "$(shortName $1)\tSn\n\tSp") \
        <(cat $1/rnaseq/gmst/raw.acc  | cut -f2-4 | head -3 | tail -n +2 ) \
        <(cat $1/rnaseq/hints/${dist}/hc.acc | cut -f2-4 | head -3 | tail -n +2)
}

export -f singleSpecies
export -f shortName
export level

header
echo $species | tr " " "\n" | xargs -I {} bash -c "singleSpecies {}"
