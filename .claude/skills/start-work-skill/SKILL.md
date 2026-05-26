---
name: start-work-skill
description: Begin implementation work on a JIRA ticket or GitHub issue with a structured, execution-ready plan. Use this whenever the user says they want to "start work on", "kick off", "begin", "pick up", or "plan" a ticket, story, issue, or task — even when they just paste a ticket key (like DEV-12345) or an issue URL with no other instruction. Fetches the story via the appropriate tool, persists context to investigation-artifacts/, and produces a story summary, scope, risks, implementation plan, prioritized TODO list, and Definition of Done. Stops before coding so the user can review the plan.
metadata:
  type: skill
---

# Start work on a story

This skill plans implementation work on a single ticket or issue. The work is split into three phases: **identify the source**, **fetch and persist context**, and **produce the plan**. After the plan is delivered the skill halts and asks whether to proceed to coding — it never starts implementation on its own.

The reason this matters is that real engineering work routinely fails before code is written: misread acceptance criteria, missed linked PRs, assumptions silently baked in. A short, disciplined kickoff catches those problems while they're cheap to fix, and the persisted artifacts mean the work can be resumed days later without re-reading the ticket from scratch.

## Inputs the user might give you

The user typically gives one of:

- A JIRA key like `DEV-12345` or `ABC-789`
- A JIRA URL like `https://rover.atlassian.net/browse/DEV-12345`
- A GitHub issue reference like `owner/repo#1234` or `#1234` (if in a repo)
- A GitHub URL like `https://github.com/rover/web/issues/1234`
- Optionally, a branch name and constraints (runtime, testing, deployment)

If a `branch_name` is provided, carry it through the workflow: include it in **Story Metadata** and explicitly state whether implementation should continue on that branch or whether a new branch is required.

If the input is ambiguous (just a number, just a word), ask which system it lives in before guessing.

## Phase 1 — Identify the source

Detect the source by pattern:

| Pattern                                  | Source | Tool to use                           |
|------------------------------------------|--------|---------------------------------------|
| `[A-Z]+-[0-9]+`                          | JIRA   | `acli` (via `atlassian-cli` skill)    |
| `atlassian.net/browse/...` URL           | JIRA   | `acli`                                |
| `owner/repo#N` or `#N` in a git repo     | GitHub | `gh` (via `github-cli` skill)         |
| `github.com/.../issues/N` URL            | GitHub | `gh`                                  |

When the source is JIRA, load the `atlassian-cli` skill before running any `acli` command. When the source is GitHub, load the `github-cli` skill before running any `gh` command. These skills know the authentication flow, command syntax, and JSON field names; reaching for the raw CLI without them is how field-name and escaping errors creep in.

## Phase 2 — Fetch and persist context

### 2a. Fetch the story

For JIRA, fetch: summary, description, acceptance criteria (often in a custom field or in the description), status, priority, labels, components, fix version, assignee, reporter, linked issues, and the latest 10 comments.

For GitHub, fetch: title, body, labels, milestone, assignees, linked PRs/issues (closes/blocks/related), and the latest 10 comments.

### 2b. Halt on auth failure

If the fetch fails because `acli` or `gh` is not authenticated, or because the user lacks access, **stop immediately**. Tell the user exactly what failed and the command they need to run to authenticate (e.g. `acli jira auth login --site rover`, `gh auth login`). Do not fabricate a plan from partial info — a wrong plan is worse than no plan.

