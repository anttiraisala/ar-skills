# CLAUDE.md

Working rules for AI assistants (and humans) working on **ar-skills**.

## Project

A collection of Claude skills by Antti Raisala. One folder per skill: `skills/<name>/SKILL.md` (frontmatter `name` and `description`, then the body). Names are lowercase kebab-case.

## Rules

- Branch: `master`. Licence: MIT.
- Everything in the repository is in English, except Finnish trigger phrases (with diacritics) in skill descriptions and command names. Chat with the maintainer is in the language he writes in (Finnish).
- When a skill is added or changed, update the skill list in `README.md` (between `<!-- skills:start -->` and `<!-- skills:end -->`: name, one-line explanation, download link), `PROGRESS.md`, and this file if a rule changed.
- Before every commit: update all description files, tell the maintainer briefly what will be committed and pushed, and wait for his go-ahead (unless he has just given it for exactly this commit). After the push, check that the remote equals `HEAD`.
- The README starts with the title, one line, and the "For use with AI" section.
- Never commit secrets. Never force-push.
- Skills are saved in the user's account through a review card; the copy here is the source for downloading.
- Every skill has a `Version:` line in its body. Raise it on every change and keep the README list in step. The repo copy is the source of truth; the account copy is updated only when the maintainer saves the review card.
- A skill that relies on another skill has a `Requires: name1, name2` line directly under its `Version:` line (`none` if it has no dependency). The `deps` command of `ar-skill-repo` checks that every required skill exists in `skills/` and that there are no cycles.
