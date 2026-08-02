---
paths:
  - "**/*_test.go"
---

# Go Test Conventions

### Writing Tests

Tests must exercise behavior, not just confirm the code runs. Before writing
assertions for a function/endpoint, enumerate the cases that apply to it:

- Happy path (typical valid input)
- Boundary values (empty string, 0, empty slice/map, nil, min/max, off-by-one)
- Invalid or missing input (nil, zero value, wrong type via interface{}/any, missing required field)
- Error paths — assert on the specific sentinel/wrapped error via `errors.Is`/`errors.As`, not just `err != nil`
- State-dependent cases where relevant (already exists, duplicate, concurrent modification, empty store, context already canceled)

A test file covering only the happy path is incomplete. Avoid assertions that
only check `err == nil` or "no panic" — assert on the actual returned
value/shape/side effect. Prefer `github.com/google/go-cmp/cmp` (with
`cmpopts.IgnoreUnexported` where needed) over `reflect.DeepEqual` for
structs — `DeepEqual` panics or silently mismatches on unexported fields,
function values, and NaN.

**IMPORTANT: never assert only `if err != nil { t.Fatal(...) }` on an error
path test — that passes for the wrong error too.** Assert the specific error:

```go
var errNotFound *NotFoundError
if !errors.As(err, &errNotFound) {
    t.Fatalf("got error %v, want *NotFoundError", err)
}
```

### Structure: table-driven, one behavior per subtest

Default to table-driven tests with `t.Run` subtests — one row per case from
the enumeration above, named for the *scenario*, not the input value
(`"empty_slice"`, not `"case_2"`).

```go
func TestParseAmount(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    int64
        wantErr error
    }{
        {name: "typical value", input: "42.00", want: 4200},
        {name: "zero", input: "0", want: 0},
        {name: "empty string", input: "", wantErr: ErrEmptyInput},
        {name: "negative", input: "-1.00", want: -100},
        {name: "missing decimal", input: "42", want: 4200},
        {name: "malformed", input: "abc", wantErr: ErrMalformed},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            got, err := ParseAmount(tt.input)
            if tt.wantErr != nil {
                if !errors.Is(err, tt.wantErr) {
                    t.Fatalf("err = %v, want %v", err, tt.wantErr)
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got != tt.want {
                t.Fatalf("got %d, want %d", got, tt.want)
            }
        })
    }
}
```

On Go 1.22+ the per-iteration loop variable is safe to capture directly in
the closure. On Go <1.22, shadow it first (`tt := tt`) before `t.Run` —
otherwise every subtest silently runs against the last row's value.

### Naming

- Test function: `TestFuncName` or `TestType_Method` for methods, matching
  the identifier under test so `go test -run` can target it.
- Subtest names describe the scenario in `snake_case` or `lower with spaces`,
  never the raw input value alone — a failing test name should tell you what
  broke without reading the table.
- Benchmark: `BenchmarkFuncName`. Fuzz target: `FuzzFuncName`.

### Setup, teardown, and helpers

- Use `t.Cleanup(func() { ... })` for teardown, not `defer`, inside table
  tests and helper constructors — `defer` in a helper runs when the helper
  returns, not when the subtest ends; `t.Cleanup` registers against the
  actual test/subtest and still runs on `t.Fatal`.
- Mark any function that calls `t.Fatal`/`t.Error` but isn't itself a test
  with `t.Helper()` as its first line, so failures report the caller's line
  number, not the helper's.
- Extract shared fixture construction (`newTestServer(t)`, `seedDB(t, db)`)
  into helpers that return cleanup via `t.Cleanup`, not into `TestMain` global
  state — global fixtures create hidden ordering dependencies between tests.
- Don't rely on test execution order or on state left behind by another test.
  Each test must pass with `go test -run TestName` in isolation and with
  `go test -shuffle=on`.

### Parallelism and concurrency

- Call `t.Parallel()` as the first statement in both the outer test and each
  subtest when the cases are independent — this is also what surfaces data
  races and shared-state bugs that `-race` alone won't catch.
- Do not call `t.Parallel()` for subtests that mutate a shared fixture
  (same in-memory map, same temp file, same package-level var) unless the
  fixture is one-per-subtest.
- Always run the suite with `-race` in CI (`go test -race ./...`) for any
  package with goroutines, channels, or shared mutable state — a green test
  run without `-race` proves nothing about concurrent correctness.
- Never synchronize with `time.Sleep` to "wait for a goroutine to finish."
  Use channels, `sync.WaitGroup`, or a context deadline the test asserts on.
  A `time.Sleep`-based test either flakes under load or hides a real race.
