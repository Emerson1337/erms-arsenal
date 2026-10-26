#!/bin/sh
# PreToolUse hook on Write|Edit. Injects the clean-code-standards rules whenever
# the target file is TypeScript or JavaScript. Silent for every other file type.

file_path=$(jq -r '.tool_input.file_path // empty')

case "$file_path" in
  *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

# No apostrophes in the text below: bash 3.2 (macOS /bin/sh) mis-parses a lone single quote
# inside a heredoc nested in command substitution.
reminder=$(cat <<'RULES'
clean-code-standards apply to this file. They are non-negotiable and they win over any
framework-specific guidance on conflict.

Hard bans — this edit does not ship with any of them:
- `any`. Use a real type, a generic, or `unknown` plus a type guard. Zod at boundaries.
- `as` assertions. Write a type guard or validate with Zod. `as const` and `satisfies` are fine.
- Lint or type-checker suppression: `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `--no-verify`.
  Fix the code or change the shared config. Never suppress to make a check pass — report the blocker.
- Chained or nested ternaries. One level is the ceiling. A chain becomes a lookup map; nesting
  becomes an extracted function with early returns.

Also enforced:
- Comments are a last resort. The default is no comment. Rename, then extract a named function or
  constant, and only then comment — and only for what the code cannot express (an external policy,
  a vendor bug, a deliberate trade-off, a `TODO(#id)` with a removal condition). No comment that
  restates the code. JSDoc only for APIs consumed outside this repo.
- Object calisthenics at medium effort: guard clauses over `else`, one level of indentation, no
  abbreviations, small units, one dot per line, first-class collections.

Read the rules/ files in the `clean-code-standards` skill for the worked examples before deciding
that an exception is warranted.
RULES
)

jq -n --arg context "$reminder" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $context
  },
  suppressOutput: true
}'
