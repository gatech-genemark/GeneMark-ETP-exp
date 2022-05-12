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


reliable() {
    type="$1"
    $bindir/compare_intervals_exact.pl --f1 $reliable --f2 $pred --$type
}

full() {
    type="$1"
    $bindir/compare_intervals_exact.pl --f1 $full --f2 $pred --pseudo $pseudo --$type
}

printAcc() {
    level="$3"
    sn=$(echo "$1" | head -2 | tail -1 | cut -f4)
    sp=$(echo "$2" |  head -3 | tail -1 | cut -f4)
    echo -e "${level}_Sn\t$sn"
    echo -e "${level}_Sp\t$sp"
    f1="$(printf "%.2f" $(bc -l <<< "2*$sn*$sp/($sn+$sp)"))"
    echo -e "${level}_F1\t$f1"

}

printNumbers() {
    level="$3"
    reliableTP=$(echo "$1" | head -2 | tail -1 | cut -f2)
    allTP=$(echo "$2" | head -2 | tail -1 | cut -f2)
    allFP=$(echo "$2" | head -3 | tail -1 | cut -f3)
    echo -e "Reliable_${level}_TP\t$reliableTP"
    echo -e "All_${level}_TP\t$allTP"
    echo -e "All_${level}_FP\t$allFP"
}

reliableGene="$(reliable gene)"
fullGene="$(full gene)"
printAcc "$reliableGene" "$fullGene" Gene

reliableExon="$(reliable cds)"
fullExon="$(full cds)"
printAcc "$reliableExon" "$fullExon" Exon

printNumbers "$reliableGene" "$fullGene" Gene
printNumbers "$reliableExon" "$fullExon" Exon
