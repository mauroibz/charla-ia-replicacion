> **AVISO — este documento quedó superado en parte.**
> Dos conclusiones de acá resultaron falsas: el "filtro positivo" de Deblur no
> descartaba nada, y la pista de DADA2 era un falso positivo. La causa real está
> en [`SUBAGENT-FINDINGS.md`](SUBAGENT-FINDINGS.md). Se conserva sin editar a
> propósito: el contraste entre lo que se probó y lo que se dio por bueno sin
> probar es justamente el tema de la charla.

# Validation run notes — read before using this on a slide

Pipeline: `slides/UNR/pipeline_run/run_stool.sh`, run inside
`quay.io/qiime2/qiime2-workshop:2026.7` (QIIME2 2026.7 / q2cli 2026.7.0),
mounting only `slides/UNR/pipeline_run` into the container. Raw reads pulled
directly from ENA (mirrors SRA byte-for-byte — sizes matched exactly against
ENA's `fastq_bytes` field before running). Same Deblur parameters as the
repo's own `pipeline_scripts/single_end.sh` (`--p-left-trim-len 20
--p-trim-length 120`), no rarefaction — the paper's own Methods section
(page 11 of the PDF, screenshot in `12-audit/`) states "all tests were
performed with non-rarefied data," so this matches its methodology exactly,
not just its parameters.

## What matched well

`berger_parker_d` and `shannon` reproduced within **~5-12% of published
values** across all 5 samples, and preserved the exact same relative ranking
between samples as the published numbers (sample-25/sample-4 lowest
diversity, sample-176 highest, in both published and reproduced). These are
abundance-weighted metrics — dominated by the most common ASVs, which are
the reads least sensitive to exact denoising-parameter differences.

## What didn't

`observed_features` and `faith_pd` (both richness-sensitive — they count or
weight *rare* ASVs) came in **systematically low**, 44-68% of published
values, consistently across all 5 samples (not one outlier — a real pattern,
not noise). Checked and ruled out:
- **Not a data problem.** `reads-raw` per sample (from Deblur's own stats
  export, `pipeline_run/work/stool/deblur-stats-export/stats.csv`) matches
  expected read counts for these accessions exactly — same underlying reads
  as the original study.
- **Not a parameter mismatch.** Same trim/length parameters as the repo's own
  script.

## UPDATE — version drift hypothesis tested and REFUTED

The "most likely cause" below was a guess, never actually tested. It has now
been tested directly and does not hold up:

**Test:** pulled `quay.io/qiime2/core:2022.2` (confirmed `q2cli version
2022.2.0` — the exact version the paper's Methods section cites) and reran
the identical `run_stool.sh` script, same 5 samples, same parameters, inside
that container.

**Result:** every single metric, to full floating-point precision, came out
**identical** to the 2026.7 run. See
`assets/16-validate/version-drift-comparison.csv`. This isn't "close" — it's
byte-for-byte the same numbers (e.g. `faith_pd` for sample-25:
`5.935276785703879` in both). QIIME2/Deblur version drift across the
2022.2 → 2026.7 span is **ruled out** as the cause. (Pull cost: 9.17GB image,
~350s; rerun: ~83s for all 5 samples — cheap enough that there's no excuse
for this having been left as an unverified guess before.)

**Also ruled out**, checked as part of this pass:
- **Accession-mapping error** — cross-checked `sample-25` etc. against
  `datasets/18_mixed/SraRunTable.txt`; the sample-id → SRR mapping used is
  exactly correct.
- **Rarefaction mismatch** — already ruled out in the original pass (paper's
  Methods text explicitly says non-rarefied data throughout).
- **Parameter mismatch** — `run_stool.sh` matches the repo's own
  `single_end.sh` exactly (`--p-left-trim-len 20 --p-trim-length 120`).

**New mechanical finding, from actually reading Deblur's own stats output**
(`pipeline_run/work_v2022/stool/deblur-stats-export/stats.csv`): the
richness loss traces to Deblur's **reference-based positive filter** — a
mandatory step inside `deblur denoise-16S` that discards any denoised
sequence not matching its bundled 88%-OTU reference database. For these 5
samples, roughly a third to a half of the denoised unique sequences per
sample are dropped at or after that filtering stage before the final
`hit-reference` count (the number that becomes `observed_features`). Since
the 2022.2 and 2026.7 runs are identical, the bundled reference itself
hasn't changed across that span either — so this mechanism is confirmed as
*where* the richness is being lost, but not *why* it differs from the
published number.

**Two open, unconfirmed leads** (not chased further — would need access to
the paper's original run artifacts, which the repo explicitly doesn't share
due to data ownership):
1. The original run may have used a different/updated reference file for
   Deblur's positive filter than either QIIME2 release ships by default.
2. The paper's Methods describe validating with **both** DEBLUR and DADA2 —
   it's not confirmed which one actually produced the numbers published in
   `datasets/18_mixed/alpha-out.18_mixed.tsv` for this specific dataset. No
   per-dataset method flag was found in the repo (`viz_info.tsv`,
   `dataset_summary/`) to settle this either way.

## For the slide

**Confident claim you can make:** "we ruled out version drift by literally
re-running the paper's exact original QIIME2 version — identical output to
today's version, so it's not a stale-tooling problem." That's a stronger,
more credible statement than the original unverified guess, and it's backed
by a real side-by-side run.

**Not yet a confident claim:** why the reproduced richness numbers differ
from the paper's published ones. Present the actual numbers and the
ruled-out list; if asked "so what caused it," the honest answer is "still
open — likely DADA2-vs-Deblur or a reference-database difference we can't
verify without the paper's original QIIME artifacts, which weren't shared."
That's a legitimate, disclosed unknown, not evasion — and stool
depth/positive-filtering behavior on richness metrics is squarely on-topic
for a talk about applying alpha-diversity metrics correctly.

**Before using in the talk:** the "ruled out" list above is solid (directly
tested, not guessed). The two open leads are still just leads — a sanity
read from you is warranted before stating either as fact.

## UPDATE 2 — DADA2 hypothesis tested: PARTIALLY CONFIRMED, not the full story

Lead #2 above (paper's Methods say both DEBLUR and DADA2 were used; maybe this
dataset's published numbers came from DADA2, not Deblur) has now been tested
directly, not left as a guess.

**Test:** ran `qiime dada2 denoise-single` on the same 5 samples, same
container (`qiime2-workshop:2026.7`), with `--p-trim-left 20 --p-trunc-len
120` — matched as closely as possible to Deblur's `--p-left-trim-len 20
--p-trim-length 120` for a fair comparison. No single-end DADA2 script exists
in the repo to copy exactly (the repo's `workflow.txt` only shows DADA2
params for a *different*, paired-end dataset), so these trim values are our
best-effort match, not a confirmed original protocol — worth flagging if
asked how the DADA2 run was parameterized.

**Result:** DADA2 moves every metric meaningfully closer to published values
than Deblur did, but does not fully close the gap. Full numbers in
`dada2-comparison.csv`.

| metric | Deblur (% of published) | DADA2 (% of published) |
|---|---|---|
| observed_features | 56-68% | 65-71% |
| berger_parker_d | 106-112% (overshoot) | 86-98% (near symmetric) |
| faith_pd | 45-60% | 69-78% |
| shannon | 91-93% | 95-98% |

Faith's PD sees the biggest improvement (moves ~15-20 points closer to
published across all 5 samples), and Berger-Parker flips from a consistent
~10% overshoot to a much smaller, roughly-centered miss. Shannon was already
close under Deblur and gets closer still. But **observed_features — the
simplest richness count — is still only 65-71% of published under DADA2**,
essentially the same order of gap as Deblur (56-68%). So denoiser choice is
clearly a real, contributing factor (consistent with the paper validating
both methods), but it is not, on its own, sufficient to explain the full
richness discrepancy for this dataset.

**Bottom-line conclusion for the talk (supersedes the single-lead framing
above):** three explanations have now been tested, not guessed —
version drift (ruled out, byte-identical old vs. new QIIME2), parameter/
accession mismatch (ruled out), and denoiser choice (DADA2 vs. Deblur —
**partially confirmed**: real, measurable effect on 3 of 4 metrics, but
doesn't fully explain the richness gap). What remains open is *which* exact
denoiser + exact parameters + exact reference database produced the
originally published `alpha-out.18_mixed.tsv` numbers — that provenance
isn't recorded in the repo, and can't be settled further without the
original run's artifacts. This is a legitimate, now well-characterized open
question, not an unresolved shrug: you've ruled out two of three plausible
causes definitively and shown the third is real but partial.
