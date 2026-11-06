# Package the approved PNG into a multi-resolution Windows ICO without changing its design.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repo = Split-Path $PSScriptRoot -Parent
$assetFolder = Join-Path $repo 'src\WindowsIconToolkit.App\Assets'
$pngPath = Join-Path $repo 'design\app-icon.png'
$icoPath = Join-Path $assetFolder 'AppIcon.ico'
$source = [Drawing.Bitmap]::new($pngPath)
$images = @()
$sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
try {
    # Export the approved artwork at a normal shell-icon optical size. Keep the
    # source PNG and the internal gaps unchanged; discard only outer padding.
    $left = $source.Width; $top = $source.Height; $right = -1; $bottom = -1
    for ($y = 0; $y -lt $source.Height; $y++) {
        for ($x = 0; $x -lt $source.Width; $x++) {
            if ($source.GetPixel($x, $y).A -ge 128) {
                $left = [Math]::Min($left, $x); $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x); $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left) { throw 'App icon source has no visible artwork.' }
    $left = [Math]::Max(0, $left - 2); $top = [Math]::Max(0, $top - 2)
    $right = [Math]::Min($source.Width - 1, $right + 2)
    $bottom = [Math]::Min($source.Height - 1, $bottom + 2)
    $sourceRectangle = [Drawing.RectangleF]::new($left, $top, ($right - $left + 1), ($bottom - $top + 1))
    foreach ($size in $sizes) {
        $bitmap = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $png = [IO.MemoryStream]::new()
        try {
            $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.Clear([Drawing.Color]::Transparent)
            $scale = ($size * 0.96) / [Math]::Max($sourceRectangle.Width, $sourceRectangle.Height)
            $width = $sourceRectangle.Width * $scale
            $height = $sourceRectangle.Height * $scale
            $destination = [Drawing.RectangleF]::new(($size - $width) / 2, ($size - $height) / 2, $width, $height)
            $graphics.DrawImage($source, $destination, $sourceRectangle, [Drawing.GraphicsUnit]::Pixel)
            $bitmap.Save($png, [Drawing.Imaging.ImageFormat]::Png)
            $images += ,$png.ToArray()
        } finally {
            $png.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
        }
    }
} finally { $source.Dispose() }

$stream = [IO.MemoryStream]::new()
$writer = [IO.BinaryWriter]::new($stream)
try {
    $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
        $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
        $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$images[$i].Length); $writer.Write([uint32]$offset)
        $offset += $images[$i].Length
    }
    foreach ($image in $images) { $writer.Write([byte[]]$image) }
    $writer.Flush()
    [IO.File]::WriteAllBytes($icoPath, $stream.ToArray())
} finally { $writer.Dispose(); $stream.Dispose() }
Write-Host "Exported app icon: $icoPath"
