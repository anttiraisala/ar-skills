# CLAUDE.md

Working rules for AI assistants (and humans) working on **ar-skills**.

## Project

A collection of Claude skills by Antti Raisala. One folder per skill: `skills/<name>/SKILL.md` (frontmatter `name` and `description`, then the body). Names are lowercase kebab-case.

## Rules

- Branch: `master`. Licence: MIT.
- Everything in the repository is in English. Chat with the maintainer is in the language he writes in (Finnish).
- When a skill is added or changed, update the skill list in `README.md` (between `<!-- skills:start -->` and `<!-- skills:end -->`: name, one-line explanation, download link), `PROGRESS.md`, and this file if a rule changed.
- Before every commit: update all description files, tell the maintainer briefly what will be committed and pushed, and wait for his go-ahead (unless he has just given it for exactly this commit). After the push, check that the remote equals `HEAD`.
- The README starts with the title, one line, and the "For use with AI" section.
- Never commit secrets. Never force-push.
- Skills are saved in the user's account through a review card; the copy here is the source for downloading.
