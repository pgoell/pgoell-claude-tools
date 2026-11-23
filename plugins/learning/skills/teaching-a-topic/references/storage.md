# Store and retrieve a learning record

## Choose the destination

Use a destination the user named. Otherwise use a Kasten vault already identified
in the conversation or workspace, through available Kasten tools or its mounted
files. Do not search arbitrary home directories for a vault or probe credentials.
With no known vault, use `${XDG_DATA_HOME:-$HOME/.local/share}/pgoell-learning/`
on a local coding host. Expand this at runtime, never assume a specific username.
Keep personal records out of the project's source tree and git history by default.
Do not use `/tmp` as the durable record. If the host offers no writable persistent
destination, continue in chat and say persistence is unavailable; do not block
the first teaching question on storage setup.

Create a collision-free `<topic>/<local-date-time>-<unique-suffix>.md` under the
chosen local root. In Kasten follow its current filing convention instead. Tell
the learner the actual path once. Do not overwrite an existing session with the
same topic. Announce a save only after it succeeds.

For retrieval, start with an explicit path, source link or topic. Use bounded
filename/content search and read only the matching records. Never treat a topic
name alone as permission to replace an earlier session. For local writes, reread
before updating, preserve unrelated text, and use atomic replacement. If another
writer changed the record, merge the new attempt into the fresh version or save
a separate uniquely named session; never silently drop either writer's content.

## Kasten adapter

1. Read the tool's guide first. Before any write, read the vault's
   `99 Misc/01 Config/reading-this-vault.md` (or its configured equivalent) and
   the ontology guide it points to. Follow the current link resolution, type and
   filing rules; do not hardcode a new ontology or folder hierarchy.
2. Reuse an existing record only on resume. For a new note without a user-given
   path, follow the guide's agent inbox rule (currently `00 Inbox/00 Agent/`).
   Use a unique topic/session filename. Never hand-write managed `id`, `created`
   or `modified` frontmatter, or modify the vault's version-control directory.
3. Use `read_note` then `save_note` or `append_note`, passing the returned `sha`
   for an update. A new note uses the tool's create semantics. On stale digest,
   reread, preserve concurrent edits and retry with the new digest. Never retry
   an update as an unconditional create. Check whether an uncertain write landed
   before retrying, using the session and attempt IDs to avoid duplicates.
4. A mounted vault uses its documented file-write path instead. Do not mix tool
   writes and filesystem writes for one session. If a call fails, report the
   unsaved checkpoint, continue teaching, and offer an available durable fallback;
   do not claim the graph or record was updated.

Use only the tools actually exposed by the host; prefixes vary. Kasten's agent
API has no shell, glob or regex. Use `list_notes`, fixed-string `search_notes`,
`read_note` and bounded `query_graph` there. On a local mounted vault, normal
filesystem tools remain available. Do not imply that this plugin adds Kasten
tools to a host that has none. Claude Code, Codex and Cursor share this protocol;
only the question interface and storage capabilities differ.

## Graph integration and limits

Link the session to existing concept and source notes, using resolved paths and
the vault's relation vocabulary. If a relationship is unclear, use a plain link
and explain it in prose rather than asserting an invented typed relation. Never
put a learner misconception into a canonical concept note as fact. Keep proposed
concept-note edits separate until the learner asks to integrate them.

Kasten currently draws one node per note, not per claim or heading. Stable claim
IDs in session records support precise practice now; they do not create visible
proposition nodes. Do not create hundreds of tiny notes to mimic the video's
graph. Distinguish prerequisite links, reasoning steps and assessment evidence.
Store jointly required premises in an explicit reasoning step: two ordinary
arrows alone do not express that both premises are required.

The plugin does not add a graph layout, mastery overlay, new chat inputs or a
learning database. Such Kasten app changes are future work. The current product
path is source note + existing chat pane + linked session note + existing graph.
