#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Make all acc figures.
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0"
    exit
fi

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

full="Caenorhabditis_elegans Arabidopsis_thaliana Drosophila_melanogaster"
supported="Solanum_lycopersicum Danio_rerio Gallus_gallus  Mus_musculus"

singleSpecies() {
    species=$1
    supported=$2
    remote=order

    cd $species

    if [ -d "rnaseq/hints/species_excluded.fa" ]
    then
        closer=species
    else
        closer=genus
    fi

    mkdir acc_figures; cd acc_figures

    ${bindir}/plotGM.sh Gene $closer $species .. $supported
    ${bindir}/plotGM.sh Gene $remote $species .. $supported
    ${bindir}/plotGM.sh Exon $closer $species .. $supported
    ${bindir}/plotGM.sh Exon $remote $species .. $supported

    ${bindir}/plotAll.sh Gene $closer $species .. $supported
    ${bindir}/plotAll.sh Gene $remote $species .. $supported
    ${bindir}/plotAll.sh Exon $closer $species .. $supported
    ${bindir}/plotAll.sh Exon $remote $species .. $supported

    ${bindir}/plotTsebra.sh Gene $closer $species .. $supported
    ${bindir}/plotTsebra.sh Gene $remote $species .. $supported
    ${bindir}/plotTsebra.sh Exon $closer $species .. $supported
    ${bindir}/plotTsebra.sh Exon $remote $species .. $supported
}
export -f singleSpecies
export bindir

echo $full | tr " " "\n" | xargs -I {} bash -c "singleSpecies {} false"
echo $supported | tr " " "\n" | xargs -I {} bash -c "singleSpecies {} true"
