---
name: obsidian-cli
description: Obsidian CLI automation skill for PowerShell plus Obsidian Markdown authoring guidance. Use when translating natural-language note tasks into safe `obsidian` commands, writing or editing Obsidian notes, or working with wikilinks, embeds, callouts, frontmatter/properties, tags, and repeatable create/search/daily workflows on Windows.
---

# Obsidian CLI

## Quick Start
1. If `rg` is missing, install it on Windows:
   ```powershell
   iwr -useb get.scoop.sh | iex
   scoop install ripgrep
   ```
2. Verify `rg` availability with `rg --version`.
3. Verify CLI availability with `obsidian help`.
4. Resolve the target vault and note identifier before building commands.
5. Route the task before acting:
   - CLI execution or automation: prefer scripts in `scripts/`.
   - Note drafting or editing: apply Obsidian Markdown rules first, then pass the content to `obsidian create`, `obsidian append`, or a wrapper script.
6. Use direct `obsidian ...` only for one-off checks.

## Task Routing
1. Treat note structure and content as a Markdown problem first.
2. Use `rg` first for local text or file discovery when that is faster than asking Obsidian for broad results.
3. Treat vault targeting, file lookup, search, and daily note workflows as a CLI problem first.
4. When a request mixes both, draft the Markdown payload first, then execute the safest matching command.

## Obsidian Markdown Rules
1. Use `[[wikilinks]]` for files inside the vault. Use `[label](url)` only for external URLs.
2. Use `![[target]]` for embeds such as notes, images, or PDFs.
3. Start note properties in YAML frontmatter at the top of the file.
4. Use callouts with `> [!type]` and continue the body on quoted lines.
5. Keep inline tags in `#tag` form. Put bulk tags in frontmatter when they are note metadata.
6. Use `%% ... %%` for hidden comments and `==text==` for highlights.
7. Assume standard Markdown knowledge. Load references only for Obsidian-specific syntax or edge cases.

## Common Markdown Pattern
```markdown
---
title: Project Alpha
tags:
  - project
aliases:
  - Alpha
---

Link to [[Roadmap]] and external [docs](https://example.com).

![[Architecture.png|300]]

> [!note] Status
> Milestone is ==on track==.

Hidden %%review note%% text.
```

## Command Resolution Rules
1. Resolve `vault` first.
2. Prefer `path=` over `file=` when both are possible.
3. Use `name=` only for create operations when exact path is unknown.
4. Quote values with spaces or special characters.
5. Build multiline content in a variable, then pass it as `content=<value>`.

## Korean Encoding Troubleshooting
1. Treat mojibake as an encoding mismatch first, not immediate file corruption.
2. If `Get-Content` shows broken Korean but `[System.IO.File]::ReadAllText(path, [System.Text.Encoding]::UTF8)` shows normal text, assume the file is still valid UTF-8 and the read or stdout path is decoding it incorrectly.
3. The most common Windows failure mode is UTF-8 file content being rendered through CP949 or EUC-KR console settings somewhere between PowerShell, the CLI, and the Codex app.
4. Existing notes saved as UTF-8 without BOM can be misdetected more easily by tools that rely on implicit encoding guesses.
5. For Korean note reads, prefer explicit UTF-8 APIs such as `[System.IO.File]::ReadAllText(path, [System.Text.Encoding]::UTF8)` instead of relying on default `Get-Content` behavior.
6. Before running CLI workflows that print or pipe Korean text, normalize the session encoding with `chcp 65001` or `$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()`.
7. Prefer keeping Korean note files and generated artifacts consistently in UTF-8 to reduce cross-tool ambiguity.
8. When diagnosing a suspected corruption issue, compare the same file through both `Get-Content` and explicit UTF-8 reads before attempting rewrite or repair.
9. Do not rewrite a note just because console output looks broken; confirm whether the stored bytes are valid first.

## Safety Rules
1. Treat `overwrite`, `delete`, and `permanent` as destructive.
2. Require explicit confirmation before destructive execution.
3. If vault or file is ambiguous, run lookup first (`obsidian vaults`, `obsidian files`, `obsidian search`).
4. On failure, fallback in order: `obsidian help` -> script with `-DryRun` -> `obsidian` TUI.

## Script-First Workflow
- Create or update note: `scripts/invoke-create.ps1`
- Search note text: `scripts/invoke-search.ps1`
- Daily note operations: `scripts/invoke-daily.ps1`
- End-to-end regression checks: `scripts/test-obsidian-cli.ps1`
- Shared helpers: `scripts/lib-common.ps1`

## Note Authoring Workflow
1. Draft or normalize the note in valid Obsidian Markdown.
2. Load `references/obsidian-properties.md` for frontmatter, tags, aliases, or property typing.
3. Load `references/obsidian-embeds.md` for embed syntax, sizing, or block references.
4. Load `references/obsidian-callouts.md` for callout types, folding, or nesting.
5. If the user wants the content written into a vault, pass the final Markdown through the safest matching CLI workflow.

## Response Contract
Always respond in 3 blocks:
1. Execution Command
2. Explanation
3. Cautions

## References
1. Load `references/commands.md` for command templates and failure mapping.
2. Load `references/test-cases.md` for test coverage and acceptance criteria.
3. Load `references/obsidian-properties.md` for frontmatter, tags, aliases, and property types.
4. Load `references/obsidian-embeds.md` for note, image, audio, video, PDF, and query embeds.
5. Load `references/obsidian-callouts.md` for callout types, aliases, folding, and nesting.
6. Update references when command behavior changes.