If the fetch fails for a different reason (network, malformed key, ticket genuinely doesn't exist), say so clearly and ask the user how to proceed.

### 2c. Persist artifacts

Derive a `<story-slug>` from the story title: lowercase, kebab-case, alphanumerics and dashes only, max ~60 chars. Prefix with the ticket key when available so the folder sorts naturally (e.g. `DEV-12345-improve-search-ranking`, `gh-1234-fix-checkout-redirect`).

Create the folder at the **repo root**: `investigation-artifacts/<story-slug>/`. Use `git rev-parse --show-toplevel` to find the repo root; do not put it under the current working directory if you're in a subfolder.

Ensure `investigation-artifacts/` is in `.gitignore` at the repo root. If `.gitignore` doesn't have it, append it. If there's no `.gitignore` at all, create one with just that line. This keeps notes local to each engineer.

If the folder already exists, **update** files in place rather than duplicating. Diff before overwriting so old notes aren't silently lost — append a `## Updated YYYY-MM-DD` section if the content has materially changed.

Write these files:

- `story-metadata.md` — title, link, key/issue number, status, priority, labels, milestone/fix version, assignees
- `story-body.md` — full description and acceptance criteria, verbatim
- `linked-items.md` — linked PRs/issues with their status and a one-line summary; "none" if there are none
- `comments-latest.md` — include the latest 10 comments, marking each as **relevant** or **not relevant** to implementation. Always include any comment that changes scope, acceptance criteria, dependencies, decisions, or blockers. Routine bot noise can be marked not relevant.
- `assumptions.md` — explicit list of assumptions you're making and questions the ticket doesn't answer

The point of these files is resumability: in two weeks when the user comes back, they should be able to reconstruct the context without re-opening the ticket.

## Phase 3 — Produce the plan

Output, in this exact order, in the conversation:

### 1. Story Metadata

A short header block: key/number, title, link, status, priority, assignee, branch (if provided). One line per field.

When a branch is provided, add a one-line branch decision directly under the metadata block: continue on `<branch_name>` or create a new branch (with a suggested name).

### 2. Story Summary

3–6 bullets capturing what the ticket is asking for, in your own words. Not a paraphrase of the description — a *summary* that surfaces the load-bearing parts. If the ticket is vague, say so here.

### 3. Scope

- **In scope**: what this story covers
- **Out of scope**: what it deliberately doesn't (and what the related-but-separate work would be)

If scope is genuinely unclear from the ticket, list the ambiguities under Risks/Unknowns rather than guessing.

### 4. Risks / Unknowns

Blockers, dependencies, ambiguities, anything that would change the plan if it turned out a different way. Be specific: "the API contract for X is unclear — does it return a list or a paginated response?" beats "API contract is unclear."

### 5. Implementation Plan

- **Approach**: the shape of the solution in 2–4 sentences
- **Architectural impact**: any cross-cutting changes (auth, schema, public API, shared components)
- **Files/modules likely affected**: real paths when you can identify them, with line numbers if relevant
- **Data model / API / contract changes**: schema migrations, REST/GraphQL changes, breaking changes to internal interfaces
- **Validation & error handling**: what can fail and how it should fail
- **Test strategy**: unit, integration, e2e — what gets covered at each layer

This section is where you do the actual thinking. If you can't fill in a sub-bullet because the ticket doesn't give you enough info, name the unknown and put a question on it, don't invent.

### 6. TODO Checklist

Format exactly:

```
- [ ] P0: <first critical task>
- [ ] P0: <second critical task>
- [ ] P1: <important task>
- [ ] P2: <nice-to-have task>
```

Rules:

- Tasks must be atomic — one verifiable outcome per task
- Order is execution order within each priority tier
- Include at least one test task per major area you're touching
- Include one documentation/changelog task if behavior visibly changes
- P0 = required for the story to merge; P1 = strongly preferred but not blocking; P2 = nice-to-have / future work

Also mirror this checklist to the `TodoWrite` tool so progress is trackable in the harness.

### 7. Definition of Done

A short checklist tied directly to the acceptance criteria from the ticket. Each item should be observable ("the new endpoint returns 200 for X and 404 for Y") rather than aspirational ("the code is clean").

### 8. Investigation Artifacts Path

The absolute path to the `investigation-artifacts/<story-slug>/` folder so the user can find the persisted notes.

## Phase 4 — Stop and ask

After delivering the plan, **stop**. Ask the user:

> "Plan complete. Want me to start on P0 tasks, or would you like to adjust the plan first?"

Do not begin implementation until the user gives explicit go-ahead. If they ask for adjustments, update the plan and the artifacts before moving on.

## Things to avoid

- **Don't trust a stale ticket silently.** If the most recent comment contradicts the description, surface that explicitly under Risks rather than picking one and hoping.
- **Don't pad the plan.** A 12-item TODO list for a one-line typo fix is worse than a 2-item one. Match the depth of the plan to the size of the work.
- **Don't speculate about files you haven't verified exist.** When you list "files likely affected," base it on `grep`/`find` results or the ticket's own pointers, not vibes. If you genuinely don't know which files, say "unknown — needs a codebase pass" instead.
- **Don't proceed on partial fetches.** If the description loaded but comments didn't, note that and re-try comments rather than producing a plan against half the ticket.
- **Don't rewrite history in artifacts.** Updating an existing artifact folder should preserve prior notes (date-stamped append), not replace them.

## When to skip this skill

This skill is for non-trivial work where the cost of a planning pass is justified. Skip it when:

- The user has already done the planning and just wants you to execute
- The change is mechanical (rename, lint fix, dependency bump) and the ticket title fully describes the work
- The user explicitly says "just start" or "no plan, just code"

In those cases, do the work directly and reference the ticket in the commit message.
