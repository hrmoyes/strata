<!-- strata:contract (managed by Strata: change workflow settings only) -->
# Strata: agent working memory

This repository is the product. Everything Strata adds lives in this file and
one folder:

```
STRATA.md      the rules (this file)
strata/
  context/     working memory: artifacts, evidence, references (§1)
  docs/        the agents' living map of the project (§4a)
```

This file is tracked, and so is `strata/docs/`. What under `strata/context/`
is tracked depends on the project's **mode** (§1a). In the default **local**
mode nothing there is ever committed, so a fresh clone has these rules and no
`strata/context/` folder. That is normal. Create the folder the first time
you need it.

Read in this order: `CLAUDE.md` / `AGENTS.md` (which point here) → this file
→ `strata/docs/INDEX.md`.

**Project conventions win on code.** Style, architecture, test commands and
review rules already in this repo override anything here. This file governs
*how work is recorded and handed over*, not how the code is written.

**This file is workflow only.** Do not write project facts here: the stack,
build and test commands, file layout, what does or doesn't exist yet. Those
go in `CLAUDE.md` (one per sub-folder if parts of the repo differ) or in
`strata/docs/`, where they are kept current. The only project-specific edits this
file takes are workflow settings: the branch name, the landing method, and
the test and push policies.

---

## 0. Start of every session

Do this before anything else, however far along the project is:

1. Check the mode (§1a): look for `strata:begin (mode: …)` in
   `.gitignore`. No marker means local. Make sure `strata/context/artifacts/` exists
   (create it if missing).
2. List the artifacts and read each one's `README.md` header and summary line.
   Note any with `status: active` or `blocked`, and the suffix on each one's
   **newest** iteration (see §3).
3. Decide where the request fits:
   * it continues an existing artifact → work there, as iteration `N+1`;
   * it is new work → create a new artifact (§2);
   * it is trivial (see the threshold below) → just do it.
4. If an artifact's newest iteration ends `-PART`, the previous agent left work
   for you. Read its "Not done" section before you start.

**Continue or start new?** Continue an artifact when the new work changes the
same "Not done" list or the same pending human decision. Otherwise start a
new artifact and link the related one from its README. If continuing would
mean widening the artifact's title to fit, that is a sign it should have
been a new artifact.

**Adopting this in a project that already exists.** Do not reconstruct
history. Old commits, existing `TODO.md` / `PLAN.md` files and issue trackers
stay where they are and remain valid. Artifacts start from today. When a task
needs background, the first iteration of its artifact may record what you
learned about the current state. That is evidence gathered today, not a
backfilled journal.

**Threshold.** You need an artifact when the work spans more than one sitting,
touches more than a couple of files, involves investigation (a bug, a
performance problem, a design choice), or produces findings someone will want
later. A typo fix, a one-line obvious change or a question answered in chat
needs none. When unsure, create one: it costs a minute, and
**knowledge that is not in an artifact does not exist for the next agent.**
Chat is not a record. Context gets compacted, sessions end, and the next agent
starts with only what is on disk.

## 1. Layout

```
strata/context/
  artifacts/     one folder per task: the record of how it got done
  evidence/      raw logs, dumps, traces and probe output. Always local.
  externals/     third-party clones kept for reference. Never a source of truth. Always local.
  scratch/       throwaway output nobody needs to read again. Always local.
```

Parallel agents work in git worktrees **outside** the repository (§6), so that
build tools, test runners and linters never pick up a second copy of the code.

## 1a. Mode: local (default) or shared

The mode is recorded in the managed block in `.gitignore`
(`# strata:begin (mode: local)` or `(mode: shared)`), so everyone who
clones the repo gets the same one.

**local (the default).** All of `strata/context/` stays on the machine that wrote it.
Handoffs work between sessions and parallel agents on that one machine.
Nothing an agent writes there can leak through a push, and agents can record
messy, honest notes freely. Use this unless more than one person or machine
needs to pick up the work.

**shared (for cross-team work).** `strata/context/artifacts/` is committed with the
code. Artifacts travel with every push, branch and pull request, so a teammate,
another machine or a cloud agent that checks out the branch sees the same
status, the same `-PART` / `-READY` signal, and the same "Not done" list.
Everything else under `strata/context/` stays local. In shared mode:

* **Raw evidence never goes in `artifacts/`.** Logs, dumps, traces, database
  output and probe output go in `strata/context/evidence/<artifact>/<N>-<NAME>/`,
  which stays on your machine. The iteration report says what the evidence
  showed and **how to rerun it** (the command, the input, the environment), so
  a teammate can reproduce it instead of reading your copy.
