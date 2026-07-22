# 🚀 AI Stack One-Click Setup

**Node.js · Python · OmniRoute · Hermes Agent**

A one-command setup script that installs and wires together the full local AI development stack:

| Component | What it does |
|-----------|-------------|
| **Node.js** | JavaScript runtime (needed for OmniRoute) |
| **Python** | Runtime for Hermes Agent + ML tools |
| **OmniRoute** | Smart AI router with 237 providers (90+ free tiers) |
| **Hermes Agent** | Open-source AI coding agent with tools, memory, multi-platform |

Once installed, Hermes talks to OmniRoute, which load-balances across free/paid AI providers. You get a powerful coding assistant powered by **free-tier Claude, Gemini, GPT, and more** — without paying API bills.

---

## Quick Install

### Windows (PowerShell — recommended)

```powershell
irm https://raw.githubusercontent.com/AlexiisEdios/ai-stack-setup/main/setup-all.ps1 | iex
```

Or download `setup-all.ps1` and run it.

> **Run PowerShell as Administrator** for best results (enables winget installs).  
> If you're not admin, the script still works — it skips winget and uses fallbacks.

### Linux / macOS / WSL / Git Bash

```bash
curl -fsSL https://raw.githubusercontent.com/AlexiisEdios/ai-stack-setup/main/setup-all.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/AlexiisEdios/ai-stack-setup.git
cd ai-stack-setup
chmod +x setup-all.sh && ./setup-all.sh
```

---

## What the Script Does

1. **Checks & installs** Node.js v22 (via nvm, winget, or direct download)
2. **Checks & installs** Python 3.11 (via winget or direct download)
3. **Installs OmniRoute** globally via npm
4. **Installs Hermes Agent** via the official installer
5. **Configures** Hermes to use OmniRoute as its inference backend
6. **Starts OmniRoute** and tests it with a chat completion
7. **Tests Hermes** with a quick prompt
8. **Prints next steps** with links

Everything is **idempotent** — re-running the script skips already-installed components.

---

## After Setup

```bash
# Open OmniRoute dashboard (add free API keys here)
# → http://localhost:20128

# Start chatting with Hermes
hermes chat

# Set a default model (e.g., free Hy3 model)
hermes model set hy3:free

# Run a one-off command
hermes chat --once --message "Write a Python script to sort a list"
```

### Add Free Providers in OmniRoute

1. Open http://localhost:20128
2. Go to **Providers** → **Add Provider**
3. Pick **Hy3** (free, no API key needed) or others:
   - **Hy3** — Free Claude/Gemini/Llama models
   - **Gemini Free** — Google's Gemini models (free tier)
   - **GitHub Models** — Free with GitHub login
   - **OpenRouter** — Many free models with rate limits
4. Create a **Combo** (routing strategy) with your chosen models
5. Your Hermes agent can now use them!

---

## Architecture

```
          ┌─────────────┐
          │  Hermes      │  Your AI coding agent
          │  Agent       │  (CLI, tools, memory)
          └──────┬───────┘
                 │ http://localhost:20128/v1
          ┌──────▼───────┐
          │  OmniRoute    │  Smart AI router
          │  Gateway      │  237 providers, auto-fallback
          └──────┬───────┘
                 │
     ┌───────────┼───────────────┐
     ▼           ▼               ▼
  Claude      Gemini          GPT
  (free)      (free)       (paid tier)
     ▼           ▼               ▼
  Hy3 Free   Gemini Free    OpenAI API
```

---

## File Structure

```
ai-stack-setup/
├── setup-all.sh       # Bash script (Linux, macOS, Git Bash)
├── setup-all.ps1      # PowerShell script (Windows)
└── README.md          # This file
```

---

## Requirements

- **OS**: Windows 10+, Linux, macOS
- **Shell**: PowerShell 5.1+ (Windows), Bash (Linux/Mac/Git Bash)
- **Internet**: Required for downloads (about 300 MB total)
- **Disk**: ~1 GB free space
- **Time**: 5–15 minutes (depends on download speed)

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `node: command not found` | Restart your terminal after install, or add it to PATH manually |
| `hermes: command not found` | Run: `$env:Path += ";$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts"` (PowerShell) or `export PATH="$HOME/.local/bin:$PATH"` (Bash) |
| OmniRoute won't start | Check port 20128 is free: `netstat -ano | findstr :20128` |
| Hermes can't reach OmniRoute | Make sure OmniRoute is running, then run `hermes model set-endpoint http://localhost:20128/v1` |
| Permission denied (Linux/Mac) | `chmod +x setup-all.sh` |
| winget not found (Windows) | Install [App Installer](https://www.microsoft.com/p/app-installer/9nblggh4nns1) from Microsoft Store, or install Node.js/Python manually |

---

## License

MIT — use freely, share widely, contribute back.

---

## About

Built by [@AlexiisEdios](https://github.com/AlexiisEdios) with love and late-night chai.

- **Hermes Agent**: https://hermes-agent.nousresearch.com
- **OmniRoute**: https://omniroute.online
- **Node.js**: https://nodejs.org
- **Python**: https://python.org
