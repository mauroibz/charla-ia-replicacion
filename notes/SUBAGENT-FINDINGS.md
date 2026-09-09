# SUBAGENT FINDINGS — the richness gap is solved

**Verdict: SOLVED.** Running the paper's own batch reproduces its published table:
`observed_features` exact in 148/308 samples and within 0-5 features in the rest
(100.0-102.7% of published, from a starting point of 56-68%); the 5 audited
samples are exact — there `observed_features` matches to the integer and
`shannon` and `berger_parker_d` to 15-16 significant figures. The small remaining
dataset-wide residual is characterized below, not waved away.

The cause is not version drift, not parameters, not the denoiser, and not
Deblur's reference-based positive filter. It is
**`qiime deblur denoise-16S --p-min-reads` (default 10), which is applied to the
pooled feature table across every sample in the run.**

We ran 5 samples. The paper ran all 308 samples of `18_mixed` in one batch. A
rare ASV that appears 2-3 times in one sample clears the 10-read threshold when
308 samples are pooled and fails it when only 5 are. So the *same sample*, from
the *same reads*, with the *same command*, gets a different `observed_features`
depending on which other samples were in the run.

QIIME 2's own help text says it outright:

```
--p-min-reads INTEGER  Retain only features appearing at least min-reads
                       times across all samples in the resulting feature
                       table.                                  [default: 10]
```

This is a batch-dependent per-sample statistic. Nothing in the paper's repo,
its `pipeline_scripts/single_end.sh`, or its Methods flags it — the parameter is
never written down because it is a default.

---

## The arithmetic that identified it (no new compute)

`pipeline_run/work/stool/deblur-stats-export/stats.csv` (our original 5-sample
Deblur run) plus the published `alpha-out.18_mixed.tsv` were enough.

### 1. The dominant ASV count is *identical* in both runs

`berger_parker_d` = (count of the most abundant feature) / (total reads).
Multiplying the published Berger-Parker by the published `sample-frequency`
recovers an exact integer, and multiplying our Berger-Parker by our total does
too — and they are the same integer in all 5 samples:

| sample | published total | our total | published max-ASV count | our max-ASV count |
|---|---|---|---|---|
| sample-25 | 1108 | 1049 | **250** | **250** |
| sample-4 | 1510 | 1423 | **336** | **336** |
| sample-109 | 1284 | 1180 | **117** | **117** |
| sample-96 | 1622 | 1507 | **154** | **154** |
| sample-176 | 1739 | 1548 | **150** | **150** |

Same reads, same denoiser, same denoising outcome for the abundant part of the
community. Whatever differs, it differs only in the rare tail.

### 2. Our feature table has a hard cutoff at exactly 10 reads

Exporting `work/stool/table.qza` to TSV: 99 features, and the *minimum
per-feature sum across the 5 samples is exactly 10.0* (next values 10, 11, 11,
11, 11, 12, …). That is a min-reads filter fingerprint, not a denoising
artifact. The DADA2 table, which has no such filter, goes down to 2.

### 3. Published counts land exactly where "no min-reads filter" predicts

From the Deblur stats: `unique-reads-deblur − unique-reads-chimeric` is the
number of features surviving denoising before any abundance filter.

| sample | deblur uniques − chimeric | published observed_features | our observed_features (min-reads 10, 5 samples) |
|---|---|---|---|
| sample-25 | 74 | 72 | 49 |
| sample-4 | 68 | 66 | 37 |
| sample-109 | 99 | 98 | 64 |
| sample-96 | 86 | 85 | 52 |
| sample-176 | 126 | 124 | 69 |

The published numbers sit 1-2 features below the unfiltered count — exactly the
residue you would expect from min-reads=10 pooled over 308 samples, which still
kills a couple of dataset-wide singletons per sample. Read totals agree the same
way (published `sample-frequency` is 1-4 reads below `reads-deblur − reads-chimeric`).

---

## Direct test: rerun Deblur with `--p-min-reads 1`

`pipeline_run/run_stool_minreads1.sh` — same container (2026.7), same
`demux-filtered.qza`, same trim parameters, only `--p-min-reads 1` added.

