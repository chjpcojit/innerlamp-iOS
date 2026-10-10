# Verifying `resource:` and detecting drift

The `resource:` field is the concept's only mechanical link to reality. Everything else is prose,
and prose cannot be checked by a tool. This file covers verifying a path before writing it, what to
do when the target is not a plain file, and how to detect that an existing concept has drifted away
from the code.

## The absolute rule

**Never write a `resource:` path you have not confirmed exists.** Do not infer it from the folder
listing that led you to the code, do not copy it from a spec, and do not reconstruct it from the
naming convention — a folder that looks like `InnerLamp/Presentation/Scenes/ForgotPassword/` may
not exist under that exact spelling.

Confirm with an actual filesystem check:

```bash
ls -d InnerLamp/Presentation/Scenes/SignUp/
ls InnerLamp/Domain/Entities/ILUserEntity.swift
```

or a `Glob` against the pattern. Run it before writing the frontmatter, not after.

## Folder vs file targets

| Subject | `resource:` points at | Trailing slash |
|---|---|---|
| Feature | the feature's scene folder | yes |
| Component | the component's `.swift` file | no |
| Domain Entity | the entity's `.swift` file | no |
| UseCase | the UseCase's `.swift` file | no |
| Design Token group | `.../DesignSystem/Tokens/DESIGN_SYSTEM.md` | no |
| API Endpoint | the feature's `Endpoint` conformance file, or the shared `Core/Networking/Endpoint.swift` when the conformance lives elsewhere | no |
| Architecture Pattern | the primary source file defining the pattern (e.g. `InnerLamp/Core/Base/Coordinator.swift`) | no |

A feature concept points at the folder because a feature spans many files; the per-file detail
belongs in the Architecture table inside the concept. A concept about a single type points at that
type's file, because a folder-level `resource:` would be too coarse to drift-check meaningfully.

## When the path does not exist

This is a finding, not an obstacle. Handle it in this order:

1. **Search for the real location.** The thing may have moved: `find . -name 'ILLoginEntity.swift' -not -path './.git/*'`.
2. **If it moved**, write the real path, and if you are updating an existing concept, note the move
   in the `log.md` entry — a moved file is exactly the kind of drift a reader needs told.
3. **If it genuinely does not exist** (the feature was never built, or was deleted), stop. Do not
   write a concept about code that is not there. Report to the user what you expected to find and
   what is actually present, and ask how to proceed.

Never substitute a plausible path to make the frontmatter complete. A concept whose `resource:`
points at nothing is worse than no concept, because it is trusted and wrong.

## Verifying the Architecture table

Every file named in a concept's Architecture table gets the same treatment as `resource:` — it must
exist at the path written. This is the most common source of drift, because the table lists many
files and only one of them is covered by `resource:`.

Read each file, at least enough to confirm:

- The type name is what you are about to write (a renamed class is a renamed class).
- The layer classification is right (a file in `Domain/UseCases/` that is actually a thin
  pass-through is still a UseCase, but a file that contains UIKit imports is not Domain).
- The one-line role you write is true of the current code, not of the code as it was when the
  concept was last updated.

## Detecting drift in an existing concept

When updating a concept, do not trust its prose. Re-derive it:

1. Read the concept's Architecture table and `resource:` target.
2. Open each file listed. Diff your reading against the table.
3. Look specifically for the drift patterns that actually occur in this codebase:

| Drift pattern | Looks like |
|---|---|
| Renamed symbol | Table says `ILSignUpUseCase`, code has `ILSignUpUseCaseImpl` and a protocol — or the `IL` prefix was dropped |
| Moved file | Table says `Domain/UseCases/SignUp/`, code has it under a differently-named folder |
| Stub became real, or real became stub | Prose says `sendVerificationCode` is a `print("TODO")` stub; code now calls a network service — or the reverse, a real call was reverted |
| Dependency rewired | Concept says the coordinator is owned by `AppCoordinator`; code now nests it under a section coordinator |
| Reused component renamed | Concept lists `ILButton` (`.goldOutline`); the case was renamed or removed |
| Validation rule changed | Concept states a minimum password length; code has a different number |

4. Rewrite the affected sections from what you read, and record the change in `log.md` with the
   reason. "Corrected the Architecture table after `X` was renamed to `Y`" is the shape.

## Handling `status` during a drift check

Drift in the *description* does not by itself change `status`. Status tracks whether the described
behavior is verified working end-to-end, which is a separate question from whether the description
is accurate.

Both directions are possible and both must be handled honestly:

- A stub that is now a real call does **not** automatically make the concept `stable`. The criterion
  is that the flow was exercised end-to-end against a real/staging backend. If you cannot confirm
  that, leave `draft` and say what is still unverified.
- Real behavior that was reverted to a stub **does** make a `stable` concept `draft`, immediately,
  with the reverted item listed in Pending work. Never leave a `stable` marking on a concept that
  now describes a stub.

## Reporting, not silently fixing

When your drift check turns up something a human needs to decide — a feature whose code was deleted
entirely, a concept whose subject turned out to be two things, a `verified:` attestation that your
rewrite invalidates — surface it in your response to the user rather than resolving it unilaterally.
The concept is a shared artifact; a silent rewrite of a verified one is the worst outcome.
