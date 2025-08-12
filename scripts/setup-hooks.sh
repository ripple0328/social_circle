#!/bin/bash
#
# Setup script for SocialCircle git hooks
# This script creates symbolic links from .git/hooks/ to scripts/hooks/
#

set -e

echo "🔧 Setting up git hooks for SocialCircle..."

# Check if we're in the project root
if [ ! -f "mix.exs" ]; then
    echo "❌ Error: mix.exs not found. Please run this script from the project root."
    exit 1
fi

# Create symbolic links for each hook
HOOKS_DIR="$(pwd)/scripts/hooks"
GIT_HOOKS_DIR="$(pwd)/.git/hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ Error: scripts/hooks directory not found"
    exit 1
fi

# Function to setup a hook
setup_hook() {
    local hook_name="$1"
    local source_hook="$HOOKS_DIR/$hook_name"
    local target_hook="$GIT_HOOKS_DIR/$hook_name"
    
    if [ -f "$source_hook" ]; then
        # Remove existing hook if it exists
        if [ -e "$target_hook" ]; then
            rm "$target_hook"
        fi
        
        # Create symbolic link
        ln -sf "../../scripts/hooks/$hook_name" "$target_hook"
        echo "✅ Linked $hook_name hook"
    fi
}

# Setup available hooks
setup_hook "pre-commit"
setup_hook "pre-push"

echo "🎉 Git hooks setup complete!"
echo ""
echo "The following hooks are now active:"
echo "  • pre-commit: Runs code quality checks (compile, format, test)"
echo "  • pre-push: Runs comprehensive checks before pushing"
echo ""
echo "💡 Tip: You can run 'mix precommit' manually to test the pre-commit checks"