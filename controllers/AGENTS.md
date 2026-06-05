# Area: controllers — Express CRUD handlers for REST resources

> See @AGENTS.md at the repo root for repo-wide rules.

## Shape

Each controller is a single file named `<plural-resource>.controller.js` (e.g. `albums.controller.js`). It imports the corresponding model namespace with `import * as <PascalCase> from '../models/<plural-resource>.model.js'` and defines a file-local `notFound` helper that creates an `Error` with `.status = 404` and throws it. The file exports five named functions — `list`, `show`, `store`, `update`, `destroy` — in that order, covering the full CRUD surface. There is no default export. No tests, styles, or types are co-located in this directory.

## Reference

`@./albums.controller.js` — median complexity, complete five-export CRUD shape, and the clearest example of the model-import → notFound-helper → named-exports pattern.

## Adding one more

1. Create `<plural-resource>.controller.js` in this directory.
2. Import the model namespace: `import * as <PascalCase> from '../models/<plural-resource>.model.js'`.
3. Define the file-local `notFound` helper with a resource-specific message and `.status = 404`.
4. Export `list`, `show`, `store`, `update`, `destroy` as named exports in that order — see `@./albums.controller.js`.
5. Create `routes/<plural-resource>.js` mapping those five exports to Express verbs — mirror `@../routes/albums.js`.
6. Register the new router in `@../routes/index.js` under `/<plural-resource>`.

## Tripwires

- All five exports must be **named**, not default. The route files import them via `* as ctrl`, so a default export will break silently.
