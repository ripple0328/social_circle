# SocialCircle

## Local Development Setup

### Prerequisites
- Docker and Docker Compose
- [mise](https://mise.jdx.dev/) (for managing Elixir/Erlang versions)
- inotify-tools (for file watching)

#### Installation

**Arch Linux / Manjaro:**
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

**macOS:**
```bash
# Install via Homebrew
brew install mise docker docker-compose fswatch

# Install Elixir/Erlang via mise
mise install elixir@1.18 erlang@28
mise use elixir@1.18 erlang@28
```

### Database Setup
1. Start PostgreSQL with Docker Compose:
   ```bash
   docker-compose up -d db
   ```

2. Setup the database:
   ```bash
   mix ecto.setup
   ```

### Running the Application
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

### Database Management
- Create and migrate: `mix ecto.setup`
- Run migrations: `mix ecto.migrate` 
- Rollback migration: `mix ecto.rollback`
- Reset database: `mix ecto.reset`
- Stop database: `docker-compose down`

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
