---
name: compare
description: >
  Use when the user wants to compare two or more documents, quotes, estimates,
  options, or plans side by side. Also triggers when the user pastes multiple
  alternatives without explicitly saying "compare" but clearly wants help
  deciding or understanding differences.
---

# Compare

Extract key figures and criteria from the provided documents and produce a focused side-by-side comparison.

## Core approach

1. Read everything the user provided before producing output
2. Identify the dimensions that matter most for this specific comparison — cost, timeline, risk, compatibility, constraints, etc. — based on what's in the documents and what the user asked
3. Build a table (or tables) organized around those dimensions
4. Note constraints or assumptions the user stated — factor these into the comparison rather than treating them as a footnote
5. Flag meaningful differences, risks, or tradeoffs
6. Stop there — no unsolicited research, no tangents, no recommendations beyond what was asked

## Output structure

Use this structure, adapting section titles to fit the content:

**Summary table** — one row per option, columns for the most decision-relevant dimensions. For financial comparisons, include a net cost row that accounts for any stated constraints (e.g. insurance deductibles, rebates, mandatory upgrades).

**Constraint impact** — if the user stated constraints (budget ceiling, insurance rules, regulatory requirements, compatibility needs), show explicitly how each option handles them. Don't bury this in a footnote.

**Key differences** — 3–6 bullet points on the differences that actually matter. Skip differences that are cosmetic or irrelevant to the decision.

**Flags** — anything that looks like a risk, gap, or ambiguity in the source material (missing line items, unusual terms, unclear scope). Keep it short and factual; don't editorialize.

Omit any section that doesn't add value for the specific comparison at hand.

## Tone and scope

- Neutral. Present findings; don't advocate for an option unless asked.
- Concrete. Use the actual numbers, names, and terms from the documents.
- Focused. If the user asked about cost, lead with cost. Don't rebalance toward dimensions they didn't ask about.
- No filler. Skip preamble, caveats about not being a professional, and summaries that restate the table.
