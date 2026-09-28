# Language: technical preset

Applies to every written surface of a deck built on this preset: titles, diagram labels, table cells, callouts, source lines, and speaker notes. The audience builds and runs the system, so the copy names the parts the way the code does and states every measure with its unit.

## Rules

1. **The title states the decision or the finding, with a number.** One sentence in sentence case, no terminal period, at most two lines and about 15 words. The number is a latency, a count, a duration, an error rate, or a cost from the source. Test: could this title sit on a slide about a different system? If yes, rewrite it.
2. **Name components the way the code does.** Use the real identifier (`checkout-api`, `orders.v1`, `payments-db`) in diagrams, tables, callouts, and body, set in mono. Do not prettify it ("Checkout API Service") and do not invent a friendlier alias. In a title, write the identifier plainly in the title font.
3. **Units, always.** Every measure carries its unit (ms, s, min, h, GB, req/s, %), with a no-break space between number and unit. One unit per metric across the deck: if p99 is in ms on one slide, it is in ms on every slide. Say which percentile (p50, p95, p99) and over what window.
4. **Say what the system does, in the active voice.** "`outbox-relay` publishes to `orders.v1`", not "events are published". Name the actor, then the action.
5. **No marketing words.** Replace "seamless", "robust", "blazing fast", "next-gen", "scalable" and their kin with the measure: "p99 140 ms at 2x peak", "survives the loss of 1 of 3 brokers".
6. **Label edges and messages with what travels.** A sequence message names the call or the payload (`POST /checkout`, `202 Accepted, order_id`), not the intent ("sends request").
7. **Short text blocks.** A callout is 2 or 3 sentences; a table cell is a value or a short phrase with its reason ("Yes: same transaction"). Split any sentence over 25 words.
8. **Numbers.** 2 to 3 significant figures; numerals for all counts and measures; ISO dates (2026-10-20) and ISO weeks (W33) in tables and charts.
9. **Sources.** Write "Source: <system or test>, <what>, <when>" at the bottom left of every slide with data. Name the dashboard, trace sample, load test id, or config file.
10. **Code is real.** Code on a slide compiles in its language, carries its file path, and is cut to the lines that make the point. Never paraphrase code in pseudo-code dressed as a real language.

## Facts

Use only facts, figures, names, and arithmetic that appear in the source material. If a title needs a number the source lacks, write the title with what the source does give and tell the user what is missing. Sums, percentages, and growth rates count as new figures unless the source states them. An identifier counts as a fact: never invent a service, topic, or table name the source does not use.

## Before and after

Each rewrite uses only figures from the fictional checkout story in the gallery slides.

| Before                            | After                                                                         | What changed                                           |
| --------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------ |
| System architecture               | The checkout request now ends at the orders-db commit, 3 hops from the client | Topic label becomes the design decision with a count   |
| Latency overview                  | Checkout p99 jumped from 240 to 610 ms after the sync fraud check shipped     | Names the percentile, both values, the unit, the cause |
| Our blazing-fast new event bus    | Reading orders.v1 directly cuts finance ledger lag from 24 h to 4 min         | Marketing adjective replaced by the measured change    |
| Options considered                | The outbox reaches 140 ms checkout p99 in 3 sprints, 2 fewer than CDC         | States the recommendation and the comparison           |
| Events are published reliably     | Writing the order and its event in 1 transaction removes the dual-write bug   | Passive, vague claim becomes the mechanism             |
| Robust, seamless CI/CD            | The health gate stops a bad build at 5% of traffic within 12 min              | Buzzwords replaced by the gate, the blast radius, time |
| Checkout API Service calls the DB | `checkout-api` commits to `orders-db` in 11 ms (p50)                          | Prettified name replaced by identifiers, with the unit |
