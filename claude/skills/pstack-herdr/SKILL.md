---
name: pstack-herdr
description: "herdr flavor for pstack: run pstack's parallel workers (swarm workers, arena arms, review panels) as visible herdr terminals instead of hidden subagents, mixing Claude Code with opencode on other model families. Use when a pstack skill fans out work AND this session runs inside herdr (the Herdr app: HC_TERMINAL_ID set; or the herdr TUI: HERDR_ENV=1), or when the user asks for herdr workers, /pstack-herdr, or a cross-model review."
---

# pstack, herdr flavor

pstack skills say "spawn N subagents" (`Task`/`Agent`). Inside herdr, do that
fan-out as herdr terminals so the user can watch, steer, or take over any
worker. Everything else in the pstack skill (framing, briefs, aggregation, the
report) stays exactly as the skill says.

## Gate: which herdr

- `HC_TERMINAL_ID` is set: the **Herdr app** (herdr-core). Use `hc`. This is the default setup.
- `HERDR_ENV=1`: the **herdr TUI**. Use `herdr`.
- Neither: not inside herdr. Say so in one line and fall back to pstack's
  normal `Agent` subagents. Never drive a herdr session from outside it.

Learn the CLI from the binary (`hc --help`, `hc <cmd> --help`; or `herdr agent`,
`herdr pane`), not from memory.

## Route each worker

Start every worker with `hop` (on PATH). It works on both backends:

| pstack role | Worker |
| --- | --- |
| Writes code (swarm slice, race arm, `/correct` fix) | `hop -k claude -n <name> -C <worktree>` |
| Review panel entry, `/arena` arm, second opinion | `hop -n <name> -m deepseek -C <dir>` (opencode, a different model family) |
| Out of Claude tokens, or the user says "local" | add `-m local` (Ollama `gpt-oss-64k`, free and offline) |

Keep **at least one non-Claude reviewer** in every review panel. Disagreement
across model families is the point of the panel.

**Local model limit:** this laptop (24 GB) runs ONE `-m local` worker at a time.
Route every other non-Claude worker to `-m deepseek`. Before starting a local
worker, check the live terminals (`hc ls` or `herdr agent list`) and reuse an
existing local worker if there is one.

## Isolate writers

Each worker that edits files gets its own git worktree on its own branch,
created from the exact SHA the brief names:

```bash
git worktree add "../$(basename "$PWD")-<name>" -b "herdr/<name>" <sha>
```

Read-only reviewers share the main checkout. Their brief says "do not edit
files", and you check `git status` after they finish.

## Dispatch and collect

1. Make a run directory: `RUN=$(mktemp -d -t pstack-herdr)`.
2. Start every worker first (`hop ...` without `-p`), so they boot in parallel.
   Wait for each to be idle before prompting:
   `hc get <name> --json | jq -r .status.state` (app) or `herdr agent wait <name>` (TUI).
3. Each brief stands alone (pstack's rules) and ends with: "Write your final
   report to `$RUN/<name>.md`. Its last line is `PASS`, `ISSUES`, or `BLOCKED`."
4. Send every brief, then wait for all of them:
   - App: `hc send <name> "$(cat "$RUN/<name>.brief")"` for each, then
     `hc wait --children all --timeout 1800`. Workers started by `hop` from this
     terminal are its children. If the wait checks in before they finish, wait again.
   - TUI: `herdr agent prompt <name> "<brief>" --wait --timeout 1800000 &` for each, then `wait`.
5. Read `$RUN/<name>.md`. A report file is the result. Terminal output is
   not. If a file is missing, read the terminal once (`hc read <name> --lines 200`
   or `herdr agent read <name> --source recent --lines 200`) and record a gap if
   it holds no report. Respawn once, as pstack's swarm says.
6. A blocked worker is waiting on an approval or question. Show the user its
   screen (`hc read` / `herdr agent read`) and ask them. Never answer a worker's
   approval prompt yourself, and never use `hc send --force`.

## Cleanup

- Name workers after their role: `arm-a`, `review-deepseek`, `fix-auth`.
- When the report is done, end the workers: `hc kill <name> && hc rm <name>`
  (app) or `herdr pane close <pane>` (TUI). Keep worktrees whose branches still
  need merging, and list them in the report.
