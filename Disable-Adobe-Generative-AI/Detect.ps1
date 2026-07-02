<#
    Detection - Adobe Generative AI (AI Assistant) disabled
    Checks bEnableGentech = 0 under FeatureLockDown for both
    Acrobat Pro and Acrobat Reader.

    Exit 0 = compliant (GenAI disabled on all paths)
    Exit 1 = non-compliant (remediation required)

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
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  [DETECT]  $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
    } catch { }
}

$nonCompliant = $false

foreach ($path in $paths) {
    try {
        $val = (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name
        if ($val -ne 0) {
            $nonCompliant = $true
            Write-Log "Incorrect value ($val) at $path"
        }
    } catch {
        $nonCompliant = $true
        Write-Log "Missing at $path"
    }
}

if ($nonCompliant) {
    Write-Log "Result: NON-COMPLIANT"
    Write-Output "Non-compliant: bEnableGentech not set to 0 on all paths"
    exit 1
} else {
    Write-Log "Result: COMPLIANT"
    Write-Output "Compliant: Generative AI disabled"
    exit 0
}