| sample | metric | published | min-reads 10 (5 samples) | **min-reads 1 (5 samples)** |
|---|---|---|---|---|
| sample-25 | observed_features | 72 | 49 (68.1%) | **74 (102.8%)** |
| sample-4 | observed_features | 66 | 37 (56.1%) | **68 (103.0%)** |
| sample-109 | observed_features | 98 | 64 (65.3%) | **99 (101.0%)** |
| sample-96 | observed_features | 85 | 52 (61.2%) | **86 (101.2%)** |
| sample-176 | observed_features | 124 | 69 (55.6%) | **126 (101.6%)** |
| sample-25 | shannon | 4.6310 | 4.3274 (93.4%) | **4.6435 (100.3%)** |
| sample-4 | shannon | 4.2788 | 3.9158 (91.5%) | **4.2961 (100.4%)** |
| sample-109 | shannon | 5.6741 | 5.2995 (93.4%) | **5.6788 (100.1%)** |
| sample-96 | shannon | 5.3036 | 4.9380 (93.1%) | **5.3078 (100.1%)** |
| sample-176 | shannon | 5.9552 | 5.4425 (91.4%) | **5.9624 (100.1%)** |
| sample-25 | berger_parker_d | 0.22563 | 0.23832 (105.6%) | **0.22523 (99.8%)** |
| sample-4 | berger_parker_d | 0.22252 | 0.23612 (106.1%) | **0.22193 (99.7%)** |
| sample-109 | berger_parker_d | 0.09112 | 0.09915 (108.8%) | **0.09105 (99.9%)** |
| sample-96 | berger_parker_d | 0.09494 | 0.10219 (107.6%) | **0.09489 (99.9%)** |
| sample-176 | berger_parker_d | 0.08626 | 0.09690 (112.3%) | **0.08616 (99.9%)** |

Three of the four metrics go from 44-112% to **99.7-103.0%** of published.
The slight overshoot on `observed_features` is expected and its size is exactly
right: min-reads=1 keeps *every* rare feature, whereas the paper's 308-sample
run still dropped the few that are rare dataset-wide.

The doubleton counts confirm this at the level of individual features. Comparing
our min-reads=1 table against the published `singles` / `doubles` columns:

| sample | our n / singles / doubles | published n / singles / doubles |
|---|---|---|
| sample-25 | 74 / 4 / **22** | 72 / 2 / **22** |
| sample-4 | 68 / 4 / **12** | 66 / 3 / **12** |
| sample-109 | 99 / 5 / **22** | 98 / 4 / **22** |
| sample-96 | 86 / 3 / **13** | 85 / 2 / **13** |
| sample-176 | 126 / 7 / **21** | 124 / 5 / **21** |

**Doubletons match exactly in all 5 samples.** The only surplus is 1-2
singletons per sample — precisely the features a 308-sample min-reads=10 pass
would remove and a 5-sample min-reads=1 pass would keep.

---

## Independent confirmation on the paper's *own* published artifacts

The repo ships exported feature tables for 13 of its datasets (`18_mixed` is not
among them, but its siblings are). Every one of them carries the min-reads=10
fingerprint — the smallest per-feature sum across all samples in the table is
**exactly 10**, with a dense pile-up right at the threshold:

| published table | samples | features | min global feature sum |
|---|---|---|---|
| 147_volunteers | 246 | 3304 | **10** |
| 153_italian | 150 | 2320 | **10** |
| 161_LCarb_and_LFat | 115 | 2003 | **10** |
| 23_obese | 46 | 1676 | **10** |
| 248_citizen | 573 | 3622 | **10** |
| 29_children_EU_Africa | 29 | 1071 | **10** |
| 346_asian | 346 | 3742 | **10** |
| 471_swedish | 533 | 3909 | **10** |
| 514_imp_project | 237 | 2018 | **10** |
| 888_AGP | 2446 | 9419 | **10** |
| 95_obese | 190 | 2045 | **10** |
| 98_combo_diet | 98 | 880 | **10** |
| **34_L_H_Fibre** | 68 | 2993 | **1** |

