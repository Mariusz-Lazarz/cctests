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

For a directory's local conventions — naming, exports, how to add one more — see that directory's own `AGENTS.md` (listed under **Subdirectory Knowledge** below), not this map.

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

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` to keep the graph current

## Subdirectory Knowledge

Scoped `AGENTS.md` docs, maintained by `/scope-init`.

- @controllers/AGENTS.md — Express CRUD handlers for REST resources
- @routes/AGENTS.md — Express routers mapping REST verbs to controller functions
