# PROGRESS

| # | Date | Change |
|---|---|---|
| 1 | 2026-11-06 | Repository created; first commit with `ar-git-repo` (create, check and maintain repos, skills-collection mode, README skill list). |
| 2 | 2026-11-06 | `ar-git-repo` version 2: version line, version check in check mode, "Source and updating" section; README list shows versions. |
| 3 | 2026-11-06 | `ar-skill-repo` version 3 added: maintains the skills collection (list, add, update, rename, remove, sync, check, deps, status, pack, tag, history, new, review). `sync` rewrites the README "For use with AI" section and the skill list; `Requires:` convention with cycle and missing-skill check; critique rule; Finnish trigger phrases with diacritics. |
| 4 | 2026-11-06 | `ar-git-repo` version 3: new Mode 4 "suggest repo name" (reads the conversation, default 20 names in five styles with an idea and a one-line description each, three favourites, availability check, asks which project when there are several); Mode 1 calls it when no name is given; Finnish trigger phrases added to the description. |
| 5 | 2026-11-06 | `ar-requirement-driven-development` version 1 added: Requirement Driven Development with `RDD-REQUIREMENTS.md` (overview and requirements), `RDD-IDEAS.md` (ideas, open questions) and `RDD-PROGRESS.md` (status, action points, evidence); `PROGRESS.md` stays the change log. Interview workflow (overview, ideas, requirements, action points, implementation), commands incl. `rdd help`, rule that AI suggestions are ideas until accepted, no implementation without an explicit go, `verified` only with evidence; `init` writes the rules into the project `CLAUDE.md`. Requires `ar-git-repo`. Not run end to end; the `sync` script was not run, the README row was added by hand. |
| 6 | 2026-11-06 | `ar-git-repo` version 4: new Mode 5 "external commit" (also "ulkoinen commit", "deferred commit"). When a commit or push fails and the fixes (push again, attach the repository with push access, a connected GitHub tool) do not help, or on request, the skill builds one zip with `files/`, a self-contained non-interactive `apply.sh` (fresh clone, old-content SHA-256 guard, commit, push without force, PASS/FAIL line, undo command), a generated `REPORT.md`, a paste-ready `PROMPT.txt` and `SHA256SUMS`. The commit rule now points to Mode 5. Not run end to end; no package has been generated or applied yet, and the `sync` script was not run (README row edited by hand). |

## Testing

Nothing here is executable code. The skill text has not been run end to end by the skill loader; the check mode was performed by hand on this repo before the first commit.

## Planned

- More skills as the maintainer asks.

## Open questions

- Whether the account copies of `ar-git-repo` and `ar-skill-repo` have been saved from the review card (the file here is the source).
