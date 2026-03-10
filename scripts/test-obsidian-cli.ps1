[CmdletBinding()]
param(
    [string]$Vault,
    [ValidateSet('smoke', 'full')]
    [string]$Suite = 'smoke',
    [string]$OutputPath,
    [switch]$StopOnFail,
    [switch]$AllowDailyMutation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib-common.ps1')

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot '..\\artifacts'
}

$createScript = Join-Path $PSScriptRoot 'invoke-create.ps1'
$searchScript = Join-Path $PSScriptRoot 'invoke-search.ps1'
$dailyScript = Join-Path $PSScriptRoot 'invoke-daily.ps1'

function Get-ResultObject {
    param([object[]]$Stream)

    $result = $Stream | Where-Object {
        $_ -is [psobject] -and
        $_.PSObject.Properties.Name -contains 'Command' -and
        $_.PSObject.Properties.Name -contains 'ExitCode'
    } | Select-Object -Last 1

    if (-not $result) {
        throw 'No command result object was returned.'
    }

    return $result
}

$effectiveVault = $Vault
if ([string]::IsNullOrWhiteSpace($effectiveVault)) {
    $vaults = Get-ObsidianVaults
    if ($vaults.Count -eq 0) {
        throw 'No vaults available. Open Obsidian and create or register a vault first.'
    }

    $effectiveVault = $vaults[0]
}

Assert-VaultExists -Vault $effectiveVault

$script:results = New-Object 'System.Collections.Generic.List[object]'
$token = Get-Date -Format 'yyyyMMdd-HHmmss'
$notePath = "tmp/obsidian-cli-tests/smoke-$token-한글.md"
$noteByName = "obtest-name-$token.md"
$searchToken = "obtest-$token"
$noteContent = @"
# Obsidian CLI Smoke
$searchToken
line-2
"@

function Invoke-Case {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [scriptblock]$Body,
        [switch]$ExpectedFailure
    )

    $started = Get-Date
    $commandPreview = ''

    try {
        $value = & $Body
        if ($value -is [psobject] -and ($value.PSObject.Properties.Name -contains 'Command')) {
            $commandPreview = [string]$value.Command
        }

        if ($ExpectedFailure) {
            throw 'Expected failure but case succeeded.'
        }

        $duration = ((Get-Date) - $started).TotalMilliseconds
        $script:results.Add((New-TestResult -Name $Name -Passed $true -DurationMs $duration -Error '' -Command $commandPreview))
    }
    catch {
        $duration = ((Get-Date) - $started).TotalMilliseconds
        if ($ExpectedFailure) {
            $script:results.Add((New-TestResult -Name $Name -Passed $true -DurationMs $duration -Error '' -Command $commandPreview))
            return
        }

        $script:results.Add((New-TestResult -Name $Name -Passed $false -DurationMs $duration -Error $_.Exception.Message -Command $commandPreview))
        if ($StopOnFail) {
            throw
        }
    }
}

Invoke-Case -Name 'version command works' -Body {
    $res = Invoke-ObsidianCommand -Command 'version'
    if ($res.ExitCode -ne 0) {
        throw 'version command failed.'
    }

    $res
}

Invoke-Case -Name 'target vault exists' -Body {
    $vaults = Get-ObsidianVaults
    if ($vaults -notcontains $effectiveVault) {
        throw "Vault '$effectiveVault' not found in vault list."
    }

    [pscustomobject]@{ Command = 'obsidian vaults' }
}

Invoke-Case -Name 'create note with unicode and multiline content' -Body {
    $raw = & $createScript -Vault $effectiveVault -Path $notePath -Content $noteContent -Overwrite -ConfirmRisk
    $res = Get-ResultObject -Stream @($raw)
    if ($res.ExitCode -ne 0) {
        throw 'Create command returned non-zero exit code.'
    }

    $res
}

Invoke-Case -Name 'read note and verify token' -Body {
    $res = Invoke-ObsidianCommand -Command 'read' -KeyValues @{ vault = $effectiveVault; path = $notePath }
    $joined = $res.Output -join "`n"
    if ($joined -notmatch [Regex]::Escape($searchToken)) {
        throw 'Expected search token was not found in note content.'
    }

    $res
}

