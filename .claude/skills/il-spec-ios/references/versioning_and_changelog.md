# Versioning and changelog rules

Every spec file (`requirements.md`, `design.md`, `tasks.md`) carries a version header, and every
update to any of them adds a corresponding entry to the shared `changelog.md` in the same folder.
This exists so a reviewer (human or AI) can tell at a glance whether a spec they're reading is
current, and *why* it changed since they last read it — without diffing git history.

## Header format (top of each of the three files)

```markdown
# <Requirements|Design|Tasks> — <Feature>

Version: <major>.<minor>
Last updated: <YYYY-MM-DD>
Status: <one-line status, e.g. "in-progress — API integration pending">

> See `changelog.md` in this folder for the version history of this spec.
```

All three files share the **same version number** at any given time — they are versioned as one
unit, not independently. If only `design.md` changes, still bump the version number in all three
files' headers (even if `requirements.md`'s content didn't change) so it's obvious they were last
reviewed together as of that version.

## Bump rule

- **Minor bump (`+0.1`)**: a clarification, a resolved open question that doesn't restructure
  anything, a small added acceptance criterion, a task list correction.
- **Major bump (`+1.0`)**: a scope change (something moves into/out of scope), a new Phase added to
  `tasks.md`, a structural change to the flow in `design.md` (e.g. adding/removing an API call
  step).

When in doubt, prefer a minor bump — `changelog.md`'s prose description is what actually
communicates the change; the version number is a rough marker, not a precise semver contract.

## changelog.md entry format

Newest version first (reverse chronological). One entry per version, referencing which of the
three files changed and why:

```markdown
## v<version> (<date>)

- `requirements.md`: <what changed and why, in plain language>.
- `design.md`: <what changed and why — or explicitly "no change needed, verified">.
- `tasks.md`: <what changed and why — new Phase, item(s) checked off, item(s) removed>.
- Reason: <one or two sentences on the underlying cause — a new user requirement, an answered
  open question, a corrected assumption after reading the real code, etc.>
```

If a file genuinely didn't need to change for this version, say so explicitly ("no change needed")
rather than omitting it — this confirms it was checked, not forgotten (see `SKILL.md` step 3.2).

## Worked example — resolving an open question two different ways

From `Docs/Specs/SignUp/changelog.md`, showing that answering a `⚠️ Not confirmed` item can either
simplify the design or leave it structurally unchanged — both are valid, and the entry states which
happened:

```markdown
## v1.3 (2026-09-15)

- Resolved the ⚠️ open question from v1.2 on ToS/Privacy content source: confirmed as a public URL
  loaded in a web view.
- `design.md`: simplified — dropped a previously speculative enum, confirmed no Domain/UseCase/
  Repository layer is needed.
- `tasks.md` Phase 5: replaced the "resolve content source" task with "get real URL values" as the
  new blocking task.
- Reason: resolving this question simplified the design (removed a layer that's no longer needed).

## v1.4 (2026-09-15)

- Resolved the ⚠️ open question from v1.1 on whether phone-check is a separate API call: confirmed
  it's part of the same `send-code` response.
- `design.md`: Step 1 updated to state this as confirmed fact — no structural change, the flow was
  already modeled correctly.
- Reason: demonstrates resolving a question doesn't always require a structural change, but the
  spec must still record that it was explicitly confirmed rather than left as an unstated
  assumption.
```

## Initial version

The first version of any new spec is always `v1.0 (initial)`, regardless of Prospective or
Retroactive mode — see `modes.md` for how the entry's description differs between the two.
