# Scripts Directory

This directory contains development scripts and tools for the SocialCircle project.

## Git Hooks

The `hooks/` subdirectory contains git hooks that enforce code quality and consistency across the development team.

### Available Hooks

- **`pre-commit`** - Runs before each commit to ensure code quality
  - Compiles code with warnings as errors
  - Runs code formatting (`mix format`)
  - Static code analysis with Credo
  - Security scanning with Sobelow
  - Cleans up unused dependencies
  - Runs full test suite with coverage

- **`pre-push`** - Runs before pushing to remote repository
  - Runs comprehensive quality suite (`mix quality`)
  - Includes Dialyzer type checking
  - Performs dependency conflict checks
  - Validates TODO/FIXME comments

### Setup

After cloning the repository, all developers must run:

```bash
./scripts/setup-hooks.sh
```

This creates symbolic links from `.git/hooks/` to the hooks in this directory, ensuring all developers use the same quality checks.

### Manual Testing

You can test the hooks manually:

```bash
# Test pre-commit checks (fast)
mix precommit

# Test comprehensive quality suite (includes Dialyzer)
mix quality

# Test individual components
mix credo --strict
mix sobelow
mix dialyzer
mix format --check-formatted
mix coveralls.html
```

### Troubleshooting

- **Hook fails with permission errors**: Ensure the script is executable: `chmod +x scripts/setup-hooks.sh`
- **Mix command not found**: Ensure Elixir is installed and in your PATH
- **Hooks not running**: Verify symbolic links exist: `ls -la .git/hooks/pre-*`

### Customizing Hooks

The hooks are stored in version control, so changes affect all developers. Test thoroughly before modifying:

1. Edit the hook file in `scripts/hooks/`
2. Test with `./scripts/setup-hooks.sh && mix precommit`
3. Commit changes and notify team members