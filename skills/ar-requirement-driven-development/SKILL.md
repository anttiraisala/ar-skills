---
name: ar-requirement-driven-development
description: Guide and maintain Requirement Driven Development (RDD) in a project with the files RDD-REQUIREMENTS.md, RDD-IDEAS.md and RDD-PROGRESS.md. Interviews the user, turns ideas into requirements and action points, and keeps all files current. Use when asked about project requirements, ideas, action points or RDD, or on "rdd help", "rdd ohje", "rdd status", "rdd init", "mitä vaatimuksia tässä projektissa on", "lisää idea", "lisää vaatimus", "tiivistä toimenpiteiksi", "mitä osaat".
---

# ar-requirement-driven-development

Version: 1 (raise by one on every change to this file, and keep the number in the README skill list the same).
Requires: ar-git-repo

Requirement Driven Development (RDD): a project is driven by requirements the maintainer has agreed. Ideas are refined first, requirements are broken into action points, and progress is tracked per requirement. This skill interviews, advises, and keeps the RDD files current at all times. Chat in the language the user writes in; everything written into a repository is in English (command words may be Finnish).

Repo creation, base files and commit hygiene belong to `ar-git-repo`; follow its rules for them. If `ar-git-repo` is not installed, read its raw file from `anttiraisala/ar-skills` (`skills/ar-git-repo/SKILL.md`) or ask the user.

## Files (project root, uppercase names)

The first line under the title of every file states its role, and spells out the abbreviation RDD once.

**RDD-REQUIREMENTS.md**: an `## Overview` section (Purpose, Users, In scope, Out of scope, Constraints; about ten lines, the single source for what the project is), then the requirement table: `ID | Requirement | Acceptance criterion | Origin | Revisions`. The README one-line description is taken from the Purpose and kept the same.

**RDD-IDEAS.md**: table `ID | Idea | Status | Notes`, then `## Open questions` with `OQ-nnn` items. Idea statuses: `new`, `refining`, `promoted -> REQ-nnn`, `dropped (reason)`.

**RDD-PROGRESS.md**: the current state. Table `ID | Status | Evidence` with one row per requirement. Statuses: `planned`, `in progress`, `done`, `verified`, `changed`, `dropped`. Under it, one `## REQ-nnn action points` list per requirement with items `- [ ] AP-nnn text` (`[x]` when done).

**PROGRESS.md**: stays the dated change log of the repo (a base file of `ar-git-repo`): one row per change with the date, what changed, which IDs, and what was actually run. Evidence belongs only in RDD-PROGRESS.md; the log mentions the change and the IDs.

IDs: `REQ-001`, `IDEA-001`, `OQ-001`, `AP-001`. Numbers run on across the project and are never reused. Dropped or changed items stay in the file with the reason.

## Core rules

1. **The user decides.** Anything the AI proposes goes into RDD-IDEAS.md first. RDD-REQUIREMENTS.md rows, Overview text and Out-of-scope lines change only after the user explicitly accepts them. Never write a requirement in the user's name on an assumption.
2. **No implementation without an explicit go.** Discussion, ideas, requirement and status edits are documents only. Start code or other changes to the product only when the user says so (for example "toteuta", "toimi"), naming what to do. At the end of a turn where nothing was implemented, say so.
3. **Always current.** Every change that touches the project (idea, requirement, decision, code, status) updates the affected RDD files and PROGRESS.md in the same commit. At the start of every session in an RDD project, read the three RDD files and report drift before other work: a done action point without evidence, a promoted idea without a REQ row, `verified` without evidence, a requirement missing from RDD-PROGRESS.md, a changed Overview.
4. **Honest status.** `verified` needs evidence in the Evidence column (a test run, command output, or a described manual check against the acceptance criterion). Without it the status is `done` at most. Never claim something was tested if it was not.
5. **Changes leave a trace.** Editing a requirement text adds a note in Revisions and sets its status to `changed` until it is verified again. Changing the Overview adds a PROGRESS.md row, because it can make earlier requirements stale.
6. **Conflicts are raised.** If a request contradicts a requirement or an Out-of-scope line, say so and ask before acting.

## Workflow (interview and advice)

Order: Overview, ideas, requirements, action points, implementation. Ask at most about four short questions per round, on one topic, and say what is still missing.

