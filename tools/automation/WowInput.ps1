# Win32 input + WoW chat log tail for P1 dev automation (HWND + SendInput only)
$ErrorActionPreference = "Stop"

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class WowWin32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    public const int SW_RESTORE = 9;
    public const uint INPUT_KEYBOARD = 1;
    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const uint KEYEVENTF_UNICODE = 0x0004;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct INPUT {
        public uint type;
        public InputUnion U;
    }
    [StructLayout(LayoutKind.Explicit)] public struct InputUnion {
        [FieldOffset(0)] public KEYBDINPUT ki;
    }
    [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT {
        public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo;
    }
    public static void KeyTap(ushort vk) {
        INPUT down = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = vk } } };
        INPUT up = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = vk, dwFlags = KEYEVENTF_KEYUP } } };
        SendInput(1, new INPUT[] { down }, Marshal.SizeOf(typeof(INPUT)));
        SendInput(1, new INPUT[] { up }, Marshal.SizeOf(typeof(INPUT)));
    }
    public static void ChordTap(ushort vk, ushort modifier) {
        INPUT modDown = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = modifier } } };
        INPUT keyDown = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = vk } } };
        INPUT keyUp = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = vk, dwFlags = KEYEVENTF_KEYUP } } };
        INPUT modUp = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wVk = modifier, dwFlags = KEYEVENTF_KEYUP } } };
        SendInput(1, new INPUT[] { modDown }, Marshal.SizeOf(typeof(INPUT)));
        SendInput(1, new INPUT[] { keyDown }, Marshal.SizeOf(typeof(INPUT)));
        SendInput(1, new INPUT[] { keyUp }, Marshal.SizeOf(typeof(INPUT)));
        SendInput(1, new INPUT[] { modUp }, Marshal.SizeOf(typeof(INPUT)));
    }
    public static void UnicodeChar(char ch) {
        ushort scan = (ushort)ch;
        INPUT down = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wScan = scan, dwFlags = KEYEVENTF_UNICODE } } };
        INPUT up = new INPUT { type = INPUT_KEYBOARD, U = new InputUnion { ki = new KEYBDINPUT { wScan = scan, dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP } } };
        SendInput(1, new INPUT[] { down }, Marshal.SizeOf(typeof(INPUT)));
        SendInput(1, new INPUT[] { up }, Marshal.SizeOf(typeof(INPUT)));
    }
    public static void UnicodeText(string text) {
        if (text == null) return;
        foreach (char ch in text) { UnicodeChar(ch); }
    }
    public static void LeftClick(int x, int y) {
        SetCursorPos(x, y);
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero);
    }
}
"@

function Get-WowPath {
    $cfg = Join-Path (Split-Path $PSScriptRoot -Parent) "wow-path.cfg"
    if (Test-Path $cfg) {
        return (Get-Content $cfg -Raw).Trim()
    }
    throw "Missing tools/wow-path.cfg - run PLAY.bat once"
}

function Get-WowLoginCredentials {
    $cfg = Join-Path (Split-Path $PSScriptRoot -Parent) "wow-login.cfg"
    if (-not (Test-Path $cfg)) { return $null }
    $account = $null
    $password = $null
    foreach ($line in (Get-Content $cfg -Encoding UTF8)) {
        $line = $line.Trim()
        if ($line -match '^\s*#' -or -not $line) { continue }
        if ($line -match '^account\s*=\s*(.+)$') { $account = $Matches[1].Trim() }
        if ($line -match '^password\s*=\s*(.+)$') { $password = $Matches[1].Trim() }
    }
    if ($account -and $password) {
        return @{ account = $account; password = $password }
    }
    return $null
}

function Send-WowUnicodeLine {
    param([string]$Text)
    Focus-WowWindow | Out-Null
    [WowWin32]::UnicodeText($Text)
    Start-Sleep -Milliseconds 120
}

