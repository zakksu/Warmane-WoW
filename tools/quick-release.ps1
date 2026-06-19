# Bump patch version, rebuild zips, commit, push, tag, and optionally publish a GitHub release.
param(
    [string]$Notes = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'handoff-common.ps1')

$warlockLoader = Join-Path $root "PhaseOne_LevelingPack\Interface\AddOns\PhaseOneLoader\PhaseOneLoader.lua"
$druidLoader = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns\PhaseOneLoader\PhaseOneLoader.lua"
$releaseTxt = Join-Path $root "RELEASE.txt"
$readme = Join-Path $root "README.md"

function Set-PackVersion {
    param([string]$Path, [string]$Version)
    $text = Get-Content -Path $Path -Raw -Encoding UTF8
    $updated = $text -replace 'PACK_VERSION = "[^"]+"', ('PACK_VERSION = "' + $Version + '"')
    if ($updated -eq $text) { throw "PACK_VERSION not found in $Path" }
    Set-Content -Path $Path -Value $updated -Encoding UTF8 -NoNewline
}

function Update-ReleaseOneLiner {
    param([string]$Version)
    $lines = Get-Content -Path $releaseTxt -Encoding UTF8
    if ($lines.Count -lt 1) { throw "RELEASE.txt is empty" }
    $lines[0] = "Phase One Warmane Leveling Packs - v$Version"
    if ($lines.Count -ge 2 -and $lines[1] -match '^Released:') {
        $lines[1] = "Released: $(Get-Date -Format 'yyyy-MM-dd')"
    }
    Set-Content -Path $releaseTxt -Value $lines -Encoding UTF8
}

function Update-ReadmeLatestRelease {
    param([string]$Version)
    if (-not (Test-Path $readme)) { return }
    $text = Get-Content -Path $readme -Raw -Encoding UTF8
    $date = Get-Date -Format 'MMM d, yyyy'
    $pattern = '\*\*Latest release: v[\d.]+(?:-druid)?\*\* \([^)]+\)'
    $replacement = "**Latest release: v$Version** ($date)"
    $updated = $text -replace $pattern, $replacement
    if ($updated -ne $text) {
        Set-Content -Path $readme -Value $updated -Encoding UTF8 -NoNewline
    }
}

function Invoke-GhRelease {
    param(
        [string]$Tag,
        [string]$Version,
        [string[]]$Assets,
        [string]$ReleaseNotes
    )

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Warning "GitHub CLI (gh) not found - skipping GitHub release."
        return
    }

    if (-not (Test-GhAuthenticated)) {
        Write-Warning "gh is not authenticated - skipping GitHub release. Run: gh auth login"
        return
    }

    $notes = if ($ReleaseNotes) { $ReleaseNotes } else { "Phase One Warmane leveling packs v$Version" }
    $existing = gh release view $Tag 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Updating existing GitHub release $Tag..."
        gh release edit $Tag --title $Tag --notes $notes | Out-Null
        gh release upload $Tag $Assets --clobber | Out-Null
    } else {
        Write-Host "Creating GitHub release $Tag..."
        gh release create $Tag $Assets --title $Tag --notes $notes | Out-Null
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "gh release step failed (exit $LASTEXITCODE). Zips were still built locally."
    } else {
        Write-Host "GitHub release $Tag published."
    }
}

Write-Host "========================================"
Write-Host " Phase One — quick release"
Write-Host "========================================"
Write-Host ""

$loaderText = Get-Content -Path $warlockLoader -Raw -Encoding UTF8
if ($loaderText -notmatch 'PACK_VERSION = "(\d+)\.(\d+)\.(\d+)"') {
    throw "Could not parse PACK_VERSION from $warlockLoader"
}

$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$patch = [int]$Matches[3] + 1
$newVersion = "$major.$minor.$patch"
$tag = "v$newVersion"
$druidVersion = "$newVersion-druid"

Write-Host "Bumping $major.$minor.$($patch - 1) -> $newVersion"
Set-PackVersion -Path $warlockLoader -Version $newVersion
Set-PackVersion -Path $druidLoader -Version $druidVersion
Update-ReleaseOneLiner -Version $newVersion
Update-ReadmeLatestRelease -Version $newVersion
Write-Host "Updated PhaseOneLoader versions and RELEASE.txt"

Write-Host ""
Write-Host "Building distribution zips..."
& (Join-Path $PSScriptRoot "build-all.ps1")

$zipWarlock = Join-Path $root "PhaseOne_LevelingPack.zip"
$zipDruid = Join-Path $root "PhaseOne_Druid_LevelingPack.zip"
foreach ($zip in @($zipWarlock, $zipDruid)) {
    if (-not (Test-Path $zip)) { throw "Expected zip missing: $zip" }
}

Push-Location $root
try {
    $dirty = git status --porcelain
    if (-not $dirty) {
        Write-Warning "No file changes to commit besides version bump (working tree may already be clean)."
    }

    git add -A
    $commitMsg = "Release $tag"
    if ($Notes) { $commitMsg += "`n`n$Notes" }
    git commit -m $commitMsg
    if ($LASTEXITCODE -ne 0) {
        throw "git commit failed. Fix conflicts or stage changes, then re-run."
    }

    Write-Host "Pushing main..."
    if (-not (Invoke-GitPush -Remote 'origin' -Ref 'main')) {
        Write-Warning "git push failed (configure git credentials or run: gh auth login). Release committed locally."
    }

    Write-Host "Tagging $tag..."
    git tag -a $tag -m "Release $tag" -f
    if (-not (Invoke-GitPush -Remote 'origin' -Ref "refs/tags/$tag" -Force)) {
        Write-Warning "git push tag failed. Tag exists locally: $tag"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Invoke-GhRelease -Tag $tag -Version $newVersion -Assets @($zipWarlock, $zipDruid) -ReleaseNotes $Notes

Write-Host ""
Write-Host "========================================"
Write-Host " Release $tag complete"
Write-Host "========================================"
Write-Host " Zips:"
Write-Host "   $zipWarlock"
Write-Host "   $zipDruid"
Write-Host ""
Write-Host " Players: run INSTALL.bat again, or copy changed addon folders, then /reload."
Write-Host " See Docs/INCREMENTAL_UPDATES.md"
