#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2022, Georgia Institute of Technology, USA
#
# Collect annot stats
# ==============================================================

import csv
import re
import collections
import sys
import copy
import argparse
import os
import numpy as np
import robustats
from tabulate import tabulate


def getTranscriptID(fileType, row):
    if fileType == ".gtf":
        regex = 'transcript_id "([^"]+)"'
    elif fileType == ".gff" or fileType == ".gff3":
        if row[2] == "mRNA":
            regex = 'ID=([^;]+);'
        else:
            regex = 'Parent=([^;]+);'
    else:
        sys.exit("Unsupported file type.")
    result = re.search(regex, row[8])
    if result:
        return result.groups()[0]
    else:
        return None


def getGeneID(fileType, row):
    if fileType == ".gtf":
        regex = 'gene_id "([^"]+)"'
    elif fileType == ".gff" or fileType == ".gff3":
        if row[2] == "mRNA":
            regex = 'Parent=([^;]+);'
        else:
            sys.exit("Unexpected feature in gff")
    else:
        sys.exit("Unsupported file type.")
    result = re.search(regex, row[8])
    if result:
        return result.groups()[0]
    else:
        return None


def getSignature(row):
    return row[0] + "_" + row[3] + "_" + row[4] + "_" + row[6]


class Feature():
    def __init__(self, row):
        self.support = False
        self.length = int(row[4]) - int(row[3]) + 1
        self.signature = getSignature(row)
        self.chr = row[0]
        self.beginning = int(row[3])
        self.end = int(row[4])
        self.strand = row[6]
        self.row = row
        self.type = None

    def __gt__(self, other):
        return self.beginning > other.beginning


class Transcript():

    def __init__(self):
        self.exons = []
        self.introns = []
        self.start = None
        self.stop = None
        self.length = 0
        self.intronLength = 0
        self.intronLengths = []
        self.exonLengths = []
        self.startFound = False
        self.stopFound = False
        self.exonsCategorized = False

    def lengthWithIntrons(self):
        return self.length + self.intronLength

    def addFeature(self, row):
        if row[2] == "CDS":
            self.addExon(row)
        elif row[2] == "start_codon":
            self.addStart(row)
        elif row[2] == "stop_codon":
            self.addStop(row)

    def addExon(self, row):
        self.exonsCategorized = False
        exon = Feature(row)
        self.length += exon.length
        self.exonLengths.append(exon.length)
        self.exons.append(exon)

    def addIntron(self, row):
        intron = Feature(row)
        self.intronLength += intron.length
        self.intronLengths.append(intron.length)
        self.introns.append(intron)

    def addStart(self, row):
        self.start = Feature(row)

    def addStop(self, row):
        self.stop = Feature(row)

    def isComplete(self):
        return self.start and self.stop

    def inferIntrons(self):
        self.exons.sort()
        for i in range(len(self.exons) - 1):
            row = copy.deepcopy(self.exons[i].row)
            row[2] = "intron"
            row[3] = str(int(row[4]) + 1)
            row[4] = str(int(self.exons[i + 1].row[3]) - 1)
            self.addIntron(row)

    def categorizeExons(self):
        self.exonsCategorized = True

        if len(self.exons) == 1:
            if self.isComplete():
                self.exons[0].type = "single"
            else:
                self.exons[0].type = "unknown"
            return

        self.exons.sort()

        for i in range(len(self.exons)):
            exon = self.exons[i]

            if i == 0:
                if exon.strand == "+" and self.start:
                    exon.type = "initial"
                elif exon.strand == "-" and self.stop:
                    exon.type = "terminal"
                else:
                    exon.type = "unknown"

            elif i != len(self.exons) - 1:
                exon.type = "internal"

            else:
                if exon.strand == "+" and self.stop:
                    exon.type = "terminal"
                elif exon.strand == "-" and self.start:
                    exon.type = "initial"
                else:
                    exon.type = "unknown"


class Gene():

    def __init__(self):
        self.transcripts = collections.OrderedDict()

    def addTranscript(self, ID):
        self.transcripts[ID] = Transcript()

    def inferIntrons(self):
        for transcript in self.transcripts.values():
            transcript.inferIntrons()

    def getTranscripts(self):
        return self.transcripts.values()

    def collectStats(self):

        self.exonLengths = {}
        self.intronLengths = []
        self.transcriptCounts = []
        self.intronsPerTranscript = []
        self.transcriptCount = 0
        self.codingLengths = []
        self.intronLengths = []
        self.exonLengths = []

        for transcript in self.transcripts.values():
            self.intronsPerTranscript.append(len(transcript.introns))
            self.codingLengths.append(transcript.length)
            self.intronLengths += transcript.intronLengths
            self.exonLengths += transcript.exonLengths
            self.transcriptCount += 1


