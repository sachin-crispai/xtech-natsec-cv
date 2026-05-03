# AI Project Snapshots

This directory stores versioned project snapshots for use with ChatGPT, Claude Desktop, Gemini, and human reviewers. Each snapshot should describe the project as it exists at a point in time, what has been decided, what remains uncertain, and what kind of response is requested from the next reviewer or AI assistant.

Use these files as requirements-and-response records in the traditional project management sense:

- Requirements: project intent, constraints, success criteria, current architecture, open questions, and requested analysis.
- Response: decisions made, recommendations received, implementation notes, risks accepted, and follow-up actions.

## Naming

Use ISO dates so snapshots sort naturally:

```text
YYYY-MM-DD-project-snapshot.md
YYYY-MM-DD-ai-review-response.md
YYYY-MM-DD-requirements-update.md
```

For major milestones, add a short suffix:

```text
2026-05-02-hackathon-baseline.md
2026-05-03-demo-readiness-review.md
2026-05-04-post-demo-roadmap.md
```

## Recommended Workflow

1. Create a dated snapshot before asking an AI system for substantial help.
2. Paste the snapshot into the AI tool with a specific request.
3. Save useful AI output as a dated response file in this directory.
4. Promote accepted recommendations into code, docs, issues, or a later requirements update.
5. Keep rejected recommendations in the response file with a short reason when they may be revisited.

## Snapshot Contents

Each snapshot should include:

- Executive summary
- Project goal and target users
- Current repo structure
- Current implementation status
- Known gaps, risks, and assumptions
- Near-term priorities
- Future roadmap
- Questions for the AI reviewer
- Response log or decision log

## Snapshot Index

| Version | Date | File | Coverage |
|---------|------|------|----------|
| v001 (unversioned) | 2026-05-02 | [2026-05-02-project-snapshot.md](2026-05-02-project-snapshot.md) | Software only: architecture, gaps, roadmap, risks |
| v002 | 2026-05-02 | [v002-2026-05-02-full-platform.md](v002-2026-05-02-full-platform.md) | **Master context** — software + GPU hardware inventory + rack configs + AI prompt library |

**Start here:** paste `v002-2026-05-02-full-platform.md` into any AI session for full project context.

## Response File Naming

When an AI session produces useful output worth preserving, save it as a dated response file:

```
YYYY-MM-DD-<topic>-response-<ai-tool>.md
```

Example: `2026-05-02-fusion-algorithm-response-chatgpt.md`

Link it in the response log table at the bottom of the originating snapshot.
