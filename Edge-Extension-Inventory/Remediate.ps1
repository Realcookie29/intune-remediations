<#
.SYNOPSIS
    No-op remediation script - inventory only, no action taken.

.DESCRIPTION
    Intune Remediation requires a remediation script whenever the detection
    script exits 1. Since in phase 1 we only want to inventory and change nothing
    on devices, this script deliberately does nothing. The valuable data lives in
    the detection output (see Intune > Reports > Remediations).

.NOTES
    Author: Alper Atar
    Version: 1.0
#>

Write-Output "Inventory only - no remediation performed."
exit 0
