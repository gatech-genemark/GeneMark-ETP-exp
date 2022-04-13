#!/usr/bin/env python3
# ==============================================================
# Tomas Bruna
# Copyright 2020, Georgia Institute of Technology, USA
#
# ==============================================================


import argparse
import matplotlib.pyplot as plt
import pandas as pd


def processData(data):
    data["F1"] = 2 * data["Sn"] * data["Sp"] / (data["Sn"] + data["Sp"])
    overallSnSp = data.tail(1)
    data = data[:-1]
    return overallSnSp, data


def plot(data, output, title, ymin, ymax):

    overallSnSp, acc = processData(data)

    #fig, ax1 = plt.subplots(figsize=(6.4, 5.8))
    fig, ax1 = plt.subplots()

    snColor = "tab:blue"
    spColor = "tab:orange"
    f1Color = "black"

    ax1.plot(acc["penalty"], acc["Sn"], linestyle='-', marker='.',
             lw=1, color=snColor, label='Sn')
    ax1.plot(acc["penalty"], acc["Sp"], linestyle='-', marker='.',
             lw=1, color=spColor, label='Sp')
    ax1.plot(acc["penalty"], acc["F1"], linestyle='-', marker='.',
             lw=1, color=f1Color, label='F1')

    ax1.axhline(float(overallSnSp["Sn"]), 0, 1, color=snColor,
                lw=0.8, linestyle='--',  label='Baseline Sn')
    ax1.axhline(float(overallSnSp["Sp"]), 0, 1, color=spColor,
                lw=0.8, linestyle='--', label='Baseline Sp')
    ax1.axhline(float(overallSnSp["F1"]), 0, 1, color=f1Color,
                lw=0.8, linestyle='--', label='Baseline F1')

    ax1.set_xlabel("Repeat penalty (negative)")
    ax1.set_ylabel("Accuracy (%)")

    ax1.set_ylim(ymin, ymax)

    #ax1.legend(loc='upper center',  bbox_to_anchor=(0.5, -0.15), ncol=2)
    ax1.legend(loc='lower left')

    plt.title(title.replace("_", " "))
    ax1.tick_params(axis="x", labelsize=7)
    for label in ax1.xaxis.get_ticklabels()[1::2]:
        label.set_visible(False)

    plt.tight_layout()
    plt.savefig(output, dpi=600)


def main():
    args = parseCmd()
    data = pd.read_csv(args.input, sep="\t")
    plot(data, args.output, args.title, args.ymin, args.ymax)


def parseCmd():

    parser = argparse.ArgumentParser(description='')

    parser.add_argument('input', type=str)
    parser.add_argument('output', type=str)
    parser.add_argument('--title', default="", type=str)
    parser.add_argument('--ymin', type=float, default=0)
    parser.add_argument('--ymax', type=float, default=100)

    return parser.parse_args()


if __name__ == '__main__':
    main()