function Invoke-WowLoginScreen {
    param(
        [string]$Account,
        [string]$Password
    )
    if (-not $Account -or -not $Password) { return $false }
    Focus-WowWindow | Out-Null
    Start-Sleep -Milliseconds 800
    $r = Get-WowWindowRect
    $cx = $r.left + [int]($r.width * 0.50)
    $cy = $r.top + [int]($r.height * 0.42)
    Click-WowScreen -X $cx -Y $cy -DelayMs 200
    Start-Sleep -Milliseconds 300
    [WowWin32]::ChordTap(0x41, 0x11)
    Start-Sleep -Milliseconds 100
    Send-WowUnicodeLine $Account
    [WowWin32]::KeyTap(0x09)
    Start-Sleep -Milliseconds 200
    Send-WowUnicodeLine $Password
    Start-Sleep -Milliseconds 200
    [WowWin32]::KeyTap(0x0D)
    Start-Sleep -Seconds 6
    return $true
}

function Invoke-WowEnterWorld {
    Focus-WowWindow | Out-Null
    Start-Sleep -Seconds 2
    [WowWin32]::KeyTap(0x0D)
    Start-Sleep -Seconds 10
}

function Test-WowRunning {
    return [bool](Get-Process -Name "Wow" -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Get-WowProcess {
    $proc = Get-Process -Name "Wow" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { throw "Wow.exe not running" }
    return $proc
}

function Get-WowWindowTitle {
    try {
        return (Get-WowProcess).MainWindowTitle
    } catch {
        return ""
    }
}

function Send-WowKey {
    param([uint16]$Vk)
    Focus-WowWindow | Out-Null
    [WowWin32]::KeyTap($Vk)
}

function Start-WowClient {
    param([int]$WaitSec = 240)
    if (Test-WowRunning) { return $true }
    $wow = Get-WowPath
    $exe = Join-Path $wow "Wow.exe"
    if (-not (Test-Path $exe)) { throw "Wow.exe not found: $exe" }
    Start-Process -FilePath $exe -WorkingDirectory $wow | Out-Null
    $deadline = (Get-Date).AddSeconds($WaitSec)
    while ((Get-Date) -lt $deadline) {
        $proc = Get-Process -Name "Wow" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($proc -and $proc.MainWindowHandle -ne [IntPtr]::Zero) {
            Start-Sleep -Seconds 3
            return $true
        }
        Start-Sleep -Seconds 2
    }
    throw "WoW window not ready within ${WaitSec}s (log in at character select if needed)"
}

function Ensure-WowReady {
    param(
        [int]$StartWaitSec = 240,
        [int]$InWorldTimeoutSec = 90,
        [switch]$SkipInWorldCheck,
        [switch]$SkipAutoLogin
    )
    if (-not (Test-WowRunning)) {
        Start-WowClient -WaitSec $StartWaitSec | Out-Null
    }
    Focus-WowWindow | Out-Null
    if ($SkipInWorldCheck) { return $true }

    $inWorld = Wait-WowPlayerInWorld -TimeoutSec 12
    if (-not $inWorld -and -not $SkipAutoLogin) {
        $creds = Get-WowLoginCredentials
        if ($creds) {
            Write-Host "Attempting WoW login (tools/wow-login.cfg) ..." -ForegroundColor DarkCyan
            Invoke-WowLoginScreen -Account $creds.account -Password $creds.password | Out-Null
            Invoke-WowEnterWorld
            $inWorld = Wait-WowPlayerInWorld -TimeoutSec $InWorldTimeoutSec
        }
    }
    if (-not $inWorld) {
        $inWorld = Wait-WowPlayerInWorld -TimeoutSec $InWorldTimeoutSec
    }
    if (-not $inWorld) {
        throw "WoW not in-world within ${InWorldTimeoutSec}s (check wow-login.cfg or log in manually)"
    }
    return $true
}

function Wait-FrameXmlUpdated {
    param(
        [int]$TimeoutSec = 45,
        [long]$SinceLength = -1
    )
    $path = Get-FrameXmlLogPath
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $path) {
            $len = (Get-Item $path).Length
            if ($SinceLength -lt 0 -or $len -gt $SinceLength) { return $len }
        }
        Start-Sleep -Milliseconds 500
    }
    if (Test-Path $path) { return (Get-Item $path).Length }
    return 0
}

