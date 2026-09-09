Checked the repo's `readme.md` first — it says processing was done with QIIME2 "installed on a conda environment," which usually means a live conda solve (slow, and exactly the kind of thing that risks touching the host if run directly). Went with the official pre-built image instead of solving a fresh environment:

```
docker pull quay.io/qiime2/qiime2-workshop:2026.7
```

11.5GB uncompressed, 2.99GB pulled over the network — no live dependency solve needed. Verified it works and checked resources before running anything real:

```
$ docker run --rm quay.io/qiime2/qiime2-workshop:2026.7 bash -c "qiime --version; nproc; free -h"
q2cli version 2026.7.0
Run `qiime info` for more version details.
12
               total        used        free      shared  buff/cache   available
Mem:            30Gi        6.7Gi       470Mi       388Mi        24Gi        23Gi
```

(The image does print a deprecation notice — QIIME2's Docker images are moving off this base after the 2026.7.x line, worth knowing for next time, doesn't block anything today.)

Then cloned the actual repo and mounted only the working directory into the container — nothing outside `slides/UNR/pipeline_run` is visible to it, and any package installs the pipeline itself triggers happen inside the container's filesystem, not the host:

```
git clone https://github.com/MauroIb/alpha-diversities.git
docker run --rm -v "$(pwd)/pipeline_run:/data" quay.io/qiime2/qiime2-workshop:2026.7 bash /data/run_stool.sh
```

No host-level installs at all — conda, Deblur, mafft, fasttree all live inside the image already. Total setup time from zero to a working QIIME2 environment: under 2 minutes (mostly the image pull), versus what would normally be a from-scratch conda solve that regularly takes 15-30+ minutes and fails on dependency conflicts often enough that most tutorials budget time for retries.
