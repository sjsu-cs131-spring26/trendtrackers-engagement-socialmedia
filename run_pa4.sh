#!/usr/bin/env bash

# Trendtrackers Project Assignment 4 Script
# Authors: Arhaam Azhari, Serife Aynur Kocdas, Tejas Manjunatha
# Description: Cleans dataset, then generates output files containing information about social media usage

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

# Step 5: Filter valid rows
awk -F'\t' '
BEGIN { OFS="\t" }
NR==1 { print; next }

($1 != "NA" && $3 != "NA" && $5 != "NA" && $8 ~ /^-?[0-9]+(\.[0-9]+)?$/) {
    print
}
' out/cleaned_dataset.tsv > out/filtered_sample.tsv

# Step 6: Sentiment Buckets
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

# Step 7: Language Summary
# 1. Print the header directly to the file first (overwriting if it exists)
echo -e "language\tcount\tavg_sentiment\tmin\tmax" > out/entity_summary.tsv

# 2. Process data, sort only the data rows, and append to the file
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
    for (l in count) {
        printf "%s\t%d\t%.4f\t%.4f\t%.4f\n", l, count[l], sum[l]/count[l], min[l], max[l]
    }
}
' out/filtered_sample.tsv | sort >> out/entity_summary.tsv

# Step 8: Top Keywords in primary_theme
echo "Calculating top primary themes..."
echo -e "primary_theme\tcount" > out/top_keywords.tsv

awk -F'\t' '
BEGIN { OFS="\t" }
NR==1 { next }

{
    theme = $6
    if (theme != "NA" && theme != "") {
        theme_count[theme]++
    }
}

END {
    for (t in theme_count) {
        print t, theme_count[t]
    }
}
' out/filtered_sample.tsv | sort -t$'\t' -k2,2nr >> out/top_keywords.tsv


# Step 9: Top URLs
echo "Calculating top URL domains..."
echo -e "domain\tcount" > out/top_urls.tsv

awk -F'\t' '
BEGIN { OFS="\t" }
NR==1 { next }

{
    url = $3
    if (url != "NA" && url != "") {
        # 1. Strip the http:// or https:// protocol if it exists
        sub(/^https?:\/\//, "", url)
        
        # 2. Strip the first forward slash and everything after it
        sub(/\/.*/, "", url)
        
        # Add the cleaned domain to our count
        if (url != "") {
            url_count[url]++
        }
    }
}

END {
    for (u in url_count) {
        print u, url_count[u]
    }
}
' out/filtered_sample.tsv | sort -t$'\t' -k2,2nr >> out/top_urls.tsv

echo "AWK processing complete."
