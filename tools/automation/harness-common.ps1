# Shared report + SavedVariables parsing for P1 agent harness
$ErrorActionPreference = "Stop"

function Get-HarnessReportDir {
    return Join-Path $PSScriptRoot "reports"
}

function Get-P1DruidGuideSavedVarsPath {
    $wow = Get-WowPath
    $root = Join-Path $wow "WTF\Account"
    if (-not (Test-Path $root)) { return $null }
    $files = @(Get-ChildItem -Path $root -Recurse -Filter "P1DruidGuide.lua" -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq "SavedVariables" } |
        Sort-Object LastWriteTime -Descending)
    if ($files.Count -eq 0) { return $null }
    return $files[0].FullName
}

function Read-P1HarnessSavedVars {
    $path = Get-P1DruidGuideSavedVarsPath
    if (-not $path -or -not (Test-Path $path)) {
        return @{
            path = $path
            exists = $false
            lastTestPass = $null
            lastTestTotal = $null
            lastTestAt = $null
            devLogCount = 0
        }
    }
    $text = Get-Content -Path $path -Raw -Encoding UTF8
    $pass = $null
    $total = $null
    $at = $null
    if ($text -match '\["lastTestPass"\]\s*=\s*(\d+)') { $pass = [int]$Matches[1] }
    if ($text -match '\["lastTestTotal"\]\s*=\s*(\d+)') { $total = [int]$Matches[1] }
    if ($text -match '\["lastTestAt"\]\s*=\s*([\d.]+)') { $at = [double]$Matches[1] }
    $devCount = ([regex]::Matches($text, '\["devLog"\]')).Count
    return @{
        path = $path
        exists = $true
        lastTestPass = $pass
        lastTestTotal = $total
        lastTestAt = $at
        devLogCount = $devCount
    }
}

function Get-P1AddonsTxtStatus {
    $wow = Get-WowPath
    $root = Join-Path $wow "WTF\Account"
    $status = @{}
    if (-not (Test-Path $root)) { return $status }
    Get-ChildItem -Path $root -Recurse -Filter "AddOns.txt" -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Replace($wow + "\", "")
        $map = @{}
        Get-Content $_.FullName -Encoding UTF8 | ForEach-Object {
            if ($_ -match '^([^:]+):\s*([01])\s*$') {
                $map[$Matches[1].Trim()] = [int]$Matches[2]
            }
        }
        if ($map.ContainsKey("P1DruidGuide")) {
            $status[$rel] = $map["P1DruidGuide"]
        }
    }
    return $status
}

function New-HarnessRecommendations {
    param($Report)
    $tips = New-Object System.Collections.Generic.List[string]
    if ($Report.addonsTxt) {
        foreach ($key in $Report.addonsTxt.Keys) {
            if ([int]$Report.addonsTxt[$key] -eq 0) {
                $tips.Add("P1DruidGuide is OFF in $key - log out to character select and enable it") | Out-Null
            }
        }
    }
    if ($Report.frameXml.errors.Count -gt 0) {
        $tips.Add("FrameXML shows P1 load errors - run PLAY.bat then /reload (or relog)") | Out-Null
    }
    if (-not $Report.chatLog.exists) {
        $tips.Add("WoWChatLog.txt missing - run /chatlog in game once while logged in") | Out-Null
    }
    if ($Report.savedVars.exists -and $null -eq $Report.savedVars.lastTestPass) {
        $tips.Add("No lastTestPass in SavedVariables - TestHarness did not run (/p1test run)") | Out-Null
    }
    if ($tips.Count -eq 0 -and -not $Report.success) {
        $tips.Add("Use windowed mode, druid toon, then /p1test run manually and check chat") | Out-Null
    }
    return $tips
}

function Write-HarnessReport {
    param(
        [hashtable]$Report,
        [string]$FileName = "harness-latest.json"
    )
    $dir = Get-HarnessReportDir
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $path = Join-Path $dir $FileName
    $Report.recommendations = @(New-HarnessRecommendations -Report $Report)
    $json = $Report | ConvertTo-Json -Depth 8
    Set-Content -Path $path -Value $json -Encoding UTF8
    return (Resolve-Path $path).Path
}