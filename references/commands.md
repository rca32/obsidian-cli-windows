# Obsidian CLI Command Templates

## Target Resolution
1. Resolve `vault` first. If missing, use active vault or ask for explicit name.
2. For note targets, prefer `path` over `file`.
3. Use `name` only with `create` when exact path is not required.

## Create or Update
### Script
```powershell
.\scripts\invoke-create.ps1 -Vault "kb" -Path "Notes/daily.md" -Content "hello" -DryRun
```

### Raw CLI
```powershell
obsidian create vault="kb" path="Notes/daily.md" content="hello"
obsidian create vault="kb" path="Notes/daily.md" content="hello" overwrite
```

## Search
### Script
```powershell
.\scripts\invoke-search.ps1 -Vault "kb" -Query "risk" -Path "Notes" -Format json
```

### Raw CLI
```powershell
obsidian search vault="kb" query="risk" path="Notes" format=json
obsidian search:context vault="kb" query="risk" limit=20
```

## Daily Note
### Script
```powershell
.\scripts\invoke-daily.ps1 -Vault "kb" -Mode append -Content "- [ ] follow up"
```

### Raw CLI
```powershell
obsidian daily:path vault="kb"
obsidian daily:read vault="kb"
obsidian daily:append vault="kb" content="- [ ] task"
obsidian daily:prepend vault="kb" content="# plan"
```

## Test Runner
```powershell
.\scripts\test-obsidian-cli.ps1 -Vault "kb" -Suite smoke
.\scripts\test-obsidian-cli.ps1 -Vault "kb" -Suite full -OutputPath ".\artifacts"
.\scripts\test-obsidian-cli.ps1 -Vault "kb" -Suite full -AllowDailyMutation
```

## Failure Mapping
1. `Error: File ... not found`
- Verify target with `obsidian files vault="..."`.
- Retry with exact `path=`.

2. `Missing required parameter: content`
- Ensure `content` is non-empty.
- For intentional blank line append, pass a single space.

3. `Vault not found` or empty output
- Check vault name with `obsidian vaults`.
- Retry with explicit `vault=`.

4. CLI command unknown
- Run `obsidian help` and update script templates.

## Destructive Flags
1. Require explicit confirmation for `overwrite`, `delete`, `permanent`.
2. Use `-DryRun` first when running new automation.
