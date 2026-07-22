#!/usr/bin/env bash
# ============================================================================
# AI Stack One-Click Setup
# ============================================================================
# Installs: Node.js, Python, OmniRoute, Hermes Agent
# Tests the integration with a "hello world" prompt
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AlexiisEdios/ai-stack-setup/master/setup-all.sh | bash
#
# Or:
#   chmod +x setup-all.sh && ./setup-all.sh
#
# Supports: Linux, macOS, Windows (Git Bash / WSL)
# ============================================================================

set -e

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Config ──────────────────────────────────────────────────────────────────
NODE_VERSION="22"
PYTHON_VERSION="3.11"
OMNIROUTE_PORT=20128
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

# ── Helpers ─────────────────────────────────────────────────────────────────
info()  { echo -e "${CYAN}→${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; exit 1; }
header(){ echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}\n"; }
spacer(){ echo; }

# ── Banner ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}"
echo "   ╔══════════════════════════════════════════════╗"
echo "   ║       AI Stack One-Click Setup               ║"
echo "   ║   Node.js · Python · OmniRoute · Hermes      ║"
echo "   ╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo "   This script installs everything needed to run an"
echo "   AI coding agent (Hermes) + smart router (OmniRoute)"
echo "   with free AI provider tiers."
echo ""

# ── Detect OS ───────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Linux*)   PLATFORM="linux" ;;
  Darwin*)  PLATFORM="macos" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
  *)        fail "Unsupported OS: $OS (try the PowerShell script on Windows)" ;;
esac
info "Detected platform: $PLATFORM"
spacer

# ── 1. Install Node.js ─────────────────────────────────────────────────────
header "Step 1: Node.js"

if command -v node &>/dev/null; then
  NODE_VER=$(node --version 2>/dev/null)
  ok "Node.js already installed: $NODE_VER"
else
  info "Installing Node.js $NODE_VERSION..."
  case "$PLATFORM" in
    linux)
      # Use NodeSource setup script
      curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
      apt-get install -y nodejs
      ;;
    macos)
      if command -v brew &>/dev/null; then
        brew install node@${NODE_VERSION}
      else
        # Install via nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install $NODE_VERSION
        nvm use $NODE_VERSION
      fi
      ;;
    windows)
      # Git Bash — use nvm-windows via npm or direct download
      if command -v nvm &>/dev/null; then
        nvm install $NODE_VERSION
        nvm use $NODE_VERSION
      elif command -v winget &>/dev/null; then
        winget install OpenJS.NodeJS.LTS
      else
        fail "Install Node.js manually from https://nodejs.org/ then re-run this script"
      fi
      ;;
  esac
  if command -v node &>/dev/null; then
    ok "Node.js $(node --version) installed"
  else
    fail "Node.js installation failed — install manually from https://nodejs.org/"
  fi
fi

# Verify npm too
if ! command -v npm &>/dev/null; then
  fail "npm not found (should come with Node.js)"
fi
ok "npm $(npm --version)"

spacer

# ── 2. Install Python ──────────────────────────────────────────────────────
header "Step 2: Python"

if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version 2>/dev/null)
  ok "Python already installed: $PY_VER"
elif command -v python &>/dev/null; then
  PY_VER=$(python --version 2>/dev/null)
  ok "Python already installed: $PY_VER"
else
  info "Installing Python $PYTHON_VERSION..."
  case "$PLATFORM" in
    linux)
      apt-get update -qq && apt-get install -y -qq python3 python3-pip python3-venv
      ;;
    macos)
      if command -v brew &>/dev/null; then
        brew install python@${PYTHON_VERSION}
      else
        fail "Install Python manually from https://python.org/ then re-run"
      fi
      ;;
    windows)
      if command -v winget &>/dev/null; then
        winget install Python.Python.3.11
      else
        fail "Install Python from https://www.python.org/downloads/ then re-run"
      fi
      ;;
  esac
  command -v python3 &>/dev/null || python3() { python "$@"; }
  ok "Python $(python3 --version 2>/dev/null || python --version 2>/dev/null) installed"
fi

# Ensure pip
if ! python3 -m pip --version &>/dev/null 2>&1; then
  info "Installing pip..."
  python3 -m ensurepip --upgrade 2>/dev/null || \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3
fi
ok "pip $(python3 -m pip --version 2>/dev/null | awk '{print $2}')"

spacer

# ── 3. Install OmniRoute ───────────────────────────────────────────────────
header "Step 3: OmniRoute (AI Router)"

if command -v omniroute &>/dev/null; then
  OR_VER=$(omniroute --version 2>/dev/null)
  ok "OmniRoute already installed: v$OR_VER"
