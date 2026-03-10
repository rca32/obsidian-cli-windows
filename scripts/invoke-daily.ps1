[CmdletBinding()]
param(
    [string]$Vault,
    [ValidateSet('path', 'read', 'append', 'prepend', 'open')]
    [string]$Mode = 'path',
    [string]$Content,
    [switch]$Inline,
    [switch]$Open,
    [ValidateSet('tab', 'split', 'window')]
    [string]$PaneType,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib-common.ps1')

Assert-VaultExists -Vault $Vault

switch ($Mode) {
    'path' { $command = 'daily:path' }
    'read' { $command = 'daily:read' }
    'append' { $command = 'daily:append' }
    'prepend' { $command = 'daily:prepend' }
    'open' { $command = 'daily' }
    default { throw "Unsupported mode: $Mode" }
}

if (($Mode -eq 'append' -or $Mode -eq 'prepend') -and -not $PSBoundParameters.ContainsKey('Content')) {
    throw "Mode '$Mode' requires -Content."
}

$keyValues = @{}
if (-not [string]::IsNullOrWhiteSpace($Vault)) {
    $keyValues['vault'] = $Vault
}
if ($PSBoundParameters.ContainsKey('Content')) {
    $keyValues['content'] = $Content
}
if ($PSBoundParameters.ContainsKey('PaneType')) {
    $keyValues['paneType'] = $PaneType
}

$flags = @()
if ($Inline) { $flags += 'inline' }
if ($Open -and ($Mode -eq 'append' -or $Mode -eq 'prepend')) {
    $flags += 'open'
}

$result = Invoke-ObsidianCommand -Command $command -KeyValues $keyValues -Flags $flags -DryRun:$DryRun

Write-Output "Command: $($result.Command)"
if ($result.DryRun) {
    Write-Output 'DryRun: no command executed.'
}
elseif ($result.Output.Count -gt 0) {
    $result.Output | ForEach-Object { Write-Output $_ }
}

$result
