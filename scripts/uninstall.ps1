[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$Quiet)
$ErrorActionPreference = 'Stop'
$expected = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\WindowsIconToolkit'))
$actual = [IO.Path]::GetFullPath($PSScriptRoot)
if (-not [string]::Equals($actual, $expected, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'This uninstaller can run only from the installed Windows Icon Toolkit directory.'
}
if ((Get-Item -LiteralPath $actual).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Installation root cannot be a symbolic link.' }
$marker = Get-Content -LiteralPath (Join-Path $actual '.windows-icon-toolkit-install.json') -Raw | ConvertFrom-Json
if ($marker.ProductId -ne 'awkj/windows-icon-toolkit' -or $marker.InstallRoot -ne $expected) { throw 'Invalid installation marker.' }

if ($PSCmdlet.ShouldProcess($expected, 'Uninstall Windows Icon Toolkit')) {
    $exe = Join-Path $actual 'WindowsIconToolkit.App.exe'
    foreach ($process in @(Get-Process 'WindowsIconToolkit.App' -ErrorAction SilentlyContinue)) {
        if ([string]::Equals($process.Path, $exe, [StringComparison]::OrdinalIgnoreCase)) {
            $process.CloseMainWindow() | Out-Null
            if (-not $process.WaitForExit(2000)) { $process.Kill(); $process.WaitForExit() }
        }
    }
    $shortcutPath = Join-Path ([Environment]::GetFolderPath('Programs')) 'Windows Icon Toolkit.lnk'
    if (Test-Path -LiteralPath $shortcutPath) {
        $shell = New-Object -ComObject WScript.Shell
        if ($shell.CreateShortcut($shortcutPath).TargetPath -eq $exe) { Remove-Item -LiteralPath $shortcutPath -Force }
    }
    $entry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WindowsIconToolkit'
    if (Test-Path -LiteralPath $entry) {
        if ((Get-ItemProperty -Path $entry).InstallLocation -eq $expected) { Remove-Item -LiteralPath $entry -Recurse -Force }
    }
    # The absolute directory and product marker were checked above; no other directory is removed.
    Remove-Item -LiteralPath $actual -Recurse -Force
    if (-not $Quiet) { Write-Host 'Windows Icon Toolkit uninstalled.' }
}
