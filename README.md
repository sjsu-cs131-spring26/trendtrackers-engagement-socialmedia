# trendtrackers-engagement-socialmedia

## Team Members: 
Joshua Darlucio,
Ishita Thethy,
Serife Aynur Kocdas,
Arhaam Azhari,
Tejas Manjunatha.

### Dataset Information

Dataset Name: Exorde Social Media Dataset:- December 2024 (Week 1)
Domain: Social Media
Source: Hugging Face
Dataset Link: https://huggingface.co/datasets/Exorde/exorde-social-media-december-2024-week1

Intro to our dataset: This dataset contains a large scale collection of public social media posts gathered during the first week of December 2024. Each record includes multilingual text data along with metadata such as timestamps, detected language, sentiment scores, emotion labels, thematic categories, keywords, and source URLs. The dataset is stored in Parquet format, enabling efficient processing of large volumes of data.

## Final project for CS131 – Big Data Processing 

# TrendTrackers – Big Data Social Media Analysis

## Overview

This project focuses on building a data pipeline to analyze large-scale social media data using PySpark. The dataset contains over 65 million records collected from multiple platforms, including information such as text content, language, sentiment, themes, and timestamps.

The goal of the project is to take raw, unstructured data and transform it into useful insights using a distributed processing approach. The pipeline performs cleaning, transformation, and aggregation to generate structured outputs such as language distribution, theme distribution, sentiment by theme, and activity trends.

---

## Dataset

We used the **Exorde Social Media Dataset (December 2024, Week 1)** from Hugging Face.

- Size: 65.5 million records  
- Format: Parquet  
- Key fields:
  - Text content
  - Language
  - Theme classification
  - Sentiment score
  - Timestamp
  - Source URL

This dataset was chosen because it is large enough to require distributed processing and contains multiple dimensions for analysis.

---

## Project Structure

- `finaldemo_trendtrackers.ipynb` → Main notebook containing the pipeline and analysis

---

## How to Run the Project

### Requirements

- Python 3.x  
- PySpark  
- Google Cloud (Dataproc or similar setup)  
- Access to dataset in cloud storage (GCS)

---

### Steps

1. Upload dataset to Google Cloud Storage (GCS)

2. Start a Dataproc cluster or use a managed Spark environment

3. Run the notebook or PySpark script:
   - Read data from GCS
   - Apply transformations (filtering, grouping, aggregations)
   - Write output back to GCS

4. Outputs will be generated as aggregated tables (Parquet format)

---

## Pipeline Summary

The pipeline performs the following steps:

1. Data Loading
   - Reads Parquet data from cloud storage

2. Data Cleaning
   - Removes rows with missing or invalid values
   - Normalizes URL fields

3. Transformations
   - Grouping by language, theme, and date
   - Computing counts and average sentiment
   - Extracting domain information

4. Output Generation
   - Language distribution
   - Theme distribution
   - Sentiment by theme
   - Top domains
   - Daily activity trends

---

## Cloud Execution

The pipeline was executed using Google Cloud Dataproc in a distributed environment.

- Data stored in GCS
- Spark jobs executed across multiple workers
- Processing handled 65 million records efficiently

Execution logs and screenshots are included in the report as proof of distributed execution.

---

## Key Insights

- Most posts are in English (72% of dataset)
- User activity is concentrated in a few themes (Entertainment, People, Politics, Technology)
- Political content shows more negative sentiment compared to other themes
- A large portion of data comes from platforms like X (Twitter) and Reddit
- Daily activity remains consistently high (millions of posts per day)

---

## Notes

- This project focuses on batch processing (not real-time)
- Results depend on the dataset (one week of data)
- Sentiment scores are precomputed and may not capture full context

---

## Repository

Make sure to check the notebook for full pipeline implementation and outputs.
