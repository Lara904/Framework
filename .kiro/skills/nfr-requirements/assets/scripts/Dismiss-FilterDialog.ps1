<#
.SYNOPSIS
  Auto-confirm the model's filter macro dialog(s).

.DESCRIPTION
  The reference model's 'RequirementsFilter' macro shows a VBA MsgBox
  ("Warning, values in columns 'Relevant' and 'Status' will be modified ... Do you want to
  continue?") with Oui/Non buttons. A VBA MsgBox is modal and blocks Excel COM
  (Application.Run does not return until it is dismissed), and Application.DisplayAlerts does NOT
  suppress it. This watcher polls for that dialog and confirms it (default button = Oui) so the
  macro can run unattended. Run it as a background job in parallel with Application.Run.

.PARAMETER TimeoutSeconds
  How long to keep watching (default 120).

.PARAMETER DialogTitle
  Window title of the macro dialog (default 'Requirements filter').
#>
[CmdletBinding()]
param(
  [int]$TimeoutSeconds = 120,
  [string]$DialogTitle = 'Requirements filter'
)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class FgWin {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
}
"@

$root = [System.Windows.Automation.AutomationElement]::RootElement
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$dismissed = 0
while ((Get-Date) -lt $deadline) {
  try {
    $cond = New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::NameProperty, $DialogTitle)
    $win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
    if ($win) {
      $h = [IntPtr]$win.Current.NativeWindowHandle
      if ($h -ne [IntPtr]::Zero) {
        [FgWin]::ShowWindow($h, 5) | Out-Null   # SW_SHOW
        [FgWin]::SetForegroundWindow($h) | Out-Null
        Start-Sleep -Milliseconds 200
        # Default button is "Oui" -> Enter confirms.
        [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
        $dismissed++
        Start-Sleep -Milliseconds 400
      }
    }
  } catch {}
  Start-Sleep -Milliseconds 300
}
Write-Output "dismissed=$dismissed"
