Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-ObsidianAvailable {
    $null = Get-Command obsidian -ErrorAction Stop
}

function Get-ObsidianVaults {
    Assert-ObsidianAvailable
    $output = & obsidian vaults 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Failed to list vaults. $($output -join "`n")"
    }

    return @(
        $output |
        Where-Object { $_ -and $_.Trim() -ne '' } |
        ForEach-Object { $_.Trim() }
    )
}

function Assert-VaultExists {
    param(
        [string]$Vault
    )

    if ([string]::IsNullOrWhiteSpace($Vault)) {
        return
    }

    $vaults = Get-ObsidianVaults
    if ($vaults -notcontains $Vault) {
        throw "Vault '$Vault' not found. Available: $($vaults -join ', ')"
    }
}

function Resolve-NoteTarget {
    param(
        [string]$Path,
        [string]$File,
        [string]$Name
    )

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        return [ordered]@{ Key = 'path'; Value = $Path }
    }

    if (-not [string]::IsNullOrWhiteSpace($File)) {
        return [ordered]@{ Key = 'file'; Value = $File }
    }

    if (-not [string]::IsNullOrWhiteSpace($Name)) {
        return [ordered]@{ Key = 'name'; Value = $Name }
    }

    throw 'A note target is required. Provide Path, File, or Name.'
}

function Add-KeyValueArg {
    param(
        [Parameter(Mandatory)]
        [ref]$Args,

        [Parameter(Mandatory)]
        [string]$Key,

        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return
    }

    if ($Value -eq '') {
        return
    }

    $Args.Value += "$Key=$Value"
}

function Format-CommandPreview {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $parts = foreach ($arg in $Arguments) {
        if ($arg -match '[\s"]') {
            '"' + $arg.Replace('"', '`"') + '"'
        }
        else {
            $arg
        }
    }

    return 'obsidian ' + [string]::Join(' ', $parts)
}

function Invoke-ObsidianCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [hashtable]$KeyValues = @{},

        [string[]]$Flags = @(),

        [switch]$DryRun,

        [switch]$AllowFailure
    )

    Assert-ObsidianAvailable

    $argsList = @($Command)
    foreach ($key in $KeyValues.Keys) {
        $value = $KeyValues[$key]
        if ($null -eq $value -or $value -eq '') {
            continue
        }

        $argsList += "$key=$value"
    }

    foreach ($flag in $Flags) {
        if ([string]::IsNullOrWhiteSpace($flag)) {
            continue
        }

        $argsList += $flag
    }

    $preview = Format-CommandPreview -Arguments $argsList

    if ($DryRun) {
        return [pscustomobject]@{
            Command  = $preview
            ExitCode = 0
            Output   = @()
            DryRun   = $true
        }
    }

    $output = & obsidian @argsList 2>&1
    $exitCode = $LASTEXITCODE

    $result = [pscustomobject]@{
        Command  = $preview
        ExitCode = $exitCode
        Output   = @($output)
        DryRun   = $false
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $message = "Command failed with exit code $exitCode`n$preview`n$($output -join "`n")"
        throw $message
    }

    return $result
}

function New-TestResult {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [bool]$Passed,

        [double]$DurationMs,

        [string]$Error,

        [string]$Command
    )

    return [pscustomobject]@{
        Name       = $Name
        Passed     = $Passed
        DurationMs = [Math]::Round($DurationMs, 2)
        Error      = $Error
        Command    = $Command
    }
}

function Write-TestReport {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Results,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [string]$Suite = 'smoke',

        [string]$Vault = ''
    )

    if (-not (Test-Path -Path $OutputPath)) {
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $txtPath = Join-Path $OutputPath "obsidian-cli-test-$Suite-$timestamp.txt"
    $jsonPath = Join-Path $OutputPath "obsidian-cli-test-$Suite-$timestamp.json"

    $total = $Results.Count
    $passed = @($Results | Where-Object { $_.Passed }).Count
    $failed = $total - $passed

    $lines = @()
    $lines += "suite: $Suite"
    $lines += "vault: $Vault"
    $lines += "timestamp: $timestamp"
    $lines += "total: $total"
    $lines += "passed: $passed"
    $lines += "failed: $failed"
    $lines += ''

    foreach ($result in $Results) {
        $status = if ($result.Passed) { 'PASS' } else { 'FAIL' }
        $lines += "[$status] $($result.Name) ($($result.DurationMs) ms)"
        if (-not $result.Passed -and $result.Error) {
            $lines += "  error: $($result.Error)"
        }
        if ($result.Command) {
            $lines += "  command: $($result.Command)"
        }
    }

    Set-Content -Path $txtPath -Value $lines -Encoding utf8

    $json = [pscustomobject]@{
        suite     = $Suite
        vault     = $Vault
        timestamp = $timestamp
        total     = $total
        passed    = $passed
        failed    = $failed
        results   = $Results
    }

    $json | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding utf8

    return [pscustomobject]@{
        TextPath = $txtPath
        JsonPath = $jsonPath
        Total    = $total
        Passed   = $passed
        Failed   = $failed
    }
}
