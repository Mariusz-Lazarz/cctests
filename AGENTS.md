# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

REST API for the [Chinook](https://github.com/lerocha/chinook-database) music store SQLite database. Built with Express 5, better-sqlite3, and ES modules (`"type": "module"`).

## Commands

```bash
npm start        # production
npm run dev      # nodemon watch mode (requires nodemon)
```

No test runner is configured. Manually test endpoints with `curl` or similar.

## Architecture

A request flows `server.js` → `app.js` → `routes/` → `controllers/` → `models/` → `db.js`. Each resource is a layered triplet across `routes/`, `controllers/`, and `models/`, mounted under `/api/<resource>`. Layout by directory:

- `routes/` — Express routers; one file per resource plus an `index.js` barrel that mounts each under `/api/<resource>`.
- `controllers/` — Express request handlers; call models, shape responses, signal not-found.
- `models/` — all SQL, via better-sqlite3 prepared statements. No DB access lives outside here.
- `middleware/` — cross-cutting Express middleware (e.g. `errorHandler.js`, which shapes errors as `{ error: { message, status } }`).
- root (`server.js`, `app.js`, `db.js`) — process entry, app wiring, and the shared better-sqlite3 singleton.

`airports.json` — static reference data, not served by the API.

## Development Guidelines

### Git Workflow

- Never commit directly to `main`/`master`. Always work on a feature branch (e.g. `feat/<short-name>`, `fix/<short-name>`) and open a PR to merge.
- If you're on `main`/`master` when a change is needed, create and switch to a branch first.

### JSON Tools

Use `jq` instead of reading JSON files directly:

```bash
jq '<query>' <file>
```

Examples:

- `jq '.users[] | select(.id == 42)' db.json`
- `jq '.config.database' settings.json`
- `jq 'keys' unknown.json` # when the structure is unknown

### YAML Tools

Use `yq` (Mike Farah, Go version — jq-compatible syntax) instead of reading YAML files directly:

```bash
yq '<query>' <file>
```

Examples:

- `yq '.services.db' docker-compose.yml`
- `yq '.users[] | select(.id == 42)' config.yaml`
- `yq 'keys' unknown.yaml` # when the structure is unknown
- `yq -o=json '.' file.yaml` # convert YAML → JSON

### Documentation Updates

Docstrings, comments, and any files files describe only the current state of the code. When a change makes a piece of documentation outdated, rewrite it — do not append the new decision alongside the old one.

- Never leave changelog-style traces in docs (e.g. "as of task X we switched to Y", "previously did X, now does Y", "Note: updated because..."). If it explains why *now* differs from *before*, it belongs in the commit message or PR description, not in the doc.
- Before editing a doc block, read it in full and decide whether the whole block still holds together, not just whether the new sentence is true.
- If a prior edit already left conflicting or stale statements in a doc you're touching, clean them up as part of the change instead of adding a third, newer statement on top.

### Test Changes

When a test fails, the default is to fix the code, not the test. Never edit a test's expectations, assertions, or mocks just to make it pass.

- Only change a test if the underlying requirement or behavior genuinely changed as part of the task — and the code change that caused the failure was intentional, not a bug you introduced.
- If a test fails because of code you changed on purpose, update the test to match the new intended behavior — that's expected and fine.
- If a test fails and it's unclear whether the code or the test is wrong, do not guess. Stop and ask the user, explaining what the test expects, what the code actually does, and why the two disagree. Do not silently adjust the test to force a green result.

### Writing Tests

Tests must exercise behavior, not just confirm the code runs. Before writing assertions for a
function/endpoint, enumerate the cases that apply to it:

- Happy path (typical valid input)
- Boundary values (empty string, 0, empty array/list, min/max, off-by-one)
- Invalid or missing input (null, undefined, wrong type, missing required field)
- Error paths — assert on the specific error/status, not just "it throws" or "status != 200"
- State-dependent cases where relevant (already exists, duplicate, concurrent modification, empty DB)

A test file covering only the happy path is incomplete. Avoid assertions that only check
truthiness or "no exception thrown" — assert on the actual returned value/shape/side effect.

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` to keep the graph current

## Subdirectory Knowledge

Scoped `AGENTS.md` docs, maintained by `/scope-init`.
