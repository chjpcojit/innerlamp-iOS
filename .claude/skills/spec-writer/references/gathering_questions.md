# Gathering questions from the user

Before generating or updating any spec file, ask the required questions using the `ask_user` tool
(or equivalent), never by guessing. This reference defines the required question set and the
phrasing rules that make questions easy for a non-technical stakeholder to answer.

## Phrasing rules

- **One topic per question.** Never bundle two decisions into one question.
- **Concrete, not abstract.** Instead of "What's the navigation model?", ask "Can this screen be
  reached from outside its own feature flow (e.g. from a menu in another section), or only from
  within one flow?"
- **Give an example or default** whenever possible, so the user can just confirm or pick, rather
  than compose an answer from scratch:
  - Bad: "What should the acceptance criteria be?"
  - Good: "What happens if the user submits with invalid input — show inline field errors and
    block submission (default), or something else?"
- **Short.** A question the user can answer in one line or one tap beats a paragraph they have to
  parse.

## Required question set (before generating a new spec)

Ask these in order, one at a time or grouped in a single short form — whichever fits the
`ask_user` tool's format:

1. **Feature name?** (PascalCase) — e.g. `Settings`, `PaymentHistory`.
2. **Is this feature already implemented in code, or not yet built?** → determines Prospective vs
   Retroactive mode (`modes.md`).
3. **In one sentence: who is the user and what do they want to accomplish?** (the user story)
4. **Can this screen be reached from outside its own feature flow** (cross-section, likely owned by
   `AppCoordinator`), **or only from within one existing section**?
5. **Does completing this feature's main action trigger more than one sequential API call** —
   including calls that belong to a *different* feature right after this one (e.g. this feature
   sends a code, then a different screen verifies it)? Yes/No — if yes, a Step-by-step Flow section
   is required in `design.md` (see `step_by_step_flow.md`).
6. **For each API call identified above: is the exact contract (endpoint, request/response shape,
   error cases) already confirmed with the backend, or still unknown?** Anything "still unknown"
   becomes a `⚠️ Not confirmed` marker, not an assumed shape.
7. **Is there any hidden validation/check step you know about that isn't obvious from the main
   action** — e.g. a duplicate check, a rate limit, a secondary confirmation? (This is the question
   that surfaces things like "check phone isn't already registered" before they get silently
   folded into a one-line user story.)

## When updating an existing spec (not creating fresh)

Ask instead:

1. **What changed?** — one sentence: a new requirement, a scope change (e.g. moving something out
   of "Out of scope" into scope), or an answer to a previously `⚠️ Not confirmed` item?
2. If it answers a `⚠️ Not confirmed` item: **what is the answer**, phrased as plainly as possible
   (e.g. "public URL" vs "static bundled text" vs "fetched from our own API").
3. If it's a new/changed behavior: **does it affect an existing acceptance criterion, or is it
   entirely new?**

## The "never skip" rule

If the user doesn't answer a required question (declines, or says "not sure yet"), do **not**:
- Leave it out of the spec entirely.
- Pick a default and present it as if confirmed.
- Ask again repeatedly in the same session — ask once, then proceed with it marked open.

Instead, write it into the spec using the exact format from `SKILL.md` rule 3:

```
> ⚠️ Not confirmed: <the question, one sentence> — <what it blocks, e.g. "blocks tasks.md Phase 3
> from being implementable">.
```

Place it in the section it's most relevant to (`requirements.md`'s "Pending" section for
behavior/content questions, `design.md`'s relevant flow step for technical/API questions) — not
just dumped at the top of the file where it loses context.
