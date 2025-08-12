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

## Code Quality & Security

The project includes comprehensive code quality tools and automated checks:

### Quality Tools
- **Credo**: Static code analysis for maintainable code
- **Dialyzer**: Static analysis for type safety and bug detection
- **Sobelow**: Security-focused static analysis for Phoenix applications
- **ExCoveralls**: Test coverage reporting

### Development Services
Start all development services with Docker Compose:
```bash
# Start all services (database, Redis, MinIO, MockServer, MailHog)
docker compose up -d

# Or individual services
mix db.up          # PostgreSQL only
docker compose up -d redis minio  # Specific services
```

**Available services:**
- **PostgreSQL**: Database on `localhost:5432`
- **Redis**: Caching/sessions on `localhost:6379`
- **MinIO**: S3-compatible storage at `localhost:9000` (console: `localhost:9001`)
- **MockServer**: API mocking at `localhost:1080`
- **MailHog**: Email testing UI at `localhost:8025`

### Git Hooks & Quality Checks

**Pre-commit hooks** (run before each commit):
- Code compilation with warnings as errors
- Code formatting (`mix format`)
- Static analysis (`mix credo --strict`)
- Security scanning (`mix sobelow`)
- Dependency cleanup
- Test coverage report generation

**Pre-push hooks** (run before pushing to remote):
- Full quality suite including Dialyzer type checking
- Dependency conflict checking
- TODO/FIXME comment validation

**Setting up hooks** (required for all developers):
```bash
# After cloning the repo, run this once:
./scripts/setup-hooks.sh
```

**Manual quality checks:**
```bash
# Run all pre-commit checks (fast)
mix precommit

# Run comprehensive quality suite (includes Dialyzer)
mix quality

# Individual tools
mix credo --strict           # Static code analysis
mix dialyzer                 # Type checking (first run ~45s for PLT)
mix sobelow                  # Security scanning
mix format --check-formatted # Formatting check
```

### First-Time Dialyzer Setup
```bash
# Generate PLT files (one-time setup, ~45 seconds)
mix dialyzer --plt
```

## Development Workflow

### Initial Setup (One-time)
1. **Setup git hooks**: `./scripts/setup-hooks.sh`
2. **Generate Dialyzer PLTs**: `mix dialyzer --plt`
3. **Start development services**: `docker compose up -d`

### Daily Development
1. **Start Phoenix server**: `mix phx.server`
2. **Make changes** to your code
3. **Run tests**: `mix test`
4. **Check quality** (optional): `mix quality`
5. **Commit changes** - pre-commit hooks run automatically
6. **Push to GitHub** - pre-push hooks + CI/CD pipeline run comprehensive checks

### Quality Assurance
- **Fast checks**: `mix precommit` (formatting, compilation, Credo, Sobelow, tests)
- **Full checks**: `mix quality` (above + Dialyzer type checking)
- **Git hooks**: Automatically enforce quality on commit/push

> 💡 **Tip**: Git hooks will automatically format code and run quality checks. If hooks fail, fix the issues and commit again.

## Useful Commands

### Development
```bash
# Interactive Elixir shell with app loaded
iex -S mix phx.server

# Run specific test file
mix test test/social_circle_web/controllers/page_controller_test.exs

# Reset and seed database with sample data
mix ecto.reset

# Generate new Phoenix components
mix phx.gen.live Posts Post posts title:string content:text

# Check for outdated dependencies
mix hex.outdated
```

### Services Management
```bash
# Start all development services
docker compose up -d

# View service status
docker compose ps

# Stop all services
docker compose down

# View service logs
docker compose logs redis
docker compose logs minio
```

### Tool-specific Commands
```bash
# mise (tool version management)
mise install           # Install tools from .mise.toml
mise current           # Show current tool versions

# just (command runner, if installed)
just --list           # Show available commands
just setup            # Run project setup
just dev              # Start development server
```

## Troubleshooting

### Database Connection Issues
```bash
# Check if PostgreSQL container is running
docker ps

# View database logs
mix db.logs

# Connect to database directly
docker compose exec db psql -U postgres -d social_circle_dev
```

### Code Quality Issues
```bash
# Fix formatting issues
mix format

# Explain Credo suggestions
mix credo explain

# Regenerate Dialyzer PLTs if corrupted
rm -rf priv/plts && mix dialyzer --plt

# View security scan details
mix sobelow --verbose
```

### Development Service Issues
```bash
# Restart all services
docker compose down && docker compose up -d

# Check service health
docker compose ps

# Reset Redis cache
docker compose exec redis redis-cli FLUSHALL

# Access MinIO console
open http://localhost:9001  # admin:minioadmin123

# View MockServer expectations
curl http://localhost:1080/mockserver/status
```

### Asset Issues
```bash
# Reinstall asset tools (no Node.js needed)
mix assets.setup

# Rebuild assets
mix assets.build
```

### Port Conflicts
If port 4000 is in use, you can run on a different port:
```bash
PORT=4001 mix phx.server
```

### Tool Version Issues
```bash
# Check tool versions
mise current

# Install missing tools
mise install

# Update tools
mise upgrade
```