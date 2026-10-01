# Critique

Critique an idea, plan, decision, claim, or situation from several independent angles instead of getting one agreeable answer.

## Skills

- `/critique:critiquing-ideas`: Rewrites the input as a neutral brief, sends it to one fresh subagent per thinking frame, and reports every frame's verdict word for word, then one decision with kill conditions and the cheapest next test. A fresh subagent writes the synthesis too, so the session that shares your framing never ranks the findings. Full mode (default) runs eight core frames plus conditional ones; say "quick" for three.

## Frames

| Frame                                                              | Mode                           |
| ------------------------------------------------------------------ | ------------------------------ |
| Pre-mortem                                                         | Full, quick                    |
| Steelman opponent                                                  | Full, quick                    |
| Outside view and base rates                                        | Full, quick                    |
| Steelman proponent                                                 | Full                           |
| Second-order and systems                                           | Full                           |
| Incentives and stakeholders                                        | Full                           |
| Alternatives and opportunity cost                                  | Full                           |
| Assumption audit                                                   | Full                           |
| Chesterton's fence, falsification, jobs to be done, Fermi estimate | Full, when their trigger holds |

## Evals

`evals/` holds six plans in two framings each (neutral, and an excited author who has already decided): three with a fatal flaw planted in the stated facts, three sound. A pass catches every planted flaw, condemns no sound plan, and gives the same decision under both framings.

First A/B run (2026-09-30, 168 subagents, about 10M tokens): four arms (a plain in-session critique, one fresh critic, quick mode, full mode) all caught 6 of 6 planted flaws and condemned 0 of 6 sound plans. The fixtures are too easy to tell the arms apart, and the in-session arm had no shared conversation history, so it did not reproduce the context-driven agreement the skill targets. Harder fixtures (subtle flaws, flaws that need outside knowledge, a long friendly history before the ask) are the next step.

## Cost

Full mode runs 9 or more subagents per call (8 core frames, any conditional frames, 1 synthesis); quick mode runs 4.
