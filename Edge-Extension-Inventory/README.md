# Edge Extension Inventory

An Intune Remediation that inventories **all Microsoft Edge extensions** installed
across every user profile on a managed device. It reports back per device without
changing anything — a read-only inventory built on top of the Remediations engine.

## What it does

The **detection script** walks every user profile under `C:\Users`, finds each
Edge profile (`Default`, `Profile 1`, …), and reads the installed extensions
directly from disk. For each extension it collects:

| Field | Description |
|-------|-------------|
| `id` | The 32-character Chrome/Edge extension ID |
| `name` | Display name (resolves `__MSG_*__` placeholders via `_locales`) |
| `version` | Newest installed version |
| `user` | The Windows user the extension belongs to |
| `enabled` | Whether the extension is enabled in the profile's `Preferences` |

The result is written as compact JSON to the detection output, visible in
**Intune > Reports > Remediations > (this remediation) > Pre-remediation detection output**.

The detection script always exits `1` ("issue detected") so Intune surfaces the
output. The **remediation script is intentionally a no-op** — nothing is modified
on the device. This is inventory only.

### Output shape

```json
[{"id":"aaaa...","name":"uBlock Origin","version":"1.57.0","user":"jdoe","enabled":true}]
```

If the payload would exceed the 2048-character report limit, the script
automatically falls back to a compact summary of unique extension IDs with an
install `count`.

## How to deploy

1. In the **Intune admin center**, go to
   **Devices > Remediations > Create**.
2. Upload the scripts:
   - **Detection script file:** `Detect.ps1`
   - **Remediation script file:** `Remediate.ps1`
3. Configure the script settings **exactly** as follows:

   | Setting | Value |
   |---------|-------|
   | Run this script using the logged-on credentials | **No** |
   | Enforce script signature check | **No** |
   | Run script in 64-bit PowerShell | **No** |

   > ⚠️ *Run in 64-bit PowerShell must be **No***. Extensions live in the user
   > profile and the paths must resolve in the 32-bit context used by Intune.

4. Assign to a device group and pick a schedule (e.g. daily).
5. After devices check in, review the results under
   **Reports > Remediations**.

## Requirements

- Microsoft Intune with the Remediations feature (Windows Enterprise E3/E5 or
  equivalent).
- Windows 10/11 devices with Microsoft Edge (Chromium).
- Runs as **SYSTEM**; no additional permissions required.

## Notes

- **Read-only:** the remediation script performs no changes. Safe to deploy
  broadly.
- The detection output is capped at 2048 characters by Intune; the script
  handles truncation gracefully.
