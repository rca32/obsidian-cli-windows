# Obsidian Properties Reference

Use YAML frontmatter at the top of the note for note metadata.

```yaml
---
title: My Note Title
date: 2024-01-15
tags:
  - project
  - important
aliases:
  - My Note
cssclasses:
  - custom-class
status: in-progress
rating: 4.5
completed: false
due: 2024-02-01T14:30:00
---
```

## Property Types

| Type | Example |
|------|---------|
| Text | `title: My Title` |
| Number | `rating: 4.5` |
| Checkbox | `completed: true` |
| Date | `date: 2024-01-15` |
| Date & Time | `due: 2024-01-15T14:30:00` |
| List | `tags: [one, two]` or YAML list |
| Links | `related: "[[Other Note]]"` |

## Default Properties

- `tags` for searchable note labels
- `aliases` for alternative note names and link suggestions
- `cssclasses` for note-specific styling hooks

## Tags

```markdown
#tag
#nested/tag
#tag-with-dashes
#tag_with_underscores
```

Tags may contain letters, numbers except as the first character, underscores, hyphens, and forward slashes. Use frontmatter tags for canonical note metadata and inline tags for lightweight in-body tagging.
