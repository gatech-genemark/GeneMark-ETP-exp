#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Make the main copmarison of supported/unsupported predictions
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0"
    exit
fi

level=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

species="Caenorhabditis_elegans Arabidopsis_thaliana Drosophila_melanogaster Solanum_lycopersicum Danio_rerio Gallus_gallus  Mus_musculus"

header() {
    echo -e "\t\tOrder-excluded\t\tSpecies-excluded"
    echo -e "\t\tAll predictions\tAb initio removed\tAll predictions\tAb initio removed"
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

    paste <(echo -e "$(shortName $1)") \
        <(echo -e "Gene Sn\nGene Sp\nGene F1\nExon Sn\nExon Sp\nExon F1") \
        <(singleFile $1/${remote}/genemark.gtf.acc) \
        <(singleFile $1/${remote}/supported/genemark_supported.gtf.acc) \
        <(singleFile $1/${closer}/genemark.gtf.acc) \
        <(singleFile $1/${closer}/supported/genemark_supported.gtf.acc)
}

export -f singleSpecies
export -f shortName
export -f singleFile

header
echo $species | tr " " "\n" | xargs -I {} bash -c "singleSpecies {}"

