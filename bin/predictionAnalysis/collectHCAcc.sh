#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Collect accuracy of HC genes: Complete, incomplete, and combined
# ==============================================================

if  [ "$#" -ne 5 ]; then
    echo "Usage: $0 fullAnnot.gtf reliableAnnot.gtf pseudo.gff3 complete.gtf incomplete.gtf"
    exit
fi

full=$1; shift
reliable=$1; shift
pseudo=$1; shift
complete=$1; shift
incomplete=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH


reliable() {
    type="$1"
    pred="$2"
    $bindir/compare_intervals_exact.pl --f1 $reliable --f2 $pred --$type
}

full() {
    type="$1"
    pred="$2"
    $bindir/compare_intervals_exact.pl --f1 $full --f2 $pred --pseudo $pseudo --$type
}

incompleteEval() {
    annot="$1"
    pred="$2"
    $bindir/classifyIncompletePredictions.py $annot $pred
}


TP() {
    echo "$1" | head -2 | tail -1 | cut -f2
}

FP() {
    echo "$1" | head -3 | tail -1 | cut -f3
}

P() {
    echo "$1" | head -2 | tail -1 | cut -f1
}

TPIncomplete() {
    echo "$1" | grep -P "exactMatch|incomplete" | cut -f2 | tr "\n" "+" | \
        sed -E "s/\+$/\n/" | bc
}

FPIncomplete() {
    echo "$1" | grep -v -P "exactMatch|incomplete" | cut -f2 | tr "\n" "+" | \
        sed -E "s/\+$/\n/" | bc
}

Incomplete() {
    echo "$1" | grep "incomplete" | grep -v "exactMatch" | cut -f2 | tr "\n" "+" | \
        sed -E "s/\+$/\n/" | bc
}

printRowNames() {
    level=$1; shift
    echo -e "${level}_Sn"
    echo -e "${level}_Sp"
    echo -e "${level}_F1"
    echo -e "Reliable_${level}_TP"
    echo -e "All_${level}_TP"
    echo -e "All_${level}_FP"
}

printColumn() {
    TPR=$1; shift
    TP=$1; shift
    FP=$1; shift
    PR=$1; shift

    sn="$(printf "%.2f" $(bc -l <<< "100*$TPR/$PR"))"
    sp="$(printf "%.2f" $(bc -l <<< "100*$TP/($TP+$FP)"))"
    f1="$(printf "%.2f" $(bc -l <<< "2*$sn*$sp/($sn+$sp)"))"
    echo -e "$sn"
    echo -e "$sp"
    echo -e "$f1"
    echo -e "$TPR"
    echo -e "$TP"
    echo -e "$FP"
}

completeReliableGene="$(reliable gene $complete)"
completeFullGene="$(full gene $complete)"

completeReliableExon="$(reliable cds $complete)"
completeFullExon="$(full cds $complete)"

incompleteReliableGene="$(incompleteEval $reliable $incomplete)"
incompleteFullGene="$(incompleteEval $full $incomplete)"

incompleteReliableExon="$(reliable cds $incomplete)"
incompleteFullExon="$(full cds $incomplete)"

echo -en "Level\tComplete\tIncomplete\tCombined\n"

paste <(printRowNames Gene) \
      <(printColumn $(TP "$completeReliableGene") \
                    $(TP "$completeFullGene") \
                    $(FP "$completeFullGene") \
                    $(P "$completeReliableGene")) \
      <(printColumn $(TPIncomplete "$incompleteReliableGene") \
                    $(TPIncomplete "$incompleteFullGene") \
                    $(FPIncomplete "$incompleteFullGene") \
                    $(P "$completeReliableGene")) \
      <(printColumn $(($(TPIncomplete "$incompleteReliableGene") + $(TP "$completeReliableGene"))) \
                    $(($(TPIncomplete "$incompleteFullGene") + $(TP "$completeFullGene"))) \
                    $(($(FPIncomplete "$incompleteFullGene") + $(FP "$completeFullGene"))) \
                    $(P "$completeReliableGene"))

paste <(printRowNames Exon) \
      <(printColumn $(TP "$completeReliableExon") \
                    $(TP "$completeFullExon") \
                    $(FP "$completeFullExon") \
                    $(P "$completeReliableExon")) \
      <(printColumn $(TP "$incompleteReliableExon") \
                    $(TP "$incompleteFullExon") \
                    $(($(FP "$incompleteFullExon") - $(Incomplete "$incompleteFullGene")))\
                    $(P "$incompleteReliableExon")) \
      <(printColumn $(($(TP "$incompleteReliableExon") + $(TP "$completeReliableExon"))) \
                    $(($(TP "$incompleteFullExon") + $(TP "$completeFullExon"))) \
                    $(($(FP "$incompleteFullExon") - $(Incomplete "$incompleteFullGene") + $(FP "$completeFullExon")))\
                    $(P "$incompleteReliableExon"))


#Longest isoform per gene
completeS=$(mktemp -p .)
${bindir}/print_longest_isoform.py $complete > $completeS
completeReliableGeneS="$(reliable gene $completeS)"
completeFullGeneS="$(full gene $completeS)"
echo "---Longest isoform per gene---"
paste <(printRowNames Gene) \
      <(printColumn $(TP "$completeReliableGeneS") \
                    $(TP "$completeFullGeneS") \
                    $(FP "$completeFullGeneS") \
                    $(P "$completeReliableGeneS")) \
      <(printColumn $(TPIncomplete "$incompleteReliableGene") \
                    $(TPIncomplete "$incompleteFullGene") \
                    $(FPIncomplete "$incompleteFullGene") \
                    $(P "$completeReliableGene")) \
      <(printColumn $(($(TPIncomplete "$incompleteReliableGene") + $(TP "$completeReliableGeneS"))) \
                    $(($(TPIncomplete "$incompleteFullGene") + $(TP "$completeFullGeneS"))) \
                    $(($(FPIncomplete "$incompleteFullGene") + $(FP "$completeFullGeneS"))) \
                    $(P "$completeReliableGeneS"))
rm $completeS
