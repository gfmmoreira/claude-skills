# claude-skills

A collection of Claude Code skills.

---

## Skills

### [1on1-coach](1on1-coach/)

Coaches you through workplace 1-on-1s. Not a note-taker, it pushes back.

**Pre-meeting:** You brain-dump what's on your mind. The skill separates what actually happened from the story you're telling yourself, challenges your framing, and builds a structured agenda calibrated to who you're meeting, manager, direct report, peer, skip-level, or stakeholder.

**Post-meeting:** Paste in raw notes. It extracts what was discussed, decided, and committed to, flags what wasn't said, and saves everything per person so it loads automatically in the next prep session.

See [example outputs](1on1-coach/examples.md).

---

### [skill-evolver](skill-evolver/)

Finds where Claude keeps failing you and proposes fixes.

It reads your past Claude Code sessions, spots the moments where you corrected or pushed back, and turns the recurring patterns into concrete rule changes — with the actual quotes as evidence. You decide what to apply. Nothing changes automatically.

The loop: frustration → evidence → proposed fix → you decide.

---

## Installation

```bash
# 1on1-coach
curl -fsSL https://raw.githubusercontent.com/gfmmoreira/claude-skills/develop/1on1-coach/install.sh | bash

# skill-evolver
curl -fsSL https://raw.githubusercontent.com/gfmmoreira/claude-skills/develop/skill-evolver/install.sh | bash
```

---

## Usage

```
/1on1-coach [person name]    # prep for an upcoming meeting
/1on1-coach capture          # log a meeting that just happened

/skill-evolver               # scan last 30 days
/skill-evolver 90            # scan last 90 days
```
