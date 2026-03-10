[CmdletBinding()]
param(
    [string]$Vault,
    [string]$Path,
    [string]$File,
    [string]$Name,
    [string]$Content,
    [switch]$Overwrite,
    [switch]$Open,
    [switch]$NewTab,
    [switch]$DryRun,
    [switch]$ConfirmRisk
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib-common.ps1')

if ($Overwrite -and -not $ConfirmRisk) {
    throw 'Overwrite requested. Re-run with -ConfirmRisk to acknowledge destructive behavior.'
}

Assert-VaultExists -Vault $Vault
$target = Resolve-NoteTarget -Path $Path -File $File -Name $Name

$keyValues = @{}
if (-not [string]::IsNullOrWhiteSpace($Vault)) {
    $keyValues['vault'] = $Vault
}
$keyValues[$target.Key] = $target.Value
if ($PSBoundParameters.ContainsKey('Content')) {
    $keyValues['content'] = $Content
}

$flags = @()
if ($Overwrite) { $flags += 'overwrite' }
if ($Open) { $flags += 'open' }
if ($NewTab) { $flags += 'newtab' }

$result = Invoke-ObsidianCommand -Command 'create' -KeyValues $keyValues -Flags $flags -DryRun:$DryRun

Write-Output "Command: $($result.Command)"
if ($result.DryRun) {
    Write-Output 'DryRun: no command executed.'
}
elseif ($result.Output.Count -gt 0) {
    $result.Output | ForEach-Object { Write-Output $_ }
}

$result
