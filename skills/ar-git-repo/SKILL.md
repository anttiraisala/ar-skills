---
name: ar-git-repo
description: Create, check or maintain a GitHub repository for a project (default owner anttiraisala, branch master, MIT). Use when asked to create a repo, check a repo ("check repo", "tsekkaa repo"), suggest a repo name ("suggest repo name", "ehdota repon nimeä", "keksi repolle nimi"), fix main/master, add a skill to ar-skills, or make an external commit ("external commit", "ulkoinen commit", "tee ulkoinen commit", "deferred commit") when a commit or push cannot be done in this session.
---

# ar-git-repo

Version: 5 (raise by one on every change to this file, and keep the number in the README skill list the same).
Requires: none

Creates, checks and maintains Git repositories the way the maintainer wants them. Chat in the language the user writes in; everything written into a repository is in English.

## Defaults (the user may override any of them)

- Owner: `anttiraisala` (confirm once when creating a repo).
- Visibility: public. Branch: `master`. Licence: MIT, copyright holder "Antti Raisala".
- Never commit secrets (tokens, keys, `.env`). Never force-push. Never delete a branch or repo without an explicit request.

## Rule for every commit: announce, update the descriptions, wait

Before every commit and push:

1. Update all description files the change touches: `README.md`, `CLAUDE.md`, `PROGRESS.md`, and in a skills collection the skill list in the README.
2. Tell the user briefly (a few lines) what you are about to commit and push: files, branch, message.
3. Wait for the user's go-ahead. Only an explicit instruction to do it counts. If the user has just given that instruction for this very commit, go ahead.
4. After the push, check that the remote branch equals `HEAD` (`git ls-remote origin master` against `git rev-parse HEAD`) and that `git status -sb` shows no `ahead`. If the commit or the push fails, follow Mode 5 (external commit).

Commit messages are English and end with the attribution lines the session gives.

## Mode 1: create a repo

1. Ask for the name and a one-line purpose (and the owner if it is not the default). If the user has no name yet, run Mode 4 (suggest repo name) first. Plan the repo: type of project, files that fit it.
2. Create it with `gh repo create OWNER/NAME --public --description "..."`. If that is refused (some sessions may only use repositories that are already configured), give the short browser steps (github.com/new, name, public, no files added) and wait until the user says it exists, then clone it.
3. Inspect the state (see Mode 2). In an empty repo create the branch `master` and push it first (`git checkout -b master`, then `git push -u origin master`); then check that `master` became the default branch, and if not, change it (`gh repo edit --default-branch master`).
4. First files by project type. Always: `LICENSE` (MIT), `README.md`, `.gitignore`, `CLAUDE.md` (working rules and decisions), `PROGRESS.md` (status, what was and was not tested, planned work, open questions). Add the project's own skeleton as needed.
5. README layout: title and one line first, then the "For use with AI" section (see below), then the rest. Show a short summary of the first commit, wait for the go-ahead, commit, push, verify.

## Mode 2: check repo (read-only)

Triggered by "check repo", "tsekkaa repo" or similar. Change nothing without approval.

0. Version check: fetch the raw `SKILL.md` of this skill from `anttiraisala/ar-skills` (see Source and updating) and compare its `Version:` line with the one above. If the repo is newer, tell the user that the saved copy of the skill is out of date and offer the review card for the new text. If the fetch fails, say so and carry on.

1. Does the repo exist, who owns it, is it public or private, is there write access (`gh api repos/OWNER/NAME`: `permissions`, `default_branch`, `visibility`, `description`)?
2. Branches and tags (`git ls-remote --heads --tags`), open pull requests, last push.
3. Branch situation: empty repo (no branches; the default setting `main` is only a placeholder), `main` only, `master` only, both, or other branches.
4. Light freshness check of `README.md`, `CLAUDE.md`, `PROGRESS.md`, `LICENSE`, `.gitignore`: missing, empty, or clearly out of date (for example a skill folder missing from the README list). Check that the README starts with title, one line and the "For use with AI" section.
5. Report in the user's language, briefly, then propose a numbered list of actions and wait. Carry out only the approved numbers, each following the announce-and-wait rule above.

