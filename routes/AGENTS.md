# Area: routes — Express routers mapping REST verbs to controller functions

> See @AGENTS.md at the repo root for repo-wide rules.

## Shape

Each resource route file is named `<plural-resource>.js` (e.g. `albums.js`). It imports `{ Router }` from `'express'` and the matching controller namespace with `import * as ctrl from '../controllers/<plural-resource>.controller.js'`. The file creates a router instance, wires exactly five routes in order — `GET /`, `GET /:id`, `POST /`, `PUT /:id`, `DELETE /:id` — to `ctrl.list`, `ctrl.show`, `ctrl.store`, `ctrl.update`, and `ctrl.destroy`, then exports the router as the default export. `index.js` is the barrel: it imports every resource router, mounts each under its plural path, and re-exports a single combined router. No tests are co-located in this directory.

## Reference

`@./albums.js` — the most direct, complete illustration of the import→wire→export pattern, with no special-case logic.

## Adding one more

1. Create `<plural-resource>.js` in this directory.
2. Import `{ Router }` from `'express'` and `* as ctrl` from `'../controllers/<plural-resource>.controller.js'`.
3. Wire five routes in order: `GET /` → `ctrl.list`, `GET /:id` → `ctrl.show`, `POST /` → `ctrl.store`, `PUT /:id` → `ctrl.update`, `DELETE /:id` → `ctrl.destroy`.
4. Export `router` as the default export.
5. In `@./index.js`, import the new router and mount it with `router.use('/<plural-resource>', <name>)`.

## Tripwires

- Import the controller namespace as `* as ctrl`, not destructured. The five method names (`list`, `show`, `store`, `update`, `destroy`) come through as named exports on that namespace — destructuring a default export instead will silently break all routes.
