# CRUSH

## Build / Test / Lint
- `mix compile`
- `mix test` – all tests
- Run a single test: `mix test path/to/file.exs:<line>`
- Format code: `mix format`
- Lint: `mix credo --strict`
- Type‑check: `mix dialyzer`
- Pre‑commit alias: `mix precommit` (runs lint, format, typecheck)

## Code Style
- Use `use MyAppWeb, :html` for LiveViews & components.
- Imports: stdlib → Phoenix → local modules. No manual aliases in routes.
- Functions snake_case; public functions end with `!` only when raising.
- Prefer pattern matching over guards unless necessary.
- Errors as `{:error, reason}` tuples; avoid unexpected exceptions.
- Access struct fields directly; use `Ecto.Changeset.get_field/2` for changesets.
- Module names: `Controller`, `View`, `Live`, `Component`. Files 80‑col wrapped and formatted by `mix format`.

## Misc
- Agent workspace in `.crush/`; ensure it is ignored via `.gitignore`.
- Cursor rules are in `.cursor/rules/`; Copilot instructions in `.github/copilot-instructions.md`.