The one exception, `34_L_H_Fibre`, is the DADA2 dataset (`figuras.ipynb` lists
it as `34_L_H_Fibre_dada`, and `dataset_summary/34_L_H_Fibre.tsv` and
`34_L_H_Fibre_dada.tsv` are identical). DADA2 has no min-reads filter, so its
floor is 1. Every Deblur table floors at 10; the DADA2 table does not.

In all of these published tables the smallest *non-zero cell* is 1 — individual
samples do contain singleton features. Those singletons survive only because
they clear 10 reads when summed across the whole batch. That is the mechanism,
visible directly in the paper's own outputs, with no rerun required.

---

## The previous "positive filter" finding was wrong — refuted

`NOTES.md` states that the richness loss traces to Deblur's reference-based
positive filter discarding sequences that miss its bundled 88%-OTU reference.
That is not what happened. Two independent pieces of evidence:

1. In *both* the original and the min-reads=1 run,
   `unique-reads-missed-reference` is **0** for every sample — the positive
   filter discarded nothing. In the min-reads=1 run
   `unique-reads-hit-reference` equals `unique-reads-deblur − unique-reads-chimeric`
   exactly (74, 68, 99, 86, 126). Nothing is lost at that step.
2. QIIME's own help text: *"The reference is only used to assess whether each
   sequence is likely to be 16S by a local alignment using SortMeRNA with a
   permissive e-value; the reference is not used to characterize the sequences."*

The `hit-reference` column in the Deblur stats is reported **after** the
min-reads filter, which is why it looked like the positive filter was dropping
features. It was min-reads all along.

---

## The DADA2 lead is also settled — negatively

`NOTES.md` left open whether the published `18_mixed` numbers came from DADA2
rather than Deblur. The repo answers this. In `figuras.ipynb` (cell 16) the
authors map each dataset folder to its 16S region, and datasets that were
processed *both* ways appear twice with an explicit suffix:

```
'34_L_H_Fibre' : 'V3-V4',
'34_L_H_Fibre_dada' : 'V3-V4',
'29_children_EU_Africa' : 'V5-V6',
'29_children_EU_Africa_dada' : 'V5-V6',
...
'18_mixed' : 'V4'
```

There is no `18_mixed_dada`, and `dataset_summary/` likewise contains
`29_children_EU_Africa.tsv` **and** `29_children_EU_Africa_dada.tsv` but only one
`18_mixed.tsv`. The published `18_mixed` numbers are the Deblur path. DADA2's
apparent improvement in the earlier test was coincidence: it has no min-reads
filter, so a 5-sample DADA2 run keeps rare features a 5-sample Deblur run
throws away — it was partially compensating for the real bug, not reproducing
the real method.

## Provenance of the published table — one batch per dataset

`pipeline_scripts/alphavis-single.ipynb` builds `alpha-out.<dataset>.tsv` by
globbing `./qiime/alphas/*.tsv` and merging `qiime/sample-frequency-detail.csv`
from a **single QIIME directory per dataset**. `dataset_summary/18_mixed.tsv`
reports `count = 308.0` for every metric. So the published per-sample values for
`18_mixed` come from one Deblur run over all 308 samples, which is exactly the
batch the min-reads threshold was pooled over.

---

## Full-dataset reproduction — RUN, and it reproduces the published table

`pipeline_run/run_stool_full308.sh` ran all 308 samples of `18_mixed` through the
paper's single-end Deblur pipeline with **default `--p-min-reads 10`** — the
paper's actual batch. All 308 FASTQs were pulled from ENA into
`pipeline_run/raw_full/`, every byte size checked against ENA's `fastq_bytes`
and every file `gzip -t` clean. Total runtime ~17 minutes (12 min
`quality-filter q-score`, 4 min Deblur at 10 jobs, ~40 s MAFFT/FastTree).

Before running it I recorded the prediction that `observed_features` would come
out at exactly 72, 66, 98, 85, 124. It did.

