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

function Test-P1HarnessSummaryLine {
    param([string]$Line)
    if (-not $Line) { return $false }
    if ($Line -match '\[P1TEST\].*PASS.*summary') { return $true }
    if ($Line -match '\[P1TEST\]\s+PASS\s+summary\s+\d+/\d+\s+pass') { return $true }
    return $false
}

function Test-P1SavedVarsSummaryPassed {
    param($SavedVars)
    if ($null -eq $SavedVars) { return $false }
    if ($null -eq $SavedVars.lastTestPass -or $null -eq $SavedVars.lastTestTotal) { return $false }
    if ($SavedVars.lastTestTotal -le 0) { return $false }
    return ($SavedVars.lastTestPass -eq $SavedVars.lastTestTotal)
}

function Get-P1HarnessFailLines {
    param([string[]]$Lines)
    return @($Lines | Where-Object { $_ -match '\[P1TEST\].*FAIL' })
}

function Wait-P1HarnessLogSummary {
    param(
        [int]$TimeoutSec = 30,
        [switch]$RequireFullPass
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $last = @{
        passed = $false
        source = "none"
        summaryLine = $null
        savedVars = $null
        harnessLog = @()
        failLines = @()
    }
    while ((Get-Date) -lt $deadline) {
        $sv = Read-P1HarnessSavedVars
        $logLines = @(Read-P1HarnessLog -LastN 120)
        $failLines = @(Get-P1HarnessFailLines -Lines $logLines)

        if (Test-P1SavedVarsSummaryPassed -SavedVars $sv) {
            $summaryLine = $null
            foreach ($line in ($logLines | Select-Object -Last 20)) {
                if (Test-P1HarnessSummaryLine -Line $line) { $summaryLine = $line; break }
            }
            if (-not $summaryLine) {
                $summaryLine = "lastTestPass=$($sv.lastTestPass)/$($sv.lastTestTotal)"
            }
            return @{
                passed = $true
                source = "SavedVariables"
                summaryLine = $summaryLine
                savedVars = $sv
                harnessLog = $logLines
                failLines = $failLines
            }
        }

        foreach ($line in ($logLines | Select-Object -Last 30)) {
            if (Test-P1HarnessSummaryLine -Line $line) {
                return @{
                    passed = $true
                    source = "harnessLog"
                    summaryLine = $line
                    savedVars = $sv
                    harnessLog = $logLines
                    failLines = $failLines
                }
            }
        }

        if (-not $RequireFullPass) {
            $chatFn = Get-Command Get-P1TestLinesFromChat -ErrorAction SilentlyContinue
            if ($chatFn) {
                foreach ($line in (Get-P1TestLinesFromChat -Lines 80)) {
                    if (Test-P1HarnessSummaryLine -Line $line) {
                        return @{
                            passed = $true
                            source = "chatLog"
                            summaryLine = $line
                            savedVars = $sv
                            harnessLog = $logLines
                            failLines = $failLines
                        }
                    }
                }
            }
        }

        $last.savedVars = $sv
        $last.harnessLog = $logLines
        $last.failLines = $failLines
        if ($sv.lastTestPass -ne $null -and $sv.lastTestTotal -ne $null -and $sv.lastTestTotal -gt 0) {
            $last.summaryLine = "lastTestPass=$($sv.lastTestPass)/$($sv.lastTestTotal)"
        }
        Start-Sleep -Milliseconds 500
    }
    return $last
}

function Wait-P1HarnessSavedVars {
    param(
        [int]$TimeoutSec = 30,
        [int]$MinPass = 0,
        [switch]$RequireFullPass
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $summary = Wait-P1HarnessLogSummary -TimeoutSec 1 -RequireFullPass:$RequireFullPass
        if ($summary.passed) {
            return $summary.savedVars
        }
        $sv = Read-P1HarnessSavedVars
        if ($sv.lastTestPass -ne $null -and $sv.lastTestTotal -ne $null) {
            if ($RequireFullPass) {
                if (Test-P1SavedVarsSummaryPassed -SavedVars $sv) { return $sv }
            } elseif ($MinPass -le 0 -or $sv.lastTestPass -ge $MinPass) {
                return $sv
            }
        }
        Start-Sleep -Milliseconds 800
    }
    return Read-P1HarnessSavedVars
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
            harnessLogCount = 0
            harnessLogLines = @()
            testsPassed = $false
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
    $harnessCount = ([regex]::Matches($text, '\["harnessLog"\]')).Count
    $harnessLines = @(Read-P1HarnessLog -LastN 120)
    $testsPassed = (Test-P1SavedVarsSummaryPassed -SavedVars @{
        lastTestPass = $pass
        lastTestTotal = $total
    })
    return @{
        path = $path
        exists = $true
        lastTestPass = $pass
        lastTestTotal = $total
        lastTestAt = $at
        devLogCount = $devCount
        harnessLogCount = $harnessCount
        harnessLogLines = $harnessLines
        testsPassed = $testsPassed
    }
}

function Read-P1HarnessLog {
    param([int]$LastN = 100)
    $path = Get-P1DruidGuideSavedVarsPath
    if (-not $path -or -not (Test-Path $path)) { return @() }
    $text = Get-Content -Path $path -Raw -Encoding UTF8
    $lines = New-Object System.Collections.Generic.List[string]

    # Prefer harnessLog ["line"] entries (mirrored [P1TEST] output from TestHarness.lua)
    if ($text -match '\["harnessLog"\]\s*=\s*\{') {
        $blockStart = $text.IndexOf('["harnessLog"]')
        $block = $text.Substring($blockStart)
        foreach ($m in [regex]::Matches($block, '\["line"\]\s*=\s*"((?:\\.|[^"\\])*)"')) {
            $val = $m.Groups[1].Value -replace '\\"', '"' -replace '\\\\', '\'
            if ($val -match '\[P1TEST\]') {
                $lines.Add($val) | Out-Null
            }
        }
    }

    if ($lines.Count -eq 0) {
        foreach ($m in [regex]::Matches($text, '\["line"\]\s*=\s*"((?:\\.|[^"\\])*)"')) {
            $val = $m.Groups[1].Value -replace '\\"', '"' -replace '\\\\', '\'
            if ($val -match '\[P1TEST\]') {
                $lines.Add($val) | Out-Null
            }
        }
    }

    if ($lines.Count -eq 0) {
        foreach ($m in [regex]::Matches($text, '\["msg"\]\s*=\s*"((?:\\.|[^"\\])*)"')) {
            $val = $m.Groups[1].Value -replace '\\"', '"' -replace '\\\\', '\'
            if ($val -match 'summary|PASS|FAIL|addon:') {
                $lines.Add("[P1TEST] SV $val") | Out-Null
            }
        }
    }

    if ($lines.Count -le $LastN) { return @($lines) }
    return @($lines | Select-Object -Last $LastN)
}

function Get-P1TestLines {
    param(
        [int]$Lines = 150,
        [switch]$PreferSavedVars
    )
    $sv = @(Read-P1HarnessLog -LastN $Lines)
    if ($PreferSavedVars -or $sv.Count -gt 0) { return $sv }
    $chatFn = Get-Command Get-P1TestLinesFromChat -ErrorAction SilentlyContinue
    if ($chatFn) {
        $chat = @(Get-P1TestLinesFromChat -Lines $Lines)
        if ($chat.Count -gt 0) { return $chat }
    }
    return $sv
}

function Get-CombinedChatTail {
    param([int]$Lines = 150)
    $chat = @(Get-ChatLogTail -Lines $Lines)
    if ($chat.Count -gt 0) { return $chat }
    if ($script:WowOcrChatLines -and $script:WowOcrChatLines.Count -gt 0) {
        return @($script:WowOcrChatLines | Select-Object -Last $Lines)
    }
    return @(Read-P1HarnessLog -LastN $Lines)
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
    $sv = $Report.savedVars
    $verification = $Report.verification

    if ($Report.addonsTxt) {
        foreach ($key in $Report.addonsTxt.Keys) {
            if ([int]$Report.addonsTxt[$key] -eq 0) {
                $tips.Add("P1DruidGuide OFF in $key - write-addons-txt failed or WoW overwrote AddOns.txt on exit") | Out-Null
            }
        }
    }
    if ($Report.frameXml -and $Report.frameXml.errors.Count -gt 0) {
        $tips.Add("FrameXML P1 load errors - fix Lua syntax in repo, re-run run-autonomous.ps1") | Out-Null
    }
    if ($Report.error) {
        $tips.Add("Automation exception: $($Report.error)") | Out-Null
    }

    if ($Report.success -and $verification -and $verification.source -eq "SavedVariables") {
        if (-not $Report.chatLog.exists) {
            $tips.Add("PASS verified via SavedVariables (lastTestPass==lastTestTotal); WoWChatLog.txt unavailable") | Out-Null
        }
        if ($Report.stepFail -gt 0) {
            $tips.Add("Step expects missed chat/OCR but SavedVariables confirm tests passed - safe to ignore step pass=false") | Out-Null
        }
        return $tips
    }

    if (-not $Report.chatLog.exists) {
        if ($Report.harnessLog -and $Report.harnessLog.count -gt 0) {
            $tips.Add("WoWChatLog.txt missing - primary verification is P1DruidGuideDB.harnessLog + lastTestPass in SavedVariables") | Out-Null
        } else {
            $tips.Add("WoWChatLog.txt missing - run /p1test run in-game; harness mirrors to SavedVariables on /reload") | Out-Null
        }
    }

    if ($sv -and $sv.exists -and $null -eq $sv.lastTestPass) {
        $tips.Add("TestHarness never ran - P1DruidGuide likely not loaded (check FrameXML + AddOns.txt)") | Out-Null
    } elseif ($sv -and $sv.exists -and $sv.lastTestPass -ne $null -and $sv.lastTestTotal -ne $null -and -not $sv.testsPassed) {
        $tips.Add("SavedVariables report $($sv.lastTestPass)/$($sv.lastTestTotal) pass - inspect harnessLog FAIL lines in report") | Out-Null
        $failLines = @()
        if ($Report.harnessLog -and $Report.harnessLog.lines) {
            $failLines = @(Get-P1HarnessFailLines -Lines $Report.harnessLog.lines)
        } elseif ($sv.harnessLogLines) {
            $failLines = @(Get-P1HarnessFailLines -Lines $sv.harnessLogLines)
        }
        foreach ($line in ($failLines | Select-Object -First 4)) {
            $short = $line -replace '^\[P1TEST\]\s+', ''
            $tips.Add("  FAIL: $short") | Out-Null
        }
    }

    if ($Report.stepFail -gt 0 -and $sv -and $sv.testsPassed) {
        $tips.Add("Steps failed on chat/OCR expect but SavedVariables show full pass - re-run or check verification.source") | Out-Null
    }

    if ($verification -and -not $verification.passed) {
        if ($verification.summaryLine) {
            $tips.Add("No PASS summary yet ($($verification.summaryLine)) - wait for /reload after /p1test run") | Out-Null
        } else {
            $tips.Add("No PASS summary in harnessLog or SavedVariables - ensure /p1test run completed before reload") | Out-Null
        }
    }

    if ($tips.Count -eq 0 -and -not $Report.success) {
        $tips.Add("Check harness-latest.json: savedVars.testsPassed, harnessLog.lines, screenshots, and step p1testLines") | Out-Null
    }
    return $tips
}

function Get-FeatureScopeManifest {
    $path = Join-Path $PSScriptRoot "feature-scope.json"
    if (-not (Test-Path $path)) { return $null }
    return Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-P1CheckResultsFromLog {
    param([string[]]$Lines)
    $map = @{}
    foreach ($line in $Lines) {
        if ($line -match '\[P1TEST\]\s+PASS\s+(.+)$') {
            $map[$Matches[1].Trim()] = $true
        } elseif ($line -match '\[P1TEST\]\s+FAIL\s+(.+?)(?:\s+—|$)') {
            $map[$Matches[1].Trim()] = $false
        }
    }
    return $map
}

function Get-ScopeFeatureStatus {
    param(
        $Manifest = $null,
        [string[]]$HarnessLines = @(),
        [hashtable]$SlashResults = $null
    )
    if (-not $Manifest) { $Manifest = Get-FeatureScopeManifest }
    if (-not $Manifest) { return @{ features = @(); allRequiredPass = $false } }

    $checks = Get-P1CheckResultsFromLog -Lines $HarnessLines
    $scopeComplete = $false
    foreach ($line in $HarnessLines) {
        if ($line -match 'scopeComplete=1') { $scopeComplete = $true }
    }

    $features = New-Object System.Collections.Generic.List[object]
    foreach ($feat in $Manifest.features) {
        $passed = 0
        $failed = @()
        foreach ($c in $feat.checks) {
            if ($checks.ContainsKey($c)) {
                if ($checks[$c]) { $passed++ } else { $failed += $c }
            } else {
                $failed += $c
            }
        }
        $ok = ($failed.Count -eq 0)
        $features.Add([ordered]@{
            id = $feat.id
            name = $feat.name
            required = [bool]$feat.required
            pass = $ok
            checksPassed = $passed
            checksTotal = @($feat.checks).Count
            failedChecks = @($failed)
        }) | Out-Null
    }

    if ($Manifest.slashSmoke) {
        foreach ($sm in $Manifest.slashSmoke) {
            $sid = $sm.feature
            $ok = $false
            if ($SlashResults -and $SlashResults.ContainsKey($sid)) {
                $ok = [bool]$SlashResults[$sid]
            }
            $features.Add([ordered]@{
                id = $sid
                name = "slash: $($sm.cmd)"
                required = $true
                pass = $ok
                checksPassed = if ($ok) { 1 } else { 0 }
                checksTotal = 1
                failedChecks = if ($ok) { @() } else { @($sm.expect) }
            }) | Out-Null
        }
    }

    $required = @($features | Where-Object { $_.required })
    $reqPass = @($required | Where-Object { $_.pass }).Count
    $allRequiredPass = ($reqPass -eq $required.Count) -and $scopeComplete

    return @{
        version = $Manifest.version
        scopeComplete = $scopeComplete
        allRequiredPass = $allRequiredPass
        requiredPass = $reqPass
        requiredTotal = $required.Count
        features = @($features)
    }
}

function Write-ScopeStatusReport {
    param($ScopeStatus)
    $dir = Get-HarnessReportDir
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $jsonPath = Join-Path $dir "scope-status.json"
    $gapsPath = Join-Path $dir "scope-gaps.txt"
    $ScopeStatus | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("P1 scope status v$($ScopeStatus.version)") | Out-Null
    $lines.Add("required: $($ScopeStatus.requiredPass)/$($ScopeStatus.requiredTotal) | scopeComplete=$($ScopeStatus.scopeComplete)") | Out-Null
    $lines.Add("") | Out-Null
    foreach ($f in $ScopeStatus.features) {
        if ($f.required -and -not $f.pass) {
            $lines.Add("FAIL [$($f.id)] $($f.name)") | Out-Null
            foreach ($fc in $f.failedChecks) { $lines.Add("  - $fc") | Out-Null }
        }
    }
    if ($ScopeStatus.allRequiredPass) {
        $lines.Add("") | Out-Null
        $lines.Add("ALL REQUIRED FEATURES PASS") | Out-Null
    }
    Set-Content -Path $gapsPath -Value $lines -Encoding UTF8
    return @{
        json = $jsonPath
        gaps = $gapsPath
    }
}

function Write-HarnessReport {
    param(
        [hashtable]$Report,
        [string]$FileName = "harness-latest.json"
    )
    $dir = Get-HarnessReportDir
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $path = Join-Path $dir $FileName

    $hLines = @()
    if ($Report.harnessLog -and $Report.harnessLog.lines) { $hLines = @($Report.harnessLog.lines) }
    elseif ($Report.savedVars -and $Report.savedVars.harnessLogLines) { $hLines = @($Report.savedVars.harnessLogLines) }
    $slashMap = @{}
    if ($Report.scopeSlash) {
        foreach ($k in $Report.scopeSlash.Keys) { $slashMap[$k] = $Report.scopeSlash[$k] }
    }
    $scope = Get-ScopeFeatureStatus -HarnessLines $hLines -SlashResults $slashMap
    $Report.scope = $scope
    $Report.scopeComplete = $scope.allRequiredPass
    if ($FileName -eq "harness-latest.json") {
        Write-ScopeStatusReport -ScopeStatus $scope | Out-Null
    }

    $Report.recommendations = @(New-HarnessRecommendations -Report $Report)
    if (-not $scope.allRequiredPass) {
        $gaps = @($scope.features | Where-Object { $_.required -and -not $_.pass } | Select-Object -First 5)
        foreach ($g in $gaps) {
            $Report.recommendations += "SCOPE GAP [$($g.id)]: $($g.failedChecks -join ', ')"
        }
    }
    $json = $Report | ConvertTo-Json -Depth 10
    Set-Content -Path $path -Value $json -Encoding UTF8
    return (Resolve-Path $path).Path
}