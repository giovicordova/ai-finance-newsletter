# Scheduling the AI Finance Briefing

## Overview

The briefing runs as **two** Claude Code Desktop scheduled tasks:

- **News routine** (Mon-Fri, 06:00 Europe/Rome): research, write, review, commit, and send the news post. On Fridays this also generates the weekly take into the same edition file, but holds it back for the take routine.
- **Take routine** (Friday only, 07:00 Europe/Rome): reads the already-generated edition and sends just the take post, one hour after the news.

Each execution fires a fresh session. The news routine writes `editions/YYYY-MM-DD.md` (and on Fridays also `editions/weekly/YYYY-Wnn.md`); the take routine reads that file and sends only.

## Prerequisites

- **Claude Code Desktop** installed and running (local tasks require the app to be open)
- **This project folder** as the working directory
- **Web search access** — the task performs 6-10 web searches per run
- The `editions/` and `editions/weekly/` directories must exist (already created)

## Setup — Claude Code Desktop

### Option 1: Conversational (recommended)

Open any Claude Code Desktop session with this project as the working folder and say:

> Set up two scheduled tasks: one Mon-Fri at 06:00 Europe/Rome that runs the prompt in `routines/news.md`, and one Friday-only at 07:00 Europe/Rome that runs the prompt in `routines/take.md`.

Claude will create both tasks for you.

### Option 2: Manual via sidebar

Create **two** local tasks via **Schedule → + New task → New local task**:

**Task 1: News routine**
- **Name:** AI Finance News (daily)
- **Prompt:** Paste the contents of `routines/news.md`
- **Working folder:** path to your local clone
- **Frequency:** Weekdays (Mon-Fri)
- **Time:** 06:00 Europe/Rome
- **Model:** Sonnet 4.6
- **Permission mode:** Auto-approve file writes

**Task 2: Take routine**
- **Name:** AI Finance Take (Friday)
- **Prompt:** Paste the contents of `routines/take.md`
- **Working folder:** path to your local clone
- **Frequency:** Friday only
- **Time:** 07:00 Europe/Rome
- **Model:** Sonnet 4.6
- **Permission mode:** Auto-approve file writes

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

This runs the 280-character cap and section-structure checks against the edition file.
