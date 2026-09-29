# Preflight Skill

Use before any code, config, deployment, or document change.

1. Confirm current directory and repository identity.
2. Read CLAUDE.md and AGENTS.md.
3. Run `.ari/hooks/preflight.sh`.
4. Inspect git status and preserve existing dirty work.
5. Confirm target branch, remote, and deployment target.
6. Stop if repo/path/remote do not match expected project identity.
7. Never use destructive reset/stash automatically to make the tree clean.