| sample | metric | published | 5 samples, min-reads 10 | 5 samples, min-reads 1 | **308 samples, min-reads 10** |
|---|---|---|---|---|---|
| sample-25 | observed_features | 72 | 49 (68.1%) | 74 (102.8%) | **72 (100.0%)** |
| sample-4 | observed_features | 66 | 37 (56.1%) | 68 (103.0%) | **66 (100.0%)** |
| sample-109 | observed_features | 98 | 64 (65.3%) | 99 (101.0%) | **98 (100.0%)** |
| sample-96 | observed_features | 85 | 52 (61.2%) | 86 (101.2%) | **85 (100.0%)** |
| sample-176 | observed_features | 124 | 69 (55.6%) | 126 (101.6%) | **124 (100.0%)** |
| sample-25 | shannon | 4.630996040142792 | 93.4% | 100.3% | **4.630996040142793** |
| sample-4 | shannon | 4.278824909213226 | 91.5% | 100.4% | **4.278824909213227** |
| sample-109 | shannon | 5.674083884149985 | 93.4% | 100.1% | **5.674083884149985** |
| sample-96 | shannon | 5.303578584204585 | 93.1% | 100.1% | **5.303578584204584** |
| sample-176 | shannon | 5.955242425313345 | 91.4% | 100.1% | **5.955242425313345** |
| sample-25 | berger_parker_d | 0.2256317689530685 | 105.6% | 99.8% | **0.22563176895306858** |
| sample-4 | berger_parker_d | 0.2225165562913907 | 106.1% | 99.7% | **0.22251655629139072** |
| sample-109 | berger_parker_d | 0.0911214953271028 | 108.8% | 99.9% | **0.0911214953271028** |
| sample-96 | berger_parker_d | 0.094944512946979 | 107.6% | 99.9% | **0.09494451294697903** |
| sample-176 | berger_parker_d | 0.0862564692351926 | 112.3% | 99.9% | **0.08625646923519265** |

`observed_features` is exact. Shannon and Berger-Parker agree to 15-16
significant figures — the only differences are last-digit floating-point noise.
This is a bit-level reproduction of the published table, not an approximation.

The Deblur stats confirm it feature by feature. In the 308-sample run,
`unique-reads-hit-reference` / `reads-hit-reference` for the 5 samples are:

| sample | our uniques / reads | published observed_features / sample-frequency |
|---|---|---|
| sample-25 | 72 / 1108 | 72 / 1108 |
| sample-4 | 66 / 1510 | 66 / 1510 |
| sample-109 | 98 / 1284 | 98 / 1284 |
| sample-96 | 85 / 1622 | 85 / 1622 |
| sample-176 | 124 / 1739 | 124 / 1739 |

Every count matches. Nothing else in the pipeline changed between the 5-sample
run and this one — same script, same container, same trim parameters, same
default `--p-min-reads 10`. Only the batch.

### All 308 samples, not just the 5

The run produced values for every sample in the dataset, and the published table
has all 308 too, so the reproduction can be scored dataset-wide rather than on
the 5 we happened to pick.

| metric | min | median | mean | max |
|---|---|---|---|---|
| observed_features | 100.0% | 100.3% | 100.42% | 102.7% |
| shannon | 100.00% | 100.01% | 100.045% | 100.83% |
| berger_parker_d | 98.43% | 100.00% | 99.953% | 100.00% |
| faith_pd | 93.4% | 100.6% | 100.91% | 112.9% |

**148 of 308 samples are bit-exact** on both `observed_features` and the total
read count in the table. Compare against the starting point: 56-68% of
published, every sample low.

### The residual, characterized (not hand-waved)

The remaining disagreement is small but *strictly one-directional*: in the other
160 samples we retain 1-5 extra features (never fewer) and the extra reads are
always attached to those extra features — there is not one sample with extra
reads but no extra features, or vice versa. Median surplus is 1 feature and 5
reads; median 3 reads per surplus feature.

Identifying the surplus features in our exported table and looking at their
*dataset-wide* abundance shows what they are:

- median global sum **12 reads**
- **73%** have a global sum ≤ 15, **88%** ≤ 20
- 44 features in the table sit at exactly the 10-read floor

They are features sitting right on the min-reads threshold. Whether a feature
with 10-15 reads dataset-wide lands above or below a 10-read cut depends on a
handful of reads, so a marginally more generous read set pushes a couple of them
over the line per sample.

