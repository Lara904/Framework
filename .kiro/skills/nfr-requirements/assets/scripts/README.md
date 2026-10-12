# Scripts - nfr-requirements skill

Excel-COM tooling for the Stellantis NFR repository (`DP-MD18-EN`). No Python / ImportExcel is
required; Excel must be installed. See `../../references/tooling.md` for the full guide,
including the OneDrive/SharePoint save caveat (edit a local TEMP copy, then move to destination).

| File | Role |
|------|------|
| `NfrRepo.psm1` | Shared module: sheet/cell map, Excel app lifecycle, `Get-NfrRow`, `Read-NfrRepository`. Reuse it; do not re-implement COM plumbing. |
| `export-nfr.ps1` | Read-only. Dump a workbook's NFR repository to TSV + print a status/relevance summary. |
| `new-nfr-workbook.ps1` | Produce the deliverable: copy the reference model, write system parameters, run the model's filter MACRO (only authorised compute), apply per-NFR Status/Comment. |
| `Dismiss-FilterDialog.ps1` | Background watcher that auto-confirms the macro's Oui/Non MsgBox (a modal VBA dialog that blocks COM). Started automatically by `new-nfr-workbook.ps1`. |

Run scripts non-interactively, e.g.:
```
powershell -NoProfile -ExecutionPolicy Bypass -File <script>.ps1 <args>
```

Clean up leaked Excel processes after an interrupted run (only when the user has no Excel open):
```
Get-Process EXCEL -ErrorAction SilentlyContinue | Stop-Process -Force
```
