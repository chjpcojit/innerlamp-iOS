# Gathering questions before generating

Most of what a concept needs is discoverable by reading the code and the bundle. Ask the user only
for what is genuinely not derivable — chiefly *intent*, and *whether the thing is verified working*,
since neither is visible in source.

Ask at most two or three questions in one message, and only ones whose answer changes what you
write. If you can determine the answer with a `Glob` or a read, do that instead of asking.

## The question set

### 1. Scope — which thing, and which type

Ask only if the request is ambiguous about what it covers.

> Document `ForgotPassword` as a Feature concept, or just its `ILForgotPasswordEntity` as a Domain
> Entity? A Feature concept covers the whole screen and flow; the entity concept covers just the
> model.

Try to resolve this yourself first: if the user named a screen or a user-facing flow, that is a
Feature. If they named a Swift type, that is the type's concept.

### 2. Is it actually implemented and working?

This is the one question that genuinely cannot be answered by reading code, because "the code
exists" and "the flow works against a real backend" are different facts, and `status:` depends on
the second.

> Is the Forgot Password flow verified working end-to-end against a real or staging backend yet, or
> still stubbed? This sets `status: stable` vs `draft`, and whether the concept needs a Pending work
> section.

If the user does not know, default to `draft` and say so. Never default to `stable`.

### 3. Update vs create, when the file already exists

If the target concept exists, confirm what is being changed rather than assuming:

> `features/login.md` already exists. Update it to reflect the newly-wired SMS login, or leave it
> and add a separate concept for the SMS flow?

### 4. Human verification

Only relevant when updating a concept that carries a `verified:` field. Do not ask whether to add
one — this skill never writes that field.

> `features/signup.md` is marked verified by a human. Your update changes the Architecture table, so
> that attestation is now stale — flag it in your PR description so a reviewer re-confirms?

## What not to ask

Do not ask the user for any of these; they are all discoverable:

| Not a question | How to find it |
|---|---|
| Which files implement the feature | `ls` the scene folder, read them |
| The `resource:` path | verify it on disk |
| Which layers exist and what they are named | read the feature's `README.md` and the source |
| What is stubbed | read the UseCase `Impl` — a `print("TODO")` body is self-evident |
| Which Design System components are reused | grep the feature's ViewController for `IL`-prefixed types |
| Which concepts already exist | read `index.md` |
| What `tags:` to use | grep existing concepts for `tags:` |

## Phrasing rules

- **One topic per question.** Do not stack two decisions into one sentence.
- **Offer the concrete options.** "Feature concept or Domain Entity concept?" beats "how should I
  document this?"
- **State the consequence.** Naming what the answer changes ("this sets `status: stable` vs
  `draft`") lets the user answer correctly without knowing the convention.
- **Suggest a default.** "If unsure, I'll mark it `draft`" gives a safe answer path.
- **Keep it short.** A question the user has to scroll to read is a question they will answer badly.

## When the user says "just do it"

Proceed, and record every unresolved decision explicitly in your response — not silently. For each
one, state what you chose and what would change it:

- Unverified end-to-end status → wrote `status: draft`, with the unverified parts listed under
  Pending work. Promote to `stable` once the flow is exercised against a real backend.
- Ambiguous scope → documented the Feature, not the individual entities; say so, and note that
  entity concepts can be added later if the models turn out to be shared.

Never let a default become an invisible assumption. The concept is a reference that others will
trust, so the parts you guessed must be visible to whoever reads it next.