- For code under test that depends on wall-clock time, inject a clock
  (interface or `func() time.Time` field) so tests control time deterministically instead of sleeping and hoping.

### Context

- Never use `context.TODO()` in a test — use `context.Background()`, or
  `context.WithTimeout`/`WithCancel` when the behavior under test is
  cancellation itself.
- Explicitly test the cancellation/deadline path for any function that takes
  a `context.Context` and does I/O: cancel before calling, cancel mid-call,
  assert `errors.Is(err, context.Canceled)` /
  `errors.Is(err, context.DeadlineExceeded)` — don't assume the plumbing
  works because the happy path does.

### Errors

- Define and export sentinel errors (`var ErrNotFound = errors.New(...)`) or
  typed errors for any error a caller is expected to branch on; test against
  those with `errors.Is`/`errors.As`, never by substring-matching
  `err.Error()`.
- If a function wraps an error with `fmt.Errorf("...: %w", err)`, assert the
  wrapped chain unwraps to the expected sentinel — a test that only checks
  the wrapping layer's message will pass even if the wrapped cause changes.
- Test that functions which must NOT return an error under certain inputs
  actually don't (negative-space assertion), not only that they return one
  when they should.

### Test doubles

- Prefer small hand-written fakes behind an interface owned by the consumer
  over a generated mock for anything with more than 1–2 methods exercised —
  fakes let you assert on state after the call; mocks tend to over-specify
  call order and break on harmless refactors.
- Use `net/http/httptest.NewServer` for HTTP client code under test; never
  hit a real network endpoint in a unit test.
- Reserve real dependencies (`testcontainers-go`, a real DB) for tests
  tagged as integration tests (see below) — never in the default `go test
  ./...` unit run.
- When a mock is justified (verifying a specific call happened with specific
  arguments, e.g. an audit log), assert on the captured arguments, not just
  "was called."

### Unit vs. integration

- Gate anything touching a real network, database, filesystem outside
  `t.TempDir()`, or external process behind a build tag:
  `//go:build integration` at the top of the file, run via
  `go test -tags=integration ./...` as a separate CI step.
- `go test ./...` (no tags) must run fully offline and deterministically in
  seconds — if it doesn't, something is miscategorized.
- Use `t.Skip("reason")` with an explicit reason for environment-gated
  tests (missing Docker, missing credentials) — never silently `return`.

### Golden files and snapshots

- Store fixtures under `testdata/` (the Go toolchain ignores this dir for
  builds automatically) — `testdata/case_name.golden` or `.json`.
- Support an `-update` flag (`var update = flag.Bool("update", false, "update
  golden files")`) that regenerates goldens from actual output, so
  intentional changes are a one-line diff review instead of hand-editing
  fixtures.
- Diff golden output with `cmp.Diff`, and print the diff on failure — a
  bare `t.Fail()` on mismatch forces the next person to reconstruct what
  changed by hand.

### Fuzzing

- Add a `Fuzz` target (`func FuzzParse(f *testing.F)`) for any function that
  parses untrusted input (wire formats, user-supplied strings, file
  formats) — seed the corpus (`f.Add(...)`) with the boundary values from
  the enumeration above, then let `go test -fuzz=FuzzParse` find the rest.
- A fuzz target's invariant should be a property ("never panics", "round-trips
  through Marshal/Unmarshal"), not a hardcoded expected output.

### Benchmarks

- Name `BenchmarkX`, reset allocation counters with `b.ReportAllocs()` when
  allocation behavior matters, and call `b.ResetTimer()` after any
  per-benchmark setup so setup cost isn't measured.
- Don't let benchmarks assert correctness — that's what the `Test` sibling
  is for; a benchmark that also checks output silently stops catching
  regressions the moment someone comments out the assertion to "just measure
  speed."

### What NOT to test

- Don't test unexported implementation details reachable only through
  reflection or same-package access hacks — test observable behavior
  through the exported API. An internal refactor that keeps behavior
  identical should not break tests.
- Don't write a test that only asserts a mock was called — assert the
  resulting state or output the call was supposed to produce.
- Don't add a test for a scenario that the type system already makes
  impossible (e.g. a non-pointer struct field being nil).

### Before calling a test file done

Re-read the enumeration at the top against the actual test file: if any of
happy path / boundaries / invalid input / error paths / state-dependent
cases apply to the function and aren't present, the file is incomplete —
add the missing case rather than shipping partial coverage.
