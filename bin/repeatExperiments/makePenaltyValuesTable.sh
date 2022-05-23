#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Collect the final penalty values from all species
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0 "
    exit
fi

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

homo="Caenorhabditis_elegans Arabidopsis_thaliana Drosophila_melanogaster Solanum_lycopersicum Danio_rerio"
hetero="Gallus_gallus  Mus_musculus"

homoheader() {
    echo -e "\tOrder-excluded proteins\t\t\tSpecies-excluded proteins"
}

heteroheader() {
    echo -e "\tGC\t\t\tGC"
    echo -e "\tLow\tMedium\tHigh\tLow\tMedium\tHigh"
}


shortName() {
    paste -d "." <(echo "$1" | cut -b1) <(echo "$1" | cut -f2 -d "_") | sed "s/\./\. /"
}

homoSpecies() {
    remote=order_excluded.fa
    if [ -d "$1/rnaseq/hints/species_excluded.fa" ]
    then
        closer=species_excluded.fa
    else
        closer=genus_excluded.fa
    fi
    paste <(echo -e "$(shortName $1)") \
        <(cat $1/$remote/penalty/penalty.value | head -1) \
        <(echo "") \
        <(echo "") \
        <(cat $1/$closer/penalty/penalty.value | head -1)
}

heteroSpecies() {
    remote=order_excluded.fa
    if [ -d "$1/rnaseq/hints/species_excluded.fa" ]
    then
        closer=species_excluded.fa
    else
        closer=genus_excluded.fa
    fi
    paste <(echo -e "$(shortName $1)") \
        <(cat $1/$remote/penalty/penalty.value.low | head -1) \
        <(cat $1/$remote/penalty/penalty.value.medium | head -1) \
        <(cat $1/$remote/penalty/penalty.value.high | head -1) \
        <(cat $1/$closer/penalty/penalty.value.low | head -1) \
        <(cat $1/$closer/penalty/penalty.value.medium | head -1) \
        <(cat $1/$closer/penalty/penalty.value.high | head -1)
}

export -f homoSpecies
export -f heteroSpecies
export -f shortName

homoheader
echo $homo | tr " " "\n" | xargs -I {} bash -c "homoSpecies {}"
heteroheader
echo $hetero | tr " " "\n" | xargs -I {} bash -c "heteroSpecies {}"

