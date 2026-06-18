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

Request flow: `server.js` → `app.js` → `routes/index.js` → `routes/<resource>.js` → `controllers/<resource>.controller.js` → `models/<resource>.model.js` → `db.js` (shared better-sqlite3 singleton).

**Three layers per resource:**
- `models/` — raw SQL via better-sqlite3 prepared statements. All DB access lives here.
- `controllers/` — Express handlers; call model functions, throw `Error` with `.status = 404` for not-found.
- `routes/` — Router wiring only; each file maps exactly five verbs (`GET /`, `GET /:id`, `POST /`, `PUT /:id`, `DELETE /:id`) to `ctrl.list/show/store/update/destroy`.

Error responses are shaped by `middleware/errorHandler.js`: `{ error: { message, status } }`.

**Existing resources:** `artists`, `albums`, `tracks` — all mounted under `/api/<resource>`.

`airports.json` — static reference data (`{ airports: [{code, name, city, country, lat, lon}] }`), not served by the API.

## Adding a New Resource

Follow the pattern in `routes/AGENTS.md` and `controllers/AGENTS.md`:
1. `models/<resource>.model.js` — five exported functions: `findAll`, `findById`, `create`, `update`, `remove`
2. `controllers/<resource>.controller.js` — five named exports: `list`, `show`, `store`, `update`, `destroy`
3. `routes/<resource>.js` — wire those five to Express verbs; import controller as `* as ctrl`
4. Register in `routes/index.js`

## Environment

`.env` keys: `PORT` (default 3000), `DB_PATH` (default `./chinook.db`).

## SQLite Safety Hook

A `PreToolUse` hook (`scripts/validate-readonly-sqlite.sh`) blocks write operations (`INSERT`, `UPDATE`, `DELETE`, `DROP`, etc.) against SQLite when run via Bash. Schema inspection and `SELECT` queries are allowed. The hook fires on every Bash tool call that references sqlite.

## JSON Tools

Use `jq` instead of reading JSON files directly:

```bash
jq '<query>' <file>
```

Examples:

- `jq '.users[] | select(.id == 42)' db.json`
- `jq '.config.database' settings.json`
- `jq 'keys' unknown.json` # when the structure is unknown

## YAML Tools

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