function Get-WowWindowRect {
    $hwnd = Focus-WowWindow
    $rect = New-Object WowWin32+RECT
    [void][WowWin32]::GetWindowRect($hwnd, [ref]$rect)
    return @{
        hwnd = $hwnd
        left = $rect.Left
        top = $rect.Top
        right = $rect.Right
        bottom = $rect.Bottom
        width = $rect.Right - $rect.Left
        height = $rect.Bottom - $rect.Top
    }
}

function Click-WowChatEditBox {
    param([int]$DelayMs = 180)
    $r = Get-WowWindowRect
    if ($r.width -le 8 -or $r.height -le 8) { return }
    $x = $r.left + [int]($r.width * 0.08)
    $y = $r.bottom - [int]($r.height * 0.06)
    Click-WowScreen -X $x -Y $y -DelayMs $DelayMs
}

function Test-WowSlashCommandSeen {
    param([string]$ExpectPattern)
    if (-not $ExpectPattern) { return $true }
    $tailFn = Get-Command Get-CombinedChatTail -ErrorAction SilentlyContinue
    if ($tailFn) {
        foreach ($line in (Get-CombinedChatTail -Lines 80)) {
            if ($line -match $ExpectPattern) { return $true }
        }
    } else {
        foreach ($line in (Get-ChatLogTail -Lines 80)) {
            if ($line -match $ExpectPattern) { return $true }
        }
    }
    $readLogFn = Get-Command Read-P1HarnessLog -ErrorAction SilentlyContinue
    if ($readLogFn) {
        foreach ($line in (Read-P1HarnessLog -LastN 40)) {
            if ($line -match $ExpectPattern) { return $true }
        }
    }
    return $false
}

function Send-WowSlashCommandVerified {
    param(
        [string]$Command,
        [string]$ExpectPattern = "",
        [int]$MaxAttempts = 3,
        [int]$VerifyTimeoutMs = 3500,
        [switch]$NoDismiss
    )
    $ok = $false
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Send-WowSlashCommand -Command $Command -NoDismiss:($NoDismiss -and $attempt -eq 1)
        if (-not $ExpectPattern) { return $true }
        $deadline = (Get-Date).AddMilliseconds($VerifyTimeoutMs)
        while ((Get-Date) -lt $deadline) {
            if (Test-WowSlashCommandSeen -ExpectPattern $ExpectPattern) {
                return $true
            }
            Start-Sleep -Milliseconds 350
        }
        if ($attempt -lt $MaxAttempts) {
            Dismiss-WowUI -EscapeCount 6 -ClickWorld -ClickChat
        }
    }
    return $false
}

function Wait-WowPlayerInWorld {
    param([int]$TimeoutSec = 90)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (-not (Test-WowRunning)) { return $null }
        Dismiss-WowUI -EscapeCount 4 -ClickChat
        Send-WowSlashCommand "/p1scan" -NoDismiss
        Start-Sleep -Milliseconds 1800
        $tailFn = Get-Command Get-CombinedChatTail -ErrorAction SilentlyContinue
        $probeLines = if ($tailFn) { @(Get-CombinedChatTail -Lines 40) } else { @(Get-ChatLogTail -Lines 40) }
        foreach ($line in $probeLines) {
            if ($line -match 'P1 Scan') { return "ok" }
            if ($line -match '\[P1TEST\]') { return "ok" }
        }
        $readSvFn = Get-Command Read-P1HarnessSavedVars -ErrorAction SilentlyContinue
        if ($readSvFn) {
            $sv = Read-P1HarnessSavedVars
            if ($sv.lastTestPass -ne $null -and $sv.lastTestTotal -ne $null) { return "ok" }
        }
        Start-Sleep -Seconds 2
    }
    return $null
}

