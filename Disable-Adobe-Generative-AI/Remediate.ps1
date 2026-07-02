<#
    Remediation - Adobe Generative AI (AI Assistant) disable
    Sets bEnableGentech = 0 (DWORD) under FeatureLockDown for both
    Acrobat Pro and Acrobat Reader. Idempotent and self-healing.

    bEnableGentech: 0 = off, 1/absent = on.

    Exit 0 = set successfully
    Exit 1 = error

    Run in 64-bit PowerShell, system context.
    Author: Alper Atar
#>

$ErrorActionPreference = 'Stop'

$paths = @(
    'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown',   # Acrobat Pro / Standard
    'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown'   # Acrobat Reader
)
$name = 'bEnableGentech'
$logFile = "$env:ProgramData\IntuneRemediations\AdobeGenAI.log"

function Write-Log {
    param([string]$Message)
    try {
        $dir = Split-Path $logFile -Parent
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  [REMED]  $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
    } catch { }
}

try {
    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Log "Path created: $path"
        }
        New-ItemProperty -Path $path -Name $name -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Log "Set: $name = 0 at $path"
    }
    Write-Output "Generative AI disabled (bEnableGentech = 0) on all paths"
    Write-Log "Result: SUCCESS"
    exit 0
}
catch {
    Write-Output "Remediation error: $($_.Exception.Message)"
    Write-Log "Result: ERROR - $($_.Exception.Message)"
    exit 1
}
