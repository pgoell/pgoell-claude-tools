This file holds this loop's answers to the plugin's rules, and any rule of its own.
next.sh joins it with the plugin's rules.md to build the brief, so a plugin update reaches the brief with no merge.

A section starts at a line that begins with two hashes and a space. It runs to the next such line.
There are three kinds of section:

- N.K, for example 5.2: the answer to the K-th FILL marker of rule N. Markers count from the top of the rule. The answer replaces the marker text, and the rest of the rule stays.
- N, for example 9: the whole of rule N, starting with "N. ". It replaces the plugin's rule N. An empty section drops rule N from the brief. A number the plugin lacks adds a rule in number order.
- 0: the header, the lines above rule 1.

next.sh refuses to run while a FILL has no answer. It names each one that is missing, with its question.
upgrade.sh writes this file from an old full rules.md.
