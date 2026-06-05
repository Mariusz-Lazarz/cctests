---
name: scope-init
description: >
  Capture the local file pattern of the current (or named) directory into a short
  AGENTS.md (120–250 words). Reads actual sibling files — naming, structure,
  imports, test co-location — then writes "here is the shape, here is the
  reference, here is how to add one more." Never asks about the project; infers
  everything from files on disk. Cites one real sibling as the canonical example.
  Use when you want agents to follow the existing convention in a focused folder:
  API handlers, UI components, database migrations, hooks, workers, etc.
  Trigger phrases: "init this folder", "scope init", "document this directory's
  pattern", "add agents doc here", "what is the pattern here".
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
---

# /scope-init — Capture the Local File Pattern

Write a short `AGENTS.md` that tells the next agent exactly what shape things take
inside *this* directory and how to add one more, by reading the files already
there. No project-wide framing, no build commands, no commit conventions — those
belong in the root `AGENTS.md`. Just the local rules, derived from evidence.

## First action — always

Before anything else, resolve the target path and check whether `AGENTS.md`
already exists there. This is a hard branch, not a suggestion.

```
1. Resolve target directory (see Input resolution below).
2. Check: does <target-dir>/AGENTS.md exist and contain more than 5 lines?
   YES → go directly to Update path. Do NOT run Create path steps.
   NO  → go to Create path.
```

Never silently overwrite a non-stub `AGENTS.md`. If it exists, update it.

## Input resolution

`$ARGUMENTS` is optional.

- **Empty** → target directory is `pwd`.
- **A directory path** → use that directory as the target.
- **A file path ending in `.md`** → write output there; inspect that file's
  containing directory for siblings.

## What this skill does NOT do

- Does not ask the user "what is this project?" or "what framework do you use?" —
  it reads the files and infers. If inference is impossible (empty directory,
  no pattern to read), it says so and stops.
- Does not write project-level sections: no top-level directory map, no build
  scripts, no CI overview, no commit conventions. One line linking to the root
  `AGENTS.md` covers all of that.
- Does not invent conventions. Every sentence in the output must trace back to a
  real file on disk.
- Does not embed multi-line code blocks. Uses `@`-references to actual files.
- Does not write generic advice ("write clean code", "be consistent"). If a rule
  cannot be checked against a diff, it gets cut.

---

## Create path

### Step 1 — Survey the directory

