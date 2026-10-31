# Security Policy

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Report privately via GitHub's **"Report a vulnerability"** button on the repository's *Security* tab (private vulnerability reporting). Include steps to reproduce and the affected version/commit. You can expect an initial response within about 7 days.

## Scope notes

- The app reads local Claude Code logs (`~/.claude/projects`) and, optionally, an Anthropic Admin API key from the `ANTHROPIC_ADMIN_KEY` env var or the macOS Keychain item `claude-buddy-admin-key`.
- The only outbound request is to `api.anthropic.com`.

## If you accidentally commit a secret

Revoke/rotate it immediately (an Admin key can be revoked in the Anthropic Console), then remove it from history. Deleting it in a later commit is not enough.
