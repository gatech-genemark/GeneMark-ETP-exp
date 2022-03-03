#!/usr/bin/env bash
# ==============================================================
# Tomas Bruna
#
# Print an intersection of two annotation (on transcript level)
# ==============================================================

if  [ "$#" -ne 2 ]; then
    echo "Usage: $0 annot1.gtf annot2.gtf"
    exit
fi

first=$1; shift
second=$1; shift

bindir=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))
export PATH=$bindir:$PATH

shared=$(mktemp)
ids=$(mktemp)

compare_intervals_exact.pl --f1 "$first" --f2 "$second" --trans --out \
    "$shared" --shared12 --original 1 > /dev/null
tr " " "\n" < "$shared"  | tail -n +4 | awk '{print "\""$1"\""}' > "$ids"
grep -Ff "$ids" "$first"

rm "$shared" "$ids"
