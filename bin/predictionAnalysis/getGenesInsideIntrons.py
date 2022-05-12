#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2021, Georgia Institute of Technology, USA
#
# Find genes inside introns of other genes.
# ==============================================================


import argparse
import csv
import re
import os
import sys
import subprocess
import tempfile


def extractFeatureGtf(text, feature):
    regex = feature + ' "([^"]+)"'
    return re.search(regex, text).groups()[0]


def systemCall(cmd):
    if subprocess.call(["bash", "-c", cmd]) != 0:
        sys.exit('error: Program exited due to an ' +
                 'error in command: ' + cmd)


def makeTranscriptBordersFromGtf(genesIn):
    transcripts = {}
    for row in csv.reader(open(genesIn), delimiter='\t'):
        if len(row) != 9:
            continue
        if row[2] != "CDS":
            continue

        trId = extractFeatureGtf(row[8], "transcript_id")
        if trId not in transcripts:
            transcripts[trId] = row
            transcripts[trId][2] = "mrna"
        else:
            transcripts[trId][3] = str(min(int(row[3]),
                                           int(transcripts[trId][3])))
            transcripts[trId][4] = str(max(int(row[4]),
                                           int(transcripts[trId][4])))

    transcriptOut = tempfile.NamedTemporaryFile("w", prefix="transcripts",
                                                dir=".", delete=False)
    for tr in transcripts:
        transcriptOut.write("\t".join(transcripts[tr]) + "\n")

    transcriptOut.close()
    return transcriptOut.name


def filterIntrons(intronsIn):
    intronsOut = tempfile.NamedTemporaryFile("w", prefix="introns",
                                             dir=".", delete=False)

    for row in csv.reader(open(intronsIn), delimiter='\t'):
        if len(row) != 9:
            continue
        if row[2].lower() != "intron":
            continue

        intronsOut.write("\t".join(row) + "\n")

    intronsOut.close()
    return intronsOut.name


def getOverlaps(transcripts, introns, args):
    insideIds = set()
    outsideIds = set()
    overlaps = tempfile.NamedTemporaryFile(prefix="overlaps",
                                           dir=".", delete=False)

    systemCall("bedtools intersect -a " + transcripts + " -b " + introns + 
               " -f 1 -wa -wb | sort | uniq > " + overlaps.name)

    alreadyPrinted = set()
    output = open(args.intronsOutput, "w")
    for row in csv.reader(open(overlaps.name), delimiter='\t'):
        insideIds.add(extractFeatureGtf(row[8], "transcript_id"))
        outsideIds.add(extractFeatureGtf(row[17], "transcript_id"))

        intronSignature = row[9] + row[12] + row[13]
        if intronSignature not in alreadyPrinted:
            output.write("\t".join(row[9:]) + "\n")
            alreadyPrinted.add(intronSignature)
    output.close()

    output = open(args.insideOutput, "w")
    for row in csv.reader(open(args.genes), delimiter='\t'):
        if len(row) != 9:
            continue
        trId = extractFeatureGtf(row[8], "transcript_id")
        if trId in insideIds:
            output.write("\t".join(row) + "\n")
    output.close()

    output = open(args.containingOutput, "w")
    for row in csv.reader(open(args.introns), delimiter='\t'):
        if len(row) != 9:
            continue
        trId = extractFeatureGtf(row[8], "transcript_id")
        if trId in outsideIds:
            output.write("\t".join(row) + "\n")
    output.close()

    os.remove(overlaps.name)


def main():
    args = parseCmd()
    transcripts = makeTranscriptBordersFromGtf(args.genes)
    introns = filterIntrons(args.introns)
    getOverlaps(transcripts, introns, args)

    print("Genes inside introns statistics:")
    systemCall("analyze_annot.sh " + args.insideOutput + " | head -11")

    print("\n------------\n")
    print("Genes with genes inside introns statistics:")
    systemCall("analyze_annot.sh " + args.containingOutput + " | head -11")

    os.remove(introns)
    os.remove(transcripts)


def parseCmd():

    parser = argparse.ArgumentParser(description='Find genes inside introns\
        of other genes.')

    parser.add_argument('introns', metavar='baseGenes.gtf', type=str,
                        help='Annotation of genes which may contain genes\
                        inside their introns.')

    parser.add_argument('genes', metavar='insideGenes.gtf', type=str,
                        help='Annotation of genes which may be inside introns\
                        of other genes. To look for genes inside introns\
                        within the same annotation, supply the same file as in\
                        the first argument.')

    parser.add_argument('insideOutput', type=str,
                        help='Output with genes inside introns')

    parser.add_argument('containingOutput', type=str,
                        help='Output with genes containing genes in introns')

    parser.add_argument('intronsOutput', type=str,
                        help='Output withintrons containing genes')

    return parser.parse_args()


if __name__ == '__main__':
    main()
