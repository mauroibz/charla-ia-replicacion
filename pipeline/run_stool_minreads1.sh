#!/bin/bash
set -euo pipefail
cd /data
mkdir -p work_minreads1/stool
cd work_minreads1/stool

cp /data/work/stool/demux-filtered.qza .

echo "== deblur denoise-16S, SAME params as run_stool.sh but --p-min-reads 1 =="
qiime deblur denoise-16S \
  --i-demultiplexed-seqs demux-filtered.qza \
  --p-left-trim-len 20 \
  --p-trim-length 120 \
  --p-min-reads 1 \
  --p-jobs-to-start 4 \
  --o-representative-sequences rep-seqs.qza \
  --o-table table.qza \
  --p-sample-stats \
  --o-stats deblur-stats.qza

echo "== phylogeny =="
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

echo "== faith pd =="
qiime diversity alpha-phylogenetic \
  --i-table table.qza --i-phylogeny rooted-tree.qza \
  --p-metric faith_pd --o-alpha-diversity faith_pd_vector.qza

mkdir -p alphas
for m in observed_features berger_parker_d shannon; do
  qiime diversity alpha --i-table table.qza --p-metric "$m" \
    --o-alpha-diversity "alphas/${m}.qza"
done
for f in alphas/*.qza; do qiime tools export --input-path "$f" --output-path "${f%.qza}"; done
qiime tools export --input-path faith_pd_vector.qza --output-path alphas/faith_pd
qiime tools export --input-path deblur-stats.qza --output-path deblur-stats-export
qiime tools export --input-path table.qza --output-path table-export
biom convert -i table-export/feature-table.biom -o table-export/feature-table.tsv --to-tsv
echo DONE
