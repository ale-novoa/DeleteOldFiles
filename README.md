# DeleteOldFiles

A PowerShell script (plus a batch wrapper for Task Scheduler) that deletes daily snapshot files older than 2 months, so a snapshot folder keeps a rolling 2-month history instead of growing forever.

## Why I built this

I was storing daily snapshot files in a folder, but only ever needed the last 2 months of history. Everything older was just taking up space with no ongoing value. This script prunes that folder automatically: anything matching the snapshot naming pattern and dated 2 months or older gets deleted, on a weekly schedule, so the folder self-maintains without anyone having to go in and clean it out by hand.

## Files

- **`DeleteOldFiles.ps1`**: does the actual work, finds snapshot files, checks their date, deletes the old ones, and logs everything.
- **`DeleteOldFiles.bat`**: a thin wrapper that Windows Task Scheduler runs; it just calls the `.ps1` with the right PowerShell flags. Task Scheduler is pointed at the `.bat`, not the `.ps1` directly, and the two files must live in the same folder.

## What `DeleteOldFiles.ps1` does

1. **Targets a fixed folder** (`$FolderPath = '\\SERVER\Folder\SubFolder'`) and looks for files matching `Snapshot_*.qvd`.
2. **Computes a cutoff date**: today's date minus 2 calendar months (`(Get-Date).Date.AddMonths(-2)`).
3. **For each matching file**, extracts the date embedded in the filename via regex (`Snapshot_(\d{4})-(\d{2})-(\d{2})\.qvd$`):
   - If the filename doesn't match the expected date pattern, or the extracted date isn't a valid calendar date, the file is skipped and logged, never touched.
   - If the file's date is on or before the cutoff, it's deleted.
   - Otherwise it's kept (still within the 2-month window).
4. **Logs every action**, every deletion, skip, and error, to a monthly log file at `Logs\DeleteOldFiles_yyyy-MM.log` next to the script, along with a run header/footer and a summary line (counts of deleted/kept/skipped/errored files) at the end of each run.
5. **Fails safely.** If the target folder isn't accessible, it logs the error and exits without attempting any deletions.

## What `DeleteOldFiles.bat` does

Resolves its own folder (`%~dp0`), then runs:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<script folder>\DeleteOldFiles.ps1"
```

and passes through the PowerShell script's exit code. `-ExecutionPolicy Bypass` is scoped to this one invocation only; it doesn't change the machine's execution policy.

## Safety notes

- Only files matching the exact `Snapshot_YYYY-MM-DD.qvd` naming pattern are ever considered. Anything else in the folder is left alone.
- Deletion is permanent (`Remove-Item -Force`); there's no dry-run/preview mode built in. Review the log after the first few runs, or comment out the `Remove-Item` line temporarily if you want to test against a new folder/pattern before trusting it.
- The date used for the cutoff comparison is the date **embedded in the filename**, not the file's filesystem last-modified date, so it depends on the snapshot naming staying consistent.

## Usage

Point Windows Task Scheduler at `DeleteOldFiles.bat` (weekly, as configured in this deployment). To run manually:

```
DeleteOldFiles.bat
```

or directly:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File DeleteOldFiles.ps1
```
