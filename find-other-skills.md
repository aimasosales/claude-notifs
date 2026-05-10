---
name: find-other-skills
description: Lists all available skill files in the current project.
type: skill
---

# Available Skills

The following skill files are present in `.claude/skills/`:

{{#each skills}}
- {{this}}
{{/each}}

> **Tip:** You can add more skills by dropping new `.md` files into this folder.