function Invoke-WowRelogCycle {
    param(
        [int]$CampSec = 26,
        [int]$LoadSec = 45,
        [int]$ReloadSec = 14
    )
    Focus-WowWindow | Out-Null
    Send-WowKey ([uint16]0x1B) | Out-Null  # Escape - close dialogs
    Start-Sleep -Milliseconds 300
    Send-WowKey ([uint16]0x1B) | Out-Null
    Start-Sleep -Milliseconds 300

    $xmlBefore = Wait-FrameXmlUpdated -TimeoutSec 2
    Send-WowSlashCommand "/camp"
    Start-Sleep -Seconds $CampSec

    Focus-WowWindow | Out-Null
    Send-WowKey ([uint16]0x0D) | Out-Null  # Enter - enter world from character select
    Enable-WowChatLog
    $toon = Wait-WowPlayerInWorld -TimeoutSec $LoadSec
    if (-not $toon) {
        Start-Sleep -Seconds 8
    }

    $xmlMid = Wait-FrameXmlUpdated -TimeoutSec 5 -SinceLength $xmlBefore
    Send-WowSlashCommand "/reload"
    Start-Sleep -Seconds $ReloadSec
    Wait-FrameXmlUpdated -TimeoutSec 25 -SinceLength $xmlMid | Out-Null
    $null = Wait-WowPlayerInWorld -TimeoutSec 40
}

function Enable-WowChatLogConfig {
    $wow = Get-WowPath
    $files = New-Object System.Collections.Generic.List[string]
    $cfg = Join-Path $wow "WTF\Config.wtf"
    if (Test-Path $cfg) { [void]$files.Add($cfg) }
    $acct = Join-Path $wow "WTF\Account"
    if (Test-Path $acct) {
        Get-ChildItem -Path $acct -Recurse -Filter "config-cache.wtf" -ErrorAction SilentlyContinue |
            ForEach-Object { [void]$files.Add($_.FullName) }
    }
    foreach ($file in $files) {
        $lines = @(Get-Content $file -Encoding UTF8)
        $has = $false
        $out = New-Object System.Collections.Generic.List[string]
        foreach ($line in $lines) {
            if ($line -match '^SET chatLog ') {
                $out.Add('SET chatLog "1"') | Out-Null
                $has = $true
            } else {
                $out.Add($line) | Out-Null
            }
        }
        if (-not $has) { $out.Add('SET chatLog "1"') | Out-Null }
        Set-Content -Path $file -Value $out -Encoding ASCII
    }
}

function Enable-WowChatLog {
    Enable-WowChatLogConfig
    $logDir = Join-Path (Get-WowPath) "Logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $path = Get-WowChatLogPath
    for ($i = 0; $i -lt 3; $i++) {
        Send-WowSlashCommandVerified -Command "/chatlog" -MaxAttempts 2 -VerifyTimeoutMs 1200
        Start-Sleep -Milliseconds 600
        if (Test-Path $path) { return $true }
        Dismiss-WowUI -EscapeCount 5 -ClickChat
    }
    return (Test-Path $path)
}

function Focus-WowWindow {
    $proc = Get-WowProcess
    $hwnd = $proc.MainWindowHandle
    if ($hwnd -eq [IntPtr]::Zero) { throw "WoW window not found (try windowed mode)" }
    if ([WowWin32]::IsIconic($hwnd)) {
        [void][WowWin32]::ShowWindow($hwnd, [WowWin32]::SW_RESTORE)
        Start-Sleep -Milliseconds 300
    }
    $fg = [WowWin32]::GetForegroundWindow()
    $fgPid = [uint32]0
    $wowPid = [uint32]0
    $fgThread = [WowWin32]::GetWindowThreadProcessId($fg, [ref]$fgPid)
    $wowThread = [WowWin32]::GetWindowThreadProcessId($hwnd, [ref]$wowPid)
    $curThread = [WowWin32]::GetCurrentThreadId()
    $attached = $false
    if ($fgThread -ne $wowThread) {
        $attached = [WowWin32]::AttachThreadInput($curThread, $wowThread, $true)
    }
    [void][WowWin32]::SetForegroundWindow($hwnd)
    if ($attached) {
        [void][WowWin32]::AttachThreadInput($curThread, $wowThread, $false)
    }
    Start-Sleep -Milliseconds 250
    return $hwnd
}

