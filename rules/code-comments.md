# Code Comments — Minimal by Default

Applies to every project, every language (PHP, Blade, JS/TS, Vue, SCSS, Python, Go, shell, tests, config).

## The rule

**Do not write inline comments.** Default output is code with zero comments. A comment is a defect
unless it survives the test in "When a comment is allowed" below.

Never write a comment that:

- Narrates what the line or block does (`// loop over rows`, `// set the flag`, `// inject the service`).
- Explains the reasoning behind the approach, a trade-off, or why an alternative was rejected
  (`// on fill() is a paid no-op — fail the issue rather than hand over a short license`).
- Records history or a previous version (`// this used to be X`, `// changed because...`, `// was buggy before`).
- Restates a ticket, a task prompt, or a design brief.
- Labels sections of a file (`// ---- helpers ----`, `// Constructor`, banner/ASCII headers).
- Marks what was just edited (`// added`, `// new`, `// updated`, `// fixed`).
- Is a docblock over an obvious method, or a `/** @var */` over a plainly typed variable.
- Is a TODO/FIXME invented without the user asking for it.

Naming and extraction replace comments. If a block needs explaining, rename the variable, extract a
well-named method, or introduce a named constant/enum instead of annotating it.

## When a comment is allowed

Rare, and at most **2 lines**, roughly **one per 30 lines** of a file:

- A non-obvious invariant a reader would otherwise violate.
- The specific bug or edge case a line exists to prevent, stated in one sentence.
- A reference to an external spec, RFC, gazette, ticket ID, or upstream issue.
- A deliberate deviation from convention that looks like a mistake without the note.
- A docblock carrying type information the language cannot express (array shapes, generics),
  where the project already uses that style.

## Where the reasoning goes instead

Design rationale, history, trade-offs and rejected alternatives belong in the commit message, the PR
description, or `docs/` — never in the source file.

## Existing comments

Do not mass-delete existing comments unless asked. When editing a block that already carries a
narrating comment, drop that comment as part of the edit. Never copy an existing verbose comment
style forward into new code just because the surrounding file does it.

## Tests

Same limit. Arrange/Act/Assert markers are fine; explanatory paragraphs above them are not.
