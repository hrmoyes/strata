# `strata/docs/`: the one-page map

Short files on what lives where and how to work with it. Keep each one under
about 50 lines, because nobody opens a long file twice. These describe the
**present** state and are updated as the code changes, unlike the log under
`strata/context/artifacts/`.

A doc is written or changed only when an agent had to rebuild knowledge the
next agent will need (layout, how to run or verify, tool quirks), or changed
something a doc describes. Extend an existing file before adding a new one,
delete what is no longer true, and say how each entry was confirmed (the
command, the observation, the date). If a doc here disagrees with the repo,
the repo wins: fix the doc. Rules: `STRATA.md` §4a.

Entries a human developer would also need carry `[for-humans]` in their
heading until a developer has reviewed them. Find them with
`grep -rn "\[for-humans\]" strata/docs`.

| file | about | when to read |
|---|---|---|
| _(add a row per doc)_ | | |
