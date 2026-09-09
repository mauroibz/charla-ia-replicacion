import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

df = pd.read_csv("../assets/16-validate/validation-table.csv")

metrics = ["observed_features", "berger_parker_d", "faith_pd", "shannon"]
samples = df["sample_id"].unique()

fig, axes = plt.subplots(1, 4, figsize=(16, 4.2))
fig.suptitle("Published vs. reproduced alpha diversity — 5 validation samples", fontsize=13, y=1.03)

for ax, metric in zip(axes, metrics):
    sub = df[df["metric"] == metric]
    x = np.arange(len(sub))
    width = 0.35
    ax.bar(x - width/2, sub["published"], width, label="Published", color="#2c5f7c")
    ax.bar(x + width/2, sub["reproduced"], width, label="Reproduced", color="#e07a3f")
    ax.set_xticks(x)
    ax.set_xticklabels(sub["sample_id"], rotation=45, ha="right", fontsize=8)
    ax.set_title(metric, fontsize=11)
    ax.spines[["top", "right"]].set_visible(False)

axes[0].legend(fontsize=9, frameon=False)
axes[0].set_ylabel("value")
plt.tight_layout()
plt.savefig("../assets/18-report/artifact-published-vs-reproduced.png", dpi=150, bbox_inches="tight")
print("saved chart")
