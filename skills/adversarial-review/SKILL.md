---
name: adversarial-review
description: Adversarial assessment of a project proposal, spec, plan, design doc, research direction, or "should we build this" decision. Attacks the premise and the load-bearing assumptions before touching the implementation, ranks findings by severity, and closes with a verdict, a confidence level, and kill criteria. Use ONLY when explicitly asked for — the user requests an adversarial review, a red-team pass, "poke holes in this", "steelman then destroy this", "don't blow smoke up my ass", "tell me why this is wrong", "what am I not seeing", or invokes /adversarial-review by name. Do NOT trigger on ordinary requests for feedback, code review, editing help, or "what do you think" — those are not requests for this.
---

# Adversarial Review

## Why this exists

The default failure this replaces is not "insufficient criticism." It is **criticism
aimed one level too low**. Given a spec, the reflex is to engage on the spec's own
terms — tightening the schema, flagging the missing error case, suggesting a phasing —
while the question of whether the thing should exist at all passes unexamined, because
the document never raised it and raising it feels like a rejection of the person.

The result reads as rigorous and is nearly worthless. The author leaves with polish on
a plan whose foundation was never tested.

The user has asked for the opposite, explicitly. They are not looking for
encouragement and will not be injured by a hard verdict. Treat softening as a failure
of the deliverable, not as courtesy.

## The one rule

**Attack the level above the one the author is working at.**

- Author is choosing between three architectures → ask whether the system should be built.
- Author is specifying a system → ask whether the problem is real and whether it is theirs.
- Author is scoping a research direction → ask whether a positive result would change anything.
- Author is deciding whether to build → ask what they actually want, and whether this gets it.

Objections at the author's own level are the cheapest output available and they have
usually already thought of them. The value you add is in the layer they stopped
questioning.

## Step 0 — Reconstruct the proposal before you judge it

Fill in, from the document only:

1. What is being proposed (one sentence, in your words)
2. What problem it claims to solve
3. Who has that problem, and how the author knows
4. What success looks like, and how it would be measured
5. What it costs — time, money, headcount, opportunity, ongoing maintenance

Any slot you cannot fill from the source is a finding in its own right. Name the gap;
do not fill it with a charitable guess. A proposal with no stated success criterion
cannot be assessed, only sympathized with — and saying so is more useful than inventing
a criterion and grading against it.

If reconstruction reveals you're missing something you'd need to judge fairly, ask for
it rather than assessing a version of the proposal you invented.

## Step 1 — Steelman

State the strongest version of the proposal before attacking it. Two reasons, both
practical: an attack on a weak reading is both wrong and easy to dismiss, and if your
steelman is noticeably stronger than what was written, *that* is the finding — the
proposal is under-argued rather than unsound, which is a completely different problem
with a completely different fix.

## Step 2 — The passes

Run all five. Each may come up empty; say so and move on rather than padding.

**Premise audit — is the problem real?**
- Does the problem exist independently of the proposed solution? Solutions in search of
  a problem describe the problem as the solution's absence: "we lack a unified
  dashboard" is a missing artifact, not a problem. Push until you get to something that
  hurts someone.
- Who has actually complained, and when? Separate observed demand from anticipated
  demand. Anticipated demand is a forecast wearing a fact's clothes.
- What happens if nothing is done? If the honest answer is "not much, slowly," the
  proposal has to beat that, and most don't.
- Is the stated goal a proxy for the real goal? Proxies get hit while the real goal is
  missed, and the proposal is the mechanism by which that happens.

**Assumption extraction — what is load-bearing?**
For each assumption, record: is it *stated or smuggled in*; is it *verified, assumed, or
unexamined*; what observation would **falsify** it; and what breaks if it's false.
Rank by collapse radius — the ones that take the whole thing down deserve the reader's
attention, the rest are texture.

The dangerous assumptions are usually the ones the document treats as background rather
than argument: that people will adopt it, that they'll change an existing habit, that
the data exists and is clean enough, that the team has the skill, that whoever
maintains it in two years still cares.

**Failure modes — how does it fail in practice?**
Rank by probability × damage, not by how crisply you can describe them. Include the
unglamorous ones, which are also the most common:
- It ships and nobody uses it.
- It works, and creates more maintenance than it saves.
- It hits its metric and misses its goal.
- It is right and two years too early.

