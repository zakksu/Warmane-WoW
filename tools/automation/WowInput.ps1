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
    public const int SW_RESTORE = 9;
    public const uint INPUT_KEYBOARD = 1;
    public const uint KEYEVENTF_KEYUP = 0x0002;
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

function Get-WowProcess {
    $proc = Get-Process -Name "Wow" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { throw "Wow.exe not running - log in first" }
    return $proc
}

function Focus-WowWindow {
    $proc = Get-WowProcess
    $hwnd = $proc.MainWindowHandle
    if ($hwnd -eq [IntPtr]::Zero) { throw "WoW window not found (try windowed mode)" }
    if ([WowWin32]::IsIconic($hwnd)) {
        [void][WowWin32]::ShowWindow($hwnd, [WowWin32]::SW_RESTORE)
        Start-Sleep -Milliseconds 300
    }
    [void][WowWin32]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 200
    return $hwnd
}

function Send-WowKeys {
    param([string]$Text)
    Add-Type -AssemblyName System.Windows.Forms
    foreach ($ch in $Text.ToCharArray()) {
        [System.Windows.Forms.SendKeys]::SendWait([string]$ch)
        Start-Sleep -Milliseconds 12
    }
}

function Send-WowSlashCommand {
    param(
        [string]$Command,
        [int]$PreDelayMs = 250
    )
    if (-not $Command.StartsWith("/")) { $Command = "/" + $Command }
    Focus-WowWindow | Out-Null
    Start-Sleep -Milliseconds $PreDelayMs
    [WowWin32]::KeyTap(0x0D) # Enter — open chat
    Start-Sleep -Milliseconds 120
    Send-WowKeys $Command
    Start-Sleep -Milliseconds 80
    [WowWin32]::KeyTap(0x0D) # Enter — execute
    Start-Sleep -Milliseconds 80
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

function Enable-WowChatLog {
    Send-WowSlashCommand "/chatlog"
    Start-Sleep -Milliseconds 400
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

function Get-P1FrameErrors {
    param([int]$TailLines = 200)
    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($line in (Get-FrameXmlTail -Lines $TailLines)) {
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
    foreach ($line in $ChatLines) {
        if ($line -match '\[P1TEST\].*PASS.*summary') { return $true }
    }
    return $false
}

