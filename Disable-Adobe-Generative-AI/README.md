# Disable Adobe Generative AI (Acrobat AI Assistant)

An Intune Remediation that **disables the Adobe Generative AI / AI Assistant**
feature in Adobe Acrobat Pro/Standard and Acrobat Reader, and keeps it disabled
(self-healing).

## Why

Adobe's AI Assistant can send document content to Adobe's cloud services. In many
organisations this is undesirable for data-governance, privacy, or compliance
reasons. This remediation enforces the supported policy switch that turns the
feature off across the whole fleet.

## What it does

Both scripts target the `bEnableGentech` value under `FeatureLockDown` for the two
Adobe products:

| Registry path | Product |
|---------------|---------|
| `HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown` | Acrobat Pro / Standard |
| `HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown` | Acrobat Reader |

`bEnableGentech`: `0` = off · `1` or absent = on.

- **Detect.ps1** — exits `0` (compliant) only if `bEnableGentech = 0` on **all**
  paths; otherwise exits `1` (remediation required).
- **Remediate.ps1** — creates the paths if needed and sets `bEnableGentech = 0`
  (DWORD). Idempotent and self-healing.

Both scripts write a log to `%ProgramData%\IntuneRemediations\AdobeGenAI.log`.

## How to deploy

1. In the **Intune admin center**, go to
   **Devices > Remediations > Create**.
2. Upload the scripts:
   - **Detection script file:** `Detect.ps1`
   - **Remediation script file:** `Remediate.ps1`
3. Configure the script settings:

   | Setting | Value |
   |---------|-------|
   | Run this script using the logged-on credentials | **No** (system context) |
   | Enforce script signature check | **No** |
   | Run script in 64-bit PowerShell | **Yes** |

4. Assign to a device group and pick a schedule (e.g. daily).
5. Review results under **Reports > Remediations**.

## Requirements

- Microsoft Intune with the Remediations feature.
- Windows 10/11 devices with Adobe Acrobat and/or Acrobat Reader.
- Runs as **SYSTEM** in **64-bit** PowerShell (writes to `HKLM`).

## Notes

- **Machine-wide policy:** applies to all users on the device via `HKLM`.
- Idempotent — safe to run repeatedly; re-applies the setting if a user or another
  process reverts it.
