# OKF frontmatter schema

Every concept in `Docs/Knowledge/` opens with YAML frontmatter delimited by `---`. This file
documents each field, its allowed values, and the rules that keep the trust tiers meaningful.

## Required fields

```yaml
---
type: Feature | API Endpoint | Domain Entity | UseCase | Architecture Pattern | Design Token | Component
title: Human-readable name, title case (e.g. "Sign Up", "ILButton")
description: One sentence — what it is and what it does. Used by index.md and by agents deciding whether to read further.
resource: <repo-relative path>
tags: [kebab-case, ...]
status: draft | stable | deprecated
generated: { by: <agent-name>, at: <ISO-8601 with offset> }
---
```

### `type`

Exactly one of the seven values listed above, spelled and capitalized as shown. It determines the
bundle section the file lives in — see `concept_types.md`.

### `title`

Title case, human-readable, no trailing punctuation. "Sign Up", not "signup" or "SignUpScreen".
For components and tokens, use the Swift symbol name (`ILButton`, `ILColors`).

### `description`

One sentence. Present tense. Says what the thing is and the single most useful fact about it —
usually its user-visible purpose or its role in the architecture. Match the density of the existing
examples:

```yaml
description: New-user registration screen — collects dharma name/nickname, phone number, and password, then requests an OTP verification code.
description: Returning-user sign-in screen — phone number (country picker) + password, with links to Sign Up, Forgot Password, and guest preview.
```

### `resource`

The repo-relative path to the code this concept describes. **Verify it exists before writing it**
(see `resource_verification.md`). Trailing slash for a feature directory, the `.swift` filename for
a type:

```yaml
resource: InnerLamp/Presentation/Scenes/SignUp/          # feature — a folder
resource: InnerLamp/Domain/Entities/ILUserEntity.swift   # entity — a file
```

Omit `resource:` entirely only for the pre-implementation complex-business-rule draft described in
`Docs/Specs/OKF.md` §3. A concept without `resource:` cannot be drift-checked and must stay
`status: draft`.

### `tags`

Kebab-case, lowercase. Reuse tags that already exist in the bundle before inventing new ones —
grep the existing concepts for `tags:` first. Existing examples: `auth`, `onboarding`, `mvvm-c`.
Add a `type`-ish tag only when it aids search (`networking`, `design-system`, `validation`).

### `status`

| Value | Meaning |
|---|---|
| `draft` | Something described is stubbed, unwired, or not yet exercised end-to-end. Must be paired with a "Pending work" section stating what. |
| `stable` | The behavior described was exercised end-to-end and no known gaps remain. |
| `deprecated` | The concept describes code that has been removed or superseded. Keep the file if it has inbound links worth redirecting; otherwise delete it and its index row. |

`draft` is the correct default for anything frontend-only whose backend call is a stub. Never
promote to `stable` on the grounds that the code "looks complete" — the criterion is exercise, not
inspection.

### `generated`

```yaml
generated: { by: claude-code, at: 2026-09-17T14:32:00+07:00 }
```

`by` names the agent that wrote the current revision. Use `claude-code` when this skill authors the
file. Existing files may carry `copilot-cli` from an earlier revision — leave those alone unless
this skill rewrites the file, in which case `by` becomes `claude-code`.

`at` is ISO-8601 with the local UTC offset. Update it on every revision.

## Optional fields

### `verified`

```yaml
verified: { by: human:ducnguyen, at: 2026-09-18T09:15:00+07:00 }
```

A human attestation that the concept was reviewed against the code in a PR. **This skill never
writes, creates, or alters this field** — an AI-authored `verified` is a lie that defeats the
field's entire purpose, since its value is precisely that a human looked.

If a concept you materially rewrote already carries `verified:`, tell the user in your response
that the attestation predates your change and should be re-confirmed in review. Do not remove it,
do not bump it.

A concept with `verified:` is a trusted reference. A concept with only `generated:` is
AI-authored and unreviewed. The presence or absence of this one field is the trust tier — there is
no separate field for it.

### `sources`

```yaml
sources:
  - path: Docs/Specs/SignUp/requirements.md
    kind: spec
  - path: Docs/Specs/SignUp/design.md
    kind: spec
  - path: InnerLamp/Presentation/Scenes/SignUp/README.md
    kind: implementation-notes
```

Where the concept's content came from. Include this whenever a spec or an implementation README
existed and was actually used — it lets a future reader trace a claim back past the concept. Use
`kind: spec` for `Docs/Specs/` files, `kind: implementation-notes` for a feature `README.md`,
`kind: code` for a file read directly.

Omit `sources:` only when the concept was derived purely from reading code with no spec or README
involved.

### `stale_after`

```yaml
stale_after: 2027-03-17
```

A date after which the concept should be re-checked even if nothing appeared to change — useful for
concepts describing external contracts (a backend API that may drift, a third-party SDK). Use
sparingly; most concepts go stale by code change, not by clock, and a date nobody honors is noise.

## Full example

The canonical shape, from `Docs/Knowledge/features/signup.md`:

```yaml
---
type: Feature
title: Sign Up
description: New-user registration screen — collects dharma name/nickname, phone number, and password, then requests an OTP verification code.
resource: InnerLamp/Presentation/Scenes/SignUp/
tags: [auth, onboarding, mvvm-c]
status: draft
generated: { by: copilot-cli, at: 2026-09-15T00:46:00+07:00 }
sources:
  - path: Docs/Specs/SignUp/requirements.md
    kind: spec
  - path: Docs/Specs/SignUp/design.md
    kind: spec
  - path: InnerLamp/Presentation/Scenes/SignUp/README.md
    kind: implementation-notes
---
```
