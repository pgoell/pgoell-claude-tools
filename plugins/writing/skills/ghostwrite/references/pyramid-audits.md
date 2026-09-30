# Pyramid audits

Four checks for the structure of a work document (memo, briefing, decision doc, long email), plus a check on the opener. Both skills use this file: `ghostwrite` runs the audits on its outline and reports them to the owner; `coach` uses them as its bank of structure issues and its structure drill.

The audits report. They do not fix the structure; the owner decides.

## The shape they check

A pyramid document puts the answer first (the apex: one sentence that answers the reader's question), then groups the support beneath it. Each group answers the question its parent raises. Groups are one of two kinds:

- **Inductive:** siblings are members of one class ("three reasons", "four risks"). Remove one and the parent still stands. This is the default.
- **Deductive:** siblings form a chain ("A, therefore B, therefore C"). Remove one and the conclusion falls. Use only when the chain is the argument.

**Escape hatch.** Answer first is a default, not a law. When the reader is hostile to the answer or does not yet know there is a problem, the owner may choose to lead with the situation and build to the answer. Offer this; do not impose either order.

## Audit 1: Question and answer alignment

For every node that has children:

1. Name the one question a reader would ask after reading it. A node that raises no nameable question is a label ("Market conditions"), not a finding.
2. Check that the children, taken together, answer that question. Try to name them with one plural noun ("reasons we should wait"). If no noun fits, the group is mixed.

Failures: **unnamed question** (the node is a label), **orphan child** (one sibling answers a different question and belongs elsewhere), **heterogeneous group** (each sibling answers its own question).

## Audit 2: MECE

For every group, relative to the question the parent raises:

1. Does each sibling answer the parent's question?
2. Do any two siblings cover the same ground under different labels? (overlap)
3. Is there an obvious case the group skips? (gap)
4. Does reordering change the meaning? If so, is the order logical (time, structure, or rank)?

Also flag six or more siblings (usually an overlap or a missing level) and a parent with one child (not a group). MECE is relative to the parent's question, not an absolute standard.

## Audit 3: So what, why true, caveman

- **So what?** Every node with children must state a finding, not name a category. "Background on the project" fails; "The project is two weeks late and will miss launch unless we cut scope now" passes.
- **Why is that true?** The children must supply evidence or reasons, not restate the parent in other words.
- **Caveman test (apex only):** compress the apex to "good or bad?". If the honest answer is "both, it depends", the apex takes no position.

## Audit 4: Inductive or deductive

For every group, ask:

1. Does one plural noun honestly cover every sibling? Then it is inductive.
2. Does it read as "X, therefore Y, therefore Z"? Then it is deductive.
3. Delete one sibling. Does the parent still hold?

Failures: **mixed group** (some siblings are class members, some are argument steps), **fragile chain** (a deductive link the reader can contest, which brings down the conclusion), **timeline posing as logic** ("we did A, then B, then C" presented as if each step proves the next). Prefer inductive unless the chain is load-bearing.

## Opener check (situation, complication, question, answer)

If the document opens with a short setup before the answer, check it:

1. Would the reader nod at the situation without friction?
2. Does the complication name a cause, not restate a symptom?
3. Does the question arise from the complication?
4. Would changing the answer force a change to the complication? If not, the setup is decoration.

If the setup cannot pass without inventing a complication, report a **mismatch**: the apex does not support this kind of opener. Name the reason (a manufactured complication, a question that restates the answer, or a setup built backwards to justify the answer) and suggest opening with the answer alone.

## Reporting format

Keep it short. For each audit, one line: pass, or the failure with the node it applies to and the question the owner should answer to fix it. Example:

- Question and answer: pass.
- MECE: siblings 2 and 3 overlap ("cost" and "budget impact" cover the same ground). Which one do you mean?
- So what: sibling 1 is a label ("Background"). What should the reader conclude from it?
- Inductive or deductive: pass.

## Socratic structure drill (coach)

The coach uses this sequence when the owner builds or rebuilds a document's structure. The owner writes every node; the coach asks and checks, and never offers candidate answers.

1. "What question will the reader have?" Check it is a real question, not a topic.
2. "What is your answer, in one sentence?" Block a label: the answer needs a verb and a claim.
3. "What question does that answer raise for the reader?" Check it differs from the first question.
4. "What plural noun names the points that answer it (reasons, risks, steps, options)?"
5. "State your first point." Then the second, then the third. Block labels. After each, run the matching audit check as a question: so what, overlap, gap.
6. "Add another point, or stop here?" More than five: ask the MECE questions before accepting.
7. "What evidence supports point 1?" Repeat per point. Check it is evidence, not restatement.

Block only labels in place of claims and groups larger than five. Everything else is a one-line question the owner may answer or wave off. After two failed attempts at the same block, let it through and note it.
