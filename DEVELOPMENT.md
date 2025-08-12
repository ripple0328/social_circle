# Development Guide

This document contains detailed instructions for setting up and developing SocialCircle locally.

## Prerequisites

- Docker and Docker Compose
- [mise](https://mise.jdx.dev/) (for managing Elixir/Erlang versions)
- inotify-tools (for file watching)

## Installation

### Arch Linux / Manjaro

```bash
# Install mise, Docker, and file watcher
sudo pacman -S mise docker docker-compose inotify-tools

# Start Docker service
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # Add user to docker group (logout/login required)

# Install Elixir/Erlang via mise
mise install elixir@1.18 erlang@28
mise use elixir@1.18 erlang@28
```

### macOS

```bash
# Install via Homebrew
brew install mise docker docker-compose fswatch

# Install Elixir/Erlang via mise
mise install elixir@1.18 erlang@28
mise use elixir@1.18 erlang@28
```

## Database Setup

1. Start PostgreSQL database:
   ```bash
   mix db.up
   ```

2. Setup the database:
   ```bash
   mix ecto.setup
   ```

3. **Setup git hooks** (required for all developers):
   ```bash
   ./scripts/setup-hooks.sh
   ```

## Running the Application

1. Install dependencies:
   ```bash
   mix deps.get
   ```

2. Start Phoenix endpoint:
   ```bash
   mix phx.server
   ```
   Or inside IEx: `iex -S mix phx.server`

3. Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Database Management

- Create and migrate: `mix ecto.setup`
- Run migrations: `mix ecto.migrate` 
- Rollback migration: `mix ecto.rollback`
- Reset database: `mix ecto.reset`
- Start database: `mix db.up`
- Stop database: `mix db.down`

## Testing

### Running Tests
```bash
# Run all tests
mix test

# Run tests with coverage
mix coveralls

# Generate HTML coverage report
mix coveralls.html
```

### Code Quality & Git Hooks

The project includes automated git hooks that run code quality checks to maintain consistency across the team:

**Pre-commit hooks** (run before each commit):
- Code compilation with warnings as errors
- Code formatting (`mix format`)
- Dependency cleanup
- Full test suite
- Coverage report generation

**Pre-push hooks** (run before pushing to remote):
- Comprehensive dependency checks
- TODO/FIXME comment validation
- Complete test suite with coverage

**Setting up hooks** (required for all developers):
```bash
# After cloning the repo, run this once:
./scripts/setup-hooks.sh
```

**Manual quality checks:**
```bash
# Run all pre-commit checks
mix precommit

# Individual checks
mix compile --warnings-as-errors
mix format --check-formatted
mix coveralls.html
```

## Development Workflow

1. **Setup git hooks** (first time only): `./scripts/setup-hooks.sh`
2. **Make changes** to your code
3. **Run tests** with `mix test` 
4. **Check formatting** with `mix format`
5. **Commit changes** - pre-commit hooks will run automatically and catch any issues
6. **Push to GitHub** - pre-push hooks + CI/CD pipeline will run comprehensive checks

> 💡 **Tip**: The git hooks will automatically format your code and run tests. If hooks fail, fix the issues and commit again.

## Useful Commands

```bash
# Interactive Elixir shell with app loaded
iex -S mix phx.server

# Run specific test file
mix test test/social_circle_web/controllers/page_controller_test.exs

# Reset and seed database
mix ecto.reset

# Generate new Phoenix components
mix phx.gen.live Posts Post posts title:string content:text

# Check for outdated dependencies
mix hex.outdated
```

## Troubleshooting

### Database Connection Issues
```bash
# Check if PostgreSQL container is running
docker ps

# View database logs
mix db.logs

# Connect to database directly
mix db.connect
```

### Asset Issues
```bash
# Reinstall Node.js dependencies
mix assets.setup

# Rebuild assets
mix assets.build
```

### Port Conflicts
If port 4000 is in use, you can run on a different port:
```bash
PORT=4001 mix phx.server
```