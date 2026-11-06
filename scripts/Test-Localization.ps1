# Check translation completeness and actual source references without changing Windows settings.
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$app = Join-Path $repo 'src\WindowsIconToolkit.App'
$languages = @('en-US','zh-CN')
$resources = @{}
foreach ($language in $languages) {
    [xml]$document = Get-Content -LiteralPath (Join-Path $app "Strings\$language\Resources.resw") -Raw -Encoding UTF8
    $values = @{}
    foreach ($entry in $document.root.data) {
        $key = [string]$entry.name
        if ($values.ContainsKey($key)) { throw "Duplicate resource: $language/$key" }
        $value = [string]$entry.value
        if ([string]::IsNullOrWhiteSpace($value)) { throw "Empty resource: $language/$key" }
        $values[$key] = $value
    }
    $resources[$language] = $values
}
$difference = @(Compare-Object @($resources['en-US'].Keys | Sort-Object) @($resources['zh-CN'].Keys | Sort-Object))
if ($difference.Count) { throw ('Translation keys do not match: ' + ($difference | Out-String)) }
foreach ($key in $resources['en-US'].Keys) {
    $english = @([regex]::Matches($resources['en-US'][$key], '\{\d+\}') | ForEach-Object Value | Sort-Object)
    $chinese = @([regex]::Matches($resources['zh-CN'][$key], '\{\d+\}') | ForEach-Object Value | Sort-Object)
    if (($english -join '|') -ne ($chinese -join '|')) { throw "Format placeholders do not match: $key" }
}

foreach ($file in (Get-ChildItem -LiteralPath $app -Recurse -File | Where-Object { $_.Extension -in @('.xaml','.cs') })) {
    $source = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($source, 'Strings\.(?:Get|Format)\("([^"]+)"')) {
        $key = $match.Groups[1].Value
        if (-not $resources['en-US'].ContainsKey($key)) { throw "Missing code resource: $key" }
    }
    foreach ($match in [regex]::Matches($source, 'x:Uid="([^"]+)"')) {
        $prefix = $match.Groups[1].Value + '.'
        if (-not @($resources['en-US'].Keys | Where-Object { $_.StartsWith($prefix) }).Count) {
            throw "Missing XAML resources: $($match.Groups[1].Value)"
        }
    }
    if ($source -match '[\u4e00-\u9fff]') { throw "Hardcoded Chinese remains in code/XAML: $($file.Name)" }
}
Write-Host "PASS: $($resources['en-US'].Count) complete resource keys in en-US and zh-CN; matching placeholders; XAML and code references resolved."
