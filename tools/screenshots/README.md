# Terminal screenshot capture

`shot1.sh "<command>" <out.png> [timeout_s] [workdir]` — one screenshot, one
throwaway Terminal window.

## Why it is built this way

Three approaches were tried and discarded, each for a concrete reason:

1. **Reuse one window and `clear` between shots.** Terminal repaints scrollback
   asynchronously, so captures landed on the *previous* command's output with a
   stray `$ clear` at the bottom.
2. **Wait on screen stability.** Useless here: during a model call nothing
   changes on screen for ten seconds while the shell is very much busy.
3. **Wait on a shared `precmd` counter.** A shared flag file is bumped by every
   window that has the hook sourced, so "the counter moved" stopped meaning
   "my command finished".

What works: a **fresh window per capture** (nothing stale to race with) plus a
**private completion flag** written by that window's own `precmd` hook.

## The bug that masqueraded as a race

Captures kept coming out truncated, which looked like a timing problem. It was
not. The flag file records `<counter> <exit-code>`, and it read `2 1` one second
after launch — the command was **failing instantly with exit code 1**, because a
fresh window does not inherit `DATABRICKS_PROFILE` or `LAB_WAREHOUSE_ID`.

Hours went into timing theories that the exit code in the flag file would have
disproved immediately. If a capture looks premature, read the exit code first.

`labenv.sh` is sourced into every capture window for exactly this reason.

## Safety

`shot.sh` resolves the target window fresh on every call, requires the owning
application to be `Terminal` with a matching pid and geometry, requires exactly
one match, re-verifies ownership after the capture, and checks the PNG
dimensions against the window bounds. It deletes the file and fails on any
mismatch, and only ever captures a single window id — never the screen.