class PredictionAnalysis():

    def __init__(self, prediction):
        self.fileType = os.path.splitext(prediction)[1]
        print(self.fileType)
        self.loadPrediction(prediction)

    def loadPrediction(self, prediction):
        self.genes = collections.OrderedDict()
        self.prediction = prediction
        self.tr2gene = {}

        i = 1
        for row in csv.reader(open(prediction), delimiter='\t'):
            if len(row) == 0:
                continue
            elif row[0][0] == "#":
                continue
            elif len(row) != 9:
                sys.exit("Error while processing line " + str(i) + " in " +
                         prediction)

            if row[2] == "mRNA":
                transcriptID = getTranscriptID(self.fileType, row)
                geneID = getGeneID(self.fileType, row)
                self.tr2gene[transcriptID] = geneID

            if row[2] != "CDS" and row[2] != "start_codon" and row[2] \
               != "stop_codon":
                continue

            transcriptID = getTranscriptID(self.fileType, row)
            if not transcriptID:
                sys.exit("Transcript ID not found")

            if self.fileType == ".gtf":
                geneID = getGeneID(self.fileType, row)
            elif self.fileType == ".gff":
                geneID = self.tr2gene[transcriptID]
            else:
                sys.exit("error: Unexpected filetype")

            if geneID not in self.genes:
                self.genes[geneID] = Gene()

            if transcriptID not in self.genes[geneID].transcripts:
                self.genes[geneID].addTranscript(transcriptID)

            self.genes[geneID].transcripts[transcriptID].addFeature(row)
            i += 1

        for gene in self.genes.values():
            gene.inferIntrons()

        self.collectOverallStatistics()

    def collectOverallStatistics(self):

        exonTypes = ["single", "initial", "internal", "terminal",
                     "unknown", "all"]
        self.exonLengths = {}
        for exonType in exonTypes:
            self.exonLengths[exonType] = []
        self.exonCounts = []
        self.intronsPerTranscript = WeightedList()
        self.codingLengths = WeightedList()
        self.intronLengths = WeightedList()
        self.exonLengths = WeightedList()
        self.transcriptCount = 0
        self.geneCount = len(self.genes)

        for gene in self.genes.values():
            gene.collectStats()
            w = gene.transcriptCount
            self.intronsPerTranscript.add(gene.intronsPerTranscript, w)
            self.codingLengths.add(gene.codingLengths, w)
            self.intronLengths.add(gene.intronLengths, w)
            self.exonLengths.add(gene.exonLengths, w)
            self.transcriptCount += w


class WeightedList():
    def __init__(self):
        self.values = []
        self.weights = []

    def add(self, values, inverseWeight):
        self.values += values
        self.weights += [1 / inverseWeight] * len(values)

    def mean(self):
        return round(np.mean(np.array(self.values)), 2)

    def weightedMean(self):
        return round(np.average(np.array(self.values),
                                weights=np.array(self.weights)),
                     2)

    def median(self):
        return np.median(np.array(self.values))

    def weightedMedian(self):
        return robustats.weighted_median(np.array(self.values),
                                         weights=np.array(self.weights))


def main():
    args = parseCmd()
    analysis = PredictionAnalysis(args.annot)
    table = [['Gene count', analysis.geneCount],
             ['Transcript count', analysis.transcriptCount]]
    print(tabulate(table))

    headers = ["Per transcript", "Average", "Median"]
    table = [['Introns per transcript', analysis.intronsPerTranscript.mean(),
              analysis.intronsPerTranscript.median()],
             ['Coding length', analysis.codingLengths.mean(),
              analysis.codingLengths.median()],
             ['Intron length', analysis.intronLengths.mean(),
              analysis.intronLengths.median()],
             ['Exon length', analysis.exonLengths.mean(),
              analysis.exonLengths.median()]]
    print(tabulate(table, headers=headers))
    print("-------------------")
    headers = ["Per gene", "Average", "Median"]
    table = [['Introns per transcript',
              analysis.intronsPerTranscript.weightedMean(),
              analysis.intronsPerTranscript.weightedMedian()],
             ['Coding length', analysis.codingLengths.weightedMean(),
              analysis.codingLengths.weightedMedian()],
             ['Intron length', analysis.intronLengths.weightedMean(),
              analysis.intronLengths.weightedMedian()],
             ['Exon length', analysis.exonLengths.weightedMean(),
              analysis.exonLengths.weightedMedian()]]
    print(tabulate(table, headers=headers))


def parseCmd():

    parser = argparse.ArgumentParser(description='Get annotation statistics.')

    parser.add_argument('annot', type=str, help='Coding annotation in gtf/gff\
        format')

    return parser.parse_args()


if __name__ == '__main__':
    main()