else
  info "Installing OmniRoute via npm (global)..."
  npm install -g omniroute
  if command -v omniroute &>/dev/null; then
    ok "OmniRoute v$(omniroute --version) installed"
  else
    fail "OmniRoute installation failed — try: npm install -g omniroute"
  fi
fi

# ── 4. Install Hermes Agent ────────────────────────────────────────────────
header "Step 4: Hermes Agent"

if command -v hermes &>/dev/null; then
  H_VER=$(hermes --version 2>/dev/null | head -1)
  ok "Hermes Agent already installed: $H_VER"
else
  info "Installing Hermes Agent..."
  case "$PLATFORM" in
    linux|macos)
      curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
      # Source it for current session
      export PATH="$HOME/.local/bin:$PATH"
      ;;
    windows)
      powershell -ExecutionPolicy ByPass -NoProfile -Command "iex (irm https://hermes-agent.nousresearch.com/install.ps1)"
      export PATH="$HOME/AppData/Local/hermes/hermes-agent/venv/Scripts:$PATH"
      ;;
  esac
  if command -v hermes &>/dev/null; then
    ok "Hermes Agent installed: $(hermes --version 2>/dev/null | head -1)"
  else
    # Might be in a different PATH location — try common spots
    if [ -f "$HOME/.local/bin/hermes" ]; then
      export PATH="$HOME/.local/bin:$PATH"
      ok "Hermes Agent installed: $(hermes --version 2>/dev/null | head -1)"
    elif [ -f "$HOME/AppData/Local/hermes/hermes-agent/venv/Scripts/hermes" ]; then
      export PATH="$HOME/AppData/Local/hermes/hermes-agent/venv/Scripts:$PATH"
      ok "Hermes Agent installed: $(hermes --version 2>/dev/null | head -1)"
    else
      warn "Hermes installed but 'hermes' command not in PATH"
      warn "Find it in ~/.local/bin/ or ~/AppData/Local/hermes/hermes-agent/venv/Scripts/"
    fi
  fi
fi

spacer

# ── 5. Configure Hermes → OmniRoute ────────────────────────────────────────
header "Step 5: Wire Hermes to OmniRoute"

# Generate a simple API key (Hermes needs one even though OmniRoute doesn't enforce it)
OMNIROUTE_KEY="sk-$(openssl rand -hex 16 2>/dev/null || python3 -c 'import secrets;print(secrets.token_hex(16))')"

# Configure Hermes to use OmniRoute as backend
if command -v hermes &>/dev/null; then
  hermes model provider custom 2>/dev/null || true
  hermes model set-endpoint http://localhost:${OMNIROUTE_PORT}/v1 2>/dev/null || true

  # Also write config.yaml directly to ensure it sticks
  HERMES_CONFIG_DIR="${HERMES_HOME}"
  if [ "$PLATFORM" = "windows" ]; then
    HERMES_CONFIG_DIR="$HOME/AppData/Local/hermes"
  fi

  # Write/update custom provider and default model config
  if [ -f "$HERMES_CONFIG_DIR/config.yaml" ]; then
    info "Updating existing Hermes config to use OmniRoute..."

    # Use sed to update the relevant sections (cross-platform)
    # Add custom provider if not present
    if grep -q "custom_providers:" "$HERMES_CONFIG_DIR/config.yaml" 2>/dev/null; then
      # Check if Omnirouter provider already exists
      if ! grep -q "Omnirouter\|OmniRoute" "$HERMES_CONFIG_DIR/config.yaml" 2>/dev/null; then
        # Append to custom_providers list
        cat >> "$HERMES_CONFIG_DIR/config.yaml" << CFGEOF

  - name: OmniRoute
    base_url: http://localhost:${OMNIROUTE_PORT}/v1
    api_key: ${OMNIROUTE_KEY}
CFGEOF
      fi
    else
      # Add custom_providers section
      cat >> "$HERMES_CONFIG_DIR/config.yaml" << CFGEOF
custom_providers:
  - name: OmniRoute
    base_url: http://localhost:${OMNIROUTE_PORT}/v1
    api_key: ${OMNIROUTE_KEY}
CFGEOF
    fi
  else
    info "Creating fresh Hermes config..."
    cat > "$HERMES_CONFIG_DIR/config.yaml" << CFGEOF
model:
  default: omni/auto
  provider: custom:OmniRoute
  api_key: ${OMNIROUTE_KEY}
  base_url: http://localhost:${OMNIROUTE_PORT}/v1
  context_length: 65536
custom_providers:
  - name: OmniRoute
    base_url: http://localhost:${OMNIROUTE_PORT}/v1
    api_key: ${OMNIROUTE_KEY}
toolsets:
  - hermes-cli
  - web
web:
  backend: firecrawl
