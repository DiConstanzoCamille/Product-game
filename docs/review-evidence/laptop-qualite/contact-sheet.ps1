param([string]$captureDirectory = $PSScriptRoot)
Add-Type -AssemblyName System.Drawing
$captures = @(Get-ChildItem -LiteralPath $captureDirectory -Filter '*.png' | Where-Object Name -ne 'contact-sheet.png' | Sort-Object Name)
$sheet = [System.Drawing.Bitmap]::new(1600, [int]([Math]::Ceiling($captures.Count / 4.0) * 250))
$canvas = [System.Drawing.Graphics]::FromImage($sheet)
$canvas.Clear([System.Drawing.Color]::White)
$font = [System.Drawing.Font]::new('Arial', 12)
try {
    for ($index = 0; $index -lt $captures.Count; $index++) {
        $picture = [System.Drawing.Image]::FromFile($captures[$index].FullName)
        try {
            $left = [int](($index % 4) * 400)
            $top = [int]([Math]::Floor($index / 4.0) * 250)
            $canvas.DrawImage($picture, $left, $top, 400, 225)
            $canvas.DrawString($captures[$index].BaseName, $font, [System.Drawing.Brushes]::Black, $left, ($top + 227))
        } finally { $picture.Dispose() }
    }
    $sheet.Save((Join-Path $captureDirectory 'contact-sheet.png'), [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $font.Dispose()
    $canvas.Dispose()
    $sheet.Dispose()
}
