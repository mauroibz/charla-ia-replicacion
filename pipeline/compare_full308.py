#!/usr/bin/env python3
"""Compare reproduced alpha metrics against the published alpha-out.18_mixed.tsv."""
import csv, os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PUB = os.path.join(ROOT, '..', 'alpha-diversities', 'datasets', '18_mixed', 'alpha-out.18_mixed.tsv')
TARGETS = ['sample-25', 'sample-4', 'sample-109', 'sample-96', 'sample-176']
PUBCOL = {'observed_features': 'observed_features', 'shannon': 'shannon_entropy',
          'berger_parker_d': 'berger_parker_d', 'faith_pd': 'faith_pd'}

def read_pub():
    out = {}
    with open(PUB) as f:
        for row in csv.DictReader(f, delimiter='\t'):
            out[row['sample-id']] = row
    return out

def read_alpha(run, metric):
    p = os.path.join(ROOT, run, 'stool', 'alphas', metric, 'alpha-diversity.tsv')
    if not os.path.exists(p):
        return {}
    out = {}
    with open(p) as f:
        next(f)
        for line in f:
            parts = line.rstrip('\n').split('\t')
            if len(parts) >= 2 and parts[1] != '':
                out[parts[0]] = float(parts[1])
    return out

def main(runs):
    pub = read_pub()
    w = csv.writer(sys.stdout)
    w.writerow(['sample_id', 'metric', 'published'] +
               [c for r in runs for c in (r, r + '_pct')])
    for s in TARGETS:
        for metric, pc in PUBCOL.items():
            pv = float(pub[s][pc])
            row = [s, metric, pv]
            for r in runs:
                d = read_alpha(r, metric)
                v = d.get(s)
                row += ['' if v is None else v,
                        '' if v is None else f'{100*v/pv:.1f}%']
            w.writerow(row)

if __name__ == '__main__':
    main(sys.argv[1:] or ['work', 'work_dada2', 'work_minreads1', 'work_full308'])
