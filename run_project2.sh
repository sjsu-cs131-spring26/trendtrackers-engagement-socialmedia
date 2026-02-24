#!/bin/bash
# run_project2.sh
# Usage: ./run_project2.sh
#
# Dataset path:
#   data/raw.tsv
#
# Delimiter:
#   Tab (TSV)
#
# Assumptions:
# - First row is header
# - Columns: 1=date, 3=url, 5=language, 6=primary_theme

mkdir -p data
mkdir -p out
mkdir -p logs

# Emit log
exec > logs/run_project2.log 2>&1

# Generate 1k sample (preserve header)
python3 -c "
import csv, random
with open('../data/processed_data_0.tsv', 'r', encoding='utf-8') as f:
    reader = csv.reader(f, delimiter='\t')
    header = next(reader)
    rows = list(reader) # Loads file into memory
sample = random.sample(rows, min(1000, len(rows)))
with open('../trendtrackers-engagement-socialmedia/data/sample.tsv', 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f, delimiter='\t')
    writer.writerow(header)
    writer.writerows(sample)
"

# Frequency table: language
tail -n +2 data/sample.tsv | cut -f5 | grep -E '^[a-z][a-z]$' | sort | uniq -c | sort -nr > out/freq_language.txt
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
