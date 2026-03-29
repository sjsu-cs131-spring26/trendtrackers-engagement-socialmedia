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
echo "Starting AWK processing..."
# =========================
# STEP 5: FILTER VALID ROWS
# =========================
awk -F'\t' '
BEGIN { OFS="\t" }
NR==1 { print; next }

($1 != "NA" && $3 != "NA" && $5 != "NA" && $8 ~ /^-?[0-9]+(\.[0-9]+)?$/) {
    print
}
' out/cleaned_dataset.tsv > out/filtered_sample.tsv


# =========================
# STEP 6: SENTIMENT BUCKETS
# =========================
awk -F'\t' '
BEGIN { OFS="\t" }
NR==1 { next }

{
    r = $8 + 0

    if ($8 == "NA") {
        bucket = "NA"
    } else if (r >= 0.5) {
        bucket = "HI"
    } else if (r >= 0.1) {
        bucket = "MID"
    } else if (r > 0) {
        bucket = "LO"
    } else if (r == 0) {
        bucket = "ZERO"
    } else {
        bucket = "NEG"
    }

    c[bucket]++
}

END {
    print "bucket\tcount"
    print "HI\t" c["HI"]+0
    print "MID\t" c["MID"]+0
    print "LO\t" c["LO"]+0
    print "ZERO\t" c["ZERO"]+0
    print "NEG\t" c["NEG"]+0
    print "NA\t" c["NA"]+0
}
' out/filtered_sample.tsv > out/bucket_summary.tsv


# =========================
# STEP 7: LANGUAGE SUMMARY
# =========================
awk -F'\t' '
BEGIN { OFS="\t" }
NR==1 { next }

{
    lang = $5
    sentiment = $8 + 0

    if ($5 != "NA" && $8 != "NA") {
        sum[lang] += sentiment
        count[lang]++

        if (!(lang in min) || sentiment < min[lang]) min[lang] = sentiment
        if (!(lang in max) || sentiment > max[lang]) max[lang] = sentiment
    }
}

END {
    print "language\tcount\tavg_sentiment\tmin\tmax"
    for (l in count) {
        printf "%s\t%d\t%.4f\t%.4f\t%.4f\n", l, count[l], sum[l]/count[l], min[l], max[l]
    }
}
' out/filtered_sample.tsv | sort > out/entity_summary.tsv


echo "AWK processing complete."   
