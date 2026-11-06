[CmdletBinding()]
param([Parameter(Mandatory)][string]$Path)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
if ($bytes.Length -lt 6 -or [BitConverter]::ToUInt16($bytes, 0) -ne 0 -or [BitConverter]::ToUInt16($bytes, 2) -ne 1) { throw 'Invalid ICO header.' }
$count = [BitConverter]::ToUInt16($bytes, 4)
if (6 + 16 * $count -gt $bytes.Length) { throw 'Truncated ICO directory.' }
for ($i = 0; $i -lt $count; $i++) {
    $entry = 6 + 16 * $i
    $width = if ($bytes[$entry]) { [int]$bytes[$entry] } else { 256 }
    $height = if ($bytes[$entry + 1]) { [int]$bytes[$entry + 1] } else { 256 }
    $length = [BitConverter]::ToUInt32($bytes, $entry + 8)
    $offset = [BitConverter]::ToUInt32($bytes, $entry + 12)
    if ([long]$offset + $length -gt $bytes.Length -or $length -lt 8) { throw 'Invalid ICO image bounds.' }
    $isPng = [BitConverter]::ToString($bytes, $offset, 8) -eq '89-50-4E-47-0D-0A-1A-0A'
    $stream = [IO.MemoryStream]::new()
    $icon = $null
    $bitmap = $null
    try {
        if ($isPng) {
            $stream.Write($bytes, $offset, $length)
            $stream.Position = 0
            $bitmap = [Drawing.Bitmap]::new($stream)
        } else {
            # Isolate one image so the decoder cannot silently select another size.
            $writer = [IO.BinaryWriter]::new($stream, [Text.Encoding]::UTF8, $true)
            try {
                $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
                $writer.Write($bytes, $entry, 12)
                $writer.Write([uint32]22)
                $writer.Write($bytes, $offset, $length)
                $writer.Flush()
            } finally { $writer.Dispose() }
            $stream.Position = 0
            $icon = [Drawing.Icon]::new($stream)
            $bitmap = $icon.ToBitmap()
        }
        if ($bitmap.Width -ne $width -or $bitmap.Height -ne $height) { throw 'Decoded size mismatch.' }
        $visible = 0
        $maxAlpha = 0
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $alpha = [int]$bitmap.GetPixel($x, $y).A
                if ($alpha -gt 0) { $visible++ }
                if ($alpha -gt $maxAlpha) { $maxAlpha = $alpha }
            }
        }
        [pscustomobject]@{
            Width = $width; Height = $height
            BitDepth = [BitConverter]::ToUInt16($bytes, $entry + 6)
            Encoding = if ($isPng) { 'PNG' } else { 'DIB' }
            NonzeroAlphaPixels = $visible; MaxAlpha = $maxAlpha
        }
    } finally {
        if ($bitmap) { $bitmap.Dispose() }
        if ($icon) { $icon.Dispose() }
        $stream.Dispose()
    }
}
