#!/bin/bash
# Guarded window capture. Refuses to save anything that is not the Terminal
# window belonging to $TERM_PID. Never captures the screen or a region.
set -uo pipefail
SP=/private/tmp/advk8s-shots
OUT="$1"
: "${TERM_PID:?TERM_PID must be set to the target Terminal process id}"
TERM_GEOM="${TERM_GEOM:-}"

die(){ echo "REFUSED: $*" >&2; rm -f "$OUT" "$SP/raw.png"; exit 1; }

# --- resolve the target window fresh, every time -------------------------
# TERM_GEOM="w,h" narrows to our own window when other Terminal windows are open
GW=${TERM_GEOM%%,*}; GH=${TERM_GEOM##*,}
sel(){ "$SP/winlist" | awk -F'\t' -v p="$TERM_PID" -v gw="${GW:-0}" -v gh="${GH:-0}" \
  '$2=="Terminal" && $3==p && $4==0 && $7>200 && $8>150 && (gw==0 || ($7==gw && $8==gh))'; }
row=$(sel | head -1)
[ -n "$row" ] || die "no on-screen Terminal window for pid $TERM_PID geom ${TERM_GEOM:-any}"
n=$(sel | wc -l | tr -d ' ')
[ "$n" = "1" ] || die "$n candidate Terminal windows match pid $TERM_PID geom ${TERM_GEOM:-any}; expected exactly 1"

WID=$(echo "$row" | cut -f1); OWNER=$(echo "$row" | cut -f2)
WW=$(echo "$row" | cut -f7);  WH=$(echo "$row" | cut -f8)
[ "$OWNER" = "Terminal" ] || die "owner is '$OWNER', not Terminal"

# --- capture that window id only ----------------------------------------
rm -f "$SP/raw.png"
screencapture -o -x -l"$WID" "$SP/raw.png" 2>/dev/null
[ -s "$SP/raw.png" ] || die "screencapture produced nothing for wid $WID"

# --- re-verify the id STILL belongs to the same Terminal window ----------
after=$("$SP/winlist" | awk -F'\t' -v w="$WID" '$1==w {print $2"\t"$3}')
[ "$after" = "Terminal	$TERM_PID" ] || die "wid $WID now belongs to '${after:-gone}' — window changed mid-capture"

# --- verify the pixels match that window's geometry ----------------------
read -r PW PH < <(python3 - "$SP/raw.png" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read(33)
w,h=struct.unpack('>II', d[16:24]); print(w,h)
PY
)
for s in 1 2 3; do
  if [ "$PW" = "$((WW*s))" ] && [ "$PH" = "$((WH*s))" ]; then MATCH=$s; break; fi
done
[ -n "${MATCH:-}" ] || die "captured ${PW}x${PH} does not match window ${WW}x${WH} at any backing scale"

mkdir -p "$(dirname "$OUT")"
mv "$SP/raw.png" "$OUT"
echo "ok  $(basename "$OUT")  ${PW}x${PH} (wid=$WID Terminal pid=$TERM_PID scale=${MATCH}x)"
