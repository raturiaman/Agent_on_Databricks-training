#!/bin/bash
# shot1.sh "<shell command>" <output.png> [timeout_s] [workdir]
#
# One screenshot, one throwaway Terminal window, one private completion flag.
#
# Why a fresh window: reusing one means fighting `clear`, whose scrollback
# repaint is asynchronous, so captures land on the previous command's output.
# Why a private flag: a shared flag file is bumped by every window that has the
# hook sourced, so "the counter moved" stops meaning "my command finished".
set -uo pipefail
SP=/private/tmp/advk8s-shots
CMD="$1"; OUT="$2"; TMO="${3:-300}"
WORKDIR="${4:-/Users/hadez/Documents/Company/training content/Agent_on_Databricks}"

TAG="$$_$RANDOM"
FLAG="$SP/flag.$TAG"
HOOK="$SP/hook.$TAG.zsh"
rm -f "$FLAG"
cat > "$HOOK" <<EOF
__n=0
precmd() {
  local rc=\$?
  __n=\$((__n+1))
  print -r -- "\$__n \$rc" > $FLAG
}
EOF

esc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
ctr(){ cut -d' ' -f1 "$FLAG" 2>/dev/null || echo 0; }

WID=$(/usr/bin/osascript <<AS
tell application "Terminal"
  activate
  set w to do script "cd \"$(esc "$WORKDIR")\"; source $HOOK; source $SP/labenv.sh; export PS1='$ '; clear"
  set bounds of front window to {60, 80, 1160, 700}
  return id of front window
end tell
AS
)
[ -n "$WID" ] || { echo "could not open capture window" >&2; exit 1; }

cleanup(){
  /usr/bin/osascript -e "tell application \"Terminal\" to close window id $WID" >/dev/null 2>&1
  rm -f "$FLAG" "$HOOK"
}
trap cleanup EXIT

# wait for the setup line to finish: its own precmd writes the first value
for _ in $(seq 1 60); do
  [ -s "$FLAG" ] && break
  sleep 0.5
done
sleep 0.6
BEFORE=$(ctr)

/usr/bin/osascript -e "tell application \"Terminal\" to do script \"$(esc "$CMD")\" in window id $WID" \
  >/dev/null 2>&1 || { echo "send failed" >&2; exit 1; }

DONE=0
for _ in $(seq 1 $((TMO*2))); do
  sleep 0.5
  if [ "$(ctr)" -gt "$BEFORE" ] 2>/dev/null; then DONE=1; break; fi
done
[ "$DONE" = "1" ] || echo "  (warning: timed out after ${TMO}s, capturing anyway)" >&2
sleep 1.2

/usr/bin/osascript -e 'tell application "Terminal" to activate' >/dev/null 2>&1
sleep 0.8
PID=$("$SP/winlist" | awk -F'\t' -v w="$WID" '$1==w {print $3; exit}')
[ -n "$PID" ] || { echo "window $WID not on screen" >&2; exit 1; }
TERM_PID="$PID" TERM_GEOM=1100,620 "$SP/shot.sh" "$SP/shot.tmp.png" || exit 1
"$SP/trim" "$SP/shot.tmp.png" "$OUT" 30
rm -f "$SP/shot.tmp.png"
