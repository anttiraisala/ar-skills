# ar-skills

A collection of Claude skills by Antti Raisala.

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

## Skills

<!-- skills:start -->
| Skill | What it does | Download |
|---|---|---|
| [ar-git-repo](skills/ar-git-repo/) | Creates, checks and maintains GitHub repositories (master branch, MIT, README, CLAUDE.md, PROGRESS.md) and keeps this list up to date. | [SKILL.md](https://raw.githubusercontent.com/anttiraisala/ar-skills/master/skills/ar-git-repo/SKILL.md) |
<!-- skills:end -->

## Licence

MIT, see [LICENSE](LICENSE).
