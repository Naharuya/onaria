param([string]$Device, [switch]$Buddhist)
$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot 'android-release.mjs'
$installerArgs = @()
if ($Buddhist) { $installerArgs += '--buddhist' }
if ($Device) { $installerArgs += $Device }
& node $installer @installerArgs
if ($LASTEXITCODE -ne 0) { throw 'Release update stopped. Existing app was not deleted.' }
