#!/bin/bash
set -euo pipefail
cd /data
mkdir -p work_full308/stool
cd work_full308/stool

echo "== import 308 samples =="
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-format SingleEndFastqManifestPhred33V2 \
  --input-path /data/manifest_full.tsv \
  --output-path stool_demux.qza

echo "== quality filter =="
qiime quality-filter q-score \
  --i-demux stool_demux.qza \
  --o-filtered-sequences demux-filtered.qza \
  --o-filter-stats demux-filter-stats.qza

echo "== deblur denoise-16S (default --p-min-reads 10, pooled over all 308 samples) =="
qiime deblur denoise-16S \
  --i-demultiplexed-seqs demux-filtered.qza \
  --p-left-trim-len 20 \
  --p-trim-length 120 \
  --p-jobs-to-start 10 \
  --o-representative-sequences rep-seqs.qza \
  --o-table table.qza \
  --p-sample-stats \
  --o-stats deblur-stats.qza

echo "== table export (fast metrics first) =="
mkdir -p alphas
for m in observed_features berger_parker_d shannon; do
  qiime diversity alpha --i-table table.qza --p-metric "$m" \
    --o-alpha-diversity "alphas/${m}.qza"
  qiime tools export --input-path "alphas/${m}.qza" --output-path "alphas/${m}"
done
qiime tools export --input-path deblur-stats.qza --output-path deblur-stats-export
echo "FASTMETRICS_DONE"

echo "== phylogeny (whole-dataset tree) =="
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --p-n-threads 10 \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

echo "== faith pd =="
qiime diversity alpha-phylogenetic \
  --i-table table.qza --i-phylogeny rooted-tree.qza \
  --p-metric faith_pd --o-alpha-diversity faith_pd_vector.qza
qiime tools export --input-path faith_pd_vector.qza --output-path alphas/faith_pd
echo DONE
