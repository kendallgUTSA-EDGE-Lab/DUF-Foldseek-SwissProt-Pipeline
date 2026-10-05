# DUF-Foldseek-SwissProt-Pipeline

Search DUF-containing structures against a Foldseek-formatted Swiss-Prot structure database for curated functional annotation.

## Workflow

1. Create a Foldseek query database from PDB/CIF structures.
2. Search against the SwissProt Foldseek database.
3. Export qTM, tTM, alignment TM-score, RMSD, E-value, and alignment coordinates.
4. Rank hits primarily by **qTM score**.
5. Create filtered results using **qTM > 0.5** and **E-value < 0.05**.

## Software

Tested with:

```text
Foldseek 10.941cd33
Python 3
```

## Run

```bash
conda activate foldseek_env

bash foldseek_swissprot_batch.sh \
    /path/to/query_structures \
    /path/to/swissprot_database \
    ./results_swissprot \
    8
```

Then:

```bash
python rank_filter_swissprot_results.py results_swissprot/raw_swissprot_hits.tsv
```

## Raw output columns

```text
query
target
qtmscore
ttmscore
alntmscore
rmsd
evalue
qstart
qend
tstart
tend
qlen
tlen
alnlen
```

## Processed outputs

```text
ranked_all_hits.tsv
filtered_qtm0.5_evalue0.05.tsv
best_hit_per_query.tsv
top5_per_query.tsv
```

The primary ranking metric is qTM score, highest to lowest. E-value and RMSD are secondary tie-breakers.

## Long runs

For large searches:

```bash
tmux new -s foldseek_swissprot
```

Detach with `Ctrl+B`, then `D`, and reconnect with:

```bash
tmux attach -t foldseek_swissprot
```

## GitHub

The database files, query structure collection, temporary Foldseek files, and large generated result folders are excluded from version control by `.gitignore`.

Record the exact database version/download date used for analyses because database contents change over time.
