#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Predict genes in LC regions with different penalty values
#
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0"
    exit
fi

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH


mkdir -p maskingExperiments/penaltyPredictions
cd maskingExperiments/penaltyPredictions

# Adjust etp path according to its location

for i in $(seq 0 0.01 0.2)
do
   mkdir "$i"
   cd "$i"
   ../../../../../bin/etp/gmes/gmes_petap.pl --soft_mask 1000 --mask_penalty "$i" --predict_with ../../../model/output.mod --seq ../../../nonhc/nonhc.fasta --cores 64 --verbose --evi ../../../nonhc/evi.gff --usr_cfg ../../../../../bin/etp/gmes/etp.cfg --max_gap 40000 --max_mask 40000 > loginfo
   ../../../../../bin/etp/format_back.pl genemark.gtf ../../../nonhc/nonhc.trace > nonhc.gtf
   rm -r output data
   cd ..
done