Invoke-Case -Name 'search finds created token' -Body {
    $raw = & $searchScript -Vault $effectiveVault -Query $searchToken -Path 'tmp/obsidian-cli-tests' -Format 'text'
    $res = Get-ResultObject -Stream @($raw)
    $joined = $res.Output -join "`n"
    if ([string]::IsNullOrWhiteSpace($joined)) {
        throw 'Search output is empty.'
    }

    $res
}

Invoke-Case -Name 'daily path is readable' -Body {
    $raw = & $dailyScript -Vault $effectiveVault -Mode 'path'
    $res = Get-ResultObject -Stream @($raw)
    $joined = $res.Output -join "`n"
    if ([string]::IsNullOrWhiteSpace($joined)) {
        throw 'daily:path returned empty output.'
    }

    $res
}

Invoke-Case -Name 'overwrite protection blocks unsafe call' -ExpectedFailure -Body {
    & $createScript -Vault $effectiveVault -Path $notePath -Content 'x' -Overwrite | Out-Null
    [pscustomobject]@{ Command = 'invoke-create.ps1 -Overwrite (no ConfirmRisk)' }
}

if ($Suite -eq 'full') {
    Invoke-Case -Name 'search context returns output' -Body {
        $raw = & $searchScript -Vault $effectiveVault -Query $searchToken -Path 'tmp/obsidian-cli-tests' -Context -Format 'text'
        $res = Get-ResultObject -Stream @($raw)
        if (($res.Output -join "`n").Length -lt 1) {
            throw 'search:context output is empty.'
        }

        $res
    }

    Invoke-Case -Name 'daily append command is valid (dry run by default)' -Body {
        if ($AllowDailyMutation) {
            $append = & $dailyScript -Vault $effectiveVault -Mode 'append' -Content "- [ ] test-$token"
            $appendRes = Get-ResultObject -Stream @($append)
            if ($appendRes.ExitCode -ne 0) {
                throw 'daily:append failed.'
            }

            $read = & $dailyScript -Vault $effectiveVault -Mode 'read'
            $readRes = Get-ResultObject -Stream @($read)
            if (($readRes.Output -join "`n") -notmatch [Regex]::Escape("test-$token")) {
                throw 'daily:read does not contain appended marker.'
            }

            return $readRes
        }

        $dry = & $dailyScript -Vault $effectiveVault -Mode 'append' -Content "- [ ] test-$token" -DryRun
        $dryRes = Get-ResultObject -Stream @($dry)
        if (-not $dryRes.DryRun) {
            throw 'Expected DryRun mode for default daily append test.'
        }

        $dryRes
    }

    Invoke-Case -Name 'create by name fallback' -Body {
        $raw = & $createScript -Vault $effectiveVault -Name $noteByName -Content "name fallback $token" -Overwrite -ConfirmRisk
        $res = Get-ResultObject -Stream @($raw)
        if ($res.ExitCode -ne 0) {
            throw 'Create by name failed.'
        }

        $res
    }

    Invoke-Case -Name 'path/file consistency check' -Body {
        $pathRes = Invoke-ObsidianCommand -Command 'file' -KeyValues @{ vault = $effectiveVault; path = $notePath }
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($noteByName)
        $fileRes = Invoke-ObsidianCommand -Command 'file' -KeyValues @{ vault = $effectiveVault; file = $fileName }
        if ($pathRes.ExitCode -ne 0 -or $fileRes.ExitCode -ne 0) {
            throw 'file info command failed.'
        }

        $pathRes
    }

    Invoke-Case -Name 'intentional command error is captured' -ExpectedFailure -Body {
        $res = Invoke-ObsidianCommand -Command 'not-a-real-command' -AllowFailure
        if ($res.ExitCode -eq 0) {
            throw 'Expected non-zero exit code for invalid command.'
        }

        $res
    }
}

$report = Write-TestReport -Results $script:results.ToArray() -OutputPath $OutputPath -Suite $Suite -Vault $effectiveVault

Write-Output "Suite: $Suite"
Write-Output "Vault: $effectiveVault"
Write-Output "Passed: $($report.Passed) / $($report.Total)"
Write-Output "Text Report: $($report.TextPath)"
Write-Output "JSON Report: $($report.JsonPath)"

if ($report.Failed -gt 0) {
    exit 1
}

exit 0
