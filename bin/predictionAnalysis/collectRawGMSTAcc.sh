#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Collect accuracy of raw gmst predictions
# ==============================================================

if  [ "$#" -ne 6 ]; then
    echo "Usage: $0 fullAnnot.gtf reliableAnnot.gtf pseudo.gff3 gmst.gtf stringtie.fasta stringtie.gff"
    exit
fi

full=$1; shift
reliable=$1; shift
pseudo=$1; shift
gmst=$1; shift
Sfasta=$1; shift
Sgff=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

pred=$(mktemp -p .)
${bindir}/gms2hints.pl --tseq $Sfasta --ggtf $Sgff --tgff $gmst --out $pred

complete=$(mktemp -p .)
partial=$(mktemp -p .)
grep "status \"complete\"" $pred > $complete
grep "status \"partial\"" $pred > $partial

partialStart=$(mktemp -p .)
grep -Ff <(grep stop_codon $partial | grep -Po "transcript_id [^;]+") \
    $partial > $partialStart

partialStartLongest=$(mktemp -p .)
${bindir}/print_longest_isoform.py $partialStart > $partialStartLongest

${bindir}/collectHCAcc.sh $full $reliable $pseudo $complete $partialStartLongest

rm $pred $partial $partialStart $partialStartLongest $complete
