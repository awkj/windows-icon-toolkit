[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Debug',
    [switch]$Run,
    [switch]$Publish
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$portableDotnet = Join-Path $repo '.tools\dotnet\dotnet.exe'
$dotnet = if (Test-Path -LiteralPath $portableDotnet) { $portableDotnet } else { (Get-Command dotnet -ErrorAction Stop).Source }
$project = Join-Path $repo 'src\WindowsIconToolkit.App\WindowsIconToolkit.App.csproj'
$exe = Join-Path $repo "src\WindowsIconToolkit.App\bin\x64\$Configuration\net10.0-windows10.0.26100.0\win-x64\WindowsIconToolkit.App.exe"
Push-Location $repo
try {
    if ($Run) {
        foreach ($process in @(Get-Process 'WindowsIconToolkit.App' -ErrorAction SilentlyContinue)) {
            if ([string]::Equals($process.Path, $exe, [StringComparison]::OrdinalIgnoreCase)) {
                $process.CloseMainWindow() | Out-Null
                if (-not $process.WaitForExit(2000)) { $process.Kill(); $process.WaitForExit() }
            }
        }
    }
    if ($Publish) {
        & $dotnet publish $project -c $Configuration -r win-x64 -p:Platform=x64 --self-contained true -o (Join-Path $repo 'artifacts\publish') --nologo
    } else {
        & $dotnet build $project -c $Configuration -p:Platform=x64 --nologo
    }
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    if ($Run) {
        if ($Publish) { $exe = Join-Path $repo 'artifacts\publish\WindowsIconToolkit.App.exe' }
        if (-not (Test-Path -LiteralPath $exe)) { throw "Output not found: $exe" }
        Start-Process -FilePath $exe
    }
} finally { Pop-Location }
