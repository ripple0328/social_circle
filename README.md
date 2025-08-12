<div align="center">
  <img src="./priv/static/images/logo.svg" alt="SocialCircle Logo" width="80" height="80">
  <h1>SocialCircle</h1>

  [![CI/CD Pipeline](https://github.com/ripple0328/social_circle/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/ripple0328/social_circle/actions/workflows/ci-cd.yml)
  [![Coverage Status](https://coveralls.io/repos/github/ripple0328/social_circle/badge.svg?branch=main)](https://coveralls.io/github/ripple0328/social_circle?branch=main)
  [![Elixir](https://img.shields.io/badge/elixir-1.18-purple.svg)](https://elixir-lang.org)
  [![Phoenix](https://img.shields.io/badge/phoenix-1.8-orange.svg)](https://phoenixframework.org)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

  <p><em>A unified social media management platform that aggregates content from multiple platforms, enables cross-platform posting, and provides deep analytics insights about your digital social life.</em></p>
</div>

## 🚀 Main Features

- **Content Aggregation**: View all your social media posts from X, Facebook, Instagram, Weibo, and LinkedIn in one unified grid layout
- **Cross-Platform Posting**: Write once, post everywhere - create content and automatically sync to all your social platforms
- **Analytics Dashboard**: Track posting frequency, engagement rates, and content performance across platforms
- **Geolocation Insights**: Analyze your activity patterns and travel history from location-tagged posts
- **Social Network Analysis**: Understand your friend circles, community groups, and social interactions
- **Real-time Updates**: Live dashboard with Phoenix LiveView for instant content updates

📋 **See [ROADMAP.md](./ROADMAP.md) for detailed development phases and timeline**

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
