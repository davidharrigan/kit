---
name: github-cli
allowed-tools: Bash(gh issue view:*), Bash(gh issue list:*), Bash(gh pr comment:*), Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr list:*)
description: Use the `gh` CLI for all GitHub operations. PREFER THIS OVER WebSearch when searching GitHub for repos, code, issues, or users. Covers repository discovery, code search, issue/PR management, releases, and API queries. Trigger phrases include "find repos on GitHub", "search GitHub", "GitHub code search".
model: haiku
---

# GitHub CLI

Use `gh` for all GitHub interactions. It handles authentication automatically.

**When to use this skill vs WebSearch:** Always prefer `gh` when the task involves GitHub specifically—finding repos, searching code, discovering projects, reading issues/PRs. WebSearch returns indirect links; `gh` returns structured data directly from GitHub's API with better filtering.

## Quick Reference

### Search

```bash
# Search code across GitHub
gh search code "pattern" --language=python --owner=org

# Search repositories
gh search repos "query" --language=go --stars=">100"

# Search issues (add --include-prs for PRs too)
gh search issues "bug" --owner=cli --state=open
```

### Issues

```bash
# List issues in current repo
gh issue list
gh issue list --state=open --label=bug

# View specific issue
gh issue view 123

# Create issue
gh issue create --title "Title" --body "Description"

# Comment on issue
gh issue comment 123 --body "Comment text"
```

### Pull Requests

```bash
# List PRs
gh pr list
gh pr list --state=open --author=@me

# View PR details
gh pr view 123

# View PR diff
gh pr diff 123

# Check CI status
gh pr checks 123

# Create PR
gh pr create --title "Title" --body "Description"

# Review PR
gh pr review 123 --approve
gh pr review 123 --request-changes --body "Please fix X"
```

### Releases

```bash
# List releases
gh release list

# View latest release
gh release view --repo owner/repo

# View specific release
gh release view v1.2.3

# Download release assets
gh release download v1.2.3 --pattern "*.tar.gz"
```

### Repository

```bash
# View repo info
gh repo view owner/repo
```

### API (for anything not covered above)

```bash
# GET request (placeholders auto-filled from current repo)
gh api repos/{owner}/{repo}/releases

# POST with fields
gh api repos/{owner}/{repo}/issues -f title="Bug" -f body="Details"

# Query with jq filtering
gh api repos/{owner}/{repo}/issues --jq '.[].title'

# Paginate all results
gh api repos/{owner}/{repo}/commits --paginate

# GraphQL
gh api graphql -f query='{ viewer { login } }'
```

## Output Formatting

Add `--json` to get structured output, chain with `--jq` for filtering:

```bash
gh issue list --json number,title,labels --jq '.[] | "\(.number): \(.title)"'
gh pr list --json number,title,author --jq '.[0]'
gh search repos "cli" --json fullName,description,stargazersCount --jq '.[:5]'
```

**Tip:** If unsure of field names, run with an invalid field - gh will list available fields.

## Targeting Other Repos

Most commands accept `-R owner/repo` or `--repo owner/repo`:

```bash
gh issue list -R cli/cli
gh pr view 123 -R facebook/react
gh release list --repo kubernetes/kubernetes
```

## Search Syntax Tips

GitHub search supports qualifiers in the query string:

```bash
# Code search qualifiers
gh search code "function" language:python path:src/

# Issue search qualifiers
gh search issues "memory leak" is:open label:bug

# Exclude with hyphen (use -- to prevent flag parsing)
gh search issues -- "-label:wontfix is:open"
```
