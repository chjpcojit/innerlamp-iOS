# What This Skill May Write to `Docs/Specs/<Feature>/`

Two skills already own these files: `il-spec-ios` writes them, and it is the only thing allowed
to change what they *say*. This skill implemented the work, so it is the one place allowed to
record that the work happened. The split is exactly:

| File | This skill may | This skill may NOT |
|---|---|---|
| `tasks.md` | tick `[x]` on items it genuinely completed | reword, add, or delete an item; tick anything not actually done |
| `changelog.md` | append one new version entry at the top | edit or reorder existing entries |
| `requirements.md` | sync the `Version` / `Last updated` / `Status` header lines | touch any line of prose |
| `design.md` | sync the `Version` / `Last updated` / `Status` header lines | touch any line of prose |

The header-only exception exists because the three files share one version number (see
`il-spec-ios`'s `references/versioning_and_changelog.md`) — bumping the changelog without
bumping the headers would leave the spec self-inconsistent. It is a mechanical sync, nothing more.

## 1. Ticking `tasks.md`

Tick an item only if this run actually did it, and only the items in the API-integration phase.
Typical outcome for a run that fully landed:

```markdown
- [x] Create `ILSignUpDTO` (`Data/DTOs/`) + `ILSignUpMapper` (`Data/DTOs/Mappers/`)
- [x] Create `SendVerificationCodeEndpoint`
- [x] Create `ILSignUpRepository` protocol + implementation wrapping `NetworkService`
- [x] Inject `ILSignUpRepository` into `ILSignUpUseCaseImpl.init`
- [x] Replace `sendVerificationCode` stub body with real repository call
- [x] Map network/HTTP errors to `ILSignUpError`
- [x] Update `ILSignUpViewModelTests` + add `MockILSignUpRepository`
- [ ] Manual test against a real/staging backend once available      ← stays unticked
```

The last one stays `[ ]` — a real backend was not available, and a simulator run against a mock
host does not satisfy "manual test against a real/staging backend". Never tick it to make the
phase look complete.

Two items are **not** this skill's to tick, even though they sit in the same phase:

- *"Define the API contract with the backend team"* — that is `il-spec-ios`'s
  `gathering_questions` step. It must already be `[x]` before this skill runs at all (it is the
  confirmed contract from `references/contract_requirements.md`). If it is somehow still `[ ]`,
  stop — the pre-flight failed.
- Anything in a later phase (documentation, OKF concepts) — not this skill's work.

## 2. The `changelog.md` entry

Append at the **top** (newest first), matching the format the existing file uses:

```markdown
## v1.5 (2026-09-16)

- `requirements.md`: no change needed, verified — behavior is unchanged; this version implements
  what the spec already described.
- `design.md`: no change needed, verified — the Step 1 contract was implemented as written.
- `tasks.md`: Phase 3 items for DTO/Mapper/Endpoint/Repository/injection/stub-replacement/error-
  mapping/test-update ticked; "manual test against a real/staging backend" left pending.
- Reason: `data-builder` implemented the previously-stubbed `sendVerificationCode` call
  against the contract confirmed in v1.4.
```

Write `no change needed, verified` explicitly rather than omitting a file — the format's whole
purpose is to show a file was checked, not forgotten.

## 3. Version bump

Per `il-spec-ios`'s bump rule: a task-list correction is a **minor** bump (`+0.1`). Ticking off
an existing phase's items is a minor bump. Only a new Phase or a structural design change is major
— and this skill cannot make those, because it cannot write prose.

So a normal run is: `1.4` → `1.5`, applied to the header of all three files plus the new changelog
entry.

## 4. When to stop instead of writing

If implementing the contract proved the spec wrong — the server returns a field `design.md` doesn't
mention, a step is missing from the flow, an error case behaves differently than described — **do
not** record the discovery by editing `design.md`. Stop and report:

```
Design không khớp contract thật — không tự sửa.
- design.md Step 1 nói response chỉ có otpSessionId.
- Contract thật trả thêm `expiresIn`.
- Đây là design change → cần chạy il-spec-ios cập nhật design.md (và tasks.md nếu thêm việc),
  rồi tôi implement lại.
Chưa tick task nào, chưa thêm changelog entry.
```

Do not tick, do not add a changelog entry — leave the spec exactly as it was found, so the
correction happens through the proper cascade rather than as a side effect of an implementation
run.
