#!/bin/bash
set -euo pipefail
cd /data
mkdir -p work_dada2/stool
cd work_dada2/stool

echo "== import =="
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-format SingleEndFastqManifestPhred33V2 \
  --input-path /data/manifest_stool.tsv \
  --output-path stool_demux.qza

echo "== dada2 denoise-single (trim-left 20, trunc-len 120, matched to Deblur's left-trim-len/trim-length for a fair comparison) =="
qiime dada2 denoise-single \
  --i-demultiplexed-seqs stool_demux.qza \
  --p-trim-left 20 \
  --p-trunc-len 120 \
  --p-n-threads 4 \
  --o-representative-sequences rep-seqs.qza \
  --o-table table.qza \
  --o-denoising-stats denoising-stats.qza \
  --o-base-transition-stats base-transition-stats.qza

qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv
qiime tools export --input-path denoising-stats.qzv --output-path denoising-stats-export

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

echo "DONE"
