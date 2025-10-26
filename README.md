# dotrun-jvpalma

A personal DotRun collection providing productivity scripts and aliases for git workflows, AI-assisted development, and system management.

## 📦 What's Included

### Aliases

- **Navigation** (`01-navigation.aliases`) - Quick directory navigation shortcuts
- **Git** (`15-git.aliases`) - Git and yadm workflow aliases
- **Linux** (`20-linux.aliases`) - System utilities (batcat, CPU management)
- **Main** (`25-main.aliases`) - Development tools and Claude CLI shortcuts
- **System** (`30-system.aliases`) - Shell conveniences (clear, eza listing, ip)

### Scripts

#### Git Workflows

- **Branch Management** - Smart checkout with auto-creation and remote tracking
- **Commit Helpers** - Auto-squash commits, fetch utilities, pull-rebase workflows
- **PR Tools** - Draft/ready PR management, code review generation, PR stats
- **Status & Diff** - Enhanced git status display, tree-view change visualization

#### AI-Assisted Development

- **aic.sh** - AI-generated commit messages using Claude
- **aip.sh** - AI-generated PR descriptions using Claude

#### System Tools

- **tmux** - Session management helpers
- **yadm** - Dotfile repository setup and management

## 🚀 Installation

### Prerequisites

- [DotRun](https://github.com/jvPalma/dotrun) v3.0+
- Git configured with `user.name`
- Optional: GitHub CLI (`gh`), Claude CLI (`claude`)

### Install Collection

```bash
# Clone the repository
git clone https://github.com/jvPalma-anchorage/dotrun-jvpalma.git ~/.config/dotrun-collections/dotrun-jvpalma

# Install to DotRun (if collection installer available)
dr collections install dotrun-jvpalma

# Or manually symlink/copy to your dotrun config:
cp -r ~/dotrun-jvpalma/aliases/* ~/.config/dotrun/aliases/
cp -r ~/dotrun-jvpalma/scripts/* ~/.config/dotrun/scripts/

# Reload aliases
dr aliases reload
```

## 📖 Usage Examples

### Git Workflows

```bash
# Smart branch checkout (creates if doesn't exist)
co feature-branch

# AI-generated commit message
dr aic

# AI-generated PR description
dr aip

# Quick commit and push
cmm

# Fetch and rebase on master
gprum

# Create PR as draft
prDraft

# Mark PR as ready for review
prReady 123
```

### Navigation

```bash
# Navigate up multiple directories
...  # cd ../..
.... # cd ../../..
```

### System Utilities

```bash
# Enhanced directory listing (using eza)
ll

# Tmux session management
tm           # Attach or create default session
tm myproject # Attach or create named session
tmm          # List all sessions
```

## ⚙️ Configuration

### Git Username

Scripts automatically use your git configured username:

```bash
git config --get user.name
```

For branch operations and fetch patterns, ensure this is set correctly.

### Required Environment Variables

These are set by DotRun automatically:

- `$DR_CONFIG` - Points to `~/.config/dotrun`
- `$HOME` - Your home directory

## 🔧 Customization

### Branch Naming Convention

The `co` script supports username-prefixed branches (e.g., `username/FEATURE-123-description`). It automatically:

- Normalizes to your git username
- Uppercases the first token after the first hyphen
- Creates local tracking branches for remotes

### AI Prompts

AI-assisted scripts expect prompts at:

- `~/.config/ai-context/prompts/git-prompts/commit-prompt.txt`
- `~/.config/ai-context/prompts/git-prompts/pr-prompt.txt`

## 📝 Scripts Reference

### Git Scripts

| Script                | Description                       |
| --------------------- | --------------------------------- |
| `branchName.sh`       | Display current branch name       |
| `co.sh`               | Smart checkout with auto-creation |
| `autosquashCommit.sh` | Auto-squash commit workflow       |
| `fetch.sh`            | Fetch master and user branches    |
| `master.sh`           | Update master branch              |
| `prum.sh`             | Pull master and force-push        |
| `treeChanges.sh`      | Visualize file changes as tree    |
| `codeRev.sh`          | Generate diff for code review     |
| `prDraft.sh`          | Create draft PR                   |
| `prFix.sh`            | Fix PR labels/reviewers           |
| `prReady.sh`          | Mark PR as ready                  |
| `prReview.sh`         | Run AI code review on PR          |
| `gitStatus.sh`        | Enhanced git/yadm status          |
| `prStats.sh`          | PR metrics and statistics         |

### AI Scripts

| Script   | Description                  |
| -------- | ---------------------------- |
| `aic.sh` | AI-generated commit messages |
| `aip.sh` | AI-generated PR descriptions |

### System Scripts

| Script         | Description                |
| -------------- | -------------------------- |
| `tm.sh`        | Tmux session manager       |
| `setupRepo.sh` | Initialize yadm repository |
| `yadd.sh`      | Stage yadm dotfiles        |

## 🌍 Platform Support

Tested on:

- Ubuntu 22.04+
- Debian-based distributions
- macOS (partial - some scripts may need adjustments)

## 🤝 Contributing

This is a personal collection, but feel free to fork and adapt for your own use!

## 📄 License

MIT - Feel free to use and modify as needed.

## 👤 Author

jvPalma - (Joao Palma)