* **No secrets or client data in artifacts.** No credentials, tokens, keys,
  personal data, customer records or internal hostnames. Describe them
  ("the staging DB", "a customer record with a null email") instead of
  quoting them. The pre-commit hook blocks common key formats, but it is a
  backstop, not a review.
* **Artifacts ride with the branch.** Commit the artifact files along with
  the code they describe. An artifact on a feature branch is visible to anyone
  who checks out that branch, and reaches `main` when the branch merges.
* **One branch advances an artifact at a time**: the one named in its
  header's `branch:` field. To continue it, work on that branch. For work in
  parallel with it, create a sub-artifact (§2) with its own numbering and
  link it from the parent README. If a merge still leaves two iterations with
  the same number, leave both as they are and continue from the highest.
* **The record is still not rewritten** (§4), even when a reviewer would
  prefer tidier notes. Corrections go in a new iteration.

Switching mode: rerun the Strata installer with `-Mode shared` / `--mode shared`
(or `local`) and commit the `.gitignore` change. Going from shared back to
local does not delete artifacts already in git history, and git keeps
tracking them until told otherwise. Stop tracking them (the files stay on
disk) with `git rm -r --cached strata/context/` and commit that, or the hook will
block the next commit that touches an artifact.

## 2. Artifacts

```
strata/context/artifacts/2026-01-20-login-timeout/
  README.md                         the live summary: header, one line, link to the current iteration
  1-REPRO-FINAL.md                  an iteration that needed no extra files
  2-ROOT-CAUSE-PART/                an iteration that did
    README.md
    before.log
    after.log
    probe.txt
  3-FIX-READY.md
```

* The folder name is `YYYY-MM-DD-<slug>`, dated when the artifact is created.
* An iteration that needs logs, probes, patches or dumps becomes a **folder**
  with its own `README.md`. Do not scatter files into the artifact root. The
  root stays readable: one README and a column of iterations.
* In **shared** mode, those raw files go in `strata/context/evidence/` instead
  (§1a), and the iteration folder keeps only what is safe to share.
* Artifacts **nest**. A task that grows a sub-task gets a sub-folder with its
  own `README.md`, and every rule here applies to it.

### The README header

```markdown
---
status: active        # planned | active | blocked | landed | closed | superseded
updated: 2026-01-20
branch: main          # branch or worktree, or "-" if the work is not code
next: what comes next # required for planned / active / blocked
---

# Login requests time out under load

One line, at most 200 characters, for someone who has never opened the folder.

Current iteration: [3-FIX-READY](3-FIX-READY.md).
```

`status` is the artifact's lifecycle. The suffix (§3) is whose move it is.
They answer different questions: an artifact can stay `active` while its
newest iteration is `-FINAL`. There is no generated index. The artifact
READMEs are the index.

## 3. Naming iterations: whose move is it?

An iteration is one slice of work by one agent in one sitting. Every file or
folder an agent produces in an artifact is named:

```
<N>-<MEANINGFUL-NAME>-<SUFFIX>
```

`<N>` counts up within the artifact. `<MEANINGFUL-NAME>` says what the
iteration was about (`REPRO`, `SCHEMA-MIGRATION`, `PERF-BASELINE`), never
`WORK`, `FIXES` or the date again.

The suffix answers one question without anyone opening the file: **whose move
is it now?**

| suffix | the agent is saying | whose move |
|---|---|---|
| `-FINAL` | this iteration's goal is reached | nobody's. Open the next iteration or close the artifact |
| `-PART` | from the code's side, something is still left | **another agent**, starting from where this one stopped |
| `-READY` | done on my side (code written, checks green) but the next step is not code | **the human**: manual testing, a deploy, a review, a decision |

Getting this wrong is expensive. `-FINAL` on work that still needs an agent
means the task quietly stops. `-PART` on work that is really waiting for a
human sends an agent to redo it. **When unsure, pick the suffix that keeps the
responsibility on your side**: `-PART` over `-FINAL`, `-READY` over `-FINAL`.

Whose move it is on an artifact is the suffix on its **newest** iteration.
Earlier suffixes are never renamed.

## 4. The record is not rewritten

Finished iterations are a **log, not a wiki.** New understanding does not
change an old file. A conclusion that turned out wrong stays where it is, so
the next agent can see how understanding changed.

* **Do not edit** previous iterations or their evidence: not wording, not
  verdicts, not logs.
* **Do update** the artifact `README.md`: the header, the summary line and the
  link to the current iteration. The README is the live summary.
* New work goes in a **new file**, `<N+1>-<NAME>-<SUFFIX>`. A correction to an
  earlier iteration lives there, as "what the previous iteration got wrong".
* Files that describe the present state (`strata/docs/*`, `README.md`, a `PLAN.md`,
  architecture notes) *are* updated. Those describe what is true now. The log
  describes how we got there.
