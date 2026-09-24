"""Run with python3: verify Glow centering and TUI loading in an isolated tmux."""
import re
import shlex
import subprocess
import tempfile
import time
from pathlib import Path

home = Path.home()
pattern = r"(?ms)^glow\(\) \{\n.*?^\}"
wrapper = re.search(pattern, (home / ".zshrc").read_text()).group()
mirror = Path(__file__).resolve().parents[2] / "osx/zsh/.zshrc"
assert wrapper == re.search(pattern, mirror.read_text()).group(), "Wrappers differ"
for path in (home / ".zshrc", mirror):
    subprocess.run(["zsh", "-n", str(path)], check=True)

with tempfile.TemporaryDirectory(prefix="glow-check-") as directory:
    root = Path(directory)
    (root / "check.md").write_text("CENTERING CHECK\n\n" + "word " * 70 + "\n")
    tmux = ["tmux", "-S", str(root / "socket"), "-f", "/dev/null"]
    # Test browser + inline modes. Native Glow 2.1.2's --tui FILE has an
    # unrelated initial-width bug (also reproducible without this wrapper).
    cases = [(width, args) for width in (60, 100, 182, 183)
             for args in ("check.md", "")]
    cases += [(182, ".")]
    try:
        for width, args in cases:
            shell = f"{wrapper}\nCOLUMNS={width}\nglow {args}; sleep 10"
            subprocess.run(tmux + ["new-session", "-d", "-s", "check", "-x", str(width),
                                   "-y", "24", "-c", directory,
                                   "zsh -f -c " + shlex.quote(shell)], check=True)
            deadline = time.monotonic() + 6
            opened = False
            while time.monotonic() < deadline:
                screen = subprocess.check_output(tmux + ["capture-pane", "-pt", "check"], text=True)
                if "CENTERING CHECK" in screen:
                    # Let Glow's initial terminal-size event finish reflowing.
                    time.sleep(0.3)
                    screen = subprocess.check_output(tmux + ["capture-pane", "-pt", "check"], text=True)
                    break
                if args in ("", ".") and "check.md" in screen and not opened:
                    subprocess.run(tmux + ["send-keys", "-t", "check", "Enter"], check=True)
                    opened = True
                time.sleep(0.1)
            else:
                raise AssertionError(f"Glow did not load: {width=} {args=}\n{screen}")
            margin = (width - 92 + 1) // 2 if width > 100 else 4
            title = next(line for line in screen.splitlines() if "CENTERING CHECK" in line)
            assert title.index("CENTERING CHECK") == margin, (width, args, repr(title))
            body = [line for line in screen.splitlines() if "word word" in line]
            assert body and all(line.index("word") == margin for line in body)
            assert max(len(line.rstrip()) for line in body) <= width - margin, (width, args, body)
            print(f"PASS {width} columns, glow {args or '(browser)'}: margin {margin}, document loaded")
            subprocess.run(tmux + ["kill-session", "-t", "check"], check=True)
    finally:
        subprocess.run(tmux + ["kill-server"], capture_output=True)
