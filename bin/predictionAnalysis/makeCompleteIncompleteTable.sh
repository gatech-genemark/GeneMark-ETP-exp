#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Make and overall complete/incomplete confusion matrix table
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0 "
    exit
fi

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

species="Caenorhabditis_elegans Arabidopsis_thaliana Drosophila_melanogaster Solanum_lycopersicum Danio_rerio Gallus_gallus  Mus_musculus"

header() {
    echo -e "\t\tOrder-excluded\tSpecies-excluded"
    echo -e "\t\tActually complete\tTruly incomplete\tActually complete\tTruly incomplete"
}

shortName() {
    paste -d "." <(echo "$1" | cut -b1) <(echo "$1" | cut -f2 -d "_") | sed "s/\./\. /"
}

singleSpecies() {
    if [ -d "$1/rnaseq/hints/species_excluded.fa" ]
    then
        dist=species_excluded.fa
    else
        dist=genus_excluded.fa
    fi
    paste <(echo -e "$(shortName $1)") \
        <(cat $1/rnaseq/hints/order_excluded.fa/newFilter/out/compIncomp.acc | tail -n +2) \
        <(cat $1/rnaseq/hints/${dist}/newFilter/out/compIncomp.acc | cut -f2- | tail -n +2)
}

export -f singleSpecies
export -f shortName

header
echo $species | tr " " "\n" | xargs -I {} bash -c "singleSpecies {}"