* **If a living doc disagrees with the repo, the repo wins.** A `CLAUDE.md`
  that says "no `package.json`" in a repo that has one is out of date: fix the
  doc, and note the fix in your iteration. If you are not sure which is right,
  flag the disagreement in the iteration instead of guessing.

## 4a. Docs: the current map

Artifacts are a log of one task. `strata/docs/` is the map of the project as it is
now: how it is laid out, how to run it, how to verify it, tool quirks and
limits, how external systems behave. Knowledge buried in one task's iteration
is never found by the next agent working on an unrelated task.

**When to write or change a doc.** Only on one of two triggers:

1. **You had to rebuild knowledge the next agent will need again.** If you
   spent time working out the layout, how to run something or how to verify
   it, that map goes in `strata/docs/` instead of staying in your iteration.
2. **You changed something a doc describes.** Update the doc in the same
   change. This includes the project's own docs for humans (a `README.md`, a
   `docs/` folder) when they describe what you changed. Those stay where they
   are; `strata/docs/` is only for the agents' map.

Neither applies to most tasks, so "none needed" is the normal answer in the
report's Docs line (§8).

**Keeping docs small:**

* Update or extend an existing doc before creating a new one. A new file is
  for a new topic, and gets a row in `strata/docs/INDEX.md`.
* One topic per file, about 50 lines at most. Write what is true now, not the
  story of how you found it; the story belongs in the iteration.
* When something stops being true, delete it from the doc rather than adding
  a correction underneath.
* **Every entry says how it was confirmed**: the command, the observation,
  the date. An entry that can't say this is a guess and stays out.
* The iteration links to the doc instead of repeating it.
* **Tag entries humans need too.** When an entry is something a human
  developer working on the project would also need (setup, running it, the
  layout, a gotcha that affects people), add `[for-humans]` to its heading:
  `## Running the dev server [for-humans]`. Tool quirks and agent
  verification recipes don't get the tag. Never remove a tag yourself: a
  developer removes it once they've decided what to do with the entry, so a
  tag always means "not yet reviewed by a human". Developers find them with
  `grep -rn "\[for-humans\]" strata/docs`.
* `strata/docs/` is committed in both modes, so the same rule as shared artifacts
  applies: no secrets, client data or internal hostnames.

## 5. Glossary

* **evidence**: what makes a claim true. A log, a trace, a before/after
  measurement, a command and its output, something someone can rerun. A number
  copied from another artifact is a duplicate, not evidence. A value taken from
  docs, a blog or a reference implementation and written down as measured is
  defective work. Evidence from a live external system (a feed, an API, a web
  page) records **when** it was captured, because it stops being true when the
  source changes. A known limit of the measuring tool is part of the evidence:
  "screenshots taken at 500px, because the browser won't go narrower" is
  evidence; a silently cropped "390px" screenshot is not.
* **external reference**: anything under `strata/context/externals/`. Other people's
  code. It proves **nothing** about this project. At most it helps you ask a
  better question.
* **probe**: code written to answer a question, such as a script that prints a
  struct, a temporary endpoint, a test that calls one function to look at the
  output. Its output is evidence. The probe itself is scaffolding (§7).
* **burn the bridges**: when replacing a path that looks like it works but
  doesn't, do not build a second path next to it. Delete the misleading one,
  put the target structure in place, then connect it. While the misleading
  path exists, the right one will not come together.

## 6. Parallel agents

