# Optional chat-panel OCR fallback when WoWChatLog.txt is missing.
# Crops bottom-left chat region from WoW window; uses Windows built-in OCR when available.

$ErrorActionPreference = "Stop"

function Get-WowChatRegionPath {
    param([string]$Label = "chat-region")
    Add-Type -AssemblyName System.Drawing
    $hwnd = Focus-WowWindow
    $rect = New-Object WowWin32+RECT
    [void][WowWin32]::GetWindowRect($hwnd, [ref]$rect)
    $w = $rect.Right - $rect.Left
    $h = $rect.Bottom - $rect.Top
    if ($w -le 8 -or $h -le 8) { return $null }

    $cropW = [int]($w * 0.42)
    $cropH = [int]($h * 0.28)
    $left = $rect.Left + 4
    $top = $rect.Bottom - $cropH - 4

    $dir = Join-Path $PSScriptRoot "reports\screenshots"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $path = Join-Path $dir ("{0}-{1}.png" -f $Label, (Get-Date -Format "yyyyMMdd-HHmmss"))

    $bmp = New-Object System.Drawing.Bitmap $cropW, $cropH
    try {
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($left, $top, 0, 0, (New-Object System.Drawing.Size $cropW, $cropH))
        $g.Dispose()
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $bmp.Dispose()
    }
    return (Resolve-Path $path).Path
}

function Invoke-WindowsOcrOnImage {
    param([string]$ImagePath)
    if (-not $ImagePath -or -not (Test-Path $ImagePath)) { return "" }

    $ocrType = @"
using System;
using System.IO;
using System.Threading.Tasks;
using Windows.Graphics.Imaging;
using Windows.Media.Ocr;
using Windows.Storage;
using Windows.Storage.Streams;

public static class P1WowOcr {
    public static string Run(string path) {
        try {
            var file = StorageFile.GetFileFromPathAsync(path).AsTask().GetAwaiter().GetResult();
            var stream = file.OpenAsync(FileAccessMode.Read).AsTask().GetAwaiter().GetResult();
            var decoder = BitmapDecoder.CreateAsync(stream).AsTask().GetAwaiter().GetResult();
            var software = decoder.GetSoftwareBitmapAsync().AsTask().GetAwaiter().GetResult();
            var engine = OcrEngine.TryCreateFromUserProfileLanguages();
            if (engine == null) return "";
            var result = engine.RecognizeAsync(software).AsTask().GetAwaiter().GetResult();
            return result != null ? result.Text : "";
        } catch {
            return "";
        }
    }
}
"@

    try {
        if (-not ("P1WowOcr" -as [type])) {
            Add-Type -TypeDefinition $ocrType -ReferencedAssemblies @(
                "System.Runtime.WindowsRuntime",
                "Windows.Foundation",
                "Windows.Graphics.Imaging",
                "Windows.Media.Ocr",
                "Windows.Storage",
                "Windows.Storage.Streams"
            ) -ErrorAction Stop
        }
        return [P1WowOcr]::Run($ImagePath)
    } catch {
        return ""
    }
}

function Read-WowChatOcr {
    param([int]$LastN = 40)
    $img = Get-WowChatRegionPath -Label "ocr-chat"
    if (-not $img) { return @() }
    $text = Invoke-WindowsOcrOnImage -ImagePath $img
    if (-not $text) { return @() }
    $lines = @($text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($lines.Count -le $LastN) { return $lines }
    return @($lines | Select-Object -Last $LastN)
}