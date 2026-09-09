# Caveat: sections 10-14 were not produced by a context-free agent

The runbook (and the task that produced this folder) called for a *fresh*
agent instance with none of this project's context to answer the research/
comparison/audit/self-critique/adaptation prompts, so the captured output
would read like a genuinely naive first encounter with the material rather
than something informed by already knowing the "right" answer.

That wasn't possible here: this run executed as a fork, and forks are
disallowed from spawning further Agent-tool subagents. The content in
`10-research/`, `11-comparison/`, `12-audit/`, `13-selfcritique/`, and
`14-adaptation/` was written directly by the executing agent instead, which
did have visibility into the base paper's contents (Observed features,
Berger-Parker, Faith's PD, Shannon; QIIME2/DADA2/Deblur) from earlier in the
inherited conversation. Effort was made to answer plainly and skeptically
rather than performing pre-knowledge of "the demo," but it is not a true
cold-start capture.

If the authenticity of a fresh, uncontaminated exchange matters for how these
slides land with the audience, the cleanest fix is to literally re-run these
5 prompts in a brand-new Claude web conversation by hand and swap the
`output.md` files — the `prompt.md` files in each folder are already exactly
what to paste in, in order, in one continuous thread.
