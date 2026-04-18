#!/usr/bin/env bash
set -u

# CS131 Sprint 3 Evidence Script
# Usage:
#When running on the 1k line sample
# ./scripts/run_sprint3.sh data/sample.tsv $'\t'
#When running on the 10k line sample
# ./scripts/run_sprint3.sh data/sample10k.tsv $'\t'
#When running on one section of the entire dataset
# ./scripts/run_sprint3.sh data/processed_data_0.tsv $'\t'

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

#Lists the top themes discussed by social media users within the provided dataset
echo "Generating top_categories.txt"
cut -d"$DELIM" -f6 "$DATASET" | tail -n +2 | grep -E '^[A-Za-z]' | sort | uniq -c | sort -nr | head -n 15 > "$EVID_DIR/top_categories.txt"

#Lists the top social media website domains where posts were made that exist within the dataset
echo "Generating top_domains.txt"
cut -d"$DELIM" -f3 "$DATASET" | tail -n +2 | sed -E 's#^https?://##; s#^www\.##' | cut -d/ -f1 | grep -E '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | sort | uniq -c | sort -nr | head -n 20 > "$EVID_DIR/top_domains.txt"

#Lists the most common languages which users made posts in within the dataset
echo "Generating language_distribution.txt"
cut -d"$DELIM" -f5 "$DATASET" | tail -n +2 | grep -E '^[A-Za-z]{2}$' | sort | uniq -c | sort -nr > "$EVID_DIR/language_distribution.txt"

#Creates a new tsv with every row in the input dataset that contained at least one target word
echo "Generating keyword_hits_rows.tsv"
grep -iwE 'bitcoin|crypto|ai|finance|war|market' "$DATASET" > "$EVID_DIR/keyword_hits_rows.tsv" || true

#Counts the number of rows that contain at least one target word in the dataset
echo "Generating keyword_hits_summary.txt"
wc -l < "$EVID_DIR/keyword_hits_rows.tsv" > "$EVID_DIR/keyword_hits_summary.txt"

#Counts the number of rows with a missing or blank theme of post in the dataset
echo "Generating trust_check_missing_primary_theme_count.txt"
cut -d"$DELIM" -f6 "$DATASET" | tail -n +2 | grep -Ei '^(NA|N/A|null|NULL|None|none)?$' | wc -l > "$EVID_DIR/trust_check_missing_primary_theme_count.txt"

#Checks to see if the post language column is actually formatted cleanly or not, analyzing the raw data
echo "Generating assumption_test_language_values_top20.txt"
cut -d"$DELIM" -f5 "$DATASET" | tail -n +2 | sort | uniq -c | sort -nr | head -n 20 > "$EVID_DIR/assumption_test_language_values_top20.txt"

echo "Sprint 3 run completed"
date
