# Language: product preset

Applies to every written surface of a deck built on this preset: titles, body, labels, source lines, and speaker notes. The rules below serve launches, product reviews, and engineering all-hands.

## Rules

1. **The title states the claim.** A content-slide title is one sentence: sentence case, no terminal period, no colon label ("Key findings:"), at most two lines and about 15 words, carrying the number that proves it. Test: could this title sit on a slide with different data? If yes, rewrite it. A colon that joins two clauses is fine; only the colon label is banned.
2. **Split, never shrink.** If the title will not fit in two lines at `--fs-h1`, split the slide or cut words; never reduce the title size.
3. **Titles alone tell the story.** Read only the titles in order: they must form the argument. Executive summary lines map one to one, in order, onto later titles.
4. **Group like with like.** Grouped points are the same kind of idea, in a logical order. No placeholder titles such as "There are three problems".
5. **Short bodies.** 2 to 4 items, one line each, and no more than about 50 words on a slide.
6. **The slide is not the script.** Do not put the narration on the slide; slightly different wording on screen beats reading the same text aloud.
7. **Plain words, active voice.** Use the word the audience would say in the meeting, name who does what, and split any sentence over 25 words.
8. **Numbers.** One unit scale per metric across the deck, 2 to 3 significant figures, "pp" for percentage points, numerals for counts and measures. Abbreviate scales as K, M, and B, never mixed with other forms. Write units the engineers use (min, ms, GB). Units and dates go in the chart subtitle, not the title.
9. **Sources.** Write "Source: X" or "Sources: A; B; team analysis" in the same place on every slide. Every quantitative claim carries one.
10. **Tone: short declaratives.** Say what the product does, in the present tense, with the number. Parallel pairs are allowed ("Faster builds. Smaller bills.") where the pair is the point.

## Facts

Use only facts, figures, names, and arithmetic that appear in the source material. If a title needs a number the source lacks, write the title with what the source does give and tell the user what is missing. Sums, percentages, and growth rates count as new figures unless the source states them.

## Before and after

| Before                                                | After                                                         | What changed                                          |
| ----------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------- |
| Performance improvements                              | Relay 3 cuts median CI time from 22 to 9 minutes              | Topic becomes the claim with before and after         |
| New features overview                                 | Relay 3 caches every step and shares the cache with your team | Names what the product does for the reader            |
| Q4 Sales Data                                         | Sales jumped 40% in Q4                                        | Label becomes a short claim                           |
| Market Overview                                       | The German market grows 12% a year, 3x faster than the US     | Fragment expanded into a sentence with its comparison |
| Leveraging synergies to unlock developer productivity | Each beta team got back 38 hours of CI time a week            | Buzzwords replaced by the measured result             |
