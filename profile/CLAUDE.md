# Claude Code Global Guidelines

## GitHub Operations

- **Always use GitHub MCP tools** (`mcp__github__*`) for all GitHub operations — PRs, issues, reviews, searching, etc.
- Prefer MCP tools over `gh` CLI whenever an equivalent MCP tool exists (e.g., `mcp__github__create_pull_request`, `mcp__github__pull_request_read`, `mcp__github__list_issues`).

### Git push/pull/fetch (ai-jail sandbox)

The sandbox (ai-jail) blocks `~/.ssh`, so SSH-based git operations fail. Use HTTPS with the `gh` CLI credential helper instead:

```bash
# Push using gh token injected as HTTP header
git -c "http.https://github.com/.extraheader=Authorization: basic $(echo -n "x-access-token:$(gh auth token)" | base64)" push origin <branch>
```

If `gh auth setup-git` has been run by the user, normal `git push`/`git pull` over HTTPS should work directly. If it fails with "could not read Username", fall back to the token injection method above.

## Git & Pull Request Rules

### PR Descriptions
- **Always** include a `## Test plan` section in every PR description with a checklist of verification steps

### Attribution
- **Never** add `Co-Authored-By: Claude` or any similar attribution to commit messages
- **Never** mention Claude, AI, or any AI assistant in commit messages, PR titles, or PR descriptions
- **Never** include phrases like "Generated with Claude Code", "AI-assisted", or similar in any git artifacts
- Write all commit messages and PR descriptions as if authored entirely by the developer
