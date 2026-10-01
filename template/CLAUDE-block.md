<!-- strata:begin (managed by Strata, edit STRATA.md instead) -->
## Agent workflow: read `STRATA.md` first

This project keeps agent working memory in `strata/context/` and an agents'
map of the project in `strata/docs/`, under the rules in
[`STRATA.md`](STRATA.md). Follow them in every session, whatever the task and
however far along the project is.

**Before your first action in a session:**

1. Read `STRATA.md` if it is not already in your context.
2. Check the mode in `.gitignore` (`strata:begin (mode: …)`).
   **local** (the default, and what no marker means): all of
   `strata/context/` stays on this machine. **shared**:
   `strata/context/artifacts/` is committed with the code; raw evidence stays
   local in `strata/context/evidence/`.
3. Create `strata/context/artifacts/` if it does not exist. An empty or
   missing `strata/context/` is normal on a fresh clone.
4. List `strata/context/artifacts/*/README.md` and check each one's `status`
   and the suffix on its newest iteration. Any `-PART` is work waiting for an
   agent.
5. Decide whether this request continues an artifact, needs a new one, or is
   below the threshold (trivial edits, questions).

**While working:** new findings go in a new iteration file
`<N>-<NAME>-<FINAL|PART|READY>`. Never edit earlier iterations. Keep the
artifact `README.md` header current. If a doc disagrees with the repo, the
repo wins: fix the doc.

**Before you finish:** read your own diff and remove probes, debug leftovers
and machine state (dev servers, temp folders). Check the two docs triggers
(`STRATA.md` §4a): if you had to rebuild knowledge the next agent will need
(layout, how to run or verify), or changed something a doc describes, update
`strata/docs/`, extending an existing file before adding a new one. End the
iteration with the handover report: Based on / Done / **Not done** / Needs
from human (required for `-READY`, and only for what you can't do or decide
yourself) / Docs (or "none needed") / Removed-kept. Pick the suffix that says
whose move it is. In local mode, never commit anything under
`strata/context/`. In shared mode, commit the artifact with the code, with no
secrets, client data or raw logs in it.
<!-- strata:end -->
