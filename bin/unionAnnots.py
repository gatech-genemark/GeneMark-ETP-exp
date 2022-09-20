#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2022, Georgia Institute of Technology, USA
#
# Print a union of two annotations
# ==============================================================


import argparse
import csv
import re


def extractFeatureGtf(text, feature):
    regex = feature + ' "([^"]+)"'
    return re.search(regex, text).groups()[0]


def replaceFeatureGtf(field, feature, oldValue, newValue):
    old = feature + " \"" + oldValue + "\";"
    new = feature + " \"" + newValue + "\";"
    return field.replace(old, new)


def printAnnot(file, postfix):
    for row in csv.reader(open(file), delimiter='\t'):
        if len(row) != 9:
            continue
        geneID = extractFeatureGtf(row[8], "gene_id")
        trID = extractFeatureGtf(row[8], "transcript_id")

        row[8] = replaceFeatureGtf(row[8], "gene_id", geneID, geneID + postfix)
        row[8] = replaceFeatureGtf(row[8], "transcript_id", trID,
                                   trID + postfix)
        print("\t".join(row))


def main():
    args = parseCmd()
    printAnnot(args.annot1, "-1")
    printAnnot(args.annot2, "-2")


def parseCmd():

    parser = argparse.ArgumentParser(description=' Print a union of two\
                                     annotations')

    parser.add_argument('annot1', metavar='annot1.gtf', type=str)
    parser.add_argument('annot2', metavar='annot2.gtf', type=str)

    return parser.parse_args()


if __name__ == '__main__':
    main()
