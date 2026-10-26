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

### Commit Messages
- Follow [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `<type>(<optional scope>): <description>`, with an optional body and footers. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Mark breaking changes with `!` after the type/scope or a `BREAKING CHANGE:` footer.

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

## Code Standards (MANDATORY — always in force)

These apply to **every** line of TypeScript or JavaScript you write, edit, or review, in every
project, whether or not I mention them. They are not a style preference and they are not scoped to a
particular task. On conflict with any framework guidance, a `frontend-*-best-practices` skill, or an
existing pattern in the file, **these win**.

**Load the `clean-code-standards` skill before writing or reviewing TS/JS** — it carries the worked
examples for all six rules. A `PreToolUse` hook also injects the rules on every TS/JS edit; treat that
injection as binding, not advisory.

The four hard bans are absolute. Never trade one away for speed, for consistency with surrounding
code, or to make a check pass. If a rule genuinely cannot be met, stop and tell me what is blocking
it — do not ship the violation and do not ask forgiveness in a comment.

- **Never** use `any` — a real type, a generic, or `unknown` plus a type guard. Zod at boundaries.
- **Never** use `as` assertions — write a type guard or validate with Zod. (`as const` and `satisfies` are fine.)
- **Never** suppress a linter or type checker — no `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `--no-verify`. Fix the code, or change the shared config. Never suppress to make a check pass; report the blocker instead.
- **Never** chain or nest ternaries — one level is the hard ceiling. One is fine where a statement can't go (a JSX prop, a short default). Chains become a lookup map; nesting becomes an extracted function with early returns.
- **Never write comments.** Produce zero comments in any code you write, and strip the ones you were about to write. Rename, then extract. The only exception is a *why* the code genuinely cannot express — one line, and only where its absence would mislead the next reader. Never narrate what the code already says, never leave a comment to justify a decision, and never add JSDoc unless the API is consumed outside the repo. Existing comments on lines you are not touching stay as they are.
- **Object calisthenics at medium effort** — guard clauses over `else`, one level of indentation, no abbreviations, small units, no reaching through objects.

## Test Plans

- Any requested test plan — standalone or the `## Test plan` section of a PR body — uses the `test-plan` skill's format: numbered scenarios, each with `path:`, a `->` chained `action:`, and its own Before / After (expected) table.
