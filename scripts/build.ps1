[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Debug',
    [switch]$Run
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$portableDotnet = Join-Path $repo '.tools\dotnet\dotnet.exe'
$dotnet = if (Test-Path -LiteralPath $portableDotnet) { $portableDotnet } else { (Get-Command dotnet -ErrorAction Stop).Source }
$project = Join-Path $repo 'src\WindowsIconToolkit.App\WindowsIconToolkit.App.csproj'
Push-Location $repo
try {
    & $dotnet build $project -c $Configuration -p:Platform=x64 --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    if ($Run) {
        $exe = Join-Path $repo "src\WindowsIconToolkit.App\bin\x64\$Configuration\net10.0-windows10.0.26100.0\win-x64\WindowsIconToolkit.App.exe"
        if (-not (Test-Path -LiteralPath $exe)) { throw "Output not found: $exe" }
        Start-Process -FilePath $exe
    }
} finally { Pop-Location }