1. **Overview.** Ask the five fields, propose a draft, write it after acceptance. In an empty project this is the first question.
2. **Ideas.** Record each idea as `IDEA-nnn`, ask clarifying questions, set `refining`, log unanswered questions as `OQ-nnn`.
3. **Requirements.** When an idea is clear (one sentence and a testable acceptance criterion), propose the REQ text and criterion. On acceptance: add the REQ row, mark the idea `promoted -> REQ-nnn`, add a `planned` row to RDD-PROGRESS.md.
4. **Action points.** When the user asks (for example "tiivistä toimenpiteiksi") or wants to proceed, split the requirement into small, checkable `AP-nnn` items under it in RDD-PROGRESS.md, propose an order, and wait.
5. **Implementation.** On an explicit go for named action points or a requirement: do them, tick `[x]`, update the status, check the result against the acceptance criterion, record evidence, add the PROGRESS.md row.

## Commands

The user may give a command in Finnish or English, or describe the intent freely.

- **help** ("rdd help", "rdd ohje", "mitä osaat"): explain what this skill can do in one line per command, then show the project state (counts of ideas, requirements and action points per status), any drift, and a recommended next step. In a project without RDD files, offer `init`.
- **status** ("rdd status"): read-only state and drift report, without the command list.
- **init** ("rdd init"): create the three RDD files from the templates below and add the rules block below to `CLAUDE.md`; make sure PROGRESS.md exists as the log. Missing base files are created following `ar-git-repo`. Never convert a project to RDD silently; offer it first.
- **overview** ("yleiskuva"): create or edit the Overview with the user.
- **idea** ("lisää idea", "hio ideaa <id>", "hylkää idea <id>"): add, refine or drop an idea.
- **requirement** ("lisää vaatimus", "ylennä idea <id>"): propose and add a requirement, or promote an idea.
- **actions** ("tiivistä toimenpiteiksi <REQ>"): create the action points for a requirement.
- **do** ("toteuta <AP tai REQ>"): implement, under rule 2.
- **verify** ("varmenna <REQ>"): check against the acceptance criterion and record evidence.
- **check** ("rdd check"): read-only lint: unique and unreused IDs, every promoted idea has its REQ, every REQ has a progress row, statuses consistent with evidence.

## Templates for init

RDD-REQUIREMENTS.md:

```
# RDD-REQUIREMENTS
Functional requirements agreed by the maintainer (RDD = Requirement Driven Development). IDs are never reused.

## Overview
**Purpose:**
**Users:**
**In scope:**
**Out of scope:**
**Constraints:**

## Requirements
| ID | Requirement | Acceptance criterion | Origin | Revisions |
|----|-------------|----------------------|--------|-----------|
```

RDD-IDEAS.md:

```
# RDD-IDEAS
Raw ideas and open questions (RDD = Requirement Driven Development). An idea becomes a requirement only when the maintainer accepts it.

| ID | Idea | Status | Notes |
|----|------|--------|-------|

## Open questions
```

RDD-PROGRESS.md:

```
# RDD-PROGRESS
Current status of every requirement with action points and evidence (RDD = Requirement Driven Development).
Statuses: planned, in progress, done, verified, changed, dropped.

| ID | Status | Evidence |
|----|--------|----------|
```

Rules block to add to the project's `CLAUDE.md`:

```
## Requirement Driven Development (RDD)
- Files: RDD-REQUIREMENTS.md (overview and requirements), RDD-IDEAS.md (ideas and open questions), RDD-PROGRESS.md (status, action points, evidence), PROGRESS.md (dated change log).
- Keep all four current in every commit that changes the project.
- AI suggestions go to RDD-IDEAS.md first; requirements, the overview and out-of-scope lines change only after the maintainer accepts them.
- Do not implement until the maintainer explicitly says so (for example "toteuta"); say at the end of a turn when nothing was implemented.
- A requirement is "verified" only with evidence in RDD-PROGRESS.md.
```

## Ideas and critique

When asked, and during the interview, say what you see in at most three short points, each marked as an idea or a concern: a requirement that cannot be tested, two requirements that conflict, an idea outside the scope, an action point that is too big, a rule duplicated in two files. Propose, never implement without approval, and do not repeat an idea the user has declined unless the situation changed.

## Ongoing rules

- The RDD files are project deliverables; if the project is delivered as a zip, they go inside it. Other rules of the project and the user still apply.
- Commits follow the announce-update-wait rule of `ar-git-repo`; commit messages are English.
- A session cannot update the account copy of a skill; only the user's save from a review card does that. Say this whenever this skill changed.
- If a command is ambiguous (which requirement, which action points), ask one question.
