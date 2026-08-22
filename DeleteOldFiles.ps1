# ============================================================================
# DeleteOldFiles.ps1
#
# Purpose : Deletes  .qvd snapshot files whose date (embedded in the
#           filename) is 2 calendar months or older than today. Meant to run
#           weekly via Windows Task Scheduler (through DeleteOldFiles.bat).
#
# Target  : \\SERVER\Folder\SubFolder
# Pattern : Snapshot_YYYY-MM-DD.qvd
#
# Safety  : Every run writes a timestamped log entry for every file it
#           deletes (or fails to delete). Logs are kept in the "Logs"
#           subfolder next to this script and rotated by month.
#
# Created : 2026-08-20
# Author  : Alejandro Novoa
# ============================================================================

# --- Configuration ----------------------------------------------------------

$FolderPath   = '\\SERVER\Folder\SubFolder'
$FileFilter   = 'Snapshot_*.qvd'
$DateRegex    = 'Snapshot_(\d{4})-(\d{2})-(\d{2})\.qvd$'

# Log file location: <script folder>\Logs\DeleteOldFiles_yyyy-MM.log
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LogDir    = Join-Path $ScriptDir 'Logs'
$LogFile   = Join-Path $LogDir ("DeleteOldFiles_{0}.log" -f (Get-Date -Format 'yyyy-MM'))

# Cutoff: anything dated on or before this is considered "2 months or older"
$CutoffDate = (Get-Date).Date.AddMonths(-2)

# --- Helpers -----------------------------------------------------------------

function Write-Log {
    param([string]$Message)
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $LogFile -Value $line
}

# --- Main ----------------------------------------------------------------

if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

Write-Log "----- Run started. Cutoff date (2 months back): $($CutoffDate.ToString('yyyy-MM-dd')) -----"

if (-not (Test-Path $FolderPath)) {
    Write-Log "ERROR: Folder not accessible: $FolderPath"
    Write-Log "----- Run finished (folder not found) -----"
    exit 1
}

$deletedCount = 0
$keptCount    = 0
$errorCount   = 0
$skippedCount = 0

$files = Get-ChildItem -Path $FolderPath -Filter $FileFilter -File -ErrorAction SilentlyContinue

foreach ($file in $files) {

    $match = [regex]::Match($file.Name, $DateRegex)

    if (-not $match.Success) {
        Write-Log "SKIPPED (no date in name): $($file.FullName)"
        $skippedCount++
        continue
    }

    $year  = [int]$match.Groups[1].Value
    $month = [int]$match.Groups[2].Value
    $day   = [int]$match.Groups[3].Value

    try {
        $fileDate = Get-Date -Year $year -Month $month -Day $day
    }
    catch {
        Write-Log "SKIPPED (invalid date in name): $($file.FullName)"
        $skippedCount++
        continue
    }

    if ($fileDate -le $CutoffDate) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            Write-Log "DELETED: $($file.FullName)  (file date: $($fileDate.ToString('yyyy-MM-dd')))"
            $deletedCount++
        }
        catch {
            Write-Log "ERROR deleting $($file.FullName): $($_.Exception.Message)"
            $errorCount++
        }
    }
    else {
        $keptCount++
    }
}

Write-Log "Summary: Deleted=$deletedCount Kept=$keptCount Skipped=$skippedCount Errors=$errorCount"
Write-Log "----- Run finished -----"

exit 0
