#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Predict with enforcing RNA hints conflicting ab initio predictions
# ==============================================================

if  [ "$#" -ne 1 ]; then
    echo "Usage: $0 penalty"
    exit
fi

pen=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

etpBin=/home/azureuser/etp_exp/ETP_support/bin
etpCfg=${etpBin}/gmes/etp.cfg
subsetSelectionBin=/data/bin
evalScript=/home/azureuser/etp_exp/ETP_support/etp-exp/bin/collectAcc.sh

makeRNAHints() {
    genemark=$1; shift
    rHints=$1; shift
    pHints=$1; shift
    threshold=$1; shift
    trace=$1; shift
    evi=$1; shift

    ${etpBin}/printRnaAlternatives.py $genemark $rHints --otherIntrons $pHints --minIntronScore $threshold > rna_conflicts_${threshold}
    ${etpBin}/format_back.pl rna_conflicts_${threshold} $trace > rna_conflicts_${threshold}_traced.gff
    cat rna_conflicts_${threshold} $evi > evi_${threshold}.gff
}

predict() {
    evi=$1; shift
    model=$1; shift
    seq=$1; shift
    trace=$1; shift
    allHints=$1; shift
    original=$1; shift

    dir=pred_${evi}
    evi=$(readlink -f $evi)
    mkdir $dir
    cd $dir

    ${etpBin}/gmes/gmes_petap.pl --soft_mask 1000 --mask_penalty "$pen"\
        --predict_with $model --seq $seq --cores 64 --verbose --evi $evi \
        --usr_cfg $etpCfg --max_gap 40000 --max_mask 40000 > loginfo
    ${etpBin}/format_back.pl genemark.gtf $trace > nonhc.gtf
    ${subsetSelectionBin}/selectSupportedSubsets.py nonhc.gtf $allHints --fullSupport /dev/null --anySupport nonhc_supported.gtf --noSupport /dev/null

    cat <(grep gmst $original) nonhc.gtf > genemark.gtf
    cat <(grep gmst $original) nonhc_supported.gtf > genemark_supported.gtf

    rm -r output data
    cd ..
}

mkdir rna_only; cd rna_only

makeRNAHints ../nonhc/pred_m/genemark.gtf ../nonhc/r_hints_nonhc.gtf ../nonhc/prothint/prothint.gff 0 ../nonhc/nonhc.trace ../nonhc/evi.gff
makeRNAHints ../nonhc/pred_m/genemark.gtf ../nonhc/r_hints_nonhc.gtf ../nonhc/prothint/prothint.gff 4 ../nonhc/nonhc.trace ../nonhc/evi.gff

predict evi_0.gff ../../model/output.mod ../../nonhc/nonhc.fasta ../../nonhc/nonhc.trace ../../supported/allHints.gff ../../genemark.gtf
predict evi_4.gff ../../model/output.mod ../../nonhc/nonhc.fasta ../../nonhc/nonhc.trace ../../supported/allHints.gff ../../genemark.gtf

# Eval all
export evalScript
ls */*.gtf | xargs -P 64 -I {} bash -c '$evalScript ../../annot/annot.gtf ../../annot/reliable.gtf ../../annot/pseudo.gff3 {} > {}.acc'
