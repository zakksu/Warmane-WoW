# Save WoW login to tools/wow-login.cfg (gitignored). Run: .\tools\set-wow-login.ps1
$ErrorActionPreference = "Stop"
$cfg = Join-Path $PSScriptRoot "wow-login.cfg"
$acct = Read-Host "WoW account name"
$sec = Read-Host "WoW password" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
    $pass = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    @(
        "# local only — never commit",
        "account=$acct",
        "password=$pass"
    ) | Set-Content -Path $cfg -Encoding UTF8
    Write-Host "Saved $cfg" -ForegroundColor Green
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}