approvals:
  mode: smart
security:
  allow_private_urls: true
CFGEOF
  fi
  ok "Hermes configured to route through OmniRoute at localhost:${OMNIROUTE_PORT}"
else
  warn "Hermes not in PATH yet — configure manually after adding to PATH"
  warn "Run: hermes model provider custom"
  warn "Run: hermes model set-endpoint http://localhost:${OMNIROUTE_PORT}/v1"
fi

spacer

# ── 6. Start OmniRoute & Test ──────────────────────────────────────────────
header "Step 6: Start OmniRoute & Verify"

# Kill any existing OmniRoute on our port
if command -v omniroute &>/dev/null; then
  info "Starting OmniRoute (port ${OMNIROUTE_PORT})..."

  # Start OmniRoute in background, wait for it
  omniroute --port ${OMNIROUTE_PORT} > /tmp/omniroute.log 2>&1 &
  OR_PID=$!
  info "OmniRoute PID: $OR_PID"

  # Wait for it to be ready
  for i in $(seq 1 30); do
    if curl -s http://localhost:${OMNIROUTE_PORT}/v1/models > /dev/null 2>&1; then
      ok "OmniRoute is running and serving requests"
      break
    fi
    sleep 1
  done

  if ! curl -s http://localhost:${OMNIROUTE_PORT}/v1/models > /dev/null 2>&1; then
    warn "OmniRoute may still be starting — check /tmp/omniroute.log"
    warn "Test manually: curl http://localhost:${OMNIROUTE_PORT}/v1/models"
  fi

  # Test a quick chat completion
  TEST_RESULT=$(curl -s http://localhost:${OMNIROUTE_PORT}/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
      "model": "hy3:free",
      "messages": [{"role": "user", "content": "Say hello in one word"}],
      "stream": false
    }' 2>/dev/null)

  if echo "$TEST_RESULT" | grep -q '"choices"'; then
    REPLY=$(echo "$TEST_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null || echo "(see above)")
    ok "OmniRoute chat test passed! Reply: $REPLY"
  else
    warn "OmniRoute chat test didn't return expected format (may need provider config)"
    warn "The gateway is running — configure providers via the dashboard"
  fi
else
  warn "OmniRoute not available — start it manually: omniroute"
fi

# ── 7. Test Hermes ─────────────────────────────────────────────────────────
header "Step 7: Test Hermes Agent"

if command -v hermes &>/dev/null; then
  info "Testing Hermes with a quick prompt..."
  HERMES_TEST=$(hermes chat --once --message "Reply with only the word OK" 2>&1 || true)
  if echo "$HERMES_TEST" | grep -qi "OK\|ok"; then
    ok "Hermes Agent working!"
  else
    warn "Hermes test output: $HERMES_TEST"
    warn "May need model configured in OmniRoute dashboard first"
    warn "Open http://localhost:${OMNIROUTE_PORT} and add a free provider/model"
  fi
else
  warn "Hermes not in PATH — test manually after setting up PATH"
fi

spacer
echo -e "${GREEN}${BOLD}"
echo "   ╔══════════════════════════════════════════════╗"
echo "   ║           Setup Complete!                    ║"
echo "   ╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo "   What's installed:"
echo "   • Node.js $(node --version 2>/dev/null || echo '?') + npm $(npm --version 2>/dev/null || echo '?')"
echo "   • Python $(python3 --version 2>/dev/null || python --version 2>/dev/null || echo '?')"
echo "   • OmniRoute v$(omniroute --version 2>/dev/null || echo '?') (serving on http://localhost:${OMNIROUTE_PORT})"
echo "   • Hermes Agent v$(hermes --version 2>/dev/null | head -1 || echo '?')"
echo ""
echo "   ${BOLD}Next steps:${NC}"
echo "   1. Open OmniRoute dashboard: http://localhost:${OMNIROUTE_PORT}"
echo "   2. Add free API keys in the OmniRoute dashboard → Providers"
echo "   3. Chat with Hermes:  hermes chat"
echo "   4. Set a system model: hermes model set <model-name>"
echo ""
echo "   ${BOLD}Troubleshooting:${NC}"
echo "   • OmniRoute log:  cat /tmp/omniroute.log"
echo "   • Restart:        kill $OR_PID 2>/dev/null; omniroute &"
echo "   • Hermes config:  $HERMES_CONFIG_DIR/config.yaml"
echo ""

# Save PATH instructions in case
if ! command -v hermes &>/dev/null; then
  echo -e "   ${YELLOW}⚠ 'hermes' command not in PATH. Add one of:${NC}"
  echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "      export PATH=\"\$HOME/AppData/Local/hermes/hermes-agent/venv/Scripts:\$PATH\""
fi
