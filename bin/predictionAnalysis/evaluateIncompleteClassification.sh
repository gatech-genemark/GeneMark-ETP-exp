#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Evaluate how many GMST incomplete predictions were correctly/incorrectly
# classified as complete/incomplete.
#
# In this evaluation, only correct predictions (before filtering)
# are considered; i.e. predictions with wrong stop or assembly errors are
# ignored. Also, predictions which are both complete and incomplete (w.r.t
# to different transcripts) are ignored, because these will always be
# classified correctly.
# ==============================================================

if  [ "$#" -ne 2 ]; then
    echo "Usage: $0 fullAnnot intermediateFolder"
    exit
fi

annot=$1; shift
input=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

longest=$(mktemp -p .)
# Collapse alternatives
$bindir/print_longest_isoform.py "$input/upLORF_All.gtf" > $longest

out=$(mktemp -u -p .)
$bindir/classifyIncompletePredictions.py $annot $longest --out "$out" > /dev/null

# There will be a mismatch due to some predictions having no protein hits
#echo -e "Truly incomplete:\t"$(grep -Po "transcript_id[^;]+" "$out/incomplete.gtf" | sort | uniq | wc -l)""
#echo -e "Actuall complete:\t"$(grep -Po "transcript_id[^;]+" "$out/longer.gtf" | sort | uniq | wc -l)""
#echo "---"

echo -e ".\tActually_complete\tTruly_incomplete"
echo -en "Predicted_complete\t"

tp=$(grep -o -Ff <(grep -Po "transcript_id[^;]+" "$out/longer.gtf") \
    "$input/upLORF_Complete_Unfiltered.gtf" | sort | uniq | wc -l)
echo -en "$tp\t"

fp=$(grep -o -Ff <(grep -Po "transcript_id[^;]+" "$out/incomplete.gtf") \
    "$input/upLORF_Complete_Unfiltered.gtf" | sort | uniq | wc -l)
echo "$fp"

echo -en "Predicted_incomplete\t"
fn=$(grep -o -Ff <(grep -Po "transcript_id[^;]+" "$out/longer.gtf") \
    "$input/upLORF_Partial_Unfiltered.gtf" | sort | uniq | wc -l)
echo -en "$fn\t"

tn=$(grep -o -Ff <(grep -Po "transcript_id[^;]+" "$out/incomplete.gtf") \
    "$input/upLORF_Partial_Unfiltered.gtf" | sort | uniq | wc -l)
echo "$tn"

echo "---"
printf "Complete fixed: %.2f\n" $(bc -l <<< "100*$tp/($tp+$fn)")
printf "Incomplete incorrectly classified as complete: %.2f\n" $(bc -l <<< "100*$fp/($fp+$tn)")


rm -r $out
rm $longest
