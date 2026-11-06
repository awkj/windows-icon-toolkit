# This test extracts only the generator function; it never executes registry actions.
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'Desktop-IconOverlays.ps1'
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
$function = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'New-TransparentIcon'
}, $true)
if (-not $function) { throw 'Generator function missing.' }
. ([scriptblock]::Create($function.Extent.Text))
$temporaryIcon = Join-Path ([IO.Path]::GetTempPath()) ('icon-toolkit-test-' + [guid]::NewGuid().ToString('N') + '.ico')
try {
    New-TransparentIcon $temporaryIcon
    $images = @(& (Join-Path $PSScriptRoot 'Inspect-Icon.ps1') -Path $temporaryIcon)
    $sizes = @($images | ForEach-Object Width)
    if (($sizes -join ',') -ne '16,24,32,48,64,128,256') { throw 'Unexpected icon sizes.' }
    foreach ($image in $images) {
        if ($image.NonzeroAlphaPixels -ne 0 -or $image.MaxAlpha -ne 0) { throw 'Icon contains visible pixels.' }
    }
    $images | Format-Table
    'PASS: Script syntax, seven isolated image decodes, all pixels fully transparent. No registry changes.'
} finally {
    if (Test-Path -LiteralPath $temporaryIcon) { Remove-Item -LiteralPath $temporaryIcon }
}
