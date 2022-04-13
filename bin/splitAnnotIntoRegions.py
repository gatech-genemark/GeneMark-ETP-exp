#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2021, Georgia Institute of Technology, USA
#
# Description
# ==============================================================


import argparse
import csv
import re
import sys
import subprocess
import tempfile
import os
import shutil


def extractFeatureGtf(text, feature):
    regex = feature + ' "([^"]+)"'
    return re.search(regex, text).groups()[0]


def extractFeatureGff(text, feature):
    regex = feature + '=([^;]+);'
    return re.search(regex, text).groups()[0]


def temp(prefix, suffix):
    if not os.path.exists('tempfiles'):
        os.makedirs('tempfiles')
    return tempfile.NamedTemporaryFile("w", delete=False, dir="tempfiles",
                                       prefix=prefix, suffix=suffix)


def cleanup(cleanupList):
    for file in cleanupList:
        os.remove(file)


def systemCall(cmd):
    if subprocess.call(["bash", "-c", cmd]) != 0:
        sys.exit('error: Program exited due to an ' +
                 'error in command: ' + cmd)


def readGff(gffFile):
    for row in csv.reader(open(gffFile), delimiter='\t'):
        pass


def makeRegions(ids, trace):
    regions = temp("regions", ".bed").name
    systemCall('grep -Ff <(awk \'{print $1"\t"}\' ' + ids + ') ' + trace +
               ' | awk \'BEGIN{OFS="\t"}{print $2, $3-1, $4}\' > ' + regions)
    return regions


def selectInLCRegions(ids, trace, hcRegions, annot, output):
    cleanupList = []
    regions = makeRegions(ids, trace)
    cleanupList.append(regions)

    candidates = temp("candidates", ".gtf").name
    cleanupList.append(candidates)
    systemCall('bedtools intersect -a ' + annot + ' -b ' + regions + ' > ' +
               candidates)

    hcOverlap = temp("hcOverlap", ".gtf").name
    cleanupList.append(hcOverlap)
    systemCall('bedtools intersect -a ' + annot + ' -b ' + hcRegions +
               ' | grep -Po "gene_id [^;]+" > ' + hcOverlap)

    systemCall('grep -v -Ff ' + hcOverlap + ' ' + candidates + ' > ' + output)
    cleanup(cleanupList)


def selectInHCRegions(hcRegions, annot, output):
    cleanupList = []
    candidates = temp("candidates", ".gtf").name
    cleanupList.append(candidates)
    systemCall('bedtools intersect -a ' + annot + ' -b ' + hcRegions + ' > ' +
               candidates)

    restIds = temp("rest", ".gtf").name
    cleanupList.append(restIds)
    systemCall('bedtools intersect -v -a ' + annot + ' -b ' + hcRegions +
               ' | grep -Po "gene_id [^;]+" > ' + restIds)

    spanningIDs = temp("spanning", ".gtf").name
    cleanupList.append(spanningIDs)
    systemCall('grep -Ff ' + restIds + ' ' + candidates +
               ' | grep -Po "gene_id [^;]+" > ' + spanningIDs)

    systemCall('grep -Ff ' + spanningIDs + ' ' + annot + ' > ' +
               output + "/spanning.gtf")
    systemCall('grep -v -Ff ' + spanningIDs + ' ' + candidates + ' > ' +
               output + "/hc.gtf")
    cleanup(cleanupList)


def separateGenesInIntrons(hcPred, output):
    cleanupList = []
    inIntron = temp("inIntron", ".gtf").name
    temp1 = temp("temp", ".gtf").name
    temp2 = temp("temp", ".gtf").name
    cleanupList += [inIntron, temp1, temp2]
    binDir = os.path.abspath(os.path.dirname(__file__))
    systemCall(binDir + "/getGenesInsideIntrons.py " + hcPred + " " +
               output + "/hc.gtf " + inIntron + " " + temp1 +
               " " + temp2)

    inIntronIds = temp("inIntronIds", ".gtf").name
    cleanupList.append(inIntronIds)
    systemCall('grep -Ff ' + inIntron + ' ' + output + "/hc.gtf " +
               ' | grep -Po "gene_id [^;]+" > ' + inIntronIds)

    tempOut = temp("temp", ".gtf").name
    systemCall('grep -v -Ff ' + inIntronIds + ' ' + output + "/hc.gtf " +
               ' > ' + tempOut)
    systemCall('grep -Ff ' + inIntronIds + ' ' + output + "/hc.gtf " + ' > ' +
               output + "/inHcIntron.gtf")

    shutil.move(tempOut, output + "/hc.gtf")
    cleanup(cleanupList)


def main():
    args = parseCmd()
    if not os.path.exists(args.outputFolder):
        os.makedirs(args.outputFolder)
    selectInLCRegions(args.lowIds, args.trace, args.hcRegions, args.annot,
                      args.outputFolder + "/low.gtf")
    selectInLCRegions(args.mediumIds, args.trace, args.hcRegions, args.annot,
                      args.outputFolder + "/medium.gtf")
    selectInLCRegions(args.highIds, args.trace, args.hcRegions, args.annot,
                      args.outputFolder + "/high.gtf")

    selectInHCRegions(args.hcRegions, args.annot, args.outputFolder)

    separateGenesInIntrons(args.HC, args.outputFolder)


def parseCmd():

    parser = argparse.ArgumentParser(description='Splits annotated genes into\
        regions which are (a) Fully inside low/medium/high GC segments. All\
        transcripts of a gene need to fall into the segment. (b) Fully inside\
        HC segments. Again, all transcripts of a gene need to be inside the\
        HC gene. (b-1) Genes which are fully inside introns of HC genes are \
        saved separately. (c) Genes which have at least one transcript \
        spanning two different segments.')

    parser.add_argument('annot', metavar='annot.gtf', type=str)
    parser.add_argument('lowIds', metavar='low.ids', type=str)
    parser.add_argument('mediumIds', metavar='medium.ids', type=str)
    parser.add_argument('highIds', metavar='high.ids', type=str)
    parser.add_argument('trace', metavar='nonhc.trace', type=str)
    parser.add_argument('hcRegions', metavar='hc_regions.gtf', type=str)
    parser.add_argument('HC', metavar='hc_gmst.gtf', type=str)
    parser.add_argument('outputFolder', type=str)

    return parser.parse_args()


if __name__ == '__main__':
    main()
