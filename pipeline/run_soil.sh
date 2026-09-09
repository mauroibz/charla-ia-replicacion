#!/bin/bash
set -euo pipefail
cd /data
mkdir -p work/soil
cd work/soil

echo "== import =="
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-format PairedEndFastqManifestPhred33V2 \
  --input-path /data/manifest_soil.tsv \
  --output-path soil_demux.qza

echo "== dada2 denoise-paired (250bp reads, conservative truncation) =="
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs soil_demux.qza \
  --p-trim-left-f 0 \
  --p-trim-left-r 0 \
  --p-trunc-len-f 230 \
  --p-trunc-len-r 200 \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats denoising-stats.qza \
  --o-base-transition-stats base-transition-stats.qza \
  --p-n-threads 4 \
  --verbose

echo "== phylogeny =="
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

echo "== faith pd =="
qiime diversity alpha-phylogenetic \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-metric faith_pd \
  --o-alpha-diversity faith_pd_vector.qza

echo "== core metrics =="
mkdir -p alphas
for m in observed_features berger_parker_d shannon; do
  qiime diversity alpha \
    --i-table table.qza \
    --p-metric "$m" \
    --o-alpha-diversity "alphas/${m}.qza"
done

echo "== export =="
for f in alphas/*.qza; do
  qiime tools export --input-path "$f" --output-path "${f%.qza}"
done
qiime tools export --input-path faith_pd_vector.qza --output-path alphas/faith_pd
qiime tools export --input-path denoising-stats.qza --output-path denoising-stats
qiime tools export --input-path table.qza --output-path table-export

echo "DONE"