### main to master

A default branch cannot be deleted, so rename it instead of making a copy: `gh api -X POST repos/OWNER/NAME/branches/main/rename -f new_name=master`. This moves the branch, keeps its history, pull requests and branch protection, and updates the default branch. Afterwards tell the user to run `git fetch origin && git branch -m main master && git branch -u origin/master master` in their own clones. If the repo has other branches or open pull requests, stop and ask first: renaming retargets pull requests and may affect people's checkouts, so the user decides.

## "For use with AI" section (top of every README)

Placed right after the title and one-line description, so that it is visible at once. Content:

- The clone command: `git clone https://github.com/OWNER/NAME.git` and the default branch name, filled from the repo (not guessed).
- Where the instructions for AI assistants are: `CLAUDE.md` (rules) and `PROGRESS.md` (status).
- In a skills collection: how to download one skill (the Raw link of its `SKILL.md` and a `curl -L -o SKILL.md <raw url>` line) and the whole collection (ZIP link of the branch and the clone command).
- For a private repo: a note that downloads need to be signed in or use a token; do not put a token in the file.

## Mode 4: suggest repo name

Triggered by "suggest repo name", "ehdota repon nimeä", "keksi repolle nimi" or similar, and by Mode 1 when there is no name. It only proposes; it creates nothing. Once the user picks a name, continue with Mode 1.

1. Find out what is being named:
   - No extra text: read the whole conversation and work out what is being built. If it names several projects, list the ones you found and ask which one the repo is for; never guess.
   - Extra text ("lyhyt ja leikkisä", "something with cards"): treat it as the steering and keep it above what the conversation suggests.
   - Too little to go on: ask a few short guiding questions (what it does, who uses it, short or descriptive, any word it must or must not contain), then propose.
