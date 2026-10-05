#!/usr/bin/env bash
set -euo pipefail

# Foldseek batch structural-search pipeline: SwissProt
# Usage:
# bash foldseek_swissprot_batch.sh QUERY_DIR DATABASE OUT_DIR [THREADS]
# Tested with Foldseek 10.941cd33.

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 QUERY_DIR DATABASE OUT_DIR [THREADS]"
  exit 1
fi

QUERY_DIR="$1"
DATABASE="$2"
OUT_DIR="$3"
THREADS="${4:-8}"
FOLDSEEK_BIN="${FOLDSEEK_BIN:-foldseek}"

QUERY_DB="${OUT_DIR}/queryDB"
RESULT_DB="${OUT_DIR}/resultDB"
TMP_DIR="${OUT_DIR}/tmp"
RAW_TSV="${OUT_DIR}/raw_swissprot_hits.tsv"

FORMAT_FIELDS="query,target,qtmscore,ttmscore,alntmscore,rmsd,evalue,qstart,qend,tstart,tend,qlen,tlen,alnlen"

echo "Host: $(hostname)"
echo "Date: $(date)"
echo "Query dir: $QUERY_DIR"
echo "Database: $DATABASE"
echo "Output dir: $OUT_DIR"
echo "Threads: $THREADS"

if ! command -v "$FOLDSEEK_BIN" >/dev/null 2>&1; then
  echo "ERROR: foldseek not found. Activate your environment, e.g. conda activate foldseek_env"
  exit 1
fi

"$FOLDSEEK_BIN" version || true

if [[ ! -d "$QUERY_DIR" ]]; then
  echo "ERROR: query directory not found: $QUERY_DIR"
  exit 1
fi

if [[ ! -e "$DATABASE" && ! -e "${DATABASE}.dbtype" ]]; then
  echo "ERROR: Foldseek database not found: $DATABASE"
  exit 1
fi

mkdir -p "$OUT_DIR" "$TMP_DIR"

QUERY_COUNT=$(find "$QUERY_DIR" -maxdepth 1 -type f \( -iname "*.pdb" -o -iname "*.cif" -o -iname "*.mmcif" \) | wc -l)
echo "Query structures found: $QUERY_COUNT"

if [[ "$QUERY_COUNT" -eq 0 ]]; then
  echo "ERROR: no PDB/CIF/mmCIF query structures found."
  exit 1
fi

echo "STEP 1/3: creating query database"
rm -f "${QUERY_DB}"* "${RESULT_DB}"* 2>/dev/null || true
"$FOLDSEEK_BIN" createdb "$QUERY_DIR" "$QUERY_DB"

echo "STEP 2/3: searching SwissProt"
"$FOLDSEEK_BIN" search "$QUERY_DB" "$DATABASE" "$RESULT_DB" "$TMP_DIR" --threads "$THREADS"

echo "STEP 3/3: converting results"
"$FOLDSEEK_BIN" convertalis "$QUERY_DB" "$DATABASE" "$RESULT_DB" "$RAW_TSV" --format-output "$FORMAT_FIELDS"

echo "Search complete."
echo "Raw TSV: $RAW_TSV"
wc -l "$RAW_TSV"
ls -lh "$RAW_TSV"
echo "Next:"
echo "python rank_filter_swissprot_results.py \"$RAW_TSV\""
