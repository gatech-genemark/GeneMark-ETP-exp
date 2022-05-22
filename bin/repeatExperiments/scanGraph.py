#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2020, Georgia Institute of Technology, USA
#
# Generate graph showing the number of correctly predicted exons with respect
# to a changing penalty value
# ==============================================================


import argparse
import matplotlib.pyplot as plt
import pandas as pd


def processData(data):
    data["geneSn"] = 100 * data["genes"] / max(data["genes"])
    data["exonSn"] = 100 * data["exons"] / max(data["exons"])
    return data


def plot(data, output, title, ymin, ymax):

    data = processData(data)

    s = 1.5
    fig, ax1 = plt.subplots(figsize=(6.4 / s, 4.8 / s))
    #fig, ax1 = plt.subplots()

    # = "tab:blue"

    # ax1.plot(data["penalty"], data["geneSn"], linestyle='-', marker='.',
    #          lw=1, label='Frac. of correct genes')

    ax1.plot(data["penalty"], data["exonSn"], linestyle='-', marker='.',
             lw=1, label='% of correct exons')

    # ax1.axhline(max(data["geneSn"]), 0, 1,
    #             lw=0.8, linestyle='--',  label='Baseline', color="tab:grey")
    # ax1.axhline(99.5, 0, 1,
    #             lw=0.8, linestyle='--',  label='99.5% genes', color="tab:blue",
    #             alpha = 1)

    ax1.axhline(max(data["exonSn"]), 0, 1,
                lw=0.8, linestyle='--',  label='Baseline', color="tab:grey")
    ax1.axhline(99.8, 0, 1,
                lw=0.8, linestyle='--',  label='99.8%', color="tab:blue",
                alpha = 1)

    ax1.set_xlabel("Repeat penalty")
    ax1.set_ylabel("%")

    ax1.set_ylim(ymin, ymax)

    #ax1.legend(loc='upper center',  bbox_to_anchor=(0.5, -0.15), ncol=2)
    ax1.legend(loc='lower left')

    plt.title(title.replace("_", " "))
    ax1.tick_params(axis="x", labelsize=7)
    ax1.set_xticks(data["penalty"])
    for label in ax1.xaxis.get_ticklabels()[1::2]:
        label.set_visible(False)
   # ax1.set_xticks(data["penalty"])

    plt.tight_layout()
    plt.savefig(output, dpi=600)


def main():
    args = parseCmd()
    data = pd.read_csv(args.input, sep="\t")
    plot(data, args.output, args.title, args.ymin, args.ymax)


def parseCmd():

    parser = argparse.ArgumentParser(description='Generate graph showing the\
        number of correctly predicted exons with respect to a changing penalty \
        value')

    parser.add_argument('input', type=str, help="Output of the penalty \
        scan script.")
    parser.add_argument('output', type=str)
    parser.add_argument('--title', default="", type=str)
    parser.add_argument('--ymin', type=float, default=98)
    parser.add_argument('--ymax', type=float, default=101)

    return parser.parse_args()


if __name__ == '__main__':
    main()
