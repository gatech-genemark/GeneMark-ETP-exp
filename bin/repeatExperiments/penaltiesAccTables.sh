#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Collect acc table for changing penalty value
# ==============================================================

if  [ "$#" -ne 0 ]; then
    echo "Usage: $0 "
    exit
fi

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH



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

${bindir}/../splitAnnotIntoRegions.py ../../../annot/annot.gtf \
   ../../nonhc/nonhc.trace  ../../hc_regions.gtf ../../model/hc.gff \
   annotRegions

ls */nonhc.gtf |xargs -P 64 -I {} bash -c  "${bindir}/../selectSupportedSubsets.py {} ../../supported/allHints.gff --fullSupport /dev/null --anySupport {}_supported.gtf --noSupport /dev/null"

ls */nonhc*.gtf | xargs -P 64 -I {} bash -c "${bindir}/../collectAcc.sh ../../../annot/annot.gtf annotRegions/lc.gtf ../../../annot/pseudo.gff3 {} > {}.acc"

singleTable gene nonhc.gtf.acc > gene.acc
singleTable cds nonhc.gtf.acc > cds.acc

singleTable gene nonhc.gtf_supported.gtf.acc > gene_supported.acc
singleTable cds nonhc.gtf_supported.gtf.acc > cds_supported.acc
