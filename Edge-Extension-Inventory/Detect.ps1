<#
.SYNOPSIS
    Inventories all Microsoft Edge extensions on a device, per user profile.

.DESCRIPTION
    Intended as an Intune Remediation 'detection script'. Returns a JSON output
    per device listing every extension found (extension ID, name, version, user,
    profile, and whether it is enabled). The output shows up in the Intune
    Remediation report column 'Pre-remediation detection output' (max 2048 chars).

    The exit code is always 1 (= 'issue detected') so that Intune displays the
    output and can optionally trigger the remediation script. The remediation
    script does nothing - we only want to inventory.

.NOTES
    Run as: SYSTEM
    Run script in 64-bit PowerShell: No (required NO - extensions live in the user profile)
    Author: Alper Atar
    Version: 1.0
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'
$extensions = [System.Collections.Generic.List[object]]::new()

try {
    # Find all user profiles on this machine (skip system accounts)
    $ProfileExclusions = @("defaultuser0", "wdagutilityaccount", "WsiAccount")
    $UserProfiles = Get-CimInstance Win32_UserProfile -Filter "Special = False" | 
        Select-Object Sid, LocalPath, @{Name="ProfileFolder";Expression={ Split-Path $_.LocalPath -Leaf }} |
        Where-Object { $ProfileExclusions -notcontains $_.ProfileFolder }

    foreach ($user in $userProfiles) {
        $edgeUserData = Join-Path $user.LocalPath 'AppData\Local\Microsoft\Edge\User Data'
        if (-not (Test-Path $edgeUserData)) { continue }

        # A user can have multiple Edge profiles (Default, Profile 1, etc.)
        $edgeProfiles = Get-ChildItem $edgeUserData -Directory |
            Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile *' }

        foreach ($edgeProfile in $edgeProfiles) {
            $extensionsPath = Join-Path $edgeProfile.FullName 'Extensions'
            if (-not (Test-Path $extensionsPath)) { continue }

            # Read Preferences for enabled status + display name fallback
            $preferencesFile = Join-Path $edgeProfile.FullName 'Preferences'
            $preferences = $null
            if (Test-Path $preferencesFile) {
                try {
                    $preferences = Get-Content $preferencesFile -Raw -Encoding UTF8 | ConvertFrom-Json
                } catch { }
            }

            # Loop through all extension folders (folder name = extension ID)
            $extDirs = Get-ChildItem $extensionsPath -Directory |
                Where-Object { $_.Name -match '^[a-p]{32}$' }  # valid Chrome/Edge ext ID format

            foreach ($extDir in $extDirs) {
                $extId = $extDir.Name

                # Grab the newest version folder
                $versionDir = Get-ChildItem $extDir.FullName -Directory |
                    Sort-Object Name -Descending | Select-Object -First 1
                if (-not $versionDir) { continue }

                $manifestPath = Join-Path $versionDir.FullName 'manifest.json'
                if (-not (Test-Path $manifestPath)) { continue }

                try {
                    $manifest = Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
                } catch { continue }

                # Display name can be a __MSG_xxx__ placeholder -> resolve via _locales
                $name = $manifest.name
                if ($name -like '__MSG_*__') {
                    $msgKey = $name -replace '__MSG_','' -replace '__',''
                    $defaultLocale = if ($manifest.default_locale) { $manifest.default_locale } else { 'en' }
                    $messagesPath = Join-Path $versionDir.FullName "_locales\$defaultLocale\messages.json"
                    if (Test-Path $messagesPath) {
                        try {
                            $messages = Get-Content $messagesPath -Raw -Encoding UTF8 | ConvertFrom-Json
                            $msgEntry = $messages.$msgKey
                            if ($msgEntry -and $msgEntry.message) { $name = $msgEntry.message }
                        } catch { }
                    }
                }

                # Check enabled state in Preferences
                $enabled = $true
                if ($preferences -and $preferences.extensions -and $preferences.extensions.settings) {
                    $extSetting = $preferences.extensions.settings.$extId
                    if ($extSetting -and $extSetting.state -eq 0) { $enabled = $false }
                }

                $extensions.Add([pscustomobject]@{
                    id       = $extId
                    name     = $name
                    version  = $versionDir.Name
                    user     = $user.ProfileFolder
                    profile  = $edgeprofile.Name
                    enabled  = $enabled
                })
            }
        }
    }

    # No extensions? Exit success - nothing to see here
    if ($extensions.Count -eq 0) {
        Write-Output "NO_EXTENSIONS_FOUND"
        exit 0
    }

    # Compact JSON for the 2048-char output limit
    # Each record ~80-120 chars; with many extensions we truncate to essentials
    $payload = $extensions | Select-Object id, name, version, user, enabled
    $json = $payload | ConvertTo-Json -Compress -Depth 3

    # If output > 2000 chars, fall back to unique IDs + count only
    if ($json.Length -gt 2000) {
        $compact = $extensions | Group-Object id | ForEach-Object {
            [pscustomobject]@{
                id    = $_.Name
                name  = ($_.Group | Select-Object -First 1).name
                count = $_.Count
            }
        }
        $json = $compact | ConvertTo-Json -Compress -Depth 2
    }

    Write-Output $json
    exit 1  # 'detected' -> Intune shows the output

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 0
}
