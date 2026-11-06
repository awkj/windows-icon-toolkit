[CmdletBinding()]
param(
    [ValidateSet('Hide', 'Restore', 'Status')]
    [string]$Action = 'Status',
    [switch]$IncludeShield,
    [switch]$Pause
)

$ErrorActionPreference = 'Stop'

function New-TransparentIcon([string]$Path) {
    # Monochrome ICO: XOR=0, AND=1 leaves the destination unchanged.
    # Multiple sizes avoid relying on alpha blending or missing DLL icon indices.
    $sizes = @(16, 24, 32, 48, 64, 128, 256)
    $stream = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$sizes.Count)
        $offset = 6 + 16 * $sizes.Count
        foreach ($size in $sizes) {
            $dimension = if ($size -eq 256) { 0 } else { $size }
            $stride = [int]([Math]::Ceiling($size / 32.0) * 4)
            $length = 48 + 2 * $stride * $size
            $writer.Write([byte]$dimension)
            $writer.Write([byte]$dimension)
            $writer.Write([byte]2)
            $writer.Write([byte]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]1)
            $writer.Write([uint32]$length)
            $writer.Write([uint32]$offset)
            $offset += $length
        }
        foreach ($size in $sizes) {
            $stride = [int]([Math]::Ceiling($size / 32.0) * 4)
            $planeBytes = $stride * $size
            $writer.Write([uint32]40)
            $writer.Write([int32]$size)
            $writer.Write([int32]($size * 2))
            $writer.Write([uint16]1)
            $writer.Write([uint16]1)
            $writer.Write([uint32]0)
            $writer.Write([uint32]($planeBytes * 2))
            $writer.Write([int32]0)
            $writer.Write([int32]0)
            $writer.Write([uint32]2)
            $writer.Write([uint32]0)
            $writer.Write([byte[]]@(0, 0, 0, 0, 255, 255, 255, 0))
            $writer.Write([byte[]]::new($planeBytes))
            $mask = [byte[]]::new($planeBytes)
            for ($i = 0; $i -lt $mask.Length; $i++) { $mask[$i] = 255 }
            $writer.Write($mask)
        }
        $writer.Flush()
        [IO.File]::WriteAllBytes($Path, $stream.ToArray())
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

try {
    if ($env:OS -ne 'Windows_NT') { throw 'Windows is required.' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($Action -ne 'Status' -and -not $isAdmin) {
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Action {1}' -f $PSCommandPath, $Action
        if ($IncludeShield) { $arguments += ' -IncludeShield' }
        if ($Pause) { $arguments += ' -Pause' }
        $process = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait -PassThru
        exit $process.ExitCode
    }

    $folder = Join-Path $env:ProgramData 'DesktopIconOverlayBackup'
    $iconPath = Join-Path $folder 'transparent.ico'
    # Match Dism++ Data.xml: expandable path, with no icon-index suffix.
    $replacement = '%ProgramData%\DesktopIconOverlayBackup\transparent.ico'
    $legacyReplacement = "$iconPath,0"
    $subKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
    $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine,
        [Microsoft.Win32.RegistryView]::Registry64
    )
    $key = $null
    try {
        if ($Action -eq 'Status') {
            $key = $base.OpenSubKey($subKey)
            foreach ($name in @('29', '77')) {
                $label = if ($name -eq '29') { 'Shortcut arrow' } else { 'UAC shield (experimental)' }
                $value = if ($key) { $key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) } else { $null }
                if ($null -eq $value) { $value = '(Windows default)' }
                Write-Host "$label [$name]: $value"
            }
            Write-Host "Backup directory: $folder"
        } elseif ($Action -eq 'Hide') {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            New-TransparentIcon $iconPath
            $key = $base.CreateSubKey($subKey)
            $names = @('29')
            if ($IncludeShield) { $names += '77' }
            foreach ($name in $names) {
                $backupPath = Join-Path $folder "$name.clixml"
                if (-not (Test-Path -LiteralPath $backupPath)) {
                    $exists = $key.GetValueNames() -contains $name
                    $original = [pscustomobject]@{
                        Name = $name
                        Exists = $exists
                        Kind = if ($exists) { $key.GetValueKind($name).ToString() } else { 'String' }
                        Value = if ($exists) { $key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) } else { $null }
                    }
                    $original | Export-Clixml -LiteralPath $backupPath
                }
                $key.SetValue($name, $replacement, [Microsoft.Win32.RegistryValueKind]::ExpandString)
                Write-Host "Hidden overlay: $name"
            }
            Write-Host 'Applied. Sign out and sign in again to refresh the icons.'
            Write-Host 'Keep the transparent.ico file. UAC and administrator permissions are unchanged.'
            if ($IncludeShield) { Write-Host 'Shield hiding depends on the Windows version and application.' }
        } else {
            # Restore only values backed up by this script; preserve unrelated settings.
            $key = $base.OpenSubKey($subKey, $true)
            foreach ($name in @('29', '77')) {
                $backupPath = Join-Path $folder "$name.clixml"
                if (-not (Test-Path -LiteralPath $backupPath)) { continue }
                $original = Import-Clixml -LiteralPath $backupPath
                if ($original.Name -ne $name) { throw "Invalid backup: $backupPath" }
                $current = if ($key) { $key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) } else { $null }
                if ($null -ne $current -and $current -ne $replacement -and $current -ne $legacyReplacement) {
                    throw "Overlay $name was changed by another tool. Restore stopped to preserve that change. Backup: $backupPath"
                }
                if ($original.Exists) {
                    if (-not $key) { $key = $base.CreateSubKey($subKey) }
                    $kind = [Microsoft.Win32.RegistryValueKind][Enum]::Parse([Microsoft.Win32.RegistryValueKind], $original.Kind)
                    $key.SetValue($name, $original.Value, $kind)
                } elseif ($key) {
                    $key.DeleteValue($name, $false)
                }
                Remove-Item -LiteralPath $backupPath
                Write-Host "Restored overlay: $name"
            }
            Write-Host 'Restore finished. Sign out and sign in again to refresh the icons.'
        }
    } finally {
        if ($key) { $key.Dispose() }
        $base.Dispose()
    }
    if ($Action -ne 'Status') {
        if (-not ('DesktopOverlayAssociationRefresh' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DesktopOverlayAssociationRefresh {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(uint eventId, uint flags, IntPtr item1, IntPtr item2);
}
'@
        }
        [DesktopOverlayAssociationRefresh]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($Pause) { Read-Host 'Press Enter to close' | Out-Null }
    exit 1
}
if ($Pause) { Read-Host 'Press Enter to close' | Out-Null }
