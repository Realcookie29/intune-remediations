# Intune Remediations

A collection of **Microsoft Intune Remediation** scripts (detection + remediation
pairs) for real-world Modern Workplace management. Each folder is a self-contained
remediation with its own README explaining what it does and how to deploy it.

All scripts run as SYSTEM via the Intune Remediations engine and are written to be
safe, idempotent, and easy to audit.

## Remediations

| Remediation | Description | Type |
|-------------|-------------|------|
| [Edge Extension Inventory](./Edge-Extension-Inventory) | Inventories all Microsoft Edge extensions per user profile across a device. | Read-only / inventory |
| [Disable Adobe Generative AI](./Disable-Adobe-Generative-AI) | Disables the Adobe Acrobat/Reader AI Assistant (`bEnableGentech = 0`) and keeps it disabled. | Enforce / self-healing |

## How these are structured

```
RemediationName/
├── Detect.ps1      # Intune detection script
├── Remediate.ps1   # Intune remediation script
└── README.md       # What it does + deployment guide
```

## Deploying

Each remediation's README contains the exact Intune configuration
(**Devices > Remediations > Create**), including the required 64-bit / SYSTEM /
signature settings.

## Author

Maintained by **Alper Atar** — Modern Workplace Consultant.

## License

MIT — see [LICENSE](./LICENSE).
