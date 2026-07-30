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

## Response Style

- Be direct and to the point. Answer in the fewest words that fully answer.
- **Explain simply — ELI5.** Plain words, short sentences, one idea at a time. Say "the code runs twice", not "the invocation is duplicated".
- **No metaphors, no analogies, no colorful comparisons.** Describe the actual thing. A metaphor costs tokens and gives the reader a second thing to decode.
- No preamble, no restating the request, no summary of what was just said.
- Conclusion first, then evidence only if it changes a decision. Skip the reasoning tour.
- Reserve bold and bullets for structure that earns them, not decoration.
- Never pad a report to look thorough. If something is done, say it plainly; if it's blocked, say that.

## Code Standards

Clean, reusable, gold-standard code. Full rules with examples in the `clean-code-standards` skill.

- **Never** use `any` — a real type, a generic, or `unknown` plus a type guard. Zod at boundaries.
- **Never** use `as` assertions — write a type guard or validate with Zod. (`as const` and `satisfies` are fine.)
- **Never** suppress a linter or type checker — no `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `--no-verify`. Fix the code, or change the shared config. Never suppress to make a check pass; report the blocker instead.
- **Never** chain or nest ternaries — one level is the hard ceiling. One is fine where a statement can't go (a JSX prop, a short default). Chains become a lookup map; nesting becomes an extracted function with early returns.
- **Comments are a last resort.** Rename, then extract, then comment only what the code cannot express. JSDoc only for APIs consumed outside the repo.
- **Object calisthenics at medium effort** — guard clauses over `else`, one level of indentation, no abbreviations, small units, no reaching through objects.

## Test Plans

- Any requested test plan — standalone or the `## Test plan` section of a PR body — uses the `test-plan` skill's format: numbered scenarios, each with `path:`, a `->` chained `action:`, and its own Before / After (expected) table.
