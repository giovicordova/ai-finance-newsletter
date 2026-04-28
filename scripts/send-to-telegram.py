#!/usr/bin/env python3
"""
Send a daily AI-finance edition to a Telegram channel as two separate messages:
the news post and the take post. The "## Notes" section is archive-only and is
never sent.

Usage:
  scripts/send-to-telegram.py editions/YYYY-MM-DD.md

Reads:
  TELEGRAM_BOT_TOKEN  -- from @BotFather
  TELEGRAM_CHAT_ID    -- channel/group ID the bot was added to (admin)

Edition file contract (the skill writes this format):

  # AI Finance Briefing — DD Month YYYY

  ## Telegram — News Post

  <news post text>

  <primary source URL>

  ## Telegram — Take Post

  Claude's take: <opinion text>

  <link URL>

  ## Notes (archive only — not sent to Telegram)
  ...

The script extracts the two "Telegram — ..." sections, sends each as its own
message (URL on its own line, link previews disabled), and exits.
"""

import html
import os
import re
import subprocess
import sys
import time
from pathlib import Path


def load_dotenv():
    """Load .env from the project root into os.environ, if present."""
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key, value = key.strip(), value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


# Per-post hard cap: Telegram allows 4096, but the briefing format is 280
# chars excluding the URL. We pad generously for the URL line.
TELEGRAM_LIMIT = 4000


# Section headings the skill writes, in order. The script sends one message
# per section. Anything outside these sections is ignored.
TELEGRAM_SECTIONS = [
    ("News Post", "## Telegram — News Post"),
    ("Take Post", "## Telegram — Take Post"),
]


def extract_section(md: str, heading: str) -> str | None:
    """
    Return the body of the section starting at `heading`, stopping at the next
    "## " heading or end of file. Returns None if the heading isn't found.
    Heading match is exact on the line (after stripping).
    """
    lines = md.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.strip() == heading:
            start = i + 1
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    body = "\n".join(lines[start:end]).strip()
    return body or None


def md_to_html(md: str) -> str:
    """Convert a small subset of markdown to Telegram-flavoured HTML."""
    text = md.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    # Links: [label](url) -> <a href="url">label</a>
    text = re.sub(
        r"\[([^\]]+)\]\(([^)]+)\)",
        lambda m: f'<a href="{html.escape(m.group(2), quote=True)}">{m.group(1)}</a>',
        text,
    )

    # Bold: **text** -> <b>text</b>
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)

    # Italic: *text* -> <i>text</i>  (avoid ** remnants)
    text = re.sub(r"(?<!\*)\*([^*\n]+)\*(?!\*)", r"<i>\1</i>", text)

    # Collapse 3+ blank lines
    text = re.sub(r"\n{3,}", "\n\n", text)

    return text.strip()


def send(token: str, chat_id: str, text: str, disable_preview: bool = True):
    """POST via curl — uses the macOS system trust store, avoiding Python SSL
    issues that can occur behind corporate proxies."""
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    result = subprocess.run(
        [
            "curl", "-sS", "--fail-with-body", "--max-time", "30",
            "-X", "POST", url,
            "--data-urlencode", f"chat_id={chat_id}",
            "--data-urlencode", f"text={text}",
            "--data-urlencode", "parse_mode=HTML",
            "--data-urlencode",
            f"disable_web_page_preview={'true' if disable_preview else 'false'}",
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Telegram API error: {result.stdout or result.stderr}")
    return result.stdout


def main():
    if len(sys.argv) != 2:
        print("usage: send-to-telegram.py <edition.md>", file=sys.stderr)
        sys.exit(2)

    path = sys.argv[1]
    load_dotenv()
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")
    if not token or not chat_id:
        print(
            "error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set",
            file=sys.stderr,
        )
        sys.exit(1)

    with open(path, "r", encoding="utf-8") as f:
        md = f.read()

    sections = []
    for label, heading in TELEGRAM_SECTIONS:
        body = extract_section(md, heading)
        if body is None:
            print(
                f"error: missing required section '{heading}' in {path}",
                file=sys.stderr,
            )
            sys.exit(3)
        if len(body) > TELEGRAM_LIMIT:
            print(
                f"error: {label} section exceeds {TELEGRAM_LIMIT} chars after parsing",
                file=sys.stderr,
            )
            sys.exit(4)
        sections.append((label, body))

    for i, (label, body) in enumerate(sections, 1):
        if i > 1:
            # Tiny pause to keep ordering sane in the channel and stay under
            # Telegram's per-chat rate limit.
            time.sleep(0.5)
        send(token, chat_id, md_to_html(body))
        print(f"sent {label} ({len(body)} chars)")


if __name__ == "__main__":
    main()
