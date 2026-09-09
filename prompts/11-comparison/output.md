These two papers are answering different questions that look like the same question, and that's the main thing to untangle before picking one.

**What each paper actually does:**

- **Scientific Reports (2024)** analyzed 4,596 real stool samples across 13 public projects plus synthetic datasets with controlled properties, and grouped alpha diversity metrics into four conceptual categories by what they measure: richness (Observed features), dominance (Berger-Parker), phylogenetics (Faith's PD), and information/entropy (Shannon). Its conclusion is prescriptive at the level of *category coverage*: many metrics within a category are highly correlated, so you don't need all of them, but you should report at least one metric per category to avoid a one-dimensional picture of diversity.

- **Frontiers in Microbiology (2021)** takes a statistical-power angle instead: using real and simulated datasets, it shows that different alpha and beta metrics yield different statistical power for the same underlying data, and that researchers who try multiple metrics until one is significant are effectively p-hacking. Its recommendation is procedural, not metric-specific: pre-register your statistical analysis plan (including which metric you'll use) before running the analysis, and report effect sizes and power alongside p-values.

**Where they actually disagree (or rather, don't overlap):**

The Scientific Reports paper is about *which metrics to compute* so your diversity description is complete. The Frontiers paper is about *when in your workflow you decide* which metric to compute, so your significance testing isn't biased. Neither paper argues against the other — they're compatible, and in fact complementary: you could use the 2024 paper's four-category framework to decide which metrics are worth reporting descriptively, and the 2021 paper's discipline to decide (in advance, before seeing results) which one or two of those you'll actually run a hypothesis test on.

The one place they'd pull in different directions if applied naively: the 2024 paper's "report one metric per category" advice, taken alone, could tempt you to run four separate significance tests (one per category) on the same dataset — which is exactly the multiple-comparisons/p-hacking risk the 2021 paper is warning about. So if you're doing inferential statistics (not just descriptive reporting), you need the 2021 paper's discipline layered on top of the 2024 paper's category framework, not one instead of the other.

**Which should guide your choice:** if your goal is a diversity description in a paper's results section — the 2024 framework is the more directly actionable, tells you what to compute. If your goal involves testing a hypothesis (does treatment X change diversity?) — the 2021 paper's pre-registration and power discipline should govern *how* you get from "which metrics" to "which p-value," regardless of which metrics the 2024 framework points you toward.
