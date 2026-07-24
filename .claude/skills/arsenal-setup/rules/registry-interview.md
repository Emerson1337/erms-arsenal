---
title: The registry interview
impact: MEDIUM
tags: [config, registry, interview]
---

# The registry interview

`$CONFIG_DIR/arsenal/projects.json` is the local, never-committed registry that the profile workflow skills read. `daily-checkout` can't run without at least one project in it, so setting one up is part of installation rather than a surprise on first use.

## Shape

```json
{
  "defaultProject": "",
  "projects": {
    "<project-key>": {
      "repos": [{ "name": "", "path": "" }],
      "github": { "org": "", "assignee": "" },
      "tracker": {
        "type": "clickup|jira|linear|github|none",
        "prefix": "",
        "urlTemplate": "",
        "space": ""
      },
      "chat": { "type": "slack|discord|none", "channel": "", "channelId": "" }
    }
  }
}
```

## Ask — but probe first

Every value you can read from a repo, read it and confirm instead of asking cold.

1. **Project key** — the word the user will type after `sleep`. Short, lowercase.
2. **Repos** — name and absolute clone path for each. Verify each: `git -C <path> rev-parse --show-toplevel`. Drop any that fail, and say which.
3. **GitHub org** — from a repo's remote, then confirm:
   ```bash
   git -C <path> remote get-url origin
   ```
4. **Assignee** — the handle PRs get assigned to. Offer `gh api user --jq .login` as the default.
5. **Chat** — provider, destination, and the destination's ID. Explain that an ID is more reliable than a name, and that the skills default to *not* posting until told to.
6. **Tracker** — provider, ticket prefix, URL template. Offer what the commit history shows:
   ```bash
   git -C <path> log --pretty=%s -200 \
     | grep -oE '^\[?[A-Z][A-Z0-9]+-[0-9]+' | sort | uniq -c | sort -rn | head
   ```
   No tracker → `"type": "none"`, and the skills report work as untracked. That's a supported configuration, not a gap.
7. **Default project** — should a bare `sleep` mean this one?

## Write

- Merge into the existing file; **never** replace it. Read, add the project key, write back.
- Validate the JSON before and after (`python3 -m json.tool`).
- A key that already exists → ask before overwriting, and show what would change.
- This file lives outside every git repo on purpose. It holds channel IDs and tracker spaces, and it must never end up in a commit. If the user asks to store it in a repo, say why it isn't.

## Rules

1. Probe, then confirm — don't ask for what a repo can tell you.
2. Verify every repo path; drop and report the ones that fail.
3. Merge into the registry, never overwrite it.
4. Validate JSON on both sides of the write.
5. Keep the registry out of git, always.
