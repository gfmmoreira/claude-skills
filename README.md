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

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/gfmmoreira/claude-skills/develop/1on1-coach/install.sh | bash
```

---

## Usage

```
/1on1-coach [person name]    # prep for an upcoming meeting
/1on1-coach capture          # log a meeting that just happened
```
