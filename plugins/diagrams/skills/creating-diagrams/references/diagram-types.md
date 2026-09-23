# Diagram types

> Fallback path only. With Node 18+, the bundled engine lays out, routes, and validates diagrams itself (see `SKILL.md`); use this file when drawing SVG by hand.

Five types share one SVG vocabulary (the classes in `template.html`). Pick the type from the question the reader asks, not from the input format.

| Type         | Answers                              | Use for                                                          |
| ------------ | ------------------------------------ | ---------------------------------------------------------------- |
| architecture | What exists and what talks to what?  | Services, components, cloud and security boundaries, deployments |
| workflow     | Who does what, in which order?       | Processes, approval gates, runbooks, CI/CD, agent tool loops     |
| sequence     | What happens, call by call, in time? | API call chains, request lifecycles, async round trips           |
| dataflow     | Where does data come from and go to? | Pipelines, ETL/ELT, lineage, governance, consumers               |
| lifecycle    | Which states can one thing be in?    | Status machines, retries, waiting states, terminal outcomes      |

When one question needs two types (a system map plus the order of one request), draw two diagrams, not one hybrid.

## Shared node vocabulary

Node classes carry meaning. Every saturated color on the canvas maps to one of these, and the legend names only the classes the diagram uses.

| Class          | Meaning                                                                                |
| -------------- | -------------------------------------------------------------------------------------- |
| `c-frontend`   | UI and client apps the team builds, human-facing steps                                 |
| `c-backend`    | Services, workers, compute, active processing                                          |
| `c-database`   | Stores, caches, files, successful outcomes                                             |
| `c-cloud`      | Managed cloud services, platform, waiting or queued states                             |
| `c-security`   | Auth, secrets, policy, gates, failure states                                           |
| `c-messagebus` | Queues, topics, streams, event buses                                                   |
| `c-external`   | Third parties, users and their browsers or devices, systems outside the team's control |

Modifiers: `v-emphasis` (thicker stroke, one or two nodes on the main path at most), `v-outline` (stroke only, for double borders), and `v-dashed` (planned, optional, or deprecated; say which in the legend).

Edge classes, each with its own marker so the arrowhead matches the line:

| Class        | Marker                 | Meaning                                                                                                                                                                      |
| ------------ | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `a-emphasis` | `url(#arrow-emphasis)` | Edges on the main path; one path per diagram, which may span several edges. Beats every other edge class; say "auth" in the label when a main-path edge is also an auth flow |
| `a-default`  | `url(#arrow-default)`  | Synchronous call or plain dependency                                                                                                                                         |
| `a-async`    | `url(#arrow-async)`    | Event, message, or fire-and-forget                                                                                                                                           |
| `a-security` | `url(#arrow-security)` | Auth flow, token check, policy decision                                                                                                                                      |
| `a-return`   | `url(#arrow-default)`  | Response or return (sequence diagrams)                                                                                                                                       |

Boundary classes: `b-region` (cloud region or account), `b-security` (security group, trust zone, VPC), `b-group` (any other ownership or deployment group, for example a Kubernetes cluster), `b-lane` (workflow swimlane, dataflow stage band), `b-lifeline` (sequence lifeline).

Text classes: `t-name` (11px, node name), `t-sub` (9px, one-line sublabel), `t-tag` (8px, annotation), `t-edge` (8px, relationship label), `t-legend` (8px, legend entry), `t-boundary` plus a color class such as `t-cloud` (10px, boundary label), `t-title` (12px, lane or participant header).

Base node pattern, used by every type:

```svg
<rect class="c-mask" x="X" y="Y" width="W" height="H" rx="6"/>
<rect class="c-backend" x="X" y="Y" width="W" height="H" rx="6"/>
<text class="t-name" x="X+W/2" y="Y+26" text-anchor="middle">Name</text>
<text class="t-sub" x="X+W/2" y="Y+42" text-anchor="middle">sublabel</text>
```

For a 44px node, put the name at `Y+18` and the sublabel at `Y+32`. The mask rect makes the node opaque, so an edge drawn underneath never shows through the translucent fill.

## Architecture

- One left-to-right spine for the main request path, with short vertical branches for auth, queues, caches, and side stores.
- 6 to 12 primary nodes. Past 12, split into an overview plus one detail diagram per boundary.
- Group only real ownership, trust, network, or deployment boundaries. A box drawn "for tidiness" misleads.
- Nest boundaries at most two deep (region, then security group). Leave 20px between a boundary edge and any node inside it, and 24px above the first node for the boundary label.
- The template's sample is an architecture diagram; copy its structure.

Boundary pattern:

