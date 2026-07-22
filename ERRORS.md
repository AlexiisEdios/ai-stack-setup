# AI Stack Setup — Error Log

## Errors Encountered (2026-07-22)

### 1. npm.ps1 Execution Policy Blocked
**Error:**
```
File C:\Program Files\nodejs\npm.ps1 cannot be loaded because running 
scripts is disabled on this system.
```
**Root cause:** PowerShell execution policy (`Restricted`) blocks all `.ps1` scripts. 
Node.js ships `npm` as `npm.ps1` by default on Windows. When `npm install` or any npm 
command is invoked from PowerShell, it resolves to the `.ps1` shim and gets blocked.

**Fix:** Detect `npm.cmd` (CMD shim, not affected by execution policy) and use it 
instead via `& $npmCmd` throughout the script. Also applied to `npm config get prefix` 
and `npm root -g`.

**Commits:** 524dce0

### 2. Microsoft Store Python Stub
**Error (silent logic bug):**
The script checked `if ($pythonPath)` after finding Python via `Get-Command`, but the 
Microsoft Store redirect stub (`python --version` outputs "Python was not found...") 
passes this check. The script thought Python was installed and skipped installation, 
but the stub can't actually run Python.

**Fix:** After `python --version`, check output for "Microsoft Store", "was not found", 
or "not found". If matched, set `$pythonPath = $null` to trigger real Python install.

**Commits:** 524dce0

### 3. UTF-8 BOM Required by Windows PowerShell
**Error (parse failure):**
PowerShell 5.1 on Windows fails to parse UTF-8 files without BOM, causing cryptic 
"Missing closing '}'" errors at line 0.

**Fix:** Prepend UTF-8 BOM (`\xEF\xBB\xBF`) to `setup-all.ps1`.

**Commits:** 524dce0

### 4. UTF-8 BOM Breaks irm | iex Pipeline
**Error:**
```
﻿<#: term '﻿<#' is not recognized as name of cmdlet
```
**Root cause:** When the script is piped through `irm ... | iex`, the BOM bytes 
`\xEF\xBB\xBF` are not treated as an encoding marker — they arrive as literal text 
chars `ï»¿`, so PowerShell tries to execute `ï»¿<#` as a command.

**Tension:** `-File` parsing needs BOM; `iex` piping needs no BOM. The primary install 
path is `iex`, so BOM was stripped (commit e613755).

## Status: All fixed, committed, pushed to origin/master
