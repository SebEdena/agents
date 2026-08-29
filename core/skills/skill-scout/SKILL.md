---
name: skill-scout
description: Scan past conversations across all projects for repeated manual workflows that don't yet have a skill, and report candidates with evidence.
disable-model-invocation: true
---

Skills only get written when someone notices the repetition. This skill is that noticing, done deliberately: it reads back through past conversations across every project and surfaces workflows that keep recurring by hand, with no skill covering them yet.

## Steps

1. **Inventory existing skills.** Read the frontmatter (`name` + `description`) of every `~/.claude/skills/*/SKILL.md`. Done when you have the full current list — nothing proposed later may duplicate one of these.

2. **Scan cheaply first.** Read `~/.claude/history.jsonl` and cluster its prompts by similarity of task shape, not exact wording — the same underlying ask shows up phrased differently across sessions. For each cluster, note its occurrence count and the distinct `project`/`sessionId` values it spans. Discard any cluster confined to a single session: recurrence requires at least two distinct sessions, ideally spanning more than one project. Done when every surviving cluster has its span recorded.

3. **Confirm against transcripts.** For each surviving cluster, open 2–3 of its underlying session transcripts at `~/.claude/projects/<project>/<sessionId>.jsonl` and read enough surrounding turns to confirm it's a genuine repeated *manual* multi-step pattern — not coincidental wording, and not something a skill already handled mid-conversation. Delegate this reading to one fork or subagent per cluster, so the raw transcript content never piles up in your own context — only the confirmed finding comes back. A candidate is confirmed only once you can cite a session id, a timestamp, and a short excerpt of the manual work actually done.

4. **Dedupe.** Drop any confirmed candidate that matches an entry from step 1's inventory. Done when every remaining candidate is checked against that list, not just eyeballed.

5. **Report.** For each surviving candidate, give: a short name for the pattern, a proposed skill name and one-line description, the recurrence count, and the evidence (session references plus excerpt) from step 3. This is a report, not an action — write no files, open no tickets, draft no SKILL.md. If nothing survives steps 2–4, say so plainly; "no strong candidates found" is a legitimate result, not a failure to try harder.

## Notes

- This only reads local transcript files already on disk. Nothing is sent anywhere — the report lives in this conversation.
- A pattern needs two independent sessions minimum to count; one memorable session is an anecdote, not a desire path.
