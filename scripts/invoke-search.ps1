[CmdletBinding()]
param(
    [string]$Vault,
    [Parameter(Mandatory)]
    [string]$Query,
    [string]$Path,
    [int]$Limit,
    [ValidateSet('text', 'json')]
    [string]$Format = 'text',
    [switch]$Context,
    [switch]$CaseSensitive,
    [switch]$Total,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib-common.ps1')

Assert-VaultExists -Vault $Vault

$command = if ($Context) { 'search:context' } else { 'search' }
$keyValues = @{
    query = $Query
    format = $Format
}

if (-not [string]::IsNullOrWhiteSpace($Vault)) {
    $keyValues['vault'] = $Vault
}
if (-not [string]::IsNullOrWhiteSpace($Path)) {
    $keyValues['path'] = $Path
}
if ($PSBoundParameters.ContainsKey('Limit')) {
    $keyValues['limit'] = [string]$Limit
}

$flags = @()
if ($CaseSensitive) { $flags += 'case' }
if ($Total) { $flags += 'total' }

$result = Invoke-ObsidianCommand -Command $command -KeyValues $keyValues -Flags $flags -DryRun:$DryRun

Write-Output "Command: $($result.Command)"
if ($result.DryRun) {
    Write-Output 'DryRun: no command executed.'
}
elseif ($result.Output.Count -gt 0) {
    $result.Output | ForEach-Object { Write-Output $_ }
}

$result
