"""Verify every relative link and image in the lab docs resolves on disk."""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAT = re.compile(r'!?\[[^\]]*\]\(([^)\s]+)\)')
bad = ok = 0
for dirpath, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if not d.startswith(".venv") and d != ".git"]
    for f in sorted(files):
        if not f.endswith(".md"):
            continue
        p = os.path.join(dirpath, f)
        rel = os.path.relpath(p, ROOT)
        for m in PAT.finditer(open(p, encoding="utf-8").read()):
            t = m.group(1)
            if t.startswith(("http://", "https://", "#", "mailto:")):
                continue
            target = os.path.normpath(os.path.join(dirpath, t.split("#")[0]))
            if os.path.exists(target):
                ok += 1
            else:
                bad += 1
                print(f"  BROKEN  {rel}\n          -> {t}")
print(f"\n  {ok} resolved, {bad} broken")
sys.exit(1 if bad else 0)
