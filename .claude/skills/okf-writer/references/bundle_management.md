# Bundle management — index.md, log.md, naming, cross-links

A concept is only useful if it can be found and if its history is traceable. Both files at the
bundle root carry that load, and both are updated in the same pass as the concept itself.

## index.md

`Docs/Knowledge/index.md` is the bundle's table of contents. It has three parts that this skill
maintains:

### 1. The introduction

A short prose block explaining what the bundle is, linking to `../Specs/OKF.md`, and stating the
distinction from `Docs/Specs/` (mutable work-order specs vs durable post-implementation
reference). Update only if a structural fact changes.

### 2. The sections list

Two lists: active sections with a one-line description, and a "Planned, not yet populated" list.
When a concept creates a section's first file, move that section up into the active list and
describe it in one line:

```markdown
- [`api/`](api/) — API endpoint concepts (`type: API Endpoint`), added once real
  backend contracts exist.
```

### 3. The concept table

Newest additions appended; keep the existing column shape exactly.

```markdown
| Concept | Type | Status |
|---|---|---|
| [features/signup.md](features/signup.md) | Feature | draft (backend integration pending) |
| [features/login.md](features/login.md) | Feature | draft (backend integration pending) |
| [design-system/components/il-button.md](design-system/components/il-button.md) | Component | stable |
```

The `Status` column is `status:` from the frontmatter **plus a short parenthetical reason whenever
the status is `draft`** — "draft (backend integration pending)", not bare "draft". A reader
scanning the index should learn *why* something is provisional without opening the file. For
`deprecated`, state what replaced it.

Update a row when the concept's `title`, `type`, path, or `status` changes. Do not reorder rows
just to sort them.

## log.md

`Docs/Knowledge/log.md` is the bundle's change history. **Newest entry at the top**, reverse
chronological.

```markdown
# Knowledge Bundle Update Log

## 2026-09-17

- Documented the Login screen ... and added `features/login.md` (`status: draft`).
  Marked `draft` because ... is still pending — promote to `stable` once that lands.
- Linked `features/login.md` in `index.md`'s concept table.

## 2026-09-15 (2)

- Reviewed the Login screen ... and added `features/login.md` (`status: draft`).
```

Rules:

- Heading is `## <YYYY-MM-DD>`. If a second entry lands on the same day, suffix it `## <YYYY-MM-DD> (2)`,
  matching the existing `2026-09-15 (2)` precedent.
- Each bullet is a complete sentence or two, written in past tense, naming the concept file in
  backticks and its `status`.
- State **why** the status is what it is — "marked `draft` because backend API integration is still
  pending" — not just what was written. The reason is the part a future reader cannot reconstruct.
- Note the follow-up trigger: "promote to `stable` once the Auth API lands and the end-to-end flow
  is verified against a real/staging backend."
- If the entry also touched `index.md`, say so.
- For an update rather than a create, describe what changed and why (a renamed symbol, a stub that
  became real, a validation rule that changed), not just "updated `features/login.md`".

## File and folder naming

- Feature concepts: lowercase, kebab-case, matching the feature folder name —
  `SignUp` → `features/signup.md`; `ForgotPassword` → `features/forgot-password.md`.
- Component and token concepts: lowercase kebab-case of the Swift symbol — `ILButton` →
  `design-system/components/il-button.md`; `ILColors` → `design-system/tokens/il-colors.md`.
- Endpoint concepts: `<domain>-<action>.md` — `auth-signup.md`, `auth-otp-verify.md`.
- Entity concepts: lowercase entity name with the `IL` prefix dropped where it adds no meaning to
  the filename, but keep the concept's `title:` as the real symbol name.

One concept, one file, filename predictable from the thing it documents. A reader should be able to
guess the path.

## Cross-links

Concepts link to each other with **relative markdown links**, using the repo path relative to the
link's own file — not wiki-style `[[...]]` syntax (that is an Obsidian convention, not this
bundle's):

From `features/signup.md`, linking to the login concept in the same folder:

```markdown
- Login feature (`InnerLamp/Presentation/Scenes/Login/`,
  [features/login.md](login.md)) — reachable via "Tôi đã có tài khoản".
```

From `features/signup.md` linking to a concept in a sibling section, and to a section root:

```markdown
- See [OTP](/features/otp.md) — receives the phone number from this feature.
```

Both forms appear in the existing examples. Prefer the path relative to the linking file; the
`/features/...` bundle-root form is also in use and acceptable. Be consistent within a file.

### Dangling links are allowed and intentional

A link to a concept that does not exist yet is a marker, not a bug. The existing SignUp concept
links to OTP and Login concepts that were not yet written at the time. When writing a link whose
target does not exist, say so explicitly next to it:

```markdown
- OTP feature (`InnerLamp/Presentation/Scenes/Otp/`) — receives the phone number from
  this feature after a successful verification-code request. Not yet documented as an OKF
  concept in this bundle.
```

That trailing sentence is what distinguishes an intentional marker from a typo. Include it, and
resolve it by removing the sentence when the target concept is eventually written.

## Related-concepts section

Every concept ends with `# Related concepts`. Each bullet should carry three things where they
apply: the concept name, the real code path in backticks, and the nature of the relationship
(calls, is called by, shares a component, is reachable from, supersedes). A bullet that only names
a sibling adds nothing the index does not already show.
