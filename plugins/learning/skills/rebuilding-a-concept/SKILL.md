---
name: rebuilding-a-concept
description: Use when the user wants to learn a concept by rebuilding how it came to exist and then trying to break it, rather than being handed the finished definition. Joins Toeplitz's genetic method with Lakatos's proofs and refutations. For example "help me rebuild why limits exist", "derive Euler's formula with me, then break it", or "why does event sourcing look like this? Let me build it myself first". Not for quizzing to mastery; that is quizzing-a-topic.
---

# Rebuilding a Concept

Learn an idea the way it was made: start from the problem that forced someone to invent it, let the user attempt a fix, then attack the fix with counterexamples until it holds. The textbook version comes last, as a comparison, not as the starting point.

This is slower than reading the finished theory. The payoff is that the user knows why each part of the final form is there, so it sticks.

## When to invoke

- "Help me rebuild X from scratch." "Why does X look the way it does?" "Let me invent X myself before you show me." "Teach me X the Lakatos way." "Genetic method on X."
- X can be maths (limits, the integral, Euler's polyhedron formula, group axioms) or anything with a design behind it: a data model, a framework, an architecture pattern, a protocol.

## When NOT to invoke

- The user wants the definition now, or a quick explanation. Just answer.
- The user wants to be taught and quizzed to mastery on a topic. Use `learning:quizzing-a-topic`.
- The user wants a survey of what they do not know before starting work. Use `learning:surveying-blind-spots`.

## The two ideas behind it

- **Genetic method** (Otto Toeplitz, 1927, after Felix Klein). "Genetic" means "from its origin". Instead of the polished definition, start with the problem that forced the idea, then follow the clumsy early tries toward the final form. Toeplitz taught calculus from Archimedes measuring areas, not from epsilon-delta limits. Do not replay real history step by step; take a cleaned-up path where each definition shows up only once the user feels the need for it.
- **Proofs and Refutations** (Imre Lakatos, 1976). A class proves Euler's formula V - E + F = 2 for polyhedra, then finds shapes that break it, such as a cube with a tunnel through it. Each counterexample exposes a hidden assumption (a hidden lemma). The class then picks a move:
  - **Monster-barring**: declare the counterexample not a real instance ("that is not a polyhedron").
  - **Exception-barring**: narrow the claim to exclude the case ("true for convex polyhedra").
  - **Lemma-incorporation**: fix the proof by stating the hidden assumption as an explicit condition.

  Definitions often come out of this fight (proof-generated concepts) rather than going in.

## Pick the concept

- If the user names a bounded concept, start at once. Ask nothing.
- If the concept is too broad ("teach me calculus"), ask one question to pick a single idea inside it.
- If the concept lives in the current repo (a schema, a module's design), read the relevant files first so the problem and the final form are real, not guessed. Do not show them to the user yet.

## The loop

Run these five steps in order. Keep turns short and wait for the user at each step.

1. **Pose the problem.** State the problem the concept was made to solve, as concretely as you can: a task that fails or is painful without it. Do not name the concept's parts or give its definition. For a design (a data model, a pattern), the problem is the pain it removes.
2. **User attempts.** Ask the user to solve the problem themselves, however crudely. Accept a rough sketch. Nudge with a smaller case or a hint about where to look if they stall, but do not solve it for them.
3. **Guess, then break.** Have the user state their attempt as a rule or a claim. Then hunt for cases that break it. Ask the user to find a counterexample first; supply one yourself only if they are stuck or have run out. Pick counterexamples that each expose a different hidden assumption, in roughly the order the real idea had to face them.
4. **Repair.** For each break, ask the user how to respond, then name the move they made: monster-barring, exception-barring, or lemma-incorporation. Push gently toward lemma-incorporation, since it is the move that adds knowledge, but let them try the others and see what they cost (monster-barring often just hides the problem). Keep a running list of the assumptions that had to become explicit. Repeat steps 3 and 4 until the user's rule survives the cases you can think of.
5. **Compare.** Only now show the canonical version: the textbook definition, theorem, or the real design. Line it up against the user's repaired rule. Point out where each condition or design choice in the canonical form matches one of the assumptions they surfaced, and where the canonical form handles a case they did not reach. Say plainly where their version is weaker, stronger, or just different.

## Tutor rules

- Never hand over the final definition or design before step 5, even if the user asks for a hint. Give a smaller case or a sharper counterexample instead. If the user explicitly wants to stop and see the answer, skip to step 5.
- Treat a wrong rule as progress. The point of step 3 is to find where it fails, so praise a crisp claim that can be broken over a vague one that cannot.
- Name the Lakatos move each time the user responds to a counterexample, with one line on what it gains or costs.
- Keep the path clean, not historical. Skip real dead ends that teach nothing; keep the ones that expose an assumption.
- Check facts you rely on. If a counterexample or the canonical form can be checked by a quick calculation, a script, or a repo file, check it before you use it.

## Example: Euler's polyhedron formula

1. Problem: "Count the corners, edges, and faces of a cube, a tetrahedron, and a triangular prism. Do you see a pattern?"
2. The user tables the counts and guesses V - E + F = 2.
3. They try to prove it (for example, by flattening the shape onto a plane). You ask them to find a shape that breaks it. If stuck, offer a cube with a square tunnel drilled through it (V - E + F = 0).
4. The user says "that is not a real polyhedron" (monster-barring), or "only for shapes without holes" (exception-barring), or adds "the surface can be stretched onto a sphere" as an explicit condition (lemma-incorporation). Next counterexample: two cubes joined at one corner.
5. Compare with the textbook: V - E + F = 2 for convex polyhedra, and more generally the Euler characteristic, which is 2 minus twice the number of holes.

Beyond maths, the same loop for a data model: "orders keep showing the wrong price after a product changes; fix it" leads the user to snapshot prices, counterexamples about refunds and currency push the repair, and only then do you show the real schema.

## The running notes doc

Keep a short markdown doc so the user can see the path:

- Path: `/tmp/learning-<concept-slug>/rebuild.md`, where `<concept-slug>` is a lowercased kebab-case slug of the concept.
- Announce the path when you create it.
- Record the problem, each version of the user's rule, each counterexample with the move made, the list of assumptions made explicit, and the step 5 comparison.

## Platform notes

The loop is plain conversation and needs no special tools, so it runs the same on Claude Code and Codex.
