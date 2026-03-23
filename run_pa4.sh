#!/usr/bin/env bash

# PA4 Data Cleaning Script
# Author: Arhaam Azhari
# Description: Cleans messy TSV dataset using sed + awk

set -euo pipefail

INPUT="${1:-}"

if [[ -z "$INPUT" ]]; then
    echo "Usage: bash run_pa4.sh <INPUT>" >&2
    exit 1
fi

if [[ ! -e "$INPUT" ]]; then
    echo "Error: input file does not exist: $INPUT" >&2
    exit 1
fi

if [[ ! -r "$INPUT" ]]; then
    echo "Error: input file is not readable: $INPUT" >&2
    exit 1
fi

mkdir -p out logs

chmod -R g+rX "$INPUT" 2>/dev/null || true

LOG_FILE="logs/run_pa4.log"
ERR_FILE="logs/run_pa4.err"

exec > >(tee "$LOG_FILE") 2> >(tee "$ERR_FILE" >&2)

echo "Starting PA4 cleaning..."
echo "Input file: $INPUT"

# Save small before sample
head -10 "$INPUT" > out/sample_before.tsv

# Step 1: remove Windows CR characters
sed 's/\r$//' "$INPUT" > out/temp1.tsv

# Step 2: reconstruct multiline records
awk '
NR==1 { print; next }

/^[0-9]{4}-[0-9]{2}-[0-9]{2}T/ {
    if (NR > 2) print record
    record = $0
    next
}

{
    record = record " " $0
}

END {
    if (record != "") print record
}
' out/temp1.tsv > out/temp2.tsv

# Step 3: trim spaces and normalize blank values to NA
awk -F'\t' '
BEGIN { OFS="\t" }

NR==1 { print; next }

{
    for (i = 1; i <= NF; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i)
        gsub(/[ \t]+/, " ", $i)
        if ($i == "") $i = "NA"
    }
    print
}
' out/temp2.tsv > out/temp3.tsv

# Step 4: light cleanup of secondary_themes
awk -F'\t' '
BEGIN { OFS="\t" }

NR==1 { print; next }

{
    if (NF >= 10) {
        gsub(/\[/, "", $10)
        gsub(/\]/, "", $10)
    }
    print
}
' out/temp3.tsv > out/cleaned_dataset.tsv

# Save small after sample
head -10 out/cleaned_dataset.tsv > out/sample_after.tsv

echo "Checking field consistency..."
awk -F'\t' '{print NF}' out/cleaned_dataset.tsv | sort | uniq -c

echo "Original line count:"
wc -l "$INPUT"

echo "Cleaned line count:"
wc -l out/cleaned_dataset.tsv

echo "Cleaning complete."
