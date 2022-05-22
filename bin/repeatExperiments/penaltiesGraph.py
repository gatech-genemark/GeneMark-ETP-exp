#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2020, Georgia Institute of Technology, USA
#
# ==============================================================


import argparse
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import itertools

def processData(data):
    data["F1"] = 2 * data["Sn"] * data["Sp"] / (data["Sn"] + data["Sp"])
    overallSnSp = data.tail(1)
    data = data[:-1]
    return overallSnSp, data

def flip(items, ncol):
    return itertools.chain(*[items[i::ncol] for i in range(ncol)])

def plot(data, output, title, ymin, ymax, accType, selected):

    offset = 2
    if not ymin:
        ymin = (min(min(data["Sn"]), min(data["Sp"]))) - offset
    if not ymax:
        ymax = (max(max(data["Sn"]), max(data["Sp"]))) + offset

    overallSnSp, acc = processData(data)

    s = 1.5
    fig, ax1 = plt.subplots(figsize=(6.4 / s, 4.8 / s))

    snColor = "tab:blue"
    spColor = "tab:orange"
    f1Color = "black"





    ax1.plot(acc["penalty"], acc["Sn"], linestyle='-', marker='.',
             lw=1, color=snColor, label=accType + ' Sn')

    ax1.plot(acc["penalty"], acc["Sp"], linestyle='-', marker='.',
             lw=1, color=spColor, label=accType + ' Sp')

    ax1.plot(acc["penalty"], acc["F1"], linestyle='-', marker='.',
             lw=1, color=f1Color, label=accType + ' F1')
    
    ax1.plot(np.NaN, np.NaN, '-', color='none', label=' ')

    ax1.axvline(x = selected * 100, color="black", lw=0.8, linestyle=':',
                label = "Estimated penalty value")



    ax1.axhline(float(overallSnSp["Sn"]), 0, 1, color=snColor,
                lw=0.8, linestyle='--')
    ax1.axhline(float(overallSnSp["Sp"]), 0, 1, color=spColor,
                lw=0.8, linestyle='--')
    ax1.axhline(float(overallSnSp["F1"]), 0, 1, color=f1Color,
                lw=0.8, linestyle='--')

    ax1.set_xlabel("Repeat penalty")
    ax1.set_ylabel("Accuracy (%)")

    ax1.set_ylim(ymin, ymax)

    handles, labels = ax1.get_legend_handles_labels()
    l2 = ax1.legend([handles[4]], [labels[4]], loc='lower left', frameon=False)
    ax1.legend(flip(handles[0:4], 3), flip(labels[0:4], 3), loc='lower left',
               ncol=3, handletextpad=0.5, columnspacing=1)
    a = plt.gca().add_artist(l2)
    a.set(zorder=10)

    plt.title(title.replace("_", " "))
    ax1.tick_params(axis="x", labelsize=7)
    for label in ax1.xaxis.get_ticklabels()[1::2]:
        label.set_visible(False)

    plt.tight_layout()
    plt.savefig(output, dpi=600)


def main():
    args = parseCmd()
    data = pd.read_csv(args.input, sep="\t")
    plot(data, args.output, args.title, args.ymin, args.ymax, args.type,
         args.selected)


def parseCmd():

    parser = argparse.ArgumentParser(description='')

    parser.add_argument('input', type=str)
    parser.add_argument('output', type=str)
    parser.add_argument('--title', default="", type=str)
    parser.add_argument('--type', default="", type=str)
    parser.add_argument('--ymin', type=float)
    parser.add_argument('--ymax', type=float)
    parser.add_argument('--selected', type=float)

    return parser.parse_args()


if __name__ == '__main__':
    main()
