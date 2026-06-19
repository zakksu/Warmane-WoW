# P1 automation control panel — separate window + tray icon + killswitch.
# Requires -STA (WinForms). Start via START_AUTO.bat (minimized).
param(
    [switch]$Minimized,
    [int]$DebounceSec = 10
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$here = $PSScriptRoot
. (Join-Path $here "harness-control.ps1")

$repo = Split-Path (Split-Path $here -Parent) -Parent
$autoScript = Join-Path $here "run-autonomous.ps1"
$watchRoots = @(
    (Join-Path $repo "PhaseOne_Druid_LevelingPack\Interface\AddOns"),
    (Join-Path $repo "PhaseOne_LevelingPack\Interface\AddOns")
)

$script:TestRunning = $false
$script:PendingWatch = $false
$script:DebounceTimer = $null
$script:UiTimer = $null

function Update-PanelStatus {
    param($StatusLabel, $DetailLabel, $PauseBtn, $ResumeBtn)
    $s = Get-HarnessControlState
    $latest = Get-HarnessLatestSummary
    if ($s.paused) {
        $StatusLabel.Text = "PAUSED — safe to play"
        $StatusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
        $PauseBtn.Enabled = $false
        $ResumeBtn.Enabled = $true
    } elseif ($script:TestRunning) {
        $StatusLabel.Text = "Testing WoW ..."
        $StatusLabel.ForeColor = [System.Drawing.Color]::DodgerBlue
        $PauseBtn.Enabled = $false
        $ResumeBtn.Enabled = $false
    } else {
        $StatusLabel.Text = "Watching — auto-test on save"
        $StatusLabel.ForeColor = [System.Drawing.Color]::ForestGreen
        $PauseBtn.Enabled = $true
        $ResumeBtn.Enabled = $false
    }
    $detail = ""
    if ($latest) {
        $detail = "Last: $(if ($latest.success) { 'PASS' } else { 'FAIL' }) $($latest.suite) $($latest.timestamp)"
        if ($latest.message) { $detail += " — $($latest.message)" }
    } elseif ($s.lastMessage) {
        $detail = $s.lastMessage
    }
    $DetailLabel.Text = $detail
}

function Start-AutoTestJob {
    param($StatusLabel, $DetailLabel, $PauseBtn, $ResumeBtn)
    if ($script:TestRunning) { return }
    if (Test-HarnessControlPaused) { return }
    $script:TestRunning = $true
    Update-PanelStatus $StatusLabel $DetailLabel $PauseBtn $ResumeBtn
    $pwsh = (Get-Command powershell).Source
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$autoScript`" -Suite scope -MaxCycles 1 -SkipRelog -UntilScopeComplete"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $pwsh
    $psi.Arguments = $args
    $psi.WorkingDirectory = $repo
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.WaitForExit()
    $ok = ($proc.ExitCode -eq 0)
    Update-HarnessControlRunResult -Success $ok -Message $(if ($ok) { "smoke pass" } else { "smoke fail (exit $($proc.ExitCode))" })
    $script:TestRunning = $false
    Update-PanelStatus $StatusLabel $DetailLabel $PauseBtn $ResumeBtn
}

function Queue-WatchedTest {
    param($StatusLabel, $DetailLabel, $PauseBtn, $ResumeBtn)
    if (Test-HarnessControlPaused) { return }
    if ($script:PendingWatch) { return }
    $script:PendingWatch = $true
    if ($script:DebounceTimer) { $script:DebounceTimer.Stop(); $script:DebounceTimer.Dispose() }
    $script:DebounceTimer = New-Object System.Windows.Forms.Timer
    $script:DebounceTimer.Interval = ($DebounceSec * 1000)
    $script:DebounceTimer.Add_Tick({
        $script:DebounceTimer.Stop()
        $script:PendingWatch = $false
        if (-not (Test-HarnessControlPaused)) {
            Start-AutoTestJob $StatusLabel $DetailLabel $PauseBtn $ResumeBtn
        }
    })
    $script:DebounceTimer.Start()
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "P1 Auto Control"
$form.Size = New-Object System.Drawing.Size(380, 220)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.ShowInTaskbar = $true

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(12, 12)
$status.Size = New-Object System.Drawing.Size(350, 24)
$status.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$detail = New-Object System.Windows.Forms.Label
$detail.Location = New-Object System.Drawing.Point(12, 40)
$detail.Size = New-Object System.Drawing.Size(350, 48)
$detail.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)

$btnPause = New-Object System.Windows.Forms.Button
$btnPause.Location = New-Object System.Drawing.Point(12, 100)
$btnPause.Size = New-Object System.Drawing.Size(110, 32)
$btnPause.Text = "Pause (play)"
$btnPause.Add_Click({
    Set-HarnessControlPaused -Reason "panel pause — play mode"
    Update-PanelStatus $status $detail $btnPause $btnResume
    $tray.ShowBalloonTip(3000, "P1 Auto", "Paused — WoW is yours. Click Resume when agents can run again.", [System.Windows.Forms.ToolTipIcon]::Info)
})

$btnResume = New-Object System.Windows.Forms.Button
$btnResume.Location = New-Object System.Drawing.Point(128, 100)
$btnResume.Size = New-Object System.Drawing.Size(110, 32)
$btnResume.Text = "Resume"
$btnResume.Add_Click({
    Clear-HarnessControlPaused
    Update-PanelStatus $status $detail $btnPause $btnResume
    $tray.ShowBalloonTip(2000, "P1 Auto", "Resumed — watching for addon saves.", [System.Windows.Forms.ToolTipIcon]::Info)
})

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Location = New-Object System.Drawing.Point(244, 100)
$btnRun.Size = New-Object System.Drawing.Size(110, 32)
$btnRun.Text = "Run now"
$btnRun.Add_Click({
    if (-not (Test-HarnessControlPaused)) {
        Start-AutoTestJob $status $detail $btnPause $btnResume
    }
})

$btnHide = New-Object System.Windows.Forms.Button
$btnHide.Location = New-Object System.Drawing.Point(12, 145)
$btnHide.Size = New-Object System.Drawing.Size(168, 28)
$btnHide.Text = "Hide to tray"
$btnHide.Add_Click({ $form.Hide() })

$btnQuit = New-Object System.Windows.Forms.Button
$btnQuit.Location = New-Object System.Drawing.Point(186, 145)
$btnQuit.Size = New-Object System.Drawing.Size(168, 28)
$btnQuit.Text = "Quit daemon"
$btnQuit.Add_Click({
    $script:ForceQuit = $true
    Set-HarnessControlState @{ daemonRunning = $false; pid = $null }
    if (Test-Path $script:HarnessDaemonPid) { Remove-Item $script:HarnessDaemonPid -Force }
    $tray.Visible = $false
    $form.Close()
})

$hint = New-Object System.Windows.Forms.Label
$hint.Location = New-Object System.Drawing.Point(12, 178)
$hint.Size = New-Object System.Drawing.Size(350, 18)
$hint.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$hint.ForeColor = [System.Drawing.Color]::Gray
$hint.Text = "Killswitch: double-click STOP_AUTO.bat or Pause above"

$form.Controls.AddRange(@($status, $detail, $btnPause, $btnResume, $btnRun, $btnHide, $btnQuit, $hint))

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.SystemIcons]::Shield
$tray.Text = "P1 Auto Control"
$tray.Visible = $true
$tray.Add_DoubleClick({ if ($form.Visible) { $form.Hide() } else { $form.Show(); $form.WindowState = "Normal"; $form.Activate() } })

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$null = $menu.Items.Add("Show", $null, { $form.Show(); $form.WindowState = "Normal"; $form.Activate() })
$null = $menu.Items.Add("Pause (play WoW)", $null, { Set-HarnessControlPaused -Reason "tray pause"; Update-PanelStatus $status $detail $btnPause $btnResume })
$null = $menu.Items.Add("Resume", $null, { Clear-HarnessControlPaused; Update-PanelStatus $status $detail $btnPause $btnResume })
$null = $menu.Items.Add("-")
$null = $menu.Items.Add("Quit", $null, { $btnQuit.PerformClick() })
$tray.ContextMenuStrip = $menu

$form.Add_FormClosing({
    param($sender, $e)
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and -not $script:ForceQuit) {
        $e.Cancel = $true
        $form.Hide()
        $tray.ShowBalloonTip(2000, "P1 Auto", "Running in tray. Double-click icon to reopen.", [System.Windows.Forms.ToolTipIcon]::Info)
    }
})

$watchers = @()
foreach ($root in $watchRoots) {
    if (-not (Test-Path $root)) { continue }
    foreach ($ext in @("*.lua", "*.xml")) {
        $w = New-Object System.IO.FileSystemWatcher $root, $ext
        $w.IncludeSubdirectories = $true
        $w.EnableRaisingEvents = $true
        $w.Add_Changed({ Queue-WatchedTest $status $detail $btnPause $btnResume })
        $w.Add_Created({ Queue-WatchedTest $status $detail $btnPause $btnResume })
        $w.Add_Renamed({ Queue-WatchedTest $status $detail $btnPause $btnResume })
        $watchers += $w
    }
}

Initialize-HarnessControl
Set-Content -Path $script:HarnessDaemonPid -Value $PID -Encoding ASCII
Set-HarnessControlState @{
    daemonRunning = $true
    pid = $PID
    watchEnabled = $true
    lastMessage = "daemon started"
}

$script:UiTimer = New-Object System.Windows.Forms.Timer
$script:UiTimer.Interval = 4000
$script:UiTimer.Add_Tick({ Update-PanelStatus $status $detail $btnPause $btnResume })
$script:UiTimer.Start()

Update-PanelStatus $status $detail $btnPause $btnResume
if ($Minimized) { $form.Hide(); $tray.ShowBalloonTip(3000, "P1 Auto", "Daemon started in tray. Pause before you play.", [System.Windows.Forms.ToolTipIcon]::Info) }

[System.Windows.Forms.Application]::Run($form)

$tray.Visible = $false
$tray.Dispose()
if ($script:UiTimer) { $script:UiTimer.Stop(); $script:UiTimer.Dispose() }
if ($script:DebounceTimer) { $script:DebounceTimer.Stop(); $script:DebounceTimer.Dispose() }
foreach ($w in $watchers) { $w.Dispose() }
Set-HarnessControlState @{ daemonRunning = $false; pid = $null }