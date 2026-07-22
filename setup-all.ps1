<#
.SYNOPSIS
  AI Stack One-Click Setup — Windows (PowerShell)
.DESCRIPTION
  Installs: Node.js, Python, OmniRoute (AI Router), Hermes Agent
  Configures them to work together out of the box.

.USAGE
  irm https://raw.githubusercontent.com/AlexiisEdios/ai-stack-setup/main/setup-all.ps1 | iex

  Or save and run:
    .\setup-all.ps1

.NOTES
  Requires: Windows 10+, PowerShell 5.1+, internet connection
  Some steps need admin rights (winget installs)
#>

#Requires -Version 5.1

# ── Config ────────────────────────────────────────────────────────────────
$NODE_VERSION = "22"
$OMNIROUTE_PORT = 20128
$HERMES_HOME = "$env:LOCALAPPDATA\hermes"
$HERMES_INSTALL_DIR = "$HERMES_HOME\hermes-agent"
$TEMP_LOG = "$env:TEMP\omniroute-setup.log"
$API_KEY = "sk-" + -join ((48..57) + (97..102) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

# ── Colors (PowerShell-compatible) ─────────────────────────────────────────
$Host.UI.RawUI.ForegroundColor = "White"
function Write-Info   { Write-Host "→ $args" -ForegroundColor Cyan }
function Write-OK     { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Warn   { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Fail   { Write-Host "✗ $args" -ForegroundColor Red; exit 1 }
function Write-Header { Write-Host "`n══ $args ══`n" -ForegroundColor Cyan }

# ── Banner ─────────────────────────────────────────────────────────────────
Clear-Host
Write-Host @"

   ╔══════════════════════════════════════════════╗
   ║       AI Stack One-Click Setup               ║
   ║   Node.js · Python · OmniRoute · Hermes      ║
   ╚══════════════════════════════════════════════╝

   This script installs everything needed to run an
   AI coding agent (Hermes) + smart router (OmniRoute)
   with free AI provider tiers.

"@ -ForegroundColor Cyan

# ── Admin check ───────────────────────────────────────────────────────────
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Warn "Not running as Administrator."
    Write-Warn "Some installs (winget, Python, Node.js system-wide) may fail."
    Write-Warn "Run PowerShell as Admin and try again if you hit permission errors."
    Write-Host ""
}

# ── Step 1: Node.js ───────────────────────────────────────────────────────
Write-Header "Step 1: Node.js"

$nodePath = Get-Command "node" -ErrorAction SilentlyContinue
if ($nodePath) {
    $nv = node --version
    Write-OK "Node.js already installed: $nv"
} else {
    Write-Info "Installing Node.js $NODE_VERSION..."
    try {
        # Try winget first (fastest on modern Windows)
        $winget = Get-Command "winget" -ErrorAction SilentlyContinue
        if ($winget) {
            winget install OpenJS.NodeJS.LTS --accept-source-agreements --silent 2>&1 | Out-Null
        } else {
            # Fallback: download installer
            Write-Info "Downloading Node.js installer..."
            $url = "https://nodejs.org/dist/v${NODE_VERSION}.13.0/node-v${NODE_VERSION}.13.0-x64.msi"
            # Try to find the latest LTS version
            $nodePage = Invoke-WebRequest -Uri "https://nodejs.org/en/download/" -UseBasicParsing
            if ($nodePage.Content -match 'node-v?(\d+\.\d+\.\d+)-x64\.msi') {
                $latestVer = $matches[1]
                $url = "https://nodejs.org/dist/v$latestVer/node-v$latestVer-x64.msi"
            }
            $installer = "$env:TEMP\node-installer.msi"
            Invoke-WebRequest -Uri $url -OutFile $installer
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installer`" /qn"
            Remove-Item $installer -Force -ErrorAction SilentlyContinue
        }
        # Refresh PATH
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Warn "Node.js auto-install failed: $_"
        Write-Warn "Download manually from https://nodejs.org/ and re-run"
    }
}

if (Get-Command "node" -ErrorAction SilentlyContinue) {
    Write-OK "Node.js $(node --version) + npm $(npm --version)"
} else {
    Write-Fail "Node.js not found after install. Restart PowerShell or install manually."
}

# ── Step 2: Python ────────────────────────────────────────────────────────
Write-Header "Step 2: Python"

$pythonPath = Get-Command "python" -ErrorAction SilentlyContinue
if (-not $pythonPath) {
    $pythonPath = Get-Command "python3" -ErrorAction SilentlyContinue
}

if ($pythonPath) {
    $pv = & $pythonPath.Source --version 2>&1
    Write-OK "Python already installed: $pv"
} else {
    Write-Info "Installing Python..."
    try {
        $winget = Get-Command "winget" -ErrorAction SilentlyContinue
        if ($winget) {
            winget install Python.Python.3.11 --accept-source-agreements --silent 2>&1 | Out-Null
        } else {
            # Download Python installer
            $pyPage = Invoke-WebRequest -Uri "https://www.python.org/downloads/windows/" -UseBasicParsing
            if ($pyPage.Content -match 'python-(\d+\.\d+\.\d+)-amd64\.exe') {
                $pyVer = $matches[1]
                $url = "https://www.python.org/ftp/python/$pyVer/python-$pyVer-amd64.exe"
            } else {
                $url = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
            }
            $installer = "$env:TEMP\python-installer.exe"
            Write-Info "Downloading Python from $url ..."
            Invoke-WebRequest -Uri $url -OutFile $installer
            Start-Process $installer -Wait -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1"
            Remove-Item $installer -Force -ErrorAction SilentlyContinue
        }
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Warn "Python auto-install failed: $_"
        Write-Warn "Download from https://www.python.org/downloads/ and re-run"
    }
}

$pythonExe = if (Get-Command "python" -ErrorAction SilentlyContinue) { "python" } else { "python3" }
if (Get-Command $pythonExe -ErrorAction SilentlyContinue) {
    Write-OK "Python $(& $pythonExe --version 2>&1) ready"
} else {
    Write-Fail "Python not found after install. Restart PowerShell or install manually."
}

# ── Step 3: OmniRoute ────────────────────────────────────────────────────
Write-Header "Step 3: OmniRoute (AI Router)"

$omniroutePath = Get-Command "omniroute" -ErrorAction SilentlyContinue
if ($omniroutePath) {
    $ov = & omniroute --version 2>&1
    Write-OK "OmniRoute already installed: v$ov"
} else {
    Write-Info "Installing OmniRoute via npm (global)..."
    try {
        npm install -g omniroute 2>&1 | Out-Null
        # npm global might not be in PATH immediately
        $npmPrefix = npm config get prefix
        $env:Path = "$npmPrefix;$env:Path"
    } catch {
        # Try with --force
        npm install -g omniroute --force 2>&1 | Out-Null
    }
    if (Get-Command "omniroute" -ErrorAction SilentlyContinue) {
        Write-OK "OmniRoute v$(omniroute --version) installed"
    } else {
        Write-Warn "OmniRoute installed but not in PATH."
        Write-Warn "It's at: $(npm root -g)\..\bin\omniroute"
        Write-Warn "Add npm global prefix to your PATH."
    }
}

# ── Step 4: Hermes Agent ─────────────────────────────────────────────────
Write-Header "Step 4: Hermes Agent"

$hermesPath = Get-Command "hermes" -ErrorAction SilentlyContinue
if ($hermesPath) {
    $hv = & hermes --version 2>&1 | Select-Object -First 1
    Write-OK "Hermes Agent already installed: $hv"
} else {
    Write-Info "Installing Hermes Agent..."
    try {
        # Install using the official PowerShell script
        iex (irm https://hermes-agent.nousresearch.com/install.ps1)

        # Add to PATH
        $hermesScripts = "$HERMES_INSTALL_DIR\venv\Scripts"
        if (Test-Path "$hermesScripts\hermes.exe") {
            $env:Path = "$hermesScripts;$env:Path"
        }
    } catch {
        Write-Warn "Hermes install script had an issue: $_"
        Write-Warn "Try manually: iex (irm https://hermes-agent.nousresearch.com/install.ps1)"
    }
}

if (Get-Command "hermes" -ErrorAction SilentlyContinue) {
    Write-OK "Hermes Agent: $(hermes --version 2>&1 | Select-Object -First 1)"
} else {
    Write-Warn "Hermes installed but not in current PATH session."
    Write-Warn "It's at: $HERMES_INSTALL_DIR\venv\Scripts"
    Write-Warn "Run: `$env:Path += `";$HERMES_INSTALL_DIR\venv\Scripts`""
}

# ── Step 5: Configure Hermes → OmniRoute ──────────────────────────────────
Write-Header "Step 5: Wire Hermes to OmniRoute"

$configFile = "$HERMES_HOME\config.yaml"

# Create config directory if needed
if (-not (Test-Path $HERMES_HOME)) {
    New-Item -ItemType Directory -Path $HERMES_HOME -Force | Out-Null
}

# Write/update config
if (Test-Path $configFile) {
    Write-Info "Updating existing Hermes config..."

    # Read existing config, check if OmniRoute provider is there
    $config = Get-Content $configFile -Raw
    # Check whether to add to existing custom_providers or create new section
    if ($config -notmatch "OmniRoute") {
        if ($config -match "custom_providers:") {
            # Append just a list item under existing custom_providers
            Add-Content $configFile @"

  - name: OmniRoute
    base_url: http://localhost:${OMNIROUTE_PORT}/v1
    api_key: ${API_KEY}
"@
        } else {
            # Add the full custom_providers section
            Add-Content $configFile @"

custom_providers:
  - name: OmniRoute
    base_url: http://localhost:${OMNIROUTE_PORT}/v1
    api_key: ${API_KEY}
"@
        }
    }
} else {
    Write-Info "Creating fresh Hermes config..."
    @"
model:
  default: omni/auto
  provider: custom:OmniRoute
  api_key: ${API_KEY}
  base_url: http://localhost:${OMNIROUTE_PORT}/v1
  context_length: 65536
custom_providers:
  - name: OmniRoute
    base_url: http://localhost:${OMNIROUTE_PORT}/v1
    api_key: ${API_KEY}
toolsets:
  - hermes-cli
  - web
web:
  backend: firecrawl
approvals:
  mode: smart
security:
  allow_private_urls: true
"@ | Out-File -FilePath $configFile -Encoding utf8
}

Write-OK "Hermes configured to route through OmniRoute at localhost:${OMNIROUTE_PORT}"

# ── Step 6: Start & Test OmniRoute ────────────────────────────────────────
Write-Header "Step 6: Start OmniRoute & Verify"

$omnirouteCmd = Get-Command "omniroute" -ErrorAction SilentlyContinue
if (-not $omnirouteCmd) {
    # Try npm global bin
    $npmPrefix = npm config get prefix
    $omnirouteCmd = Get-Command "$npmPrefix\omniroute" -ErrorAction SilentlyContinue
}

if ($omnirouteCmd) {
    Write-Info "Starting OmniRoute on port $OMNIROUTE_PORT..."

    # Kill any existing OmniRoute on our port
    $existing = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -match "omniroute" -or $_.CommandLine -match "$OMNIROUTE_PORT"
    }
    if ($existing) {
        $existing | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
    }

    # Start OmniRoute in background
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "omniroute"
    $psi.Arguments = "--port $OMNIROUTE_PORT"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    Start-Sleep 3

    # Wait for it to be ready (up to 30 seconds)
    $ready = $false
    for ($i = 1; $i -le 30; $i++) {
        try {
            $models = Invoke-RestMethod -Uri "http://localhost:${OMNIROUTE_PORT}/v1/models" -ErrorAction Stop
            $ready = $true
            break
        } catch {
            Start-Sleep 1
        }
    }

    if ($ready) {
        Write-OK "OmniRoute is running on http://localhost:${OMNIROUTE_PORT}"

        # Test chat completion
        try {
            $body = @{
                model = "hy3:free"
                messages = @(@{ role = "user"; content = "Say hello in one word" })
                stream = $false
            } | ConvertTo-Json

            $result = Invoke-RestMethod -Uri "http://localhost:${OMNIROUTE_PORT}/v1/chat/completions" `
                -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop

            $reply = $result.choices[0].message.content
            Write-OK "OmniRoute chat test passed! Reply: $reply"
        } catch {
            Write-Warn "OmniRoute chat test didn't return expected: $_"
            Write-Warn "The gateway is running — configure providers via the web dashboard."
        }
    } else {
        Write-Warn "Could not confirm OmniRoute started. Check for errors."
    }
} else {
    Write-Warn "OmniRoute command not found — start manually: omniroute --port $OMNIROUTE_PORT"
}

# ── Step 7: Test Hermes ──────────────────────────────────────────────────
Write-Header "Step 7: Test Hermes Agent"

$hermesCmd = Get-Command "hermes" -ErrorAction SilentlyContinue
if ($hermesCmd) {
    Write-Info "Testing Hermes with a quick prompt..."
    try {
        $output = & hermes chat --once --message "Reply with only the word OK" 2>&1
        if ($output -match "OK|ok") {
            Write-OK "Hermes Agent working!"
        } else {
            Write-Warn "Hermes test output: $output"
            Write-Warn "Needs model configured in OmniRoute dashboard."
        }
    } catch {
        Write-Warn "Hermes test failed: $_"
    }
} else {
    Write-Warn "Hermes not available — test manually after setup."
}

# ── Summary ───────────────────────────────────────────────────────────────
Write-Host @"

   ╔══════════════════════════════════════════════╗
   ║           Setup Complete!                    ║
   ╚══════════════════════════════════════════════╝

   What's installed:
"@ -ForegroundColor Green

try {
    Write-Host "   • Node.js $(node --version) + npm $(npm --version)"
} catch { Write-Host "   • Node.js (check manually)" }
try {
    Write-Host "   • Python $(python --version 2>&1)"
} catch { Write-Host "   • Python (check manually)" }
try {
    Write-Host "   • OmniRoute v$(omniroute --version)"
} catch { Write-Host "   • OmniRoute (check manually)" }
try {
    Write-Host "   • Hermes Agent v$(hermes --version 2>&1 | Select-Object -First 1)"
} catch { Write-Host "   • Hermes Agent (check manually)" }

Write-Host @"

   Next steps:
   1. Open OmniRoute dashboard: http://localhost:${OMNIROUTE_PORT}
   2. Add free API keys in the OmniRoute dashboard → Providers
   3. Chat with Hermes:           hermes chat
   4. Set a specific model:      hermes model set <model-name>

   To add Hermes to your permanent PATH:
      `$env:Path += ";$HERMES_INSTALL_DIR\venv\Scripts"

   Then add to your PowerShell profile:
      Add-Content `$PROFILE "``$env:Path += ';$HERMES_INSTALL_DIR\venv\Scripts'"

"@ -ForegroundColor Cyan