function Escape-SendKeysChar {
    param([char]$Ch)
    $special = '+^%~{}()[]'
    if ($special.IndexOf($Ch) -ge 0) {
        return '{' + $Ch + '}'
    }
    return [string]$Ch
}

function Send-WowKeys {
    param([string]$Text)
    Add-Type -AssemblyName System.Windows.Forms
    $escaped = -join ($Text.ToCharArray() | ForEach-Object { Escape-SendKeysChar $_ })
    [System.Windows.Forms.SendKeys]::SendWait($escaped)
}

function Dismiss-WowUI {
    param(
        [int]$EscapeCount = 5,
        [switch]$ClickChat,
        [switch]$ClickWorld
    )
    $r = Get-WowWindowRect
    if ($ClickWorld -or $r.width -gt 0) {
        $cx = $r.left + [int]($r.width * 0.55)
        $cy = $r.top + [int]($r.height * 0.45)
        Click-WowScreen -X $cx -Y $cy -DelayMs 120
        Start-Sleep -Milliseconds 120
    }
    for ($i = 0; $i -lt $EscapeCount; $i++) {
        [WowWin32]::KeyTap(0x1B)
        Start-Sleep -Milliseconds 220
    }
    if ($ClickChat) {
        Click-WowChatEditBox -DelayMs 120
        Start-Sleep -Milliseconds 120
        [WowWin32]::KeyTap(0x1B)
        Start-Sleep -Milliseconds 120
    }
}

function Send-WowSlashCommand {
    param(
        [string]$Command,
        [int]$PreDelayMs = 300,
        [ValidateSet("unicode", "paste", "auto")]
        [string]$InputMode = "auto",
        [switch]$NoDismiss,
        [switch]$ClickChatFirst
    )
    if (-not $Command.StartsWith("/")) { $Command = "/" + $Command }
    Focus-WowWindow | Out-Null
    if (-not $NoDismiss) { Dismiss-WowUI -EscapeCount 5 -ClickWorld -ClickChat:$ClickChatFirst }
    Start-Sleep -Milliseconds $PreDelayMs
    if ($ClickChatFirst -or $NoDismiss) {
        Click-WowChatEditBox -DelayMs 100
        Start-Sleep -Milliseconds 120
    }
    [WowWin32]::KeyTap(0x0D)
    Start-Sleep -Milliseconds 320

    $usedUnicode = $false
    if ($InputMode -eq "unicode" -or $InputMode -eq "auto") {
        try {
            [WowWin32]::UnicodeText($Command)
            $usedUnicode = $true
        } catch {
            $usedUnicode = $false
        }
    }
    if (-not $usedUnicode) {
        Set-Clipboard -Value $Command
        Start-Sleep -Milliseconds 80
        [WowWin32]::ChordTap(0x56, 0x11)
    }
    Start-Sleep -Milliseconds 220
    [WowWin32]::KeyTap(0x0D)
    Start-Sleep -Milliseconds 200
}

function Click-WowScreen {
    param([int]$X, [int]$Y, [int]$DelayMs = 200)
    Focus-WowWindow | Out-Null
    Start-Sleep -Milliseconds $DelayMs
    [WowWin32]::LeftClick($X, $Y)
}

function Get-WowChatLogPath {
    $wow = Get-WowPath
    $path = Join-Path $wow "Logs\WoWChatLog.txt"
    return $path
}

