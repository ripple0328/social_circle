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

## 📚 Documentation

- 📋 **[ROADMAP.md](./ROADMAP.md)** - Development phases and timeline
- 🛠️ **[DEVELOPMENT.md](./DEVELOPMENT.md)** - Local development setup and workflow
- 🚀 **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Production deployment guide

## 🌐 Live Demo

Visit the live application at **[social.qingbo.us](https://social.qingbo.us)**

## 🛠️ Development

**Quick Start:**
```bash
# Setup development environment
./scripts/setup-hooks.sh     # Git hooks (one-time)
docker compose up -d          # Start services  
mix deps.get                  # Dependencies
mix ecto.setup                # Database + seeds
mix dialyzer --plt            # Type checking setup
mix phx.server                # Start Phoenix
```

**Quality Tools:**
- 🔍 **Credo** - Static code analysis
- 🔒 **Sobelow** - Security scanning  
- 🎯 **Dialyzer** - Type checking
- ✅ **ExCoveralls** - Test coverage
- 🪝 **Git Hooks** - Automated quality checks

## 🤝 Contributing

We welcome contributions! Please check out:
1. [Development Guide](./DEVELOPMENT.md) for comprehensive setup
2. [GitHub Issues](https://github.com/ripple0328/social_circle/issues) for feature requests and bugs
3. [Pull Request Guidelines](./DEVELOPMENT.md#development-workflow)
