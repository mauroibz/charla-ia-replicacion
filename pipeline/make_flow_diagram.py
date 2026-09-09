import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyArrowPatch

steps = [
    "Raw reads\n(SRA/ENA fastq)",
    "Import\n(QIIME2 manifest)",
    "Quality filter /\ndenoise\n(Deblur or DADA2)",
    "Phylogeny\n(mafft + fasttree)",
    "Alpha diversity\n(observed features,\nBerger-Parker,\nFaith's PD, Shannon)",
    "Report\n(published vs.\nreproduced)",
]

fig, ax = plt.subplots(figsize=(14, 2.6))
ax.set_xlim(0, len(steps))
ax.set_ylim(0, 1)
ax.axis("off")

box_w, box_h = 0.85, 0.6
for i, label in enumerate(steps):
    x = i + 0.075
    rect = mpatches.FancyBboxPatch(
        (x, 0.2), box_w, box_h,
        boxstyle="round,pad=0.02,rounding_size=0.04",
        linewidth=1.2, edgecolor="#2c5f7c", facecolor="#eaf2f6"
    )
    ax.add_patch(rect)
    ax.text(x + box_w/2, 0.5, label, ha="center", va="center", fontsize=9, color="#1a3a4a")
    if i < len(steps) - 1:
        arrow = FancyArrowPatch(
            (x + box_w + 0.01, 0.5), (x + box_w + 0.14, 0.5),
            arrowstyle="-|>", mutation_scale=14, color="#e07a3f", linewidth=1.5
        )
        ax.add_patch(arrow)

plt.tight_layout()
plt.savefig("../assets/18-report/artifact-pipeline-flow.png", dpi=150, bbox_inches="tight")
print("saved flow diagram")
