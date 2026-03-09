#!/usr/bin/env bash
set -u

# CS131 Sprint 3 Evidence Script
# Usage:
# ./scripts/run_sprint3.sh data/sample.tsv $'\t'

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <DATASET_PATH> <DELIM>" >&2
  exit 1
fi

DATASET="$1"
DELIM="$2"

OUT_DIR="out"
EVID_DIR="out/evidence"
LOG_FILE="out/run_sprint3.log"
ERR_FILE="out/errors.log"

mkdir -p "$EVID_DIR"
: > "$LOG_FILE"
: > "$ERR_FILE"

exec > >(tee -a "$LOG_FILE") 2> "$ERR_FILE"

if [[ ! -f "$DATASET" ]]; then
  echo "ERROR: dataset not found at $DATASET" >&2
  exit 2
fi

echo "Sprint 3 run started"
date
echo "Dataset: $DATASET"
echo "Delimiter: '$DELIM'"

echo "Generating top_categories.txt"
cut -d"$DELIM" -f6 "$DATASET" | tail -n +2 | sort | uniq -c | sort -nr | head -n 20 > "$EVID_DIR/top_categories.txt"

echo "Generating top_domains.txt"
cut -d"$DELIM" -f3 "$DATASET" | tail -n +2 | sed 's#https\?://##' | cut -d/ -f1 | sort | uniq -c | sort -nr | head -n 20 > "$EVID_DIR/top_domains.txt"

echo "Generating language_distribution.txt"
cut -d"$DELIM" -f5 "$DATASET" | tail -n +2 | sort | uniq -c | sort -nr > "$EVID_DIR/language_distribution.txt"

echo "Generating keyword_hits_rows.txt"
grep -iE 'bitcoin|crypto|ai|finance|war|market' "$DATASET" > "$EVID_DIR/keyword_hits_rows.txt" || true

echo "Generating keyword_hits_summary.txt"
wc -l "$EVID_DIR/keyword_hits_rows.txt" > "$EVID_DIR/keyword_hits_summary.txt"

echo "Generating trust_check_missing_primary_theme_count.txt"
cut -d"$DELIM" -f6 "$DATASET" | tail -n +2 | grep -Ei '^(NA|N/A|null|NULL|None|none)?$' | wc -l > "$EVID_DIR/trust_check_missing_primary_theme_count.txt"

echo "Generating assumption_test_language_values_top20.txt"
cut -d"$DELIM" -f5 "$DATASET" | tail -n +2 | sort | uniq -c | sort -nr | head -n 20 > "$EVID_DIR/assumption_test_language_values_top20.txt"

echo "Sprint 3 run completed"
date