function Get-ChatLogTail {
    param([int]$Lines = 80)
    $path = Get-WowChatLogPath
    if (-not (Test-Path $path)) { return @() }
    return Get-Content -Path $path -Tail $Lines -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Wait-ForP1TestLines {
    param(
        [int]$TimeoutSec = 25,
        [string]$RequiredPattern = "\[P1TEST\].*summary"
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $seen = @{}
    $matches = New-Object System.Collections.Generic.List[string]
    while ((Get-Date) -lt $deadline) {
        foreach ($line in (Get-ChatLogTail -Lines 120)) {
            if ($line -notmatch "\[P1TEST\]") { continue }
            if ($seen.ContainsKey($line)) { continue }
            $seen[$line] = $true
            $matches.Add($line) | Out-Null
            if ($line -match $RequiredPattern) {
                return $matches
            }
        }
        Start-Sleep -Milliseconds 400
    }
    return $matches
}

function Invoke-WowClickSequence {
    param([object[]]$Clicks)
    foreach ($c in $Clicks) {
        Click-WowScreen -X $c.X -Y $c.Y -DelayMs ($c.DelayMs | ForEach-Object { if ($_){$_} else {300} })
        Start-Sleep -Milliseconds ($c.AfterMs | ForEach-Object { if ($_){$_} else {500} })
    }
}

function Get-FrameXmlLogPath {
    return Join-Path (Get-WowPath) "Logs\FrameXML.log"
}

function Get-FrameXmlTail {
    param([int]$Lines = 120)
    $path = Get-FrameXmlLogPath
    if (-not (Test-Path $path)) { return @() }
    return @(Get-Content -Path $path -Tail $Lines -Encoding UTF8 -ErrorAction SilentlyContinue)
}

function Get-FrameXmlOffset {
    $path = Get-FrameXmlLogPath
    if (-not (Test-Path $path)) { return 0 }
    return [long](Get-Item $path).Length
}

function Get-P1FrameErrorsSince {
    param([long]$Offset = 0)
    $path = Get-FrameXmlLogPath
    if (-not (Test-Path $path)) { return @() }
    $len = (Get-Item $path).Length
    if ($len -le $Offset) { return @() }
    $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $null = $fs.Seek($Offset, [System.IO.SeekOrigin]::Begin)
        $buf = New-Object byte[] ($len - $Offset)
        $read = $fs.Read($buf, 0, $buf.Length)
        $text = [System.Text.Encoding]::UTF8.GetString($buf, 0, $read)
    } finally {
        $fs.Close()
    }
    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($text -split "`n")) {
        $line = $line.TrimEnd("`r")
        if (-not $line) { continue }
        if ($line -match 'Error loading Interface\\AddOns\\P1') {
            $errors.Add($line) | Out-Null
            continue
        }
        if ($line -match 'Interface\\AddOns\\P1[^:]*:\d+:') {
            $errors.Add($line) | Out-Null
        }
    }
    return $errors
}

function Get-P1FrameErrors {
    param([int]$TailLines = 120)
    return @(Get-P1FrameErrorsSince -Offset 0) | Select-Object -Last 20
}

function Capture-WowWindow {
    param(
        [string]$OutPath = "",
        [string]$Label = "capture"
    )
    Add-Type -AssemblyName System.Drawing
    $hwnd = Focus-WowWindow
    $rect = New-Object WowWin32+RECT
    [void][WowWin32]::GetWindowRect($hwnd, [ref]$rect)
    $w = $rect.Right - $rect.Left
    $h = $rect.Bottom - $rect.Top
    if ($w -le 8 -or $h -le 8) { throw "WoW window rect too small ($w x $h) - use windowed mode" }

    if (-not $OutPath) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $dir = Join-Path $PSScriptRoot "reports\screenshots"
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $OutPath = Join-Path $dir ("{0}-{1}.png" -f $Label, $stamp)
    } else {
        $parent = Split-Path -Parent $OutPath
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }

    $bmp = New-Object System.Drawing.Bitmap $w, $h
    try {
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size $w, $h))
        $g.Dispose()
        $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $bmp.Dispose()
    }
    return (Resolve-Path $OutPath).Path
}

function Get-P1TestLinesFromChat {
    param([int]$Lines = 150)
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in (Get-ChatLogTail -Lines $Lines)) {
        if ($line -match '\[P1TEST\]') { $out.Add($line) | Out-Null }
    }
    return $out
}

function Test-P1SummaryPassed {
    param([string[]]$ChatLines)
    $fn = Get-Command Test-P1HarnessSummaryLine -ErrorAction SilentlyContinue
    foreach ($line in $ChatLines) {
        if ($fn) {
            if (Test-P1HarnessSummaryLine -Line $line) { return $true }
        } elseif ($line -match '\[P1TEST\].*PASS.*summary') {
            return $true
        }
    }
    return $false
}

