# PROGRESS

| # | Date | Change |
|---|---|---|
| 1 | 2026-11-06 | Repository created; first commit with `ar-git-repo` (create, check and maintain repos, skills-collection mode, README skill list). |
| 2 | 2026-11-06 | `ar-git-repo` version 2: version line, version check in check mode, "Source and updating" section; README list shows versions. |
| 3 | 2026-11-06 | `ar-skill-repo` version 3 added: maintains the skills collection (list, add, update, rename, remove, sync, check, deps, status, pack, tag, history, new, review). `sync` rewrites the README "For use with AI" section and the skill list; `Requires:` convention with cycle and missing-skill check; critique rule; Finnish trigger phrases with diacritics. |
| 4 | 2026-11-06 | `ar-git-repo` version 3: new Mode 4 "suggest repo name" (reads the conversation, default 20 names in five styles with an idea and a one-line description each, three favourites, availability check, asks which project when there are several); Mode 1 calls it when no name is given; Finnish trigger phrases added to the description. |
| 5 | 2026-11-06 | `ar-requirement-driven-development` version 1 added: Requirement Driven Development with `RDD-REQUIREMENTS.md` (overview and requirements), `RDD-IDEAS.md` (ideas, open questions) and `RDD-PROGRESS.md` (status, action points, evidence); `PROGRESS.md` stays the change log. Interview workflow (overview, ideas, requirements, action points, implementation), commands incl. `rdd help`, rule that AI suggestions are ideas until accepted, no implementation without an explicit go, `verified` only with evidence; `init` writes the rules into the project `CLAUDE.md`. Requires `ar-git-repo`. Not run end to end; the `sync` script was not run, the README row was added by hand. |
| 6 | 2026-11-06 | `ar-git-repo` version 4: new Mode 5 "external commit" (also "ulkoinen commit", "deferred commit"). When a commit or push fails and the fixes (push again, attach the repository with push access, a connected GitHub tool) do not help, or on request, the skill builds one zip with `files/`, a self-contained non-interactive `apply.sh` (fresh clone, old-content SHA-256 guard, commit, push without force, PASS/FAIL line, undo command), a generated `REPORT.md`, a paste-ready `PROMPT.txt` and `SHA256SUMS`. The commit rule now points to Mode 5. Not run end to end; no package has been generated or applied yet, and the `sync` script was not run (README row edited by hand). |
| 7 | 2026-11-06 | `ar-skill-repo` version 4: new `critique` command, a critical report on the whole collection (responsibilities, at most seven findings with evidence, proposal and status, Venn diagram saved as `docs/skill-critique.svg`); it asks once, then updates the README "Skill critique" block. `check` rule 10 flags a stale critique; `sync` never touches the block. Not run end to end; the `sync` script was not run (README row edited by hand). |
| 8 | 2026-11-06 | First skill critique report, written by hand by following the `critique` command: seven findings (all open), Venn diagram of ar-git-repo and ar-skill-repo as `docs/skill-critique.svg`, README section "Skill critique". The SVG was checked as XML and rendered once with `rsvg-convert`; it was not viewed on GitHub in light and dark mode. |
| 9 | 2026-11-07 | `ar-skill-repo` version 5: `sync` writes a copy-paste start prompt for AI agents into the README "For use with AI" section and adds empty command overview markers under `## Commands`; the skill writes a per-skill command overview (one section per skill, a table of commands with triggers) into the README; new `check` rule 11 compares the overview with the skills. README now has the start prompt and the command overview for all three skills. The changed `sync` script was run on a copy of the repo: the diff was as expected and a second run reported "README is up to date"; the row counts of the command tables were compared with the command and mode headings by script (5, 10, 14). `check` rule 11 and the rest of `check` were not run as a skill. The critique block is stale (covers ar-skill-repo v4). Applied via external commit (the push from the session was refused with 403). |

## Testing

Nothing here is executable code. The skill text has not been run end to end by the skill loader; the check mode was performed by hand on this repo before the first commit.

## Planned

- More skills as the maintainer asks.

## Open questions

- Whether the account copies of `ar-git-repo` and `ar-skill-repo` have been saved from the review card (the file here is the source).
