# Graph Report - .  (2026-06-05)

## Corpus Check
- Corpus is ~2,763 words - fits in a single context window. You may not need a graph.

## Summary
- 86 nodes · 77 edges · 22 communities detected
- Extraction: 74% EXTRACTED · 26% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.67)
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `Request Flow Architecture` - 5 edges
2. `Routes Directory Shape and Convention` - 5 edges
3. `Controllers Directory Shape and Convention` - 5 edges
4. `Research: jq vs Bash Token Cost Comparison` - 5 edges
5. `notFound()` - 4 edges
6. `notFound()` - 4 edges
7. `notFound()` - 4 edges
8. `routes/index.js Barrel Router` - 3 edges
9. `Five Named Exports: list, show, store, update, destroy` - 3 edges
10. `Rule: Stay In The Loop (No Ralphing)` - 3 edges

## Surprising Connections (you probably didn't know these)
- `Rule: Build Infrastructure (Agents, Skills, Hooks)` --semantically_similar_to--> `SQLite Safety Hook (PreToolUse)`  [INFERRED] [semantically similar]
  MY-RULES.md → CLAUDE.md
- `Tripwire: All Five Exports Must Be Named (Not Default)` --semantically_similar_to--> `Tripwire: Import Controller as Namespace (* as ctrl)`  [INFERRED] [semantically similar]
  controllers/AGENTS.md → routes/AGENTS.md
- `Five Named Exports: list, show, store, update, destroy` --semantically_similar_to--> `Five REST Verbs Pattern (GET POST PUT)`  [INFERRED] [semantically similar]
  controllers/AGENTS.md → routes/AGENTS.md
- `jq JSON Tool Preference` --conceptually_related_to--> `Research: jq vs Bash Token Cost Comparison`  [INFERRED]
  CLAUDE.md → research_notes.md
- `Adding a New Resource Guide` --references--> `Routes Directory Shape and Convention`  [EXTRACTED]
  CLAUDE.md → routes/AGENTS.md

## Hyperedges (group relationships)
- **Three-Layer CRUD Contract: models / controllers / routes** — claudemd_three_layer_pattern, controllersagents_shape, routesagents_shape [EXTRACTED 1.00]
- **New Resource Addition Workflow** — claudemd_adding_resource, controllersagents_adding, routesagents_adding [EXTRACTED 1.00]
- **Namespace Import Contract (* as ctrl / * as Model)** — routesagents_tripwire_namespace, controllersagents_tripwire_named, controllersagents_model_namespace [EXTRACTED 0.95]

## Communities

### Community 0 - "Resource Architecture & Conventions"
Cohesion: 0.16
Nodes (14): Adding a New Resource Guide, Error Handler Middleware (errorHandler.js), routes/index.js Barrel Router, Five Named Exports: list, show, store, update, destroy, Model Import as Namespace (import * as PascalCase), notFound Helper (Error with .status=404), albums.controller.js as Controller Reference Implementation, Controllers Directory Shape and Convention (+6 more)

### Community 1 - "JSON Tool Research & Data"
Cohesion: 0.29
Nodes (8): airports.json Static Reference Data, jq JSON Tool Preference, Test Dataset: airports.json US Filter Query, Cache Write Cost Driver ($3.75/1M tokens), Model: claude-sonnet-4-6, Finding: jq ~30% Cheaper Than Bash, Research: jq vs Bash Token Cost Comparison, Rule of Thumb: Pre-process Data Before Model Context

### Community 2 - "Artists Controller"
Cohesion: 0.43
Nodes (4): destroy(), notFound(), show(), update()

### Community 3 - "Albums Controller"
Cohesion: 0.43
Nodes (4): destroy(), notFound(), show(), update()

### Community 4 - "Tracks Controller"
Cohesion: 0.43
Nodes (4): destroy(), notFound(), show(), update()

### Community 5 - "Artists Model"
Cohesion: 0.33
Nodes (0): 

### Community 6 - "Albums Model"
Cohesion: 0.33
Nodes (0): 

### Community 7 - "Tracks Model"
Cohesion: 0.33
Nodes (0): 

### Community 8 - "Server & Database Core"
Cohesion: 0.4
Nodes (5): app.js Application Module, db.js better-sqlite3 Singleton, Request Flow Architecture, server.js Entry Point, Three-Layer Resource Pattern (models/controllers/routes)

### Community 9 - "Safety Hooks & Infrastructure"
Cohesion: 0.5
Nodes (4): SQLite Safety Hook (PreToolUse), scripts/validate-readonly-sqlite.sh Hook Script, Rule: Build Infrastructure (Agents, Skills, Hooks), System Architect Mindset with AI Assistance

### Community 10 - "AI Collaboration Rules"
Cohesion: 0.5
Nodes (4): Rule: Explicit Over Implicit Context, Rule: Plan Mode for Multi-File Tasks, Rule: Stay In The Loop (No Ralphing), Rule: Trust But Verify (Risk-Based Review)

### Community 11 - "Error Handler"
Cohesion: 1.0
Nodes (0): 

### Community 12 - "Database Module"
Cohesion: 1.0
Nodes (0): 

### Community 13 - "Server Entry"
Cohesion: 1.0
Nodes (0): 

### Community 14 - "App Module"
Cohesion: 1.0
Nodes (0): 

### Community 15 - "Albums Router"
Cohesion: 1.0
Nodes (0): 

### Community 16 - "Tracks Router"
Cohesion: 1.0
Nodes (0): 

### Community 17 - "Artists Router"
Cohesion: 1.0
Nodes (0): 

### Community 18 - "Routes Index"
Cohesion: 1.0
Nodes (0): 

### Community 19 - "Project Overview"
Cohesion: 1.0
Nodes (1): Project Overview: Chinook REST API

### Community 20 - "Resource Inventory"
Cohesion: 1.0
Nodes (1): Existing Resources: artists, albums, tracks

### Community 21 - "Code Writing Rule"
Cohesion: 1.0
Nodes (1): Rule: Still Allowed To Write Code (Claude as Multiplier)

## Knowledge Gaps
- **20 isolated node(s):** `Project Overview: Chinook REST API`, `Three-Layer Resource Pattern (models/controllers/routes)`, `Error Handler Middleware (errorHandler.js)`, `server.js Entry Point`, `app.js Application Module` (+15 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Error Handler`** (2 nodes): `errorHandler.js`, `errorHandler()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Database Module`** (1 nodes): `db.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Server Entry`** (1 nodes): `server.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Module`** (1 nodes): `app.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Albums Router`** (1 nodes): `albums.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Tracks Router`** (1 nodes): `tracks.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Artists Router`** (1 nodes): `artists.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Routes Index`** (1 nodes): `index.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Project Overview`** (1 nodes): `Project Overview: Chinook REST API`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Resource Inventory`** (1 nodes): `Existing Resources: artists, albums, tracks`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Code Writing Rule`** (1 nodes): `Rule: Still Allowed To Write Code (Claude as Multiplier)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `routes/index.js Barrel Router` connect `Resource Architecture & Conventions` to `Server & Database Core`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `notFound()` (e.g. with `show()` and `update()`) actually correct?**
  _`notFound()` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Project Overview: Chinook REST API`, `Three-Layer Resource Pattern (models/controllers/routes)`, `Error Handler Middleware (errorHandler.js)` to the rest of the system?**
  _20 weakly-connected nodes found - possible documentation gaps or missing edges._