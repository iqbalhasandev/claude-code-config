# Test Runs — Targeted While Working, Full Suite Once at the End

Applies to every project and every test framework (Jest, Vitest, PHPUnit/Pest, pytest, Go test, RSpec, Cargo, and any other).

- While implementing, run only the specific test files (or test cases) the current change touches. Name them explicitly — by file path or test name — never by a folder pattern that can sweep in the rest of the suite.
- Prefer the framework's single-process / no-watch mode for these targeted runs to save memory (e.g. Jest `--runTestsByPath <files> -i`, Vitest `run <files>`, `pytest path::test`, `php artisan test --filter`, `go test ./pkg -run Name`).
- Run the whole suite exactly once, after all the work is complete, as the final verification step.
- A full-suite failure at the end is reported by name, including failures not caused by the change.

Reason: running the whole suite after every step wastes time and memory.
