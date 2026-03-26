# Scheduling the AI Finance Briefing

## Overview

The briefing runs as a Claude Code Desktop scheduled task. Each execution fires a fresh session that researches, curates, and writes the day's edition — saving it to `editions/YYYY-MM-DD.md`.

## Prerequisites

- **Claude Code Desktop** installed and running (local tasks require the app to be open)
- **This project folder** as the working directory
- **Web search access** — the task performs 6-10 web searches per run
- The `editions/` and `editions/weekly/` directories must exist (already created)

## Setup — Claude Code Desktop

### Option 1: Conversational (recommended)

Open any Claude Code Desktop session with this project as the working folder and say:

> Set up a scheduled task that runs the ai-finance-briefing skill every weekday at 6:30 AM EST.

Claude will create the task for you.

### Option 2: Manual via sidebar

1. Click **Schedule** in the Desktop sidebar
2. Click **+ New task** → **New local task**
3. Fill in:
   - **Name:** AI Finance Daily Briefing
   - **Prompt:** `Use the ai-finance-briefing skill to generate today's briefing.`
   - **Working folder:** `/Users/giovannicordova/Documents/02_projects/ai-finance-newsletter`
   - **Frequency:** Weekdays
   - **Time:** 6:30 AM (set your system timezone to EST, or adjust for your timezone)
   - **Model:** Sonnet 4.6 (recommended — good balance of quality and speed)
   - **Permission mode:** Auto-approve file writes (the task only writes to `editions/`)
4. Click **Save**

### Option 3: Cloud task (runs without your machine)

1. Click **Schedule** → **+ New task** → **New remote task**
2. Connect your repository
3. Same prompt and cadence as above
4. Cloud tasks run against a fresh clone — they'll create editions in the repo and can commit them

## How It Works

When the task fires:
1. A fresh Claude session starts with this project as working directory
2. Claude loads the `ai-finance-briefing` skill
3. Runs 6-10 web searches across AI-finance categories
4. Curates the top stories, writes the briefing
5. Saves to `editions/YYYY-MM-DD.md`
6. On Fridays, also saves to `editions/weekly/YYYY-Wnn.md`
7. Session ends

Each run takes approximately 2-5 minutes depending on web search latency.

## Important Notes

- **Local tasks require the Desktop app to be running** and your computer awake at the scheduled time. If it misses, the task does not catch up.
- **Each run is independent** — no state carries between runs. The editions/ archive provides continuity via trajectory analysis.
- **The task stagger** — Desktop adds a deterministic delay of up to 10 minutes after the scheduled time to avoid API traffic spikes.
- **Review runs** — Open the session from the "Scheduled" section in the sidebar to see what Claude did, review the output, or check for issues.

## Manual Run

To run the briefing on demand, invoke the skill in any Claude session:

> Use the ai-finance-briefing skill to generate today's briefing.

Or simply ask Claude to "write today's AI finance briefing" — the skill triggers on that intent.

## Quality Verification

After any run, check the output:

```bash
scripts/review-edition.sh editions/YYYY-MM-DD.md
```

This runs 16-17 structural quality checks (section presence, format, word count, voice anti-patterns, anti-features).
