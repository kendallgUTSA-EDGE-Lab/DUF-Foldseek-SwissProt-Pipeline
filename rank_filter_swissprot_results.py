#!/usr/bin/env python3
import csv
import math
import os
import sys
from collections import defaultdict

COLUMNS = [
    "query","target","qtmscore","ttmscore","alntmscore","rmsd","evalue",
    "qstart","qend","tstart","tend","qlen","tlen","alnlen"
]

QTM_THRESHOLD = 0.5
EVALUE_THRESHOLD = 0.05

def f(value, default=float("nan")):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default

def read_rows(path):
    rows = []
    with open(path, newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle, delimiter="\t")
        for i, fields in enumerate(reader, 1):
            if not fields:
                continue
            if len(fields) != len(COLUMNS):
                raise ValueError(
                    "Line %d has %d columns; expected %d"
                    % (i, len(fields), len(COLUMNS))
                )
            row = dict(zip(COLUMNS, fields))
            row["_qtm"] = f(row["qtmscore"])
            row["_evalue"] = f(row["evalue"], float("inf"))
            row["_rmsd"] = f(row["rmsd"], float("inf"))
            rows.append(row)
    return rows

def hit_key(row):
    qtm = row["_qtm"]
    if math.isnan(qtm):
        qtm = float("-inf")
    return (-qtm, row["_evalue"], row["_rmsd"], row["target"])

def write_rows(path, rows):
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=COLUMNS,
            delimiter="\t",
            extrasaction="ignore"
        )
        writer.writeheader()
        writer.writerows(rows)

def main():
    if len(sys.argv) != 2:
        print("Usage: python %s raw_foldseek_hits.tsv" % os.path.basename(sys.argv[0]))
        sys.exit(1)

    input_file = os.path.abspath(sys.argv[1])
    out_dir = os.path.dirname(input_file)
    rows = read_rows(input_file)

    ranked = sorted(rows, key=lambda r: (r["query"],) + hit_key(r))
    filtered = [
        r for r in ranked
        if not math.isnan(r["_qtm"])
        and r["_qtm"] > QTM_THRESHOLD
        and r["_evalue"] < EVALUE_THRESHOLD
    ]

    by_query = defaultdict(list)
    for row in ranked:
        by_query[row["query"]].append(row)

    best = []
    top5 = []
    for query in sorted(by_query):
        hits = by_query[query]
        if hits:
            best.append(hits[0])
            top5.extend(hits[:5])

    outputs = {
        "ranked_all_hits.tsv": ranked,
        "filtered_qtm0.5_evalue0.05.tsv": filtered,
        "best_hit_per_query.tsv": best,
        "top5_per_query.tsv": top5,
    }

    for name, data in outputs.items():
        write_rows(os.path.join(out_dir, name), data)

    print("Database: SwissProt")
    print("Total hits:", len(ranked))
    print("Filtered hits:", len(filtered))
    print("Queries:", len(by_query))
    for name in outputs:
        print(os.path.join(out_dir, name))

if __name__ == "__main__":
    main()
