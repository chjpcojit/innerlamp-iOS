@AGENTS.md

## Language policy

Decided by the product owner (anh Đức), 2026-10-15. Applies to every agent and human contributor, and
**overrides any language rule in a skill, template or older doc** in this repo.

| Where | Language |
|---|---|
| Conversation with the user, questions, reports, notes and drafts that are **not committed** | Vietnamese ("anh" for the user, "em" for the agent), technical terms kept in English |
| Everything **committed to git**: docs, specs, ADRs, READMEs, commit messages, PR titles and bodies, identifiers | English |
| Code comments | Bilingual: English first, then Vietnamese |
| User-facing copy (UI strings, localisation catalogues, copy quoted in a spec) | Its own language (Vietnamese first), with an English gloss when quoted in a doc |

- Existing Vietnamese docs stay as they are until they are next edited; a change that edits such a file
  rewrites it in English in the same change. Do not open translation-only PRs.
- Files that are bilingual by convention (EN + VI, e.g. assumptions and tech-debt entries) keep that
  convention; their English part is authoritative.
