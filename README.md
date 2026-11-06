# ar-skills

A collection of Claude skills by Antti Raisala.

<!-- ai:start -->
## For use with AI

Repository: https://github.com/anttiraisala/ar-skills (default branch: `master`)

Clone everything:

```
git clone https://github.com/anttiraisala/ar-skills.git
```

Download the whole collection as a ZIP: https://github.com/anttiraisala/ar-skills/archive/refs/heads/master.zip

Download one skill (example: `ar-git-repo`):

```
curl -L -o SKILL.md https://raw.githubusercontent.com/anttiraisala/ar-skills/master/skills/ar-git-repo/SKILL.md
```

Rules for AI assistants working in this repo are in [CLAUDE.md](CLAUDE.md); status is in [PROGRESS.md](PROGRESS.md). Each skill is a folder `skills/<name>/` with a `SKILL.md`.
<!-- ai:end -->

## Skills

<!-- skills:start -->
| Skill | Version | What it does | Download |
|---|---|---|---|
| [ar-git-repo](skills/ar-git-repo/) | 4 | Creates, checks and maintains GitHub repositories (master branch, MIT, README, CLAUDE.md, PROGRESS.md), suggests repo names, builds an external commit package when a push fails, and keeps this list up to date. | [SKILL.md](https://raw.githubusercontent.com/anttiraisala/ar-skills/master/skills/ar-git-repo/SKILL.md) |
| [ar-requirement-driven-development](skills/ar-requirement-driven-development/) | 1 | Guides Requirement Driven Development (RDD) in a project: interviews the user and keeps the requirements, ideas, action points and progress files current. | [SKILL.md](https://raw.githubusercontent.com/anttiraisala/ar-skills/master/skills/ar-requirement-driven-development/SKILL.md) |
| [ar-skill-repo](skills/ar-skill-repo/) | 4 | Maintains this skills collection: add, update, check, pack and tag skills, keeps the README AI section and skill list in sync, checks Requires links, writes the skill critique report. | [SKILL.md](https://raw.githubusercontent.com/anttiraisala/ar-skills/master/skills/ar-skill-repo/SKILL.md) |
<!-- skills:end -->

## Skill critique

<!-- critique:start -->
AI-generated critique, 2026-11-06. Covers: ar-git-repo v4, ar-requirement-driven-development v1, ar-skill-repo v4.

![Overlap of ar-git-repo and ar-skill-repo](docs/skill-critique.svg)

| # | Finding | Evidence | Proposal | Status |
|---|---------|----------|----------|--------|
| 1 | The commit rule is written in two skills. | ar-git-repo "Rule for every commit"; ar-skill-repo "Rule for every commit" | Keep the full rule in ar-git-repo; in ar-skill-repo keep three lines and refer to it (`Requires:` is only a pointer). | open |
| 2 | The skills collection is handled by two skills. | ar-git-repo "Mode 3" and "Source and updating"; ar-skill-repo `add`, `update`, `sync` | Cut ar-git-repo Mode 3 to one line that points to ar-skill-repo. | open |
| 3 | Both descriptions fire on "add a skill to ar-skills". | ar-git-repo description; ar-skill-repo description | Remove that phrase from the ar-git-repo description. | open |
| 4 | The two skills that maintain repos are the largest: ar-skill-repo 17.6 kB (14 commands, two embedded Python scripts), ar-git-repo 14.7 kB (five modes). | `wc -c` of both SKILL.md files | Move the scripts of ar-skill-repo into files the skill refers to; make ar-git-repo Mode 5 its own skill (`ar-external-commit`). | open |
| 5 | Parts nobody has run: the external commit package (Mode 5), the `sync` and `deps` scripts, and the RDD skill in a real project. | PROGRESS.md "Testing" and rows 3, 5, 6, 7 | Dry run each on a throwaway repo or project and record the result in PROGRESS.md. | open |
| 6 | An instruction is out of date: when a push is impossible, ar-skill-repo says to give the files to the user. | ar-skill-repo "Setup at the start of every session", step 1 | Refer to ar-git-repo Mode 5 (external commit) in the next ar-skill-repo version. | open |
| 7 | Gap: nothing compares the saved (account) copies of all skills with the repo; only ar-git-repo checks itself, and ar-git-repo was one version behind earlier today. | ar-git-repo Mode 2 step 0; ar-skill-repo `check` rule 9 (needs a pasted copy) | Let `check` load each saved skill, read its `Version:` and compare with the repo. | open |
<!-- critique:end -->

## Licence

MIT, see [LICENSE](LICENSE).
