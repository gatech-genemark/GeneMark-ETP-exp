#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Collect acc table for changing penalty value
# ==============================================================

if  [ "$#" -ne 1 ]; then
    echo "Usage: $0 gcBin"
    exit
fi

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

gcBin=$1; shift

singleTable() {
    type=$1; shift
    accFile=$1; shift
    export type
    export accFile
    echo -e "penalty\tSn\tSp\tF1"

    ls -d 0* | xargs -I {} bash -c 'echo -en "{}\t"; grep $type {}/$accFile | cut -f2 | head -3 | tr "\n" "\t" | sed -E "s/\t$//"; echo'

    # Baseline value
    ls -d 0.00 | xargs -I {} bash -c 'echo -en "baseline\t"; grep $type {}/$accFile | cut -f2 | head -3 | tr "\n" "\t" | sed -E "s/\t$//"; echo'
}

grep -P "\tgmst\t" ../../genemark.gtf > hc.gtf

${bindir}/../splitAnnotIntoRegions.py ../../../annot/reliable.gtf \
    ../../nonhc/nonhc.trace ../../hc_regions.gtf hc.gtf \
    --lowIds ../../nonhc/low.ids --mediumIds ../../nonhc/medium.ids \
    --highIds ../../nonhc/high.ids annotRegions

ls */nonhc.gtf |xargs -P 64 -I {} bash -c  "${bindir}/../selectSupportedSubsets.py {} ../../supported/allHints.gff --fullSupport /dev/null --anySupport {}_supported.gtf --noSupport /dev/null"

ls */nonhc*.gtf | xargs -P 64 -I {} bash -c "${bindir}/../collectAcc.sh ../../../annot/annot.gtf annotRegions/${gcBin}.gtf ../../../annot/pseudo.gff3 {} > {}.acc"

singleTable gene nonhc.gtf.acc > gene.acc
singleTable cds nonhc.gtf.acc > cds.acc

singleTable gene nonhc.gtf_supported.gtf.acc > gene_supported.acc
singleTable cds nonhc.gtf_supported.gtf.acc > cds_supported.acc
