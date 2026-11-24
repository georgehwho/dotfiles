---
name: pstack-herdr
description: "herdr flavor for pstack: run pstack's parallel workers (swarm workers, arena arms, review panels) as visible herdr panes instead of hidden subagents, mixing Claude Code panes with opencode panes on other model families. Use when a pstack skill fans out work AND this session runs inside herdr (HERDR_ENV=1), or when the user asks for herdr panes, /pstack-herdr, or a cross-model review."
---

# pstack, herdr flavor

pstack skills say "spawn N subagents" (`Task`/`Agent`). Inside herdr, do that
fan-out as herdr panes so the user can watch, steer, or take over any worker.
Everything else in the pstack skill (framing, briefs, aggregation, the report)
stays exactly as the skill says.

## Gate

Run `test "${HERDR_ENV:-}" = 1`. If it fails, you are not inside herdr: say so
in one line and fall back to pstack's normal `Agent` subagents. Never drive a
herdr session from outside it.

Learn the CLI from the binary (`herdr agent`, `herdr pane`), not from memory.
Control commands return JSON. Read IDs from responses.

## Route each worker

| pstack role | herdr worker |
| --- | --- |
| Writes code (swarm slice, race arm, `/correct` fix) | Claude Code pane: `hop -k claude -n <name> -C <worktree>` |
| Review panel entry, `/arena` arm, second opinion | opencode pane on another model family: `hop -n <name> -m deepseek -C <dir>` |
| Out of Claude tokens, or the user says "local" | `-m local` on either kind (Ollama `gpt-oss-64k`, free and offline) |

Keep **at least one non-Claude reviewer** in every review panel. Disagreement
across model families is the point of the panel.

**Local model limit:** this laptop (24 GB) runs ONE `-m local` worker at a time.
Route every other non-Claude worker to `-m deepseek`. Before starting a local
worker, check `herdr agent list` for one already running and reuse it.

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
2. Start every pane first (`hop ...` without `-p`), so they boot in parallel.
3. Each brief stands alone (pstack's rules) and ends with: "Write your final
   report to `$RUN/<name>.md`. Its last line is `PASS`, `ISSUES`, or `BLOCKED`."
4. Send all prompts in parallel and wait for all of them:
   ```bash
   for n in a b c; do herdr agent prompt "$n" "$(cat "$RUN/$n.brief")" --wait --timeout 1800000 & done; wait
   ```
5. Read `$RUN/<name>.md`. A report file is the result. Terminal output is
   not. If a file is missing, read the pane once
   (`herdr agent read <name> --source recent --lines 200`) and record a gap if
   it holds no report. Respawn once, as pstack's swarm says.
6. A worker in `blocked` is waiting on an approval or question. Show the user
   `herdr agent read <name>` and ask them. Never answer a worker's approval
   prompt yourself.

## Layout and cleanup

- At most 4 worker panes per tab. Beyond that, `herdr tab create` and split there.
- Name panes after their role: `arm-a`, `review-deepseek`, `fix-auth`.
- When the report is done, close worker panes (`herdr pane close <pane>`).
  Keep worktrees whose branches still need merging, and list them in the report.
