# Tooling - reading and filling the NFR workbook

The NFR repository is an Excel `.xlsm` (macro-enabled). This Windows machine has **no Python /
openpyxl and no ImportExcel module**, but **Excel is installed**, so all tooling drives Excel
through COM. The shared primitives live in `assets/scripts/NfrRepo.psm1`; the two wrapper
scripts reuse them. Do not re-implement the COM plumbing inline.

## Running the model's own macros (the human process)
The reference model carries the filtering macros, bound to buttons/checkboxes on the Synthesis
sheet (discovered via each shape's `OnAction`, no VBA-code access needed):
- **`RequirementsFilter`** - the "filter" button: fills the `Relevant` column from the system
  parameters (DICT/RTO/SOX/DP). This is step 2 of the human process.
- **`ShowHideRequirements`** - the display checkboxes: hides/shows the Not-relevant rows.
- **`ResetFilter`** - clears the filter.

**The macro is the ONLY authorised way to compute Relevant.** No other calculation method is
permitted for a deliverable. `new-nfr-workbook.ps1` reproduces the human process: it writes the
parameters, then runs these macros via `Application.Run` after `Application.AutomationSecurity=1`
(msoAutomationSecurityLow). If the macro cannot run, the script does NOT compute relevance any
other way: it saves the workbook with the parameters filled and STOPS with an instruction for
the user to run the macro manually and come back (see "Failure handling" below).

### The confirmation dialog (must be auto-clicked)
`RequirementsFilter` shows a modal VBA **MsgBox** ("Warning, values in columns 'Relevant' and
'Status' will be modified ... Do you want to continue?", buttons **Oui/Non**). A VBA MsgBox is
modal and **blocks `Application.Run` until dismissed**, and `Application.DisplayAlerts` does NOT
suppress it. The script therefore starts a background watcher, `Dismiss-FilterDialog.ps1`, which
polls (UI Automation) for the "Requirements filter" window and sends Enter (default = Oui) so the
macro runs unattended. The macro itself also sets Status (`Proposed` if relevant, `Not relevant`
if not); the script then overwrites Status with the project's decision for relevant NFRs.

### Failure handling (macro unavailable)
If the macro throws (macros disabled by policy, VBProject blocked, etc.), the script writes the
parameter-filled workbook to the destination and raises a terminating error telling the user to:
open the workbook, verify the Synthesis parameters, click the filter button, save, and come back
so the agent can review the filtered NFRs and set Status/date/comment. Do NOT work around this by
computing Relevant yourself.

To run the macros manually (what the user is asked to do on failure):
```
$xl = New-Object -ComObject Excel.Application
$xl.AutomationSecurity = 1   # low: no macro-security prompt
$wb = $xl.Workbooks.Open($path)   # a local copy, not the bundled template
$xl.Run('RequirementsFilter')     # click 'Oui' on the confirmation dialog
$xl.Run('ShowHideRequirements')
$wb.Save(); $wb.Close($true); $xl.Quit()
```

## Critical constraint - synced folders (OneDrive / SharePoint)
Excel COM `Workbook.Save()` is **silently discarded** when the workbook lives in a synced folder
(e.g. the workspace - and therefore `output/${project_name}/` - sits under OneDrive/SharePoint).
The value is written in memory and even reported back
correctly before closing, but the file on disk reverts on reopen. Therefore every write must:
1. copy the template to a **local** working file under `$env:TEMP`,
2. edit and save that local copy,
3. copy the finished file to the (synced) destination.
`new-nfr-workbook.ps1` already does this. Keep this pattern for any new write script.

## Excel COM hygiene
- Always create the app with `New-ExcelApp` and close with `Close-ExcelApp` (releases the COM
  objects and forces GC), otherwise `EXCEL.EXE` processes leak and lock files.
- Open read-only for inspection: `$wb = $xl.Workbooks.Open($path, $false, $true)`.
- If a run is interrupted, kill leftovers:
  `Get-Process EXCEL -ErrorAction SilentlyContinue | Stop-Process -Force` (safe only when the
  user has no Excel open; ask first if unsure).
- Keep `.xlsm` as the output extension to preserve the workbook's macros and the Synthesis
  charts/formulas. Saving as `.xlsx` would strip the macros.

## Scripts

### `NfrRepo.psm1` (shared module)
Sheet/cell map, `New-ExcelApp` / `Close-ExcelApp`, `Get-NfrRow`, `Read-NfrRepository`.
The cell map (kept in sync with the reference model):
- Synthesis system parameters: `I8` Data privacy, `I9` DICT, `I10` RTO, `I11` SOX, `F4` app name.
- NFR repository: headers on row 3, data from row 4; col 2 Reference, 3 Title, 4 Dispensation,
  5 Description, **8 Relevant**, **9 Status**, **10 Last update**, **12 Comments**, 23..38 DICT
  trigger flags, 39 RTO, 40 Data privacy, 41 SOX, 42 Group, 43 Weight. Only 8/9/10/12 are edited.

### `export-nfr.ps1` (read-only)
Dumps a workbook's NFR repository to TSV and prints a status/relevance summary. Use it to
inspect the reference model, review a filled deliverable, or answer questions from live data.
```
powershell -NoProfile -ExecutionPolicy Bypass -File .kiro\skills\nfr-requirements\assets\scripts\export-nfr.ps1 `
  -Workbook <path-to-xlsm> -Out review.tsv
```
With no `-Workbook`, it reads the bundled reference template.

### `new-nfr-workbook.ps1` (produce the deliverable)
Copies the reference model, writes the system parameters, **computes Relevant** for every NFR
(reproducing the model's filter macro via `Test-NfrRelevant`), applies per-NFR Status + Comment,
saves. `-Dict`, `-Rto`, `-Sox`, `-DataPrivacy` are mandatory (they drive the filter).
```
powershell -NoProfile -ExecutionPolicy Bypass -File .kiro\skills\nfr-requirements\assets\scripts\new-nfr-workbook.ps1 `
  -Out output/${project_name}/${project_name}_NFR.xlsm `
  -Dict 1111 -Rto 9 -Sox No -DataPrivacy No -AppName "My Application" `
  -Decisions decisions.tsv
  (-AppName value is an example, fictional; the DICT/RTO/SOX values are illustrative)
```
- **Relevant is NOT in the decisions file** - it is computed. The decisions file (TAB, `;` or `,`
  auto-detected) carries only the project Status + Comment, one row per NFR:
  ```
  Reference<TAB>Status<TAB>Comment
  NFR-6002<TAB>Accepted<TAB>SAST/code analysis applies to the front-end bundle.
  NFR-5204<TAB>Verified<TAB>Hosting on a main cloud provider (IT-PM dispensation).
  ```
  A legacy `Relevant` column is tolerated but ignored. For a computed-NOT-relevant NFR the script
  forces Status = `Not relevant` (a comment row is still applied if present); any Status you give
  for such a row is ignored. `Last update` is stamped automatically. Relevant NFRs not listed keep
  the template default (`Proposed`).
- `-Decisions` is optional: omit it to produce a correctly FILTERED workbook (Relevant computed,
  relevant NFRs left at `Proposed`, filtered ones at `Not relevant`) - the same result the model's
  macro would produce, ready to hand to the business.
- **Row hiding (Display parameters).** By default the script HIDES the filtered-out (Not relevant)
  NFR rows, reproducing the model's "Display parameters" option so the deliverable shows only the
  relevant requirements - exactly like the human reference (e.g. section "1.4 Compliance" stays
  visible as a title, but its filtered NFR-1401..1411 rows are hidden). Section/title rows are
  never hidden. Use `-NoHideFiltered` to keep every row visible. `export-nfr.ps1` reads hidden and
  visible rows alike, so the summary still counts all 133 NFRs.

### How Relevant is computed (the filter)
ONLY the model's own `RequirementsFilter` macro (see "Running the model's own macros"). There is
no alternative calculation for a deliverable. `Test-NfrRelevant` in `NfrRepo.psm1` exists purely
to EXPLAIN/preview the rule when answering questions (generic = Yes; else Yes if any DICT level /
RTO class / DP / SOX trigger matches; validated to match the macro exactly at DICT 1111/RTO 9) -
never use it to fill the workbook.

## Valid values (from the model's Params sheet)
- Relevant: `Yes` / `No` (template default `To be defined`).
- Status: `Proposed`, `Accepted`, `Implemented`, `Verified`, `Not feasible`, `Not relevant`.
- Data privacy risk level: `No`, `A`, `B`, `C`, `D`.
- RTO: `1`..`8`, or `9` (not involved). PRA (DRP) class: `1`..`4`, or `9`.

## Encoding
Write decisions files and any generated text as **UTF-8 without BOM**, ASCII-safe (use `-`,
straight quotes; avoid em dashes and curly quotes) to prevent mojibake in Excel and in the deck.
