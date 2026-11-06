---
name: ar-skill-repo
description: Maintain the skills collection repository anttiraisala/ar-skills. Use when asked to add, update, rename, remove, list, check, package or release a skill in ar-skills, to sync or fix the README skill list, to show or check skill dependencies, or on commands such as "lisää skilli repoon", "listaa skillit", "tsekkaa skillit", "päivitä skilli", "paketoi skilli", "skill repo status".
---

# ar-skill-repo

Version: 3 (raise by one on every change to this file, and keep the number in the README skill list the same).
Requires: ar-git-repo

Maintains the repository `anttiraisala/ar-skills`: one folder per skill in `skills/<name>/SKILL.md`, plus `README.md`, `CLAUDE.md`, `PROGRESS.md`, `LICENSE`. Chat in the language the user writes in; everything written into the repository is in English.

Repo creation, branch fixes (main to master) and generic repo checks belong to `ar-git-repo`. This skill covers only the contents of the skills collection.

## Setup at the start of every session

1. Make sure the repo is cloned and up to date (`git clone https://github.com/anttiraisala/ar-skills.git`, or `git pull --ff-only` in an existing clone). If push access is needed and not available, say so and give the output as files for the user to commit.
2. Work on branch `master`. Never force-push. Never commit secrets.

## Rule for every commit: update, announce, wait

1. Update every file the change touches: the skill, the README skill list, `PROGRESS.md`, and `CLAUDE.md` if a rule changed.
2. Tell the user briefly which files, which branch and which commit message you are about to commit and push.
3. Wait for an explicit go-ahead. If the user has just said to do it for this very commit, proceed.
4. After the push verify: `git ls-remote origin master` equals `git rev-parse HEAD`, and `git status -sb` shows no `ahead`.

Commit messages are English, one line, format `<skill> vN: <what changed>` or `Repo: <what changed>`.

## Commands

The user may give a command in Finnish or English, or describe the intent freely.

### list ("listaa skillit")
Read-only. Show every skill in `skills/` with version, description and file size, and mark mismatches against the README list (missing row, wrong version, row without folder).

### add ("lisää skilli")
1. Get the skill text: pasted by the user, an uploaded file, or an existing skill from the user's account.
2. Validate it with the `check` rules below before writing anything.
3. Create `skills/<name>/SKILL.md`. Name is lowercase kebab-case and equals the folder. Add `Version: 1` as the first line of the body if missing.
4. Run `sync`, add a row to `PROGRESS.md`, announce, wait, commit, push, verify.
5. Show the full text as a review card (`propose_skills`) when available, and tell the user to save it; the account copy changes only when he saves it.

### update ("päivitä skilli <name>")
Edit the skill, raise its `Version:` by one, run `sync`, add a `PROGRESS.md` row, then the commit rule. Show the review card afterwards. Repo copy is the source of truth.

### rename and remove
Only on an explicit request. Rename: `git mv skills/old skills/new`, change `name:`, run `sync`, record it in `PROGRESS.md`. Remove: delete the folder, run `sync`, record it. Remind the user to delete the account copy himself, since a session cannot.

### sync ("synkkaa lista", "päivitä README")
Keeps the top of the README and the skill list current. Run it after every add, update, rename or remove, and whenever `check` finds drift. It maintains two marked blocks in `README.md`:

1. The "For use with AI" section, placed right after the title and one-line description (the layout `ar-git-repo` defines), between `<!-- ai:start -->` and `<!-- ai:end -->`. It always holds: the repository URL and default branch, the command that gets the whole repo (`git clone https://github.com/anttiraisala/ar-skills.git`), the ZIP link of the whole collection, a `curl` line for downloading one skill (example: the first skill in the list), and the pointers to `CLAUDE.md` and `PROGRESS.md`. If the section or its markers are missing, the script creates them in the right place.
2. The skill list between `<!-- skills:start -->` and `<!-- skills:end -->`: one row per folder in `skills/`, alphabetical, version from the `Version:` line, download link from the name, explanation kept from the existing row (a new skill gets the first sentence of its description, to be shortened by hand).

Run the script below from the repo root. Without `--write` it prints the diff and exits 1 if the README is out of date; with `--write` it fixes the README. It stops with an error if the README does not start with a title and a one-line description. Review the diff, then follow the commit rule.

