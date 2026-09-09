#!/bin/bash
set -euo pipefail
cd /data/work_atacama

echo "== summarize (2026.7 API) =="
qiime feature-table summarize \
  --i-table table.qza \
  --m-metadata-file /data/atacama/sample_metadata.tsv \
  --o-feature-frequencies feature-frequencies.qza \
  --o-sample-frequencies sample-frequencies.qza \
  --o-summary table.qzv

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

echo "== core alpha metrics =="
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
qiime tools export --input-path table.qza --output-path table-export
biom summarize-table -i table-export/feature-table.biom -o table-export/summary.txt

echo "DONE"
