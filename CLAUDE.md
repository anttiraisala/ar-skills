# CLAUDE.md

Working rules for AI assistants (and humans) working on **ar-skills**.

## Project

A collection of Claude skills by Antti Raisala. One folder per skill: `skills/<name>/SKILL.md` (frontmatter `name` and `description`, then the body). Names are lowercase kebab-case.

## Rules

- Branch: `master`. Licence: MIT.
- Everything in the repository is in English, except Finnish trigger phrases (with diacritics) in skill descriptions and command names. Chat with the maintainer is in the language he writes in (Finnish).
- When a skill is added or changed, update the skill list in `README.md` (between `<!-- skills:start -->` and `<!-- skills:end -->`: name, version, one-line explanation, download link), the command overview in `README.md` (between `<!-- commands:start -->` and `<!-- commands:end -->`: one section per skill, one row per command or mode), `PROGRESS.md`, and this file if a rule changed.
- Before every commit: update all description files, tell the maintainer briefly what will be committed and pushed, and wait for his go-ahead (unless he has just given it for exactly this commit). After the push, check that the remote equals `HEAD`.
- The README starts with the title, one line, and the "For use with AI" section.
- Never commit secrets. Never force-push.
- Skills are saved in the user's account through a review card; the copy here is the source for downloading.
- Every skill has a `Version:` line in its body. Raise it on every change and keep the README list in step. The repo copy is the source of truth; the account copy is updated only when the maintainer saves the review card.
- A skill that relies on another skill has a `Requires: name1, name2` line directly under its `Version:` line (`none` if it has no dependency). The `deps` command of `ar-skill-repo` checks that every required skill exists in `skills/` and that there are no cycles.
- Repo names are proper nouns: English first, but Finnish words are allowed when the context is Finnish or local (decided by the maintainer). Their one-line descriptions are English.
- Helper scripts of a skill live in `skills/<name>/tools/` and are committed with mode `100755` (`git update-index --chmod=+x`), so a clone or a zip runs them without `chmod`. A skill that uses them says where to get them. After changing the external commit scripts of `ar-git-repo`, run `skills/ar-git-repo/tools/selftest-external-commit.sh`.
- External commit packages are named `external-commit-<repo>-<YYYYMMDDHHMMSS>.zip` (UTC), are built only with `skills/ar-git-repo/tools/build-external-commit.sh`, and are never committed to the repository.
