#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2022, Georgia Institute of Technology, USA
#
# Classify incomplete predictions
# ==============================================================


import argparse
import csv
import re
import os
import tempfile
import analyze_annot
import sys
import shutil


def extractFeatureGtf(text, feature):
    regex = feature + ' "([^"]+)"'
    return re.search(regex, text).groups()[0]


def getSignature(row):
    return f'{row[0]}_{row[3]}_{row[4]}'


def cleanOutputFolder(output):
    files = os.listdir(output)
    for file in files:
        if file.endswith(".gtf"):
            os.remove(os.path.join(output, file))


class Transcript():
    def __init__(self, ID, row):
        self.ID = ID
        self.introns = set()
        self.stop = None
        self.strand = row[6]
        self.chr = row[0]
        self.start = None
        self.fullRecord = ""

    def addRecord(self, row):
        self.fullRecord += "\t".join(row) + "\n"

    def updateStop(self, row):
        # Stop codon can be split, thus the complicated procedure
        stopCandidate = int(row[4])
        if self.strand == "-":
            stopCandidate = int(row[3])
        if not self.stop:
            self.stop = stopCandidate
        else:
            if self.strand == "+":
                self.stop = max(stopCandidate, self.stop)
            else:
                self.stop = min(stopCandidate, self.stop)

    def addIntron(self, row):
        self.introns.add(getSignature(row))

    def updateStart(self, row):
        startCandidate = int(row[3])
        if self.strand == "-":
            startCandidate = int(row[4])
        if not self.start:
            self.start = startCandidate
        else:
            if self.strand == "+":
                self.start = min(startCandidate, self.start)
            else:
                self.start = max(startCandidate, self.start)

    def getStop(self):
        if self.stop is None:
            return None
        return f'{self.chr}_{self.stop}'


def loadGtf(gtfFile):
    transcripts = {}
    for row in csv.reader(open(gtfFile), delimiter='\t'):
        if len(row) != 9:
            continue
        ID = extractFeatureGtf(row[8], "transcript_id")

        if ID not in transcripts:
            transcripts[ID] = Transcript(ID, row)

        transcripts[ID].addRecord(row)

        if row[2] == "stop_codon":
            transcripts[ID].updateStop(row)

        if row[2] == "intron" or row[2] == "gap":
            transcripts[ID].addIntron(row)

        if row[2] == "CDS":
            transcripts[ID].updateStart(row)

    return transcripts


def mapStops(transcripts):
    stops = {}
    for ID, pred in transcripts.items():
        if pred.getStop() not in stops:
            stops[pred.getStop()] = [ID]
        else:
            stops[pred.getStop()].append(ID)
    return stops


def removeIntrons(introns, border, left):
    output = set()
    # This accounts for short splicing overhangs.
    tolerance = 0
    for intron in introns:
        start = int(intron.split("_")[1])
        end = int(intron.split("_")[2])
        if left:
            # Remove introns left of the boundary
            if start > border + tolerance or end > border + tolerance:
                output.add(intron)
        else:
            # Remove introns right of the boundary
            if start < border - tolerance or end < border - tolerance:
                output.add(intron)
    return output


def comparePrediction(annot, pred):
    if pred.start == annot.start:
        if pred.introns == annot.introns:
            return "exactMatch"
        else:
            return "assemblyError"

    # Introns in the common coding region must match
    if pred.strand == "+":
        if pred.start < annot.start:
            pIntrons = removeIntrons(pred.introns, annot.start, True)
            if pIntrons == annot.introns:
                return "longer"
        else:
            aIntrons = removeIntrons(annot.introns, pred.start, True)
            if aIntrons == pred.introns:
                return "incomplete"
    else:
        if pred.start > annot.start:
            pIntrons = removeIntrons(pred.introns, annot.start, False)
            if pIntrons == annot.introns:
                return "longer"
        else:
            aIntrons = removeIntrons(annot.introns, pred.start, False)
            if aIntrons == pred.introns:
                return "incomplete"

    return "assemblyError"


def comparePredictions(annotations, predictions, output):
    cleanOutputFolder(output)
    stop2Annot = mapStops(annotations)
    noStop = open(f'{output}/noStop.gtf', "w")
    stopNotMatching = open(f'{output}/stopNotMatching.gtf', "w")
    assemblyError = open(f'{output}/assemblyError.gtf', "w")
    for ID, pred in predictions.items():
        if not pred.getStop():
            noStop.write(pred.fullRecord)
            continue

        if pred.getStop() not in stop2Annot:
            stopNotMatching.write(pred.fullRecord)
            continue

        results = set()

        for annotID in stop2Annot[pred.getStop()]:
            results.add(comparePrediction(annotations[annotID], pred))

        if len(results) == 1 and list(results)[0] == "assemblyError":
            assemblyError.write(pred.fullRecord)
        else:
            results.discard("assemblyError")
            results = list(results)
            results.sort()
            filename = "_".join(results) + ".gtf"
            with open(f'{output}/{filename}', "a") as file:
                file.write(pred.fullRecord)

    noStop.close()
    stopNotMatching.close()
    assemblyError.close()


def printOutput(outFolder):
    files = os.listdir(outFolder)
    files.sort()
    outFile = open(outFolder + "/out.txt", "w")
    for file in files:
        if not file.endswith(".gtf"):
            continue
        c = analyze_annot.PredictionAnalysis(outFolder + '/' + file).geneCount
        print("\t".join([file, str(c)]))
        outFile.write("\t".join([file, str(c)]) + "\n")
    outFile.close()


def main():
    args = parseCmd()
    if args.output and os.path.exists(args.output):
        sys.exit("Warning: The output folder already exists. Exiting.")

    annotations = loadGtf(args.annot)
    predictions = loadGtf(args.pred)
    workdir = tempfile.mkdtemp(dir=".")
    comparePredictions(annotations, predictions, workdir)
    printOutput(workdir)

    if args.output:
        shutil.move(workdir, args.output)
    else:
        shutil.rmtree(workdir)


def parseCmd():

    parser = argparse.ArgumentParser(description='Classify incomplete\
         predictions.')

    parser.add_argument('annot', metavar='completeAnnot.gtf', type=str)
    parser.add_argument('pred', metavar='prediction.gtf', type=str)
    parser.add_argument('--output', metavar='outputFolder', type=str,
                        help="If specified, classified files will be saved\
                        here in gtf format.")

    return parser.parse_args()


if __name__ == '__main__':
    main()