```python
#!/usr/bin/env python3
import re, sys, difflib, pathlib

OWNER, NAME, BRANCH = "anttiraisala", "ar-skills", "master"
args = [a for a in sys.argv[1:] if not a.startswith("--")]
write = "--write" in sys.argv
repo = pathlib.Path(args[0] if args else ".").resolve()
readme = repo / "README.md"
text = readme.read_text(encoding="utf-8")
LS, LE = "<!-- skills:start -->", "<!-- skills:end -->"
AS, AE = "<!-- ai:start -->", "<!-- ai:end -->"
ml = re.search(re.escape(LS) + r"\n(.*?)\n" + re.escape(LE), text, re.S)
if not ml:
    sys.exit("README.md has no skills markers")

old = {}
for line in ml.group(1).splitlines():
    c = [x.strip() for x in line.strip().strip("|").split("|")]
    mm = re.match(r"\[([^\]]+)\]", c[0]) if c else None
    if mm and len(c) >= 3:
        old[mm.group(1)] = c[2]

names, rows = [], []
for f in sorted((repo / "skills").glob("*/SKILL.md")):
    body = f.read_text(encoding="utf-8")
    fm = re.match(r"---\n(.*?)\n---", body, re.S)
    name = re.search(r"^name:\s*(\S+)", fm.group(1), re.M).group(1) if fm else f.parent.name
    desc = re.search(r"^description:\s*(.+)$", fm.group(1), re.M).group(1) if fm else ""
    ver = re.search(r"^Version:\s*(\d+)", body, re.M)
    ver = ver.group(1) if ver else "?"
    summary = old.get(name) or (re.split(r"(?<=\.)\s", desc)[0] if desc else "<insufficient data>")
    raw = f"https://raw.githubusercontent.com/{OWNER}/{NAME}/{BRANCH}/skills/{name}/SKILL.md"
    names.append(name)
    rows.append(f"| [{name}](skills/{name}/) | {ver} | {summary} | [SKILL.md]({raw}) |")

table = "| Skill | Version | What it does | Download |\n|---|---|---|---|\n" + "\n".join(rows)
new = text[:ml.start(1)] + table + text[ml.end(1):]

example = names[0] if names else "<skill>"
FENCE = "`" * 3
ai = f"""{AS}
## For use with AI

Repository: https://github.com/{OWNER}/{NAME} (default branch: `{BRANCH}`)

Clone everything:

{FENCE}
git clone https://github.com/{OWNER}/{NAME}.git
{FENCE}

Download the whole collection as a ZIP: https://github.com/{OWNER}/{NAME}/archive/refs/heads/{BRANCH}.zip

Download one skill (example: `{example}`):

{FENCE}
curl -L -o SKILL.md https://raw.githubusercontent.com/{OWNER}/{NAME}/{BRANCH}/skills/{example}/SKILL.md
{FENCE}

Rules for AI assistants working in this repo are in [CLAUDE.md](CLAUDE.md); status is in [PROGRESS.md](PROGRESS.md). Each skill is a folder `skills/<name>/` with a `SKILL.md`.
{AE}"""

ma = re.search(re.escape(AS) + r".*?" + re.escape(AE), new, re.S)
if ma:
    new = new[:ma.start()] + ai + new[ma.end():]
else:
    mh = re.search(r"^## For use with AI\n.*?(?=^## |\Z)", new, re.S | re.M)
    if mh:
        new = new[:mh.start()] + ai + "\n\n" + new[mh.end():]
    else:
        mt = re.match(r"(# [^\n]+\n\n[^\n]+\n\n)", new)
        if not mt:
            sys.exit("README.md must start with a title and a one-line description")
        new = mt.group(1) + ai + "\n\n" + new[mt.end():]

if not re.match(r"# [^\n]+\n\n[^\n]+\n\n(<!-- ai:start -->|## For use with AI)", new):
    print("WARNING: README does not start with title, one line, For use with AI")

if new == text:
    print("README is up to date")
    sys.exit(0)
print("".join(difflib.unified_diff(text.splitlines(True), new.splitlines(True), "README.md", "README.md (new)")))
if write:
    readme.write_text(new, encoding="utf-8")
    print("README.md written")
else:
    sys.exit(1)
```

### check ("tsekkaa skillit")
Read-only lint of the whole collection. Report in the user's language, then propose numbered fixes and carry out only the approved ones.

1. Each folder has `SKILL.md`; frontmatter has `name` (equals folder, lowercase kebab-case) and `description`.
2. Description says what the skill does and when to use it, with trigger phrases; flag descriptions under about 80 or over about 600 characters, and descriptions that overlap strongly with another skill's.
3. Body has a `Version:` line with an integer; the README row shows the same number.
4. README list: markers present, alphabetical, one row per folder, download links return HTTP 200 (`curl -sI -o /dev/null -w "%{http_code}"`).
5. README starts with title, one line and the "For use with AI" section; the clone command, ZIP link and example download link are correct (run `sync` without `--write`; a diff means drift).
6. Everything in the repo is in English; no secrets (tokens, keys, `.env`, strings like `ghp_`, `sk-`); no file over 1 MB.
7. `PROGRESS.md` has a row for the latest change of every skill.
8. Dependencies: run the `deps` script; every skill named on a `Requires:` line exists in `skills/`, with no cycles.
9. Drift: if the user pastes or names the account copy of a skill, compare its `Version:` with the repo copy and say which is newer.

### deps ("riippuvuudet")
Read-only. Show which skill requires which (the `Requires:` line, see below) and run the checker below. It reports a required skill that is not in `skills/` and circular requirements, and exits 1 on either. The same script is rule 8 of `check`.

```python
#!/usr/bin/env python3
import re, sys, pathlib