Read the following (skip anything that doesn't apply):

1. **List siblings.** `ls -1` in the target directory. Note file count, dominant
   extension(s), naming convention (kebab-case, PascalCase, snake_case,
   `*.handler.ts`, `*_test.go`, etc.), any index/barrel file.
2. **Read 2–4 representative files.** Pick the most typical ones — not the largest,
   not one-offs. Read each enough to extract:
   - top-level imports (what does each file pull in, and from where?)
   - export style (default vs. named, class vs. function, barrel or not)
   - internal structure (sections, ordering, naming conventions inside the file)
   - co-located tests/styles/types? (are there sibling `*.test.*`, `*.spec.*`,
     `*.styles.*`, `*.types.*` files next to each unit?)
3. **Check for a barrel or index.** Does `index.*`, `mod.rs`, `__init__.py`, or
   similar exist? What does it re-export?
4. **Spot the test pattern.** Co-located (`*.test.ts`) or parallel tree
   (`__tests__/`, `spec/`)? What naming convention do test files use?
5. **Look for a nearby rule file.** Is there a `CLAUDE.md` or `AGENTS.md` one level
   up that mentions this directory? If so, read it and pull in only rules that
   directly apply here.

### Step 2 — Identify the reference sibling

Pick **one** file to hold up as the canonical example — the file another developer
would read first when adding a second unit. Criteria in priority order:

1. Closest to median size and complexity in the directory (not the smallest stub,
   not a special case, not the largest).
2. Has a visible test sibling or is the most complete representation of the pattern.
3. Named in the most obviously conventional way when naming is consistent.

If no clear winner, pick the most recently modified non-test file.

### Step 3 — Draft

Write the file per **Output structure** below. Target 120–250 words of body (headings
excluded from the count). Under 120 means the pattern wasn't captured; over 250
means scope crept into territory that belongs in the root `AGENTS.md`.

### Step 4 — Quality check (run before writing)

Each is a hard gate. Revise if any fails.

1. **No invented facts.** Every sentence traces to a file read in Step 1.
2. **No repo-level scope.** No build commands, no CI, no top-level directory map,
   no commit conventions. One `@AGENTS.md` link is the entire allowance.
3. **Reference sibling is cited.** `## Reference` names a real file via
   `@./filename` that was actually read.
4. **"Adding one more" is actionable.** The numbered list gives steps a new agent
   can follow without opening any other file.
5. **Body is 120–250 words.** Count the body. Trim if over; add specifics if under.
6. **No multi-line code blocks.** Single-line inline examples are fine. Anything
   longer → `@`-reference instead.
7. **No generic advice.** If you could have written a sentence without opening the
   directory, cut it.

### Step 5 — Write

Single `Write` call to the resolved path.

Report back:
- path written
- body word count
- reference sibling chosen and why in one sentence

---

## Update path

Entered when `AGENTS.md` exists at the target with more than 5 lines. The goal is
a surgical edit, not a rewrite. Preserve the user's authorial voice in anything
that is still accurate.

1. **Read the existing file in full.** Note its sections, every `@./filename`
   reference it cites, and any explicit convention it states.

2. **Re-survey the directory** (same as Create path Step 1). Look specifically for:
   - New siblings added since the file was written (new files that match the
     pattern, or new files that break it).
   - Renamed or deleted files that the AGENTS.md still references.
   - Conventions that have drifted (e.g., the barrel export moved, the test naming
     changed, a new import origin appeared in all recent files).

3. **Classify every substantive line** into one of four buckets:
   - **KEEP** — still accurate; referenced file exists, convention holds.
   - **UPDATE** — directionally right but a detail is stale (renamed file,
     moved path, changed convention). Note the exact replacement.
   - **REMOVE** — the underlying file/convention no longer exists or has been
     contradicted by what you observed in Step 2.
   - **MISSING** — a real convention visible in current siblings that the file
     doesn't mention yet.

4. **Edit surgically.** Use `Edit` for each UPDATE / REMOVE / MISSING entry
   individually. Only use `Write` to replace the whole file if more than half the
   lines are classified as REMOVE or UPDATE.

5. **Re-run the quality check** (same seven gates as the Create path) on the
   result. If the body has grown past 250 words from MISSING additions, trim
   lower-leverage KEEP content rather than dropping the new information.

6. **Report:** path, new body word count, and one line each on what was updated,
   removed, and added (e.g. *"1 updated (reference sibling renamed), 0 removed,
   1 added (barrel export wiring step)"*).

---

## Output structure

```markdown
# Area: <directory-name> — <one-phrase description of what lives here>

> See @AGENTS.md at the repo root for repo-wide rules.

## Shape

<One paragraph. Name the dominant unit (component, handler, migration, hook, …),
its naming convention with one inline example, its internal structure, what it
imports, and what it exports. Note whether tests/styles/types are co-located or
live elsewhere.>

## Reference

`@./<reference-sibling>` — <one sentence on why this is the clearest example and
what makes it representative.>

## Adding one more

1. <Create a file named `<NamingConvention>.<ext>`.>
2. <Copy the shape from the reference: imports, skeleton, export style.>
3. <Wire it in — barrel re-export, route registration, migration runner, or
   whatever registration the siblings use. Cite the file: `@./<barrel-or-registry>`.>
4. <Add a co-located test at `<test-naming-pattern>` if tests live here.>
5. <Any step specific to this directory — generator, type discriminant, manifest
   update. Omit if no such step exists.>

## Tripwires

- <"Never do X" rule observed in siblings — only include if actually visible.>
- <Omit this section entirely if no tripwires are found.>
```

**Notes:**

- `# Area:` signals immediately that this is a local, not repo-level, file.
- The `> See @AGENTS.md` line is the full allowance for repo-wide context — one
  line, not a paragraph.
- `## Shape` is discovery — what already exists.
- `## Reference` pins one file — the agent reads one, not five.
- `## Adding one more` is the reason this file exists.
- `## Tripwires` is optional and evidence-based — omit if nothing was observed.
- Do not add sections beyond these four. If something important doesn't fit here,
  it belongs in the root `AGENTS.md`.

---

## Edge cases

- **Empty or near-empty directory (0–1 source files).** Stop with: "Only `<N>`
  file(s) found — not enough siblings to infer a pattern. Add more files first, or
  describe the intended convention directly in `AGENTS.md`." Do not fabricate.
- **No dominant pattern (mixed types, irregular naming).** Write only what IS
  consistent across siblings and note explicitly that naming/structure varies. Do
  not invent a pattern.
- **All files are generated (migration timestamps, proto outputs, codegen).** Note
  the generator, cite its config or command, and replace "Adding one more" steps
  with "Use `<generator command>` — do not create these files by hand."
- **Existing `AGENTS.md` is empty or a stub (≤ 5 lines).** The "First action"
  gate sends this to Create path — overwrite is safe, there is no authorial
  content to preserve.
- **Target is the repo root.** Stop and redirect: "Run `/10x-agents-md` for the
  repo root — `/scope-init` is for sub-directories only."
