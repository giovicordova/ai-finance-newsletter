#!/usr/bin/env python3
"""
Send a markdown edition file to a Telegram channel/group.

Usage:
  scripts/send-to-telegram.py editions/YYYY-MM-DD.md

Reads:
  TELEGRAM_BOT_TOKEN  -- from @BotFather
  TELEGRAM_CHAT_ID    -- channel/group ID the bot was added to (admin)

Converts markdown to Telegram HTML, chunks on paragraph boundaries
to respect the 4096-char message limit, and posts each chunk.
"""

import html
import os
import re
import subprocess
import sys
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

TELEGRAM_LIMIT = 4000  # 4096 hard cap, leave headroom


def md_to_html(md: str) -> str:
    # Escape HTML special chars first
    text = md.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    # Links: [label](url) -> <a href="url">label</a>
    text = re.sub(
        r"\[([^\]]+)\]\(([^)]+)\)",
        lambda m: f'<a href="{html.escape(m.group(2), quote=True)}">{m.group(1)}</a>',
        text,
    )

    # Bold: **text** -> <b>text</b>
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)

    # Italic: *text* -> <i>text</i>  (avoid matching ** remnants)
    text = re.sub(r"(?<!\*)\*([^*\n]+)\*(?!\*)", r"<i>\1</i>", text)

    # Headings: # Foo / ## Foo / ### Foo -> bold line
    text = re.sub(r"^#{1,6}\s+(.+)$", r"<b>\1</b>", text, flags=re.MULTILINE)

    # Horizontal rules -> thin separator
    text = re.sub(r"^\s*---+\s*$", "—", text, flags=re.MULTILINE)

    # Collapse 3+ blank lines
    text = re.sub(r"\n{3,}", "\n\n", text)

    return text.strip()


def chunk(text: str, limit: int = TELEGRAM_LIMIT):
    if len(text) <= limit:
        return [text]
    parts, buf = [], ""
    for para in text.split("\n\n"):
        candidate = f"{buf}\n\n{para}" if buf else para
        if len(candidate) <= limit:
            buf = candidate
            continue
        if buf:
            parts.append(buf)
        if len(para) <= limit:
            buf = para
        else:
            # paragraph itself too long: hard-split on lines
            while len(para) > limit:
                cut = para.rfind("\n", 0, limit)
                cut = cut if cut > 0 else limit
                parts.append(para[:cut])
                para = para[cut:].lstrip("\n")
            buf = para
    if buf:
        parts.append(buf)
    return parts


def send(token: str, chat_id: str, text: str, disable_preview: bool = True):
    """POST via curl — uses the macOS system trust store, avoiding Python SSL issues
    that can occur behind corporate proxies."""
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
        print("error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set", file=sys.stderr)
        sys.exit(1)

    with open(path, "r", encoding="utf-8") as f:
        md = f.read()

    parts = chunk(md_to_html(md))
    for i, part in enumerate(parts, 1):
        send(token, chat_id, part)
        print(f"sent chunk {i}/{len(parts)} ({len(part)} chars)")


if __name__ == "__main__":
    main()
