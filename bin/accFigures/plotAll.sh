#!/bin/bash
# ==============================================================
# Tomas Bruna
#
# ==============================================================

if  [ "$#" -ne 5 ]; then
    echo "Usage: $0 level distanece species rootFolder supported"
    exit
fi

type=$1; shift
distance=$1; shift
species=$1; shift
rootFolder=$1; shift
supported=$1; shift

binFolder=$(readlink -e $(dirname $0))

prepareGp() {
    file=$1
    name=$2
    grep "^$type" $file | grep -v F1 | cut -f2 | tr "\n" , | awk '{print $1}' > ${name}.${type}.acc
}


x1=0
x2=100
y1=0
y2=100

prepareGp $rootFolder/other/braker1/braker/augustus.hints.gtf.acc braker1
prepareGp $rootFolder/other/braker2/${distance}_excluded/braker/augustus.hints.gtf.acc braker2
prepareGp $rootFolder/other/tsebra/${distance}_excluded/tsebra.gtf.acc tsebra
if [[ $supported == "true" ]]; then
    prepareGp $rootFolder/${distance}_excluded.fa/supported/genemark_supported.gtf.acc etp
else
    prepareGp $rootFolder/${distance}_excluded.fa/genemark.gtf.acc etp
fi
prepareGp $rootFolder/other/es/genemark.gtf.acc es
prepareGp $rootFolder/other/et/genemark.gtf.acc et
prepareGp $rootFolder/other/ep_${distance}_excluded.fa/genemark.gtf.acc ep

braker1i=$(sed -E "s/,$//" braker1.${type}.acc | tr "," "+" | bc)
braker2i=$(sed -E "s/,$//" braker2.${type}.acc | tr "," "+" | bc)
tsebrai=$(sed -E "s/,$//" tsebra.${type}.acc | tr "," "+" | bc)
etpi=$(sed -E "s/,$//" etp.${type}.acc | tr "," "+" | bc)
esi=$(sed -E "s/,$//" es.${type}.acc | tr "," "+" | bc)
eti=$(sed -E "s/,$//" et.${type}.acc | tr "," "+" | bc)
epi=$(sed -E "s/,$//" ep.${type}.acc | tr "," "+" | bc)

title=$(echo $species | tr "_" " ")

gnuplot -e "species='$species';distance='$distance';title='$title';type='$type';x1='$x1';x2='$x2';y1='$y1';y2='$y2';braker1i='$braker1i';braker2i='$braker2i';tsebrai='$tsebrai';etpi='$etpi';esi='$esi';eti='$eti';epi='$epi'" $binFolder/plotAll.gp

convert -transparent white -density 600 all.${species}.${distance}.${type}.pdf -quality 100 all.${species}.${distance}.${type}.png

