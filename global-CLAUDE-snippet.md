<!--
Optional. Paste the section below into your user-level ~/.claude/CLAUDE.md
(on Windows: %USERPROFILE%\.claude\CLAUDE.md). Claude Code loads that file
in every session, in every project, so agents will:
  - follow STRATA.md in any repo that already has it, and
  - offer to install Strata in repos that don't.
Replace <path-to-strata> with wherever you keep the Strata folder.
-->

## Strata agent workflow

- If the project root has a `STRATA.md`, follow it from the start of the
  session: read it, list `strata/context/artifacts/`, and record work as
  iterations, as it describes.
- If a project has no `STRATA.md` and the task is more than a quick question
  or one-line edit, ask once whether to install Strata from
  `<path-to-strata>` (see its `README.md`). If the answer is no, don't ask
  again in that project.
