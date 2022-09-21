#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Collect accuracy for all ETP results
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0 "
    exit
fi

full=$(readlink -f "annot/annot.gtf"); shift
reliable=$(readlink -f "annot/reliable.gtf"); shift
pseudo=$(readlink -f "annot/pseudo.gff3"); shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

# Overall acc
ls other/*/genemark.gtf \
    other/tsebra/*/tsebra.gtf \
    other/braker1/braker/augustus.hints.gtf \
    other/braker2/*/braker/augustus.hints.gtf \
    */genemark.gtf \
    */genemark_supported.gtf \
    */supported/*.gtf \
    rnaseq/hints/*/*.gtf | \
    xargs -P 64 -I {} bash -c \
    "${bindir}/collectAcc.sh $full $reliable $pseudo {} > {}.acc"

# HC Raw
${bindir}/collectRawGMSTAcc.sh $full $reliable $pseudo \
    rnaseq/gmst/transcripts_merged.fasta.gff \
    rnaseq/stringtie/transcripts_merged.fasta \
    rnaseq/stringtie/transcripts_merged.gff > rnaseq/gmst/raw.acc

# HC filtered
ls -d rnaseq/hints/*_excluded.fa/ | xargs -P 64 -I {} bash -c \
    "cd {}; ${bindir}/collectHCAcc.sh $full $reliable $pseudo complete.gtf incomplete.gtf > hc.acc"

# Complete/incomplete classification
ls -d rnaseq/hints/*_excluded.fa/newFilter/out | xargs -P 64 -I {} bash -c \
    "cd {}; ${bindir}/evaluateIncompleteClassification.sh $full intermediate > compIncomp.acc"
