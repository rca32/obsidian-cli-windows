# Obsidian CLI Test Cases

## Smoke Suite
1. `obsidian version` returns output.
2. Target vault exists in `obsidian vaults`.
3. Create note with Unicode filename and multiline content.
4. Read created note and verify expected text is present.
5. Search returns created note for a unique token.
6. `daily:path` returns a path.
7. Overwrite protection blocks unsafe overwrite call.

## Full Suite (extends Smoke)
1. Search with context mode.
2. Daily append command validation (DryRun by default, real mutation with `-AllowDailyMutation`).
3. Create with `name=` fallback.
4. File lookup by `path=` and `file=` consistency check.
5. Intentional error case captures failure summary format.

## Acceptance Criteria
1. All smoke tests pass.
2. Full suite failures are reported with case name, error text, and rerun hint.
3. Report files are generated in text and JSON.
4. No manual command editing is required for routine regression checks.

## Common Regression Risks
1. Broken quoting for spaces or Korean characters.
2. `content` truncation on multiline payloads.
3. Path/file ambiguity causing wrong note updates.
4. Silent failures when `obsidian` is not available.
