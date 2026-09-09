# Soil samples — this is the real "adapting to new data" wrinkle

Used real soil 16S data (not a rename fallback): 3 candidate accessions turned
up on the first productive search — SRX7891206/7/8, from a 2020 Data in Brief
paper on bacterial diversity in varillal soils, Allpahuayo-Mishana National
Reserve, Peru (`soil metagenome`, PRJNA611870). Picked 2 of the 3
(SRR11285499, SRR11285497), 13-15MB each, paired-end 250bp MiSeq.

## What happened

Ran the same denoise-paired approach as the repo's own paired-end workflow
(`workflow.txt`), with truncation lengths chosen conservatively for 250bp
reads. Result: **denoising succeeded, merging almost completely failed** —
of ~45-50K input read pairs per sample, only 36 and 0 pairs merged on the
first attempt (`--trim-left-f 0 --trim-left-r 0 --trunc-len-f 230
--trunc-len-r 200`). Tried once more with primer-length trims typical of a
V4 515F/806R setup (`--trim-left-f 19 --trim-left-r 20 --trunc-len-f 220
--trunc-len-r 180`) — improved slightly (70 and 129 merged) but still under
0.3% of input reads. Not usable for a real diversity calculation either way.

## Diagnosis (not confirmed against the source paper's actual methods)

The near-total merge failure, persisting after a primer-trim adjustment,
points to the forward/reverse reads not actually overlapping at the
truncation lengths tried — most likely because this study's real amplicon
insert length (V-region + primers) is longer than assumed, leaving too
little true overlap for DADA2's default strict merge criteria
(`--p-max-merge-mismatch 0`, i.e. zero mismatches allowed in the overlap).
This wasn't chased further — would require pulling the actual primer
sequences and amplicon target from the source study's methods section rather
than guessing standard V4 primers.

## Why this belongs in the deck, not just this notes file

This is the real content for the "adapting to new data" step — the
runbook anticipated exactly this ("a real wrinkle here is better slide
content than a clean success"). The honest story: the validated pipeline
does *not* transfer to new data with zero changes, and the applicability
audit from steps 12-13 was right to flag wet-lab/extraction differences as a
risk — this is a companion failure mode (amplicon/primer assumptions) that
audit didn't specifically name, which is itself worth saying out loud in the
talk: audits catch the risks you think to ask about, not all of them.

## What's NOT in this folder

No alpha-diversity numbers for the soil samples — the feature tables are
functionally empty (1 and 0 observed ASVs pre-fix, still near-zero after).
Reporting a diversity value here would be reporting noise as if it were
signal. If the talk needs a working "new sample" result rather than a
process-adaptation story, that requires either sourcing the real primer
protocol for this specific soil study, or picking a different soil dataset
where the amplicon/primer assumptions are documented and known to match.
