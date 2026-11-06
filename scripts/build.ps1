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
$output = if ($Publish) { Join-Path $repo 'artifacts' } else { Join-Path $repo 'bin' }
$stage = Join-Path $repo ".build\publish\$Configuration"
$exeName = 'WindowsIconToolkit.App.exe'
$exe = Join-Path $output $exeName
Push-Location $repo
try {
    New-Item -ItemType Directory -Path $output -Force | Out-Null
    $unexpected = @(Get-ChildItem -LiteralPath $output -Force | Where-Object { $_.Name -ne $exeName -or $_.PSIsContainer })
    if ($unexpected.Count) { throw "Output folder contains unexpected files; preserve them elsewhere first: $output" }
    foreach ($process in @(Get-Process 'WindowsIconToolkit.App' -ErrorAction SilentlyContinue)) {
        if ([string]::Equals($process.Path, $exe, [StringComparison]::OrdinalIgnoreCase)) {
            $process.CloseMainWindow() | Out-Null
            if (-not $process.WaitForExit(2000)) { $process.Kill(); $process.WaitForExit() }
        }
    }
    & $dotnet publish $project -c $Configuration -r win-x64 -p:Platform=x64 --self-contained true -o $stage --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    $files = @(Get-ChildItem -LiteralPath $stage -Force)
    if ($files.Count -ne 1 -or $files[0].Name -ne $exeName -or $files[0].PSIsContainer) {
        throw "Single-file publish produced unexpected files: $($files.Name -join ', ')"
    }
    Copy-Item -LiteralPath (Join-Path $stage $exeName) -Destination $exe -Force
    Write-Host "Single-file output: $exe"
    if ($Run) { Start-Process -FilePath $exe -WorkingDirectory $output }
} finally { Pop-Location }
