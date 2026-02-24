#!/bin/bash
set -e

INPUT_DATASET="$1"

if [ -z "$INPUT_DATASET" ]; then
  echo "Usage: ./run_project2.sh <dataset_path>"
  exit 1
fi
# 2. Create directories
mkdir -p data
mkdir -p out
mkdir -p logs

# 3. Log everything
exec > logs/run_project2.log 2>&1

echo "Starting pipeline"
date
echo "Using dataset: $INPUT_DATASET"

# Generate 1k reproducible sample 
python3 - << EOF
import csv, random

random.seed(42)

input_path = "$INPUT_DATASET"
output_path = "data/sample.tsv"

with open(input_path, 'r', encoding='utf-8') as f:
    reader = csv.reader(f, delimiter='\t')
    header = next(reader)
    rows = list(reader)

sample = random.sample(rows, min(1000, len(rows)))

with open(output_path, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f, delimiter='\t')
    writer.writerow(header)
    writer.writerows(sample)

print("Sample created at data/sample.tsv")
EOF

# Frequency table: language (using tee)
tail -n +2 data/sample.tsv \ | cut -f5 \| grep -E '^[a-z][a-z]$' \ | sort \ | uniq -c \ | sort -nr \ | tee out/freq_language.txt

echo "Created: out/freq_language.txt"

# Frequency table: primary_theme
tail -n +2 data/sample.tsv | grep '^2024-' | cut -f6 | grep -E '^[A-Za-z][A-Za-z_-]*$' | sort | uniq -c | sort -nr > out/freq_primary_theme.txt
echo "Created: out/freq_primary_theme.txt"

# Top 10 domains
tail -n +2 data/sample.tsv | grep '^2024-' | cut -f3 | cut -d '/' -f3 | grep -v '^$' | sort | uniq -c | sort -nr | head -n 10 > out/top10_domains.txt
echo "Created: out/top10_domains.txt"

# Skinny table (date, language, primary_theme)
tail -n +2 data/sample.tsv | grep '^2024-' | cut -f1,5,6 | grep -E $'\t[a-z][a-z]\t[^\t]' | sort -u > out/skinny_date_lang_theme.txt
echo "Created: out/skinny_date_lang_theme.txt"

# grep -i example
grep -i bitcoin data/sample.tsv | grep '^2024-' > out/grep_i_bitcoin.txt
echo "Created: out/grep_i_bitcoin.txt"

# grep -v example
tail -n +2 data/sample.tsv | grep '^2024-' | grep -v $'\tPolitics\t' > out/grep_v_not_politics.txt
echo "Created: out/grep_v_not_politics.txt"

# stdout vs stderr demo
ls data/sample.tsv data/DOES_NOT_EXIST.tsv > out/results_ls.txt 2> out/errors_ls.txt
echo "Created: out/results_ls.txt"
echo "Created: out/errors_ls.txt"
