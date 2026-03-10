# Obsidian Callouts Reference

## Basic Callouts

```markdown
> [!note]
> This is a note callout.

> [!info] Custom Title
> This callout has a custom title.
```

## Foldable Callouts

```markdown
> [!faq]- Collapsed by default
> Hidden until expanded.

> [!faq]+ Expanded by default
> Visible but still foldable.
```

## Nested Callouts

```markdown
> [!question] Outer callout
> > [!note] Inner callout
> > Nested content
```

## Supported Types

| Type | Aliases |
|------|---------|
| `note` | - |
| `abstract` | `summary`, `tldr` |
| `info` | - |
| `todo` | - |
| `tip` | `hint`, `important` |
| `success` | `check`, `done` |
| `question` | `help`, `faq` |
| `warning` | `caution`, `attention` |
| `failure` | `fail`, `missing` |
| `danger` | `error` |
| `bug` | - |
| `example` | - |
| `quote` | `cite` |

Use callouts for highlighted note sections, not for external Markdown renderers that do not support Obsidian syntax.
