# Catalog of proposal pathologies

Read during the premise audit and assumption extraction. Each entry gives the **tell**
(what it looks like on the page) and the **probe** (the question that exposes it).
These are patterns, not verdicts — a proposal can show a tell and still be sound. The
point is to make the pattern visible so it gets argued rather than assumed.

Grouped by where the flaw lives: in the problem, in the evidence, in the plan, in the
economics, or in the person.

---

## 1. Flaws in the problem

**Solution-shaped problem.** The problem is defined as the absence of the proposed
solution.
*Tell:* "We lack a unified X." "There's no single source of truth for Y." "We don't
have a way to Z."
*Probe:* Who is hurt today, doing what, how often? If the answer requires re-mentioning
the solution, the problem hasn't been stated yet.

**Phantom user.** The beneficiary is a category, not a person.
*Tell:* "Researchers need…", "Users want…", "The team would benefit from…" with no
instance behind it.
*Probe:* Name three. When did each last complain, and in what words?

**Proxy goal.** The stated objective is a measurable stand-in for the thing actually
wanted, and the gap between them is where the project fails.
*Tell:* The success metric could be maxed out while the underlying want goes unmet.
*Probe:* Describe the world where this metric is perfect and the person who asked for
it is still unhappy. How likely is that world?

**Unfalsifiable success.** No result could count as failure.
*Tell:* Success is "improved", "better", "more robust", "increased visibility", or
"learnings", with no threshold or comparison.
*Probe:* Write the sentence that would appear in the post-mortem if this failed. If you
can't, no one will ever be able to call it.

**Problem already solved.** Something in the building, or a $20/month tool, covers 80%
of it.
*Tell:* No survey of existing solutions, or a survey that dismisses each in a clause.
*Probe:* What is the closest existing thing, and precisely which requirement does it
miss? Is that requirement load-bearing or preference?

**Urgency without a clock.** Time pressure is asserted to foreclose the "wait" option.
*Tell:* "Window is closing", "before competitors", "now is the moment", with no dated
external event.
*Probe:* What specifically is different in six months, and who set that date?

---

## 2. Flaws in the evidence

**Anticipated demand as fact.** A forecast is written in the present tense.
*Tell:* "There is strong interest" sourced to conversations that were about something
adjacent, or to the author's own conviction.
*Probe:* Interest expressed how — a request, a complaint, a signup, or a nod in a
meeting? What did anyone *do*?

**Happy-path benchmark.** Performance evidence comes from the case the design is best
at.
*Tell:* A single demo, a clean dataset, a hand-picked example.
*Probe:* What is the realistic worst case in production, and what does the number look
like there? Who chose the test case, and when?

**Pilot that can't generalize.** The prototype succeeded under conditions the rollout
won't have — expert operator, small n, author's attention.
*Tell:* "The pilot showed…" without stating what was true of the pilot that won't be
true at scale.
*Probe:* Which conditions of the pilot are load-bearing, and which survive scaling?

**Survivorship framing.** Precedent cites the winners of a class where most attempts
died.
*Tell:* "Company X did this and it worked."
*Probe:* How many tried? What separated the survivors, and do we have that?

**Confirmation-only research.** Sources all point one way.
*Tell:* No cited disagreement, no failed prior attempt, no known cost.
*Probe:* Who has argued against this, and what is their best point?

---

## 3. Flaws in the plan

**"It's just" scoping.** Real complexity is compressed into a subordinate clause.
*Tell:* "It's just a wrapper around…", "we'd only need to…", "simply integrate with…"
*Probe:* Expand each "just" into the tasks it hides. Estimate again afterward.

**Integration hand-wave.** The proposal is detailed about the new component and vague
about every boundary it touches.
*Tell:* Architecture diagrams where arrows are unlabeled; auth, migration, and backfill
appear as single boxes.
*Probe:* Which existing system has to change, who owns it, and have they agreed?

**Assumed adoption.** The plan ends at delivery; behavior change is presumed.
*Tell:* No section on rollout, training, incentives, or what people do today instead.
*Probe:* What is the current workaround, why does it persist, and what makes switching
worth the switching cost to the individual — not to the org?

**Second-system rewrite.** A replacement is scoped to fix every known flaw at once.
*Tell:* The new version subsumes the old one's features plus a wish list; no incremental
path.
*Probe:* What is the smallest version that beats the status quo on one axis? Why not
that?

**Phase 2 sinkhole.** The hard part is deferred to a later phase that has no plan.
*Tell:* Phase 1 is specified to the week; phase 2 is a bullet list.
*Probe:* Is phase 1 valuable if phase 2 never happens? If not, this is one project and
it has not been scoped.

**Irreversibility unpriced.** A one-way door is treated like a two-way one.
*Tell:* Data model changes, public API commitments, vendor lock-in, or org restructuring
discussed without an exit path.
*Probe:* What does undoing this cost in twelve months? Does the proposal deserve
scrutiny proportional to that number?

---

## 4. Flaws in the economics

**Hidden run cost.** Build cost is estimated; the cost of it existing is not.
*Tell:* No line for on-call, upgrades, doc rot, support load, or the person who owns it
in year two.
*Probe:* Who maintains this when the author moves on, and is that in their plan?

**Missing null option.** "Do nothing" is never priced.
*Tell:* Alternatives section compares variants of the proposal to each other.
*Probe:* What is the actual cost of the status quo, per month, in the units the
proposal claims to save?

**Salami-sliced commitment.** A large commitment is presented as a small first step,
where the small step only pays off if the large one follows.
*Tell:* Modest ask, ambitious framing, no stated stopping point.
*Probe:* What is the total commitment if this works? Is anyone approving *that*?

**Opportunity cost invisible.** The proposal is evaluated against zero rather than
against the next best use of the same people.
*Tell:* No mention of what gets displaced.
*Probe:* Which named thing does not happen because this does? Is this better than that?

---

## 5. Flaws in the person

These are the most uncomfortable and often the most predictive. Raise them by their
mechanism — "the proposal's scope tracks the author's interest more closely than the
problem's shape" — never as an accusation of motive.

**Sunk-cost continuation.** The argument for finishing rests on work already done.
*Tell:* "We've already built…", "we're 70% there."
*Probe:* If you started today knowing what you know, would you choose this path? Prior
spend is not an asset.

**Capability-driven scope.** The plan matches the tools or skills the author wants to
use more closely than the problem requires.
*Tell:* Technology choice precedes requirements; the interesting part is
disproportionately detailed.
*Probe:* What would this look like if the boring solution were mandatory?

**Consensus mistaken for validation.** Agreement came from people with no stake or no
information.
*Tell:* "Everyone I talked to liked it."
*Probe:* Did anyone with the power to say no, or the burden of maintaining it, review
this?

**Identity fusion.** The proposal has become the author's position rather than a
hypothesis, so counter-evidence is processed as opposition.
*Tell:* Objections in the doc are answered rather than weighed; the FAQ is a defense.
*Probe:* What would make you drop this? If nothing, the plan is a commitment, and
should be labeled as one so it can be approved on those terms.
