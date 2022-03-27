#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Collect accuracy
# ==============================================================

if  [ "$#" -ne 4 ]; then
    echo "Usage: $0 fullAnnot.gtf reliableAnnot.gtf pseudo.gff3 pred.gtf"
    exit
fi

full=$1; shift
reliable=$1; shift
pseudo=$1; shift
pred=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH


acc() {
    type="$1"
    sn="$($bindir/compare_intervals_exact.pl --f1 $reliable --f2 $pred --$type| head -2 | tail -1 | cut -f4)"
    sp="$($bindir/compare_intervals_exact.pl --f1 $full --f2 $pred --pseudo $pseudo --$type | head -3 | tail -1 | cut -f4)"
    f1="$(printf "%.2f" $(bc -l <<< "2*$sn*$sp/($sn+$sp)"))"
    echo -e "${type}_Sn\t$sn"
    echo -e "${type}_Sp\t$sp"
    echo -e "${type}_F1\t$f1"
}

acc gene
acc cds
