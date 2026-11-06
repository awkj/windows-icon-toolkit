[CmdletBinding()]
param([switch]$Launch)
$ErrorActionPreference = 'Stop'
$productId = 'awkj/windows-icon-toolkit'
$repo = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repo 'artifacts'
$sourceExe = Join-Path $source 'WindowsIconToolkit.App.exe'
if (-not (Test-Path -LiteralPath $sourceExe)) { throw 'Run just build before installing.' }
if (@(Get-ChildItem -LiteralPath $source -Force).Count -ne 1) { throw 'Expected one self-contained EXE. Run just build again.' }
$version = [Diagnostics.FileVersionInfo]::GetVersionInfo($sourceExe).ProductVersion.Split('+')[0]
$parent = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs'))
$target = Join-Path $parent 'WindowsIconToolkit'
$stage = Join-Path $parent ('.WindowsIconToolkit-stage-' + [guid]::NewGuid().ToString('N'))
$backup = Join-Path $parent ('.WindowsIconToolkit-backup-' + [guid]::NewGuid().ToString('N'))
$markerName = '.windows-icon-toolkit-install.json'

function Assert-OwnedDirectory([string]$Directory) {
    $resolved = [IO.Path]::GetFullPath($Directory)
    if ([IO.Path]::GetDirectoryName($resolved) -ne $parent -or
        [IO.Path]::GetFileName($resolved) -notmatch '^(WindowsIconToolkit|\.WindowsIconToolkit-(stage|backup)-[a-f0-9]{32})$') {
        throw "Unsafe installation directory: $resolved"
    }
    if ((Get-Item -LiteralPath $resolved).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Installation directory cannot be a symbolic link: $resolved"
    }
    $markerPath = Join-Path $resolved $markerName
    if (-not (Test-Path -LiteralPath $markerPath)) { throw "Unrecognized installation directory: $resolved" }
    if ((Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json).ProductId -ne $productId) {
        throw "Unrecognized installation marker: $resolved"
    }
}

if (Test-Path -LiteralPath $target) { Assert-OwnedDirectory $target }
New-Item -ItemType Directory -Path $parent -Force | Out-Null
New-Item -ItemType Directory -Path $stage | Out-Null
@{ProductId=$productId;Version=$version;InstallRoot=$target;InstalledAtUtc=[DateTime]::UtcNow.ToString('o')} |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stage $markerName) -Encoding UTF8
$movedOld = $false
$installedNew = $false
try {
    Copy-Item -LiteralPath $sourceExe -Destination $stage
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'uninstall.ps1') -Destination (Join-Path $stage 'uninstall.ps1')
    $installedExe = Join-Path $target 'WindowsIconToolkit.App.exe'
    foreach ($process in @(Get-Process 'WindowsIconToolkit.App' -ErrorAction SilentlyContinue)) {
        if ([string]::Equals($process.Path, $installedExe, [StringComparison]::OrdinalIgnoreCase)) {
            $process.CloseMainWindow() | Out-Null
            if (-not $process.WaitForExit(2000)) { $process.Kill(); $process.WaitForExit() }
        }
    }
    if (Test-Path -LiteralPath $target) {
        Assert-OwnedDirectory $target
        Move-Item -LiteralPath $target -Destination $backup
        $movedOld = $true
    }
    if ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($stage)) -ne $parent -or
        [IO.Path]::GetFullPath($target) -ne (Join-Path $parent 'WindowsIconToolkit')) { throw 'Unsafe move target.' }
    Move-Item -LiteralPath $stage -Destination $target
    $installedNew = $true

    $programs = [Environment]::GetFolderPath('Programs')
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $programs 'Windows Icon Toolkit.lnk'))
    $shortcut.TargetPath = $installedExe
    $shortcut.WorkingDirectory = $target
    $shortcut.IconLocation = "$installedExe,0"
    $shortcut.Description = 'Windows desktop icon toolkit'
    $shortcut.Save()

    $entry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WindowsIconToolkit'
    New-Item -Path $entry -Force | Out-Null
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $uninstallCommand = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}"' -f $powershell, (Join-Path $target 'uninstall.ps1')
    $values = @{
        DisplayName='Windows Icon Toolkit';DisplayVersion=$version;Publisher='awkj'
        InstallLocation=$target;DisplayIcon="$installedExe,0"
        UninstallString=$uninstallCommand;QuietUninstallString=($uninstallCommand + ' -Quiet')
        URLInfoAbout='https://github.com/awkj/windows-icon-toolkit'
        InstallDate=(Get-Date -Format 'yyyyMMdd')
    }
    foreach ($name in $values.Keys) { New-ItemProperty -Path $entry -Name $name -Value $values[$name] -PropertyType String -Force | Out-Null }
    foreach ($name in @('NoModify','NoRepair')) { New-ItemProperty -Path $entry -Name $name -Value 1 -PropertyType DWord -Force | Out-Null }
    $size = [int][Math]::Ceiling((Get-ChildItem -LiteralPath $target -Recurse -File | Measure-Object Length -Sum).Sum / 1KB)
    New-ItemProperty -Path $entry -Name EstimatedSize -Value $size -PropertyType DWord -Force | Out-Null

    if ($movedOld) { Assert-OwnedDirectory $backup; Remove-Item -LiteralPath $backup -Recurse -Force }
    Write-Host "Installed Windows Icon Toolkit $version to $target"
    Write-Host 'Start menu shortcut and Windows installed-app entry created.'
    & (Join-Path $env:SystemRoot 'System32\ie4uinit.exe') -show
    if ($Launch) { Start-Process -FilePath $installedExe }
} catch {
    if (-not $installedNew -and $movedOld -and -not (Test-Path -LiteralPath $target)) {
        Assert-OwnedDirectory $backup
        Move-Item -LiteralPath $backup -Destination $target
    }
    throw
} finally {
    if (Test-Path -LiteralPath $stage) { Assert-OwnedDirectory $stage; Remove-Item -LiteralPath $stage -Recurse -Force }
}