2. Count: default 20. The user can ask for another number ("suggest 10", "ehdota 30"). Spread the names evenly over five styles: descriptive, short brand name, playful, local (place, language or in-joke), acronym. Every style gets at least one name.
3. Names: lowercase kebab-case, no spaces, not long (about 30 characters at most), like `poker-table-designer`, `ai-slop-games`, `ar-skills`. English first. Finnish words are allowed and fit when the context is Finnish or local (for example Molino for the home casino); decide from the context and say so in the idea line. A repo name is a proper noun, so it is an exception to the English-only rule.
4. Availability: for the names you are about to show, check that the owner has no repo of that name (`gh api repos/OWNER/NAME`; 404 means free). Drop taken names and say how many were dropped. Names other owners use do not matter.
5. Output: one table per style with three columns: name, idea (one sentence: why the name works), description (one line in English, about 80 to 100 characters, written to fit that name's angle, not the same sentence for every name). Then your three favourites with one sentence each. Offer another round on request.
6. When the user picks a name, use its description as it is in `gh repo create ... --description "..."` (or give it for the browser form), and use the same sentence as the README's one-line description.

## Mode 5: external commit (when this session cannot push)

Triggered by "create external commit", "external commit", "tee ulkoinen commit", "ulkoinen commit", "deferred commit", and automatically when a commit or push fails and step 2 below does not fix it. It is not a project handoff: it moves one finished change to a place that can push (the user's machine, or another AI session with write access).

1. Name the cause of the failure in one line (blocked by the permission classifier, 403 from the git proxy, repository not attached, no network, no credentials). When the user asked for an external commit, skip steps 1 and 2.
2. Try the fixes once each, in this order: push again; if the error says the repository is not in the session's sources and an `add_repo` tool exists, attach the repository with push access and push from the existing clone; a connected GitHub tool that can write files to the branch. A denial by a permission classifier is final for this session: do not look for another way around it, go to step 3.
3. Build the package without asking: the user already asked for the commit, and the package changes nothing until it is run. Never build it by hand: use the two scripts below. Do not commit or push anything yourself for the package; the changes stay in the working tree (or in the unpushed commits) of the clone.

### The tools

Two bash scripts do the work; they live in this skill's folder in the repository `anttiraisala/ar-skills`, `skills/ar-git-repo/tools/` (raw base URL `https://raw.githubusercontent.com/anttiraisala/ar-skills/master/skills/ar-git-repo/tools/`):

- `build-external-commit.sh` builds the zip.
- `apply-external-commit.sh` is the script that goes into the zip and applies it.
- `selftest-external-commit.sh` tests both end to end in a throwaway directory (local bare repositories only, no network); run it after changing either script.

Both are stored in Git with mode `100755` (`git update-index --chmod=+x`). Get them from a clone of ar-skills; if the session has none, download the two files into one new directory and `chmod +x` them (the only place where `chmod` is needed). If they cannot be fetched, say so and ask the user to attach them; never rewrite them from memory.

Build: run from the clone, with the message split into subject and body, and the attribution lines the session gives as trailers:

```
skills/ar-git-repo/tools/build-external-commit.sh --repo-dir . --out-dir <dir outside the repo> \
  --message "Subject line\n\nBody" --trailer "Co-Authored-By: ..." --trailer "Claude-Session: ..."
```

The builder fetches `origin/<branch>` (the base), compares it with the working tree (committed, uncommitted and untracked files), and builds everything from the real files with Git and `sha256sum`. Several unpushed commits become one external commit; their subjects go into the commit body. One package, one logical change. It refuses symbolic links, `.git` paths and unsafe names, and it checks its own output: the zip stores mode 755 for the apply script, the unpacked copy is executable, and `SHA256SUMS` verifies.

### The package

The zip is named exactly `external-commit-<repo>-<YYYYMMDDHHMMSS>.zip`, for example `external-commit-ar-skills-20261107142305.zip`: repository name (no owner), then the build time in UTC with year, month, day, hour (24 h), minute and second, never only a date. It holds one folder with the same name (without `.zip`) so that unpacking does not litter the current directory:

- `files/`: the new content of every added or changed file at its repository path, byte for byte, with the mode it will have in Git (755 or 644).
- `apply-external-commit.sh`: the apply script, stored with Unix mode 755. The executable bit is kept by the zip and by `unzip` on Linux, so the recipient runs `./apply-external-commit.sh` and never needs `chmod`. Do not rename the script or the folder layout.
- `MANIFEST.tsv`: one line per file: action (A, M, D), old mode, old SHA-256, new mode, new SHA-256, size, path (`-` where not applicable).
- `external-commit.meta`: format, repository `owner/name`, remote URL, branch, base commit, timestamp. `COMMIT_MESSAGE.txt`: the commit message.
- `REPORT.md`: repository, branch, base commit, commit message, a table of every file (action, old and new SHA-256, size, mode), how to run, how to undo, the exit codes and the commands that produced the manifest.
- `PROMPT.txt`: text to paste into another AI session with write access. Inline form (changes under about 40 kB, all plain text ending in a newline): the task, the rules (write each file byte for byte between the markers, overwrite, touch no other file, set the modes, never force-push, stop and report if the old content does not match), the files in `=====FILE: path=====` and `=====END FILE=====` blocks, a table of modes and SHA-256 values, and the report asked for (in the user's language, at most five lines: commit SHA, whether verification passed, anything unexpected). Otherwise the zip form: unpack the attached package, check `SHA256SUMS`, run `./apply-external-commit.sh --dry-run`, then `./apply-external-commit.sh`, and report the same way.
- `SHA256SUMS` for every other file in the package.

The `PROGRESS.md` row for the change is part of the package and says "applied via external commit".

### What `apply-external-commit.sh` does

Needs only `git`, `bash` and `sha256sum`; never `sudo`, `--force`, tokens, or network access other than git; it asks nothing. It deletes only its own temporary directory. Options: `--dry-run` (verify and show the plan, commit nothing), `--no-push` (commit in a temporary clone that is kept and whose path is printed, nothing is pushed), `--remote URL` (clone another URL, for tests or mirrors; the base commit must still match), `--help`.

1. Package check: `sha256sum -c SHA256SUMS`, and the package holds no symbolic links and no file that `SHA256SUMS` does not list. Exit 2 on any failure.
2. Manifest check: format, actions, modes, hashes, every payload file present and equal to its recorded hash, every path relative and free of `..`, `.git`, control characters and duplicates. Exit 2.
3. Target check: clone the repository into a fresh temporary directory; the recorded URL must name the recorded repository, and the base commit must exist in the clone and be an ancestor of the branch tip (wrong repository or rewritten history gives exit 2).
4. Guard: every modified or deleted file must still have the recorded old hash and mode, and every added file must be absent or already equal to the new content. Otherwise print each offending file, change nothing, exit 2. Files that already have the new content are skipped. If only other files changed on the remote since the base, go on and say so. If nothing is left to do, print "nothing to do" and exit 0.
5. Dry run stops here and prints the plan.
6. Write the files with the recorded modes (no write below a symbolic link), `git add`, `git update-index --chmod`, `git rm` for deletions, check the hashes, commit with `COMMIT_MESSAGE.txt`, then verify the commit: exactly the manifest's files, the recorded modes and content hashes.
7. Push without force. If the push is rejected, fetch and rebase once and verify again; on a conflict abort the rebase, exit 3, nothing is pushed. Check that `git ls-remote origin <branch>` equals the new `HEAD`.
8. Print `PASS <sha>` or `FAIL <reason>` and the undo command (`git revert <sha>`). Exit codes: 0 PASS or nothing to do, 1 error, 2 integrity or guard failure, 3 push conflict.

After building: send the zip with the file tool, give the paste text in the chat (when it is short), and say in a few lines in the user's language that there are two ways: unpack and run `./apply-external-commit.sh` (try `--dry-run` first), or paste the prompt into an AI session with write access. Say what was and was not tested. Do not say anything was pushed.

When the user brings back the result (commit SHA and PASS), check it with `git ls-remote https://github.com/OWNER/NAME.git <branch>` and say whether the remote equals it. If it cannot be checked, say so. External commit packages are never committed to the repository.

## Mode 3: skills collection (ar-skills)

The repo `anttiraisala/ar-skills` collects the maintainer's skills, one folder per skill in `skills/<name>/SKILL.md`. When a skill is added or changed:

1. Put the full `SKILL.md` in `skills/<name>/` (frontmatter `name` and `description`; name in lowercase kebab-case).
2. Update the skill list in the README between the markers `<!-- skills:start -->` and `<!-- skills:end -->`: one row per skill with its name (linked to its folder), a short one-line explanation of what it does, and its single-file download link. Keep the rows in alphabetical order.
3. Update `PROGRESS.md` (a row for the change) and `CLAUDE.md` if a rule changed.
4. Follow the announce-update-wait rule above before the commit.

## Ongoing work in any repo

Keep `README.md` (usage), `CLAUDE.md` (decisions) and `PROGRESS.md` (status and honest testing notes) in step with every change, as part of the same commit. Never claim something was tested if it was not.

## Source and updating of this skill

This skill is loaded from the user's account, but its source of truth is the repository `anttiraisala/ar-skills`, file `skills/ar-git-repo/SKILL.md` (raw: `https://raw.githubusercontent.com/anttiraisala/ar-skills/master/skills/ar-git-repo/SKILL.md`). The skill cannot update the account copy by itself: the user saves it from a review card. So when the user asks to change this skill (or any skill of the collection):

1. Make sure the repo is attached to the session and cloned (`add_repo` with push access if it is not), then edit `skills/<name>/SKILL.md` there and raise its `Version:` by one.
2. Update the README skill list (row text and version), `PROGRESS.md` and, if a rule changed, `CLAUDE.md`.
3. Follow the announce-update-wait rule, then commit, push and verify (Mode 5 if the push fails).
4. Show the full updated text as a review card (`propose_skills`) and tell the user to save it, because until he does the account copy stays old.
5. The repo settings (description, default branch) may be unwritable from a session; then say so and give the browser steps.
