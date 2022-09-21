#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Count the number of fully, partially, and unsupported genes
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0"
    exit
fi

countGenes() {
    file=$1
    compare_intervals_exact.pl --f1 "$file" --f2 "$file" --gene | head -2 | \
        tail -1 | cut -f1
}

count() {
    distance=$1

    HCComplete=$(countGenes rnaseq/hints/$distance/complete.gtf)

    # Done because some original complete data were overwritten
    if [ -f "rnaseq/hints/$distance/correction.txt" ]; then
        HCComplete=$(cat rnaseq/hints/$distance/correction.txt)
    fi

    unsupportedHC=$(countGenes rnaseq/hints/$distance/unsupported_noConfl_logodds.gtf)
    completeSupport=$((HCComplete - unsupportedHC))

    if [ -d "${distance}_paper" ]; then
        distance="${distance}_paper"
    fi

    tmpNonHc=$(mktemp)
    grep -v -P "\tgmst\t" $distance/genemark.gtf > $tmpNonHc
    nonHCAll=$(countGenes $tmpNonHc)

    tmpNonHcS=$(mktemp)
    grep -v -P "\tgmst\t" $distance/supported/genemark_supported.gtf > $tmpNonHcS
    nonHCSupported=$(countGenes $tmpNonHcS)

    partialSupport=$((nonHCSupported + unsupportedHC))
    noSupport=$((nonHCAll - nonHCSupported))

    sum=$((completeSupport + partialSupport + noSupport))

    echo -e "$distance\t\t"
    printf "Full_extrinsic\t%d\t%.2f\n" $completeSupport $(bc -l <<< "100*$completeSupport/$sum")
    printf "Mixed_extrinsic\t%d\t%.2f\n" $partialSupport $(bc -l <<< "100*$partialSupport/$sum")
    printf "No_support\t%d\t%.2f\n" $noSupport $(bc -l <<< "100*$noSupport/$sum")

    allGenes=$(countGenes $distance/genemark.gtf)
    echo -e "CheckSum\t$sum"
    echo -e "CheckAll\t$allGenes"

    rm $tmpNonHc $tmpNonHcS
}

if [ -d "rnaseq/hints/species_excluded.fa" ]
    then
        close=species_excluded.fa
    else
        close=genus_excluded.fa
fi

paste <(count order_excluded.fa) <(count $close)