One agent works directly in the main checkout. A worktree exists only when a
second agent needs to work at the same time. Built-in worktree features (such
as Claude Code's own worktree support) are fine even though they create the
worktree inside the repo, as long as that folder is git-ignored and excluded
from build, test and lint tooling. By hand:

```bash
# from the main checkout
git worktree add ../<repo>-worktrees/<name> -b agent/<name>
# copy untracked local config the work needs, e.g. .env
```

* **local mode:** inside a worktree, `strata/context/` does not exist (it is
  ignored). **Artifacts always live in the main checkout's `strata/context/`.** Find
  it with `git rev-parse --path-format=absolute --git-common-dir`; its parent
  folder is the main checkout.
* **shared mode:** write the artifact in **your own worktree's**
  `strata/context/artifacts/` and commit it on your branch, so it lands with the code.
  Raw evidence still goes in the main checkout's `strata/context/evidence/`.
* Your territory is your worktree and your branch. **Do not touch another
  agent's worktree or branch unless asked.**
* **Format only the files you changed.** A repo-wide formatter run rewrites
  files you do not own and creates conflicts with every other agent.
* Landing, from the main checkout, only when both trees are clean:

  ```bash
  git -C ../<repo>-worktrees/<name> rebase main
  git merge --ff-only agent/<name>
  git worktree remove ../<repo>-worktrees/<name>
  git branch -d agent/<name>
  ```

  **Refuse rather than repair.** Uncommitted work, a dirty main checkout or a
  rebase conflict means stop, leave the worktree as it is, and report. Never
  force anything to get a landing through. If the project lands through pull
  requests instead, open a PR from `agent/<name>` and stop there.

## 7. Before shipping: remove the scaffolding

A probe is how a claim was proved. It is not part of the product, and once
nobody reads it, it is a file the next agent has to understand before they can
ignore it.

So the last step of every branch, before landing or opening a PR, is to read
your **own** diff:

```bash
git diff main...HEAD --stat
git diff main...HEAD
```

For every file, test and log line you added, ask: **what breaks tomorrow if
this is gone?** If the answer is "nothing", remove it now, while you still know
what it was for. Nobody deletes it later, because by then it looks important.

Remove:

* **probe code**: scripts that print things, temporary debug endpoints or
  flags, an example binary that already answered its question, a test written
  to run one function once and look at the output;
* **debug leftovers**: `console.log` / `print` / `dbg!` behind no flag,
  commented-out code kept just in case, a feature flag whose only user was the
  probe;
* **machine state**: dev servers and other background processes you started,
  ports left bound, temporary folders and browser profiles (including ones
  outside the repo, such as in the system temp folder). Stop or delete them,
  or say in "Removed / kept" why they stay.

Keep tests that guard behaviour someone relies on. A test that only proves the
code ran once is a probe. A probe someone will want to rerun goes in the
artifact (`<N>-…/probe.txt`), not in the source tree.

Deleting a probe does not delete the evidence. The artifact keeps the output,
the log and the verdict.

In shared mode the diff also shows your artifact files. They are not
scaffolding and stay, but read them once more for secrets and client data.

## 8. Handing work over

Every iteration ends with a report, in the iteration file itself, containing:

```markdown
## Based on
The trace, log, measurement or command output each claim rests on.

## Done
What changed, and where.

## Not done
What was left out, what is unverified, where the gaps are.
Whether this fixes the root cause or a symptom.

## Needs from human
Required for -READY; leave out otherwise.
One line per decision or action, each one something the human can act on.

## Docs
Which strata/docs/ files were created or changed and why (which trigger, §4a),
or "none needed". "None needed" is the usual answer.

## Removed / kept
Which probes, temporary tests and machine state (processes, temp folders)
came back out, and what stayed on purpose.
("Added no scaffolding" is a valid one-line answer.)
```

**A report without "Not done" is incomplete**, and so is a `-READY` report
without "Needs from human". "Not done" decides between `-FINAL`, `-PART` and
`-READY`. Then update the artifact README's header and current-iteration
link.

**"Needs from human" is only for what the agent can't do or decide itself**:
credentials and access, hosting and spending, product or policy choices,
testing on a real device, sign-off. Anything the agent can decide, it decides
and records the choice and its reasoning under "Done". A question you could
have answered yourself turns a `-PART` into a needless `-READY` and stalls
the work.

If the repo changed under you during the session (new commits, files you
didn't touch), say so under "Based on", so the next agent doesn't take those
changes for yours.

## 9. Before a push that leaves your machine

* **History**: unpushed commits are the investigation. Unless the project says
  otherwise, squash them into commits that describe the effect, not the dig.
  Never rewrite history that has already been pushed.
* **Comments**: a comment stays only if, without it, the next edit would break
  something the code cannot show (an ordering, a race, a lifetime, an upgrade
  hazard). Comments that restate the code, narrate history ("used to",
  "replaces", "fixed by") or cite the investigation are deleted.
* **Scaffolding**: §7 again, over the whole push.
* **Leaks**: no `.env`, no keys, no credentials. Nothing from `strata/context/` in
  local mode; in shared mode, only `strata/context/artifacts/`, checked as in §1a.

The last question about the diff: *does this read as the product, or as the
traces of an investigation?* If it's the second, it is not ready to push.

## 10. git

`.gitignore` contains a managed block. In **local** mode (the default):

```gitignore
# strata:begin (mode: local)
/strata/context/
# strata:end
```

The whole folder, with no exceptions. In **shared** mode:

```gitignore
# strata:begin (mode: shared)
/strata/context/*
!/strata/context/artifacts/
# strata:end
```

Only `strata/context/artifacts/` is tracked; evidence, externals and scratch stay
local. `git add -f` is not a way around either: the pre-commit hook installed
with this contract refuses staged paths under `strata/context/` that the mode does
not allow, and in shared mode it also refuses artifact files that contain
common key or token formats.
