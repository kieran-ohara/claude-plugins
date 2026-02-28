# Claude Plugins Project

## Skill Structure

Skills in this project MUST follow the Claude Marketplace format as documented at:
https://code.claude.com/docs/en/skills

### Required Directory Structure

Each skill must be in its own directory with a `SKILL.md` file as the entry point:

```
plugins/<plugin-name>/skills/
├── skill-name/
│   ├── SKILL.md           # Required: Main instructions with frontmatter
│   ├── template.md        # Optional: Templates for Claude to fill
│   ├── examples/          # Optional: Example outputs
│   └── scripts/           # Optional: Scripts Claude can execute
```

**INCORRECT** ❌
```
skills/
├── skill-name.md
└── another-skill.md
```

**CORRECT** ✅
```
skills/
├── skill-name/
│   └── SKILL.md
└── another-skill/
    └── SKILL.md
```

### SKILL.md Format

Each `SKILL.md` must have YAML frontmatter followed by markdown instructions:

```yaml
---
name: skill-name
description: What this skill does and when to use it
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Grep, Glob
---

Your skill instructions here in markdown...
```

### Key Frontmatter Fields

- **`name`**: Skill identifier (becomes `/skill-name` command). Lowercase, numbers, hyphens only.
- **`description`**: What the skill does. Claude uses this to decide when to apply it. **Recommended.**
- **`disable-model-invocation`**: Set to `true` to prevent Claude from auto-invoking (manual `/skill-name` only).
- **`user-invocable`**: Set to `false` to hide from `/` menu (background knowledge only).
- **`allowed-tools`**: Tools Claude can use without permission when skill is active.
- **`context`**: Set to `fork` to run in isolated subagent.
- **`agent`**: Subagent type when `context: fork` (Explore, Plan, general-purpose, or custom).

### String Substitutions

- `$ARGUMENTS` - All arguments passed when invoking the skill
- `$ARGUMENTS[N]` or `$N` - Specific argument by index
- `${CLAUDE_SESSION_ID}` - Current session ID
- `` !`command` `` - Run shell command, insert output (dynamic context injection)

### Registering Skills in the Manifest

**CRITICAL**: After creating a new skill, you MUST register it in `.claude-plugin/marketplace.json`.

Skills must be added to the `skills` array of the appropriate plugin:

```json
{
  "plugins": [
    {
      "name": "invoice-tools",
      "source": "./plugins/invoice-tools",
      "skills": [
        "./skills/amazon-invoice",
        "./skills/uber-eats-invoice",
        "./skills/xero-invoice-importer"
      ]
    }
  ]
}
```

**Important notes**:
- Skill paths are relative to the plugin's `source` directory
- Skills won't be available until registered in the manifest
- Always update the manifest when creating or removing skills

## References

Official documentation: https://code.claude.com/docs/en/skills
