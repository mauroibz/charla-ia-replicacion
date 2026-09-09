#!/bin/bash
set -euo pipefail
cd /data
mkdir -p work_atacama
cd work_atacama

echo "== import =="
qiime tools import \
  --type EMPPairedEndSequences \
  --input-path /data/atacama/10p \
  --output-path emp-paired-end-sequences.qza

echo "== demux =="
qiime demux emp-paired \
  --m-barcodes-file /data/atacama/sample_metadata.tsv \
  --m-barcodes-column barcode-sequence \
  --p-rev-comp-mapping-barcodes \
  --i-seqs emp-paired-end-sequences.qza \
  --o-per-sample-sequences demux-full.qza \
  --o-error-correction-details demux-details.qza

echo "== subsample 0.3 =="
qiime demux subsample-paired \
  --i-sequences demux-full.qza \
  --p-fraction 0.3 \
  --o-subsampled-sequences demux-subsample.qza

qiime demux summarize \
  --i-data demux-subsample.qza \
  --o-visualization demux-subsample.qzv

echo "== filter samples >100 reads =="
qiime tools export \
  --input-path demux-subsample.qzv \
  --output-path ./demux-subsample-export/

qiime demux filter-samples \
  --i-demux demux-subsample.qza \
  --m-metadata-file ./demux-subsample-export/per-sample-fastq-counts.tsv \
  --p-where 'CAST([forward sequence count] AS INT) > 100' \
  --o-filtered-demux demux.qza

echo "== dada2 denoise (official tutorial params: trim-left 13/13, trunc-len 150/150) =="
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 13 \
  --p-trim-left-r 13 \
  --p-trunc-len-f 150 \
  --p-trunc-len-r 150 \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats denoising-stats.qza \
  --o-base-transition-stats base-transition-stats.qza

echo "== summarize =="
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file /data/atacama/sample_metadata.tsv

qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv

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

echo "== core alpha metrics (same 4 as the main deck pipeline) =="
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
qiime tools export --input-path denoising-stats.qza --output-path denoising-stats-export

echo "DONE"