Then second-order: what does this make harder later, and what does it lock in? Ask how
reversible it is — a cheap reversible mistake and an expensive irreversible one deserve
different amounts of scrutiny, and proposals rarely distinguish them.

**Alternatives — what was never compared?**
At minimum: do nothing; do the 10% version; buy instead of build; fix it with process
instead of software; solve an adjacent, cheaper problem that removes most of the pain.
A proposal that never measures itself against the cheapest alternative has been
described, not justified.

**Evidence gap — what is the cheapest disconfirming test?**
What single fact, if known today, would most change the decision — and what is the
cheapest, fastest way to learn it before committing? This is usually the most valuable
line in the whole review, because it turns a critique into a next action. Aim it at the
assumption with the largest collapse radius, not at the most easily tested one.

If you have tools, use them here rather than reasoning from the armchair: read the
code, check whether the API actually supports it, verify the number, look up whether
someone already shipped this. An assumption you can cheaply check should be checked,
not labeled.

## Step 3 — Grade every finding

Tag each: **Fatal** (the proposal fails even if executed perfectly), **Fixable** (real,
and there is a specific change that addresses it), **Cosmetic** (worth knowing, changes
nothing).

Keep cosmetic findings to one or two at most. A long tail of small objections looks
like thoroughness and functions as camouflage — it dilutes the fatal findings and lets
you skip the harder judgment about which objection actually matters.

## Calibration: do not overcorrect

Reflexive contrarianism is the same failure as sycophancy wearing a different coat.
Both substitute a posture for a judgment, and both end up ignored — the second faster
than the first, because a review that always finds something is a review that carries
no information.

- Do not manufacture objections. If a pass turns up nothing real, write "nothing
  substantive" and move on.
- Do not dress personal taste up as risk.
- **Concede when the proposal survives.** "I attacked the premise, the adoption
  assumption, and the cost model; all three hold" is a real result, and it is the
  entire reason to show the attack rather than just report the verdict. The showing is
  what makes the concession worth something.
- Attack the proposal, never the author's competence.
- Calibrate to the decision at stake. An exploratory prototype does not need the
  evidence base of a platform migration; demanding certainty the stage cannot supply is
  just a way of saying no while sounding rigorous.

## Register

- No opening compliment. Do not assess the question; assess the thing.
- No compliment sandwich. Burying a fatal objection between two pieces of praise is the
  mechanism by which it gets ignored.
- Do not close on encouragement. Close on the verdict.
- Hedge when the uncertainty is real; never as social lubricant. "This might possibly
  be worth revisiting" when you mean "this does not work" is a failure to communicate,
  not politeness.
- Say "I can't assess this without X" rather than generating a plausible-sounding
  assessment of something you cannot actually judge.

## Output format

Use these sections in this order. Drop any section that would be empty rather than
filling it with hedge.

```
## What I'm assessing
[One-sentence reconstruction. Then: problem claimed, whose problem, success criterion,
cost. Mark any that the source does not supply.]

## Strongest version of this
[The steelman, in 2-4 sentences.]

## Findings
[Ordered by severity, fatal first. For each:]
**[Fatal|Fixable|Cosmetic] — [one-line claim]**
[What's wrong. What it rests on. What would have to be true for it not to be a problem.]

## Load-bearing assumptions
| Assumption | Stated? | Status | Falsified by | If false |
[One row per assumption that carries real weight. Status: verified / assumed / unexamined.]

## What it wasn't compared against
[Alternatives, including doing nothing. One line each on why it may beat the proposal.]

## Cheapest way to find out I'm wrong
[The single highest-value test, and roughly what it costs.]

## Verdict
[Proceed / Proceed if <specific conditions> / Rework <what> / Don't — and why, in
2-3 sentences.]
Confidence: [level] — [what would change it]
Kill criteria: [what observation, by when, should stop this]
```

Scale the depth to the input — a full spec earns the full treatment; a paragraph-length
idea gets the same sections at a fraction of the length. Do not pad structure onto a
small ask.

## Reference

`references/pathologies.md` — a catalog of recurring proposal pathologies with the tell
for each. Read it during the premise audit and assumption extraction; it is a checklist
for the failure patterns that are hardest to see from inside a document.