repo = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
skills = {p.parent.name: p.read_text(encoding="utf-8") for p in (repo / "skills").glob("*/SKILL.md")}
deps, bad = {}, 0
for name, body in skills.items():
    head = body.split("\n## ")[0]
    m = re.search(r"^Requires:\s*(.+)$", head, re.M)
    items = [d.strip() for d in m.group(1).split(",")] if m else []
    deps[name] = [d for d in items if d and d.lower() not in ("-", "none")]
    for d in deps[name]:
        if d not in skills:
            print(f"{name}: requires {d}, which is not in skills/")
            bad += 1

def cycle(node, path):
    if node in path:
        return path[path.index(node):] + [node]
    for d in deps.get(node, []):
        if d in deps:
            found = cycle(d, path + [node])
            if found:
                return found

for n in sorted(deps):
    found = cycle(n, [])
    if found:
        print("cycle: " + " -> ".join(found))
        bad += 1
        break
for n in sorted(deps):
    print(f"{n} -> {', '.join(deps[n]) or '-'}")
sys.exit(1 if bad else 0)
```

### status ("skill repo status")
Read-only: `git status -sb`, `git log --oneline -5`, remote equals `HEAD`, uncommitted files, count of skills, result of `sync` without `--write`.

### pack ("paketoi skilli <name>")
Build `<name>.zip` containing the folder `<name>/` with `SKILL.md` at its top (`zip -r <name>.zip <name>`), for uploading as a skill in Claude settings. Run `check` rules 1 to 3 first. Offer the file for download; do not commit the ZIP.

### tag ("tagaa versio")
On request, create an annotated tag `<name>-vN` for the current commit of a skill (`git tag -a`), push only that tag, and add it to the `PROGRESS.md` row. Tags are never moved or deleted without an explicit request.

### history ("skillin historia <name>")
Read-only: `git log --follow --oneline -- skills/<name>/SKILL.md` together with the matching `PROGRESS.md` rows; list which version came with which commit.

### new ("uusi skilli", scaffold)
Create a skeleton from this template, ask the user for name and purpose first, then fill it in with him and finish through `add`:

```
---
name: <kebab-case-name>
description: <What it does. Use when ... (trigger phrases in the user's languages).>
---

# <name>

Version: 1
Requires: none

<One paragraph: purpose and language rules.>

## Defaults
## Commands or steps
## Rules and limits
```

### review ("arvioi skilli <name>")
Read-only quality review of one skill: are the triggers specific enough to fire and not fire wrongly, are steps unambiguous, are destructive actions gated by an explicit request, is anything contradicting `CLAUDE.md` or another skill. Give findings with concrete wording fixes; change nothing without approval.

## Skills that refer to each other

A skill can rely on another skill, for example a coding skill on a language-rules skill. Give it a `Requires:` line directly under the `Version:` line: `Requires: name1, name2` (skill names only, or `none`). In the body, say where the other skill is used ("follow the rules of `name1`"). Claude loads a skill only when its description fits the task or when another skill sends it there, so a `Requires:` line is a pointer, not a guarantee: the body should also say what to do when the required skill is not installed (read its raw file from the repository, or ask the user). Keep chains short and never circular.

## Ideas and critique (always on)

When a skill is added, updated or reviewed, and whenever the user asks for ideas, think critically and say what you see, in at most three short points, each marked as an idea or a concern. Things to look for: rules duplicated in two skills that belong in one shared skill referenced through `Requires:`; descriptions too broad (fires wrongly) or too narrow (never fires), or missing the user's actual wording including Finnish with diacritics; a skill that has grown long enough to split; fragile assumptions (file paths, tools that may be absent, the account copy being older than the repo copy); contradictions with `CLAUDE.md` or another skill; steps nobody tested. Propose, never implement without approval, and do not repeat an idea the user has declined unless the situation changed.

## Ongoing rules

- Keep `README.md`, `CLAUDE.md` and `PROGRESS.md` in step with every change, in the same commit. Never claim something was tested if it was not; state in `PROGRESS.md` what was run.
- One skill change per commit unless the user asks otherwise.
- A session cannot update the account copy of a skill; only the user's save from a review card does that. Say this whenever a skill changed.
- If a command is ambiguous (which skill, which version), ask one question.
