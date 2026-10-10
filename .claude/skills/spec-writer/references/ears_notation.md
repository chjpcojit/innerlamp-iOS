# EARS notation for requirements.md

EARS (Easy Approach to Requirements Syntax) is the required phrasing style for every acceptance
criterion in `requirements.md`. It forces each requirement to name a trigger and a mandatory system
response, which is what makes requirements directly testable and unambiguous for both a human QA
and an AI implementing them.

## The pattern

```
WHEN <trigger/event>, THE SYSTEM SHALL <mandatory behavior>.
```

Variants used in this project's specs (see `Docs/Specs/SignUp/requirements.md` for real examples):

- `WHEN <event>, THE SYSTEM SHALL <behavior>.` — the default form for a single trigger → single
  response.
- `WHEN <event> ..., THE SYSTEM SHALL <behavior>, then either: - on success: ... or - on failure
  (<condition>): ...` — for a trigger with a success/failure branch (submit-and-wait patterns).
- `WHEN <condition holds> (a state, not a discrete event), THE SYSTEM SHALL <behavior>.` — for
  conditions like "WHEN the device has no internet connection".

## Good vs bad examples

**Bad** (vague, not testable, hides which system component is responsible):
> The password field should show strength feedback.

**Good** (EARS — names the trigger and the exact system behavior):
> WHEN the user types a password, THE SYSTEM SHALL show a live 3-segment strength meter (weak /
> fair / strong).

**Bad** (bundles multiple behaviors into one criterion, hiding branches):
> Submitting the form sends the code and handles errors.

**Good** (spells out both branches explicitly):
> WHEN the user taps submit with all fields valid, THE SYSTEM SHALL show a loading state, then
> either:
> - on success: navigate to the OTP screen with the phone number in E.164-like grouped format, or
> - on failure (phone already registered): show an alert error and stay on the SignUp screen.

## Rules

1. **One criterion = one trigger.** If a single user action has multiple distinct outcomes
   (success/failure, or several error types), write them as branches of the same criterion (as in
   the example above), not as separate unrelated bullets that lose the shared trigger.
2. **Always name "THE SYSTEM SHALL"** — even though it reads slightly formal/repetitive, this is
   intentional: it keeps every criterion phrased as a testable system obligation, not a passive
   description.
3. **Never leave a hidden step implicit.** If a trigger causes a validation check, a duplicate
   check, or any other side effect before the visible outcome, that check gets its own criterion or
   its own explicit clause — see `step_by_step_flow.md` for how this maps into `design.md`'s
   technical detail. `requirements.md` states *that* the check happens and what the user sees;
   `design.md` states *how* it's implemented (which API, in which order).
4. **Out of scope / Pending / Open questions are not EARS-phrased** — those are plain prose
   sections; EARS applies specifically to the "Acceptance Criteria" section.
