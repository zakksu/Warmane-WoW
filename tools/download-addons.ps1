# Re-download third-party addons into PhaseOne_LevelingPack
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path $env:TEMP "wow-pack-build"
$addons = Join-Path $root "PhaseOne_LevelingPack\Interface\AddOns"
New-Item -ItemType Directory -Force -Path $tmp, $addons | Out-Null

$map = @{
    "Questie-335" = "https://github.com/widxwer/Questie/archive/refs/heads/335.zip"
    "WeakAuras"   = "https://github.com/Bunny67/WeakAuras-WotLK/archive/refs/heads/master.zip"
    "Leatrix_Plus"= "https://github.com/Sattva-108/Leatrix_Plus/archive/refs/heads/main.zip"
    "Bagnon"      = "https://github.com/RichSteini/Bagnon-3.3.5/archive/refs/heads/main.zip"
    "Auctionator" = "https://github.com/alchem1ster/WotLK-Auctionator/archive/refs/heads/main.zip"
}

$folderNames = @{
    "Questie-335" = "Questie-335"
    "WeakAuras"   = "WeakAuras-WotLK-master"
    "Leatrix_Plus"= "Leatrix_Plus-main"
    "Bagnon"      = "Bagnon-3.3.5-main"
    "Auctionator" = "WotLK-Auctionator-main"
}

foreach ($dest in $map.Keys) {
    $zip = Join-Path $tmp "$dest.zip"
    Write-Host "Downloading $dest..."
    Invoke-WebRequest -Uri $map[$dest] -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath $tmp -Force
    $srcRoot = Join-Path $tmp $folderNames[$dest]
    if ($dest -eq "Auctionator") {
        $srcRoot = Join-Path $srcRoot "Auctionator"
        $target = Join-Path $addons $dest
        if (Test-Path $target) { Remove-Item $target -Recurse -Force }
        Copy-Item $srcRoot $target -Recurse -Force
    } else {
        Get-ChildItem -LiteralPath $srcRoot -Directory | ForEach-Object {
            $target = Join-Path $addons $_.Name
            if (Test-Path $target) { Remove-Item $target -Recurse -Force }
            Copy-Item $_.FullName $target -Recurse -Force
        }
    }
    Write-Host "Installed $dest"
}

Write-Host "Custom addons (TomTom, PhaseOneLoader, !Astrolabe) are not overwritten."
