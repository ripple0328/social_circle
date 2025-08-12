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

1. Start PostgreSQL with Docker Compose:
   ```bash
   docker-compose up -d db
   ```

2. Setup the database:
   ```bash
   mix ecto.setup
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
- Stop database: `docker-compose down`

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

### Code Quality

The project includes pre-commit hooks that automatically run:
- Code compilation with warnings as errors
- Code formatting (`mix format`)
- Dependency cleanup
- Test coverage generation

Run quality checks manually:
```bash
# Run all pre-commit checks
mix precommit

# Individual checks
mix compile --warnings-as-errors
mix format --check-formatted
mix coveralls.html
```

## Development Workflow

1. **Make changes** to your code
2. **Run tests** with `mix test` 
3. **Check formatting** with `mix format`
4. **Commit changes** - pre-commit hooks will run automatically
5. **Push to GitHub** - CI/CD pipeline will run tests and coverage

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
docker-compose logs db

# Connect to database directly
docker-compose exec db psql -U postgres -d social_circle_dev
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