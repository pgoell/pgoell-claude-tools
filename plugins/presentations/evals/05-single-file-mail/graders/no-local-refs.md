---
type: regex
target: {source: file, path: deck/onboarding.html}
match: not_contains
flags: i
---

<script[^>]+src=["'](?!https?:|data:)[^"']_["'][^>]_></script>|<link[^>]+href=["'](?!https?:|data:|#)[^"']+\.css
