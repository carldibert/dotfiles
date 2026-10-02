#!/usr/bin/env python3
"""Row renderer for Claude Code's subagentStatusLine, styled to match claude-statusline.omp.json.

Reads {"tasks": [...]} on stdin and prints one {"id", "content"} JSON line per task.
Set CLAUDE_STATUSLINE_DEBUG=1 to save the last payload to ~/.cache/claude-statusline/.
"""
import json
import os
import sys
import time
from pathlib import Path

PALETTE = {
    "crust": "#232634", "mantle": "#292c3c", "surface0": "#414559", "surface1": "#51576d",
    "overlay": "#949cbb", "lavender": "#babbf1", "sky": "#99d1db", "teal": "#81c8be",
    "green": "#a6d189", "yellow": "#e5c890", "red": "#e78284", "pink": "#f4b8e4",
}
DIAMOND = ""
ICON_TREE, ICON_TIMER, ICON_CTX, ICON_DONE = "", "\U000f051b", "", ""


def rgb(name):
    h = PALETTE[name].lstrip("#")
    return ";".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def fg(name):
    return f"\x1b[38;2;{rgb(name)}m"


def seg(bg, color, text):
    # Same shape as the oh-my-posh diamonds: pointed left edge, notched right edge
    return (f"{fg(bg)}{DIAMOND}\x1b[0m"
            f"\x1b[48;2;{rgb(bg)}m{fg(color)} {text} \x1b[0m"
            f"\x1b[38;2;{rgb(bg)};49m\x1b[7m{DIAMOND}\x1b[0m")


def worktree_name(cwd):
    """Name of the linked git worktree containing cwd, or None for a main checkout."""
    if not cwd:
        return None
    marker = "/.claude/worktrees/"
    if marker in cwd:
        return cwd.split(marker, 1)[1].split("/", 1)[0]
    p = Path(cwd)
    for d in (p, *p.parents):
        git = d / ".git"
        if git.is_dir():
            return None
        if git.is_file():  # linked worktrees have a .git file pointing at the main repo
            return d.name
    return None


def duration(sec):
    sec = max(0, int(sec))
    h, m, s = sec // 3600, sec // 60 % 60, sec % 60
    if h:
        return f"{h}h{m:02d}m"
    return f"{m}m{s:02d}s" if m else f"{s}s"


def render(task, now):
    status = str(task.get("status") or "").lower()
    running = status in ("", "running", "in_progress", "pending")
    name = task.get("name") or task.get("label") or task.get("type") or "agent"

    dot = f"{fg('yellow')}●" if running else f"{fg('green')}{ICON_DONE}"
    out = f"{dot}\x1b[0m \x1b[1m{fg('lavender')}{name}\x1b[0m "

    wt = worktree_name(task.get("cwd"))
    if wt:
        out += seg("surface1", "pink", f"{ICON_TREE} {wt}")

    if running:
        start = task.get("startTime")
        if isinstance(start, (int, float)) and start > 0:
            start = start / 1000 if start > 1e12 else start
            out += seg("surface0", "teal", f"{ICON_TIMER} {duration(now - start)}")
        tokens, window = task.get("tokenCount"), task.get("contextWindowSize")
        if isinstance(tokens, (int, float)):
            pct = f" {round(tokens * 100 / window)}%" if window else ""
            color = "yellow" if window and tokens / window >= 0.75 else "sky"
            out += seg("mantle", color, f"{ICON_CTX} {round(tokens / 1000)}k{pct}")
    else:
        out += seg("surface0", "green", status or "done")
    return out


def main():
    raw = sys.stdin.read()
    if os.environ.get("CLAUDE_STATUSLINE_DEBUG"):
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "claude-statusline"
        cache.mkdir(parents=True, exist_ok=True)
        (cache / "subagent-input.json").write_text(raw)
    try:
        tasks = json.loads(raw).get("tasks") or []
    except ValueError:
        return
    now = time.time()
    for task in tasks:
        if "id" not in task:
            continue
        try:
            content = render(task, now)
        except Exception:
            continue  # fall back to Claude's default row
        print(json.dumps({"id": task["id"], "content": content}))


if __name__ == "__main__":
    main()