```svg
<rect class="b-security" x="X" y="Y" width="W" height="H" rx="8"/>
<text class="t-boundary t-security" x="X+10" y="Y+16">sg-api :443</text>
```

## Workflow

- Lanes are responsibility (a team, role, or system); columns are progression. Lanes run horizontally, time runs left to right.
- Lane band: a `b-lane` rect across the full width, 104px tall, with a `t-title` label in a 120px left gutter. Nodes sit centered in their lane.
- Node mapping: human step `c-frontend`, automated step `c-backend`, external system or tool `c-external`, artifact written `c-database`, wait or queue `c-cloud`.
- Decision or gate: a diamond, `c-security`, with the question as its name and each outgoing edge labeled with its answer.
- Start is a small `c-external` circle (`r="7"`); end is a pill (`rx` equal to half the height).
- Retries and rework loops route outside the main corridor (above the top lane or below the bottom lane), never back through the middle of the flow.
- 12 steps at most on the main path; group sub-steps into one node with a sublabel.

Lane and decision patterns:

```svg
<rect class="b-lane" x="20" y="Y" width="W" height="104"/>
<text class="t-title" x="32" y="Y+56">Reviewer</text>

<polygon class="c-mask" points="CX,CY-30 CX+44,CY CX,CY+30 CX-44,CY"/>
<polygon class="c-security" points="CX,CY-30 CX+44,CY CX,CY+30 CX-44,CY"/>
<text class="t-name" x="CX" y="CY+4" text-anchor="middle">Approved?</text>
```

## Sequence

- Participants across the top as 44px-tall `c-*` nodes, 140px wide, 180px apart center to center (40px clear gap). Order them by first appearance in the flow, caller on the left.
- A `b-lifeline` runs down from the bottom center of each participant (`<path class="b-lifeline" d="M CX Y1 V Y2"/>`), ending 24px below the last message.
- Messages are horizontal arrows between lifelines, one per row, 36px apart vertically. The first row sits 40px below the participant bottoms. Number every message: `1 POST /orders`.
- Message label: `t-edge`, baseline 6px above the line, centered in the first gap next to the sender (not at the midpoint of a long arrow, which lands on an intermediate lifeline), with a `c-mask` rect behind it. A label wider than the gap (`6.5px x characters + 13px`) gets a wider participant pitch or a shorter label.
- Calls use `a-default`, main-path messages `a-emphasis`, auth calls off the main path `a-security`, async sends `a-async`, responses `a-return` right to left.
- Activation bars (optional): a 10px-wide `c-backend` rect centered on the lifeline, spanning the rows where that participant is working.
- Self-call: `<path class="a-default" d="M CX+5 Y H CX+40 V Y+20 H CX+7" marker-end="url(#arrow-default)"/>`.
- Notes (local work with no message, such as "verify JWT"): a `t-tag` 8px right of the lifeline, on its own row. Notes do not count toward the message limit.
- Optional or repeated blocks: a `b-group` rect spanning the lifelines involved plus 24px on each side, 16px above the first row and 12px below the last. Put the `t-tag` label (`opt cache miss`, `loop per item`) inside its top-left corner on a `c-mask` rect, in a column with no lifeline under it. Add the block to the legend.
- Lifelines cross messages by construction; the crossing check ignores them.
- 15 messages at most. Past that, split by phase.

## Dataflow

- Columns are stages, in order: source, ingest, store, transform, serve, consume. Put a `t-title` stage header above each column and optionally a `b-lane` band behind it.
- Rows are domains or datasets; keep one dataset on one row across stages so lineage reads as a straight line.
- Sources and consumers outside the team are `c-external`; stores are `c-database`; jobs and transforms are `c-backend`; streams are `c-messagebus`; governance or PII controls are `c-security`.
- Batch movement uses `a-default`; streaming uses `a-async`. Label edges with the format or cadence (`parquet, hourly`), not a verb.
- Show governance as a `b-security` boundary around the stages it covers, not as extra arrows.

## Lifecycle

- One entity, its states, and the events that move it. Main column progression left to right: states N and N+1 sit in adjacent columns.
- State node: a pill (`rx="22"` on a 44px-tall rect). Mapping: initial or new `c-frontend`, active `c-backend`, waiting or queued `c-cloud`, success `c-database`, failure `c-security`, neutral or external `c-external`.
- Initial marker: a filled circle (`r="6"`, class `c-external`) with an edge into the first state. Terminal states get a double border: behind the state, draw a second rect 4px larger on every side with the same class plus `v-outline` (stroke only, no fill).
- Transition labels are events or conditions (`payment failed`, `timeout 30s`), on `t-edge`.
- Put failure and terminal states on a row below the main path, aligned under the state they branch from. A recoverable failure needs a real transition back (routed below the row), not an implied one.