**Leading explanation, untested:** we pulled reads from ENA's `fastq.gz`
mirrors; the paper's readme says they used **sra-tools** (`fastq-dump`), which
can differ by a few reads per run. That would shift borderline features across
the threshold in exactly this one-directional way. Settling it means
re-downloading all 308 runs through sra-tools and rerunning — not done here, so
this stays a hypothesis. What is *established* is the mechanism class: the
residual lives entirely in features within a few reads of the pooled threshold,
which is the same knob that caused the original 40% gap.

This also makes the original finding sharper rather than weaker. The
`--p-min-reads` threshold is sensitive enough that a handful of reads moves
features across it — which is precisely why running 5 samples instead of 308
moved a third to a half of them.

### Faith's PD

Faith's PD has a *second* batch dependency on top of min-reads: the phylogeny is
built de novo from that run's `rep-seqs.qza`, so a 5-sample tree comes from ~240
sequences and the 308-sample tree from thousands. Branch lengths and each
sample's spanning subtree both change.

| sample | published | 5 samples, min-reads 10 | 5 samples, min-reads 1 | **308 samples** |
|---|---|---|---|---|
| sample-25 | 9.833 | 5.935 (60.4%) | 7.767 (79.0%) | **10.234 (104.1%)** |
| sample-4 | 7.841 | 4.189 (53.4%) | 6.711 (85.6%) | **8.049 (102.6%)** |
| sample-109 | 11.771 | 6.302 (53.5%) | 9.409 (79.9%) | **11.586 (98.4%)** |
| sample-96 | 9.912 | 5.524 (55.7%) | 7.605 (76.7%) | **9.867 (99.6%)** |
| sample-176 | 14.408 | 6.428 (44.6%) | 10.992 (76.3%) | **13.456 (93.4%)** |

Faith's PD goes from 44.6-60.4% (systematically low, every sample) to
93.4-104.1%, mean **99.6%**, now scattered on *both* sides of the published
value. The bias is gone; what remains is symmetric scatter, which is what a de
novo MAFFT + FastTree phylogeny gives you — FastTree is not deterministic and
the tree is not the same object twice. Faith's PD is the one metric here that
cannot be reproduced bit-for-bit even with a correct pipeline, and that is a
property of the metric's dependence on a rebuilt tree, not a residual bug.

---

## Files

- `pipeline_run/run_stool_minreads1.sh` — the min-reads=1 test.
- `pipeline_run/run_stool_full308.sh` — the full 308-sample reproduction (run it
  detached: `docker run -d --name unr_full308 -v $PWD:/data -w /data
  quay.io/qiime2/qiime2-workshop:2026.7 bash /data/run_stool_full308.sh`).
- `pipeline_run/manifest_full.tsv` — all 308 sample-id → SRR mappings.
- `pipeline_run/raw_full/` — 308 FASTQs from ENA, every byte size verified
  against ENA's `fastq_bytes` and every file `gzip -t` clean.
- `pipeline_run/compare_full308.py` — regenerates the comparison table.
- `pipeline_run/export_full308/feature-table.tsv` — the reproduced 308-sample
  feature table (1751 features), used for the residual analysis.
- `pipeline_run/work_minreads1/`, `pipeline_run/work_full308/` — outputs.
- `assets/16-validate/minreads-comparison.csv` — machine-readable comparison.

## What this means for the talk

The gap was never a stale-tooling problem, a parameter typo, or a denoiser
choice. It was a **default parameter whose value depends on the shape of the
batch you happen to run**. Everything in the paper's Methods was followed
correctly. The reproduction still failed, because "run 5 of the 308 samples"
silently changes a per-sample statistic — and nothing in the published record
says it would.

Note also which claims survived scrutiny and which did not. Version drift,
parameter mismatch, and accession mapping were tested and correctly ruled out.
But the "positive filter" mechanism in `NOTES.md` was inferred from a stats
column without checking what that column measured, and it was wrong. The
distinction that mattered was reading `--p-min-reads`'s one-line help text and
then running the experiment it implied.

And the reproduction did not need any information the paper withheld. The repo
gave the script, the accessions, and the parameters; the missing piece was a
default value plus the fact that the batch was 308 samples, which
`dataset_summary/18_mixed.tsv` states as `count = 308.0` on its face. The
information was all there. What was missing was the *knowledge that batch
composition was load-bearing* — so nobody thought to record it, and nobody
thought to ask.
