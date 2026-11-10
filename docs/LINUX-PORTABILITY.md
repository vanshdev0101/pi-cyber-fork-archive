# pi-cyber — Linux Portability Findings & Fixes

Machine: CachyOS Linux, x86_64. Repo: ~/.pi/pi-cyber (fork: github.com/vanshdev0101/pi-cyber).
Root cause: the harness was built and frozen on an Apple Silicon Mac ("marban").
The engine (TS adapters/agents/skills) is platform-agnostic — every Linux problem
is in the install/bootstrap layer, not the logic.

## Blockers and solutions

| # | Component | macOS assumption | Linux reality | Impact | Fix |
|---|-----------|------------------|---------------|--------|-----|
| 1 | Scanner asset matcher `src/tools/installer.ts:46-62` | OS_RE=darwin/macos/osx, ARM_RE=arm64, EXCLUDE drops amd64/x86_64 | needs linux+amd64 | BLOCKER: every GitHub-release scanner picks a Mac binary or none | host-aware picker (process.platform/arch), route resolveLatest through it |
| 2 | Installed binaries `~/.pi/scanners/bin/*` | Mach-O arm64 | exec format error | BLOCKER (from #1) | delete bad binaries |
| 3 | `tools/manifest.resolved.json` | URLs *_macOS_arm64 | reused after fix unless cleared | must clear | rm resolved.json + state.json, reinstall |
| 4 | `tools/install-curl-impersonate.sh:18-34` | both branches fetch -macos; x86_64 hard-exits | upstream ships Linux assets, script ignores | BLOCKER for bypass_fetch | add linux x86_64-linux-gnu asset + SHA pin |
| 5 | cloakbrowser `tools/manifest.json:27` | "free v145 macOS build keyless" | Linux build may need CLOAKBROWSER_LICENSE_KEY | browser tool may not work free | run npm installer; report if key needed |
| 6 | jwt-hack `manifest.json:28` | brew install (arm64) | no brew; GitHub Linux binary exists | soft | auto-fixed by #1 |
| 7 | nmap `manifest.json:19` | macOS installer x86_64-only | use pacman | minor (on-demand) | `sudo pacman -S nmap` (manual) |
| 8 | `shasum` in tools/*.sh | default on macOS | only if perl shasum present (IS here) | soft | none |

## Already fixed earlier in session
- /Users/marban paths in boot.ts + mcp.json -> $HOME
- opencode-pi global path in boot.ts -> guarded with existsSync
- launcher ran pi under node (no bun:sqlite) -> pi.sh execs under bun
- MCP servers needed uvx -> installed uv
- marban proxy removed; model repointed (OpenRouter free / local Ollama)
- theme reskinned matrix green
- (docs/ still reference /Users/marban — cosmetic, left alone)

## Not a problem
- adapters don't branch on OS (only doctor.ts reports platform)
- core scanners publish linux_amd64 assets (confirmed nuclei_3.11.1_linux_amd64.zip)
- runtime stack present: bun, node (fnm), python3, git, curl, rg

---

## RESOLUTION (applied 2026-11-10)

| # | Blocker | Status | What was done |
|---|---------|--------|---------------|
| 1 | Scanner matcher darwin/arm64 | ✅ FIXED | `pickHostAsset()` added (host-aware via process.platform/arch); resolveLatest routed through it. Pushed. |
| 2 | Mach-O arm64 binaries | ✅ FIXED | Cleared bad binaries; reinstalled as ELF x86-64. |
| 3 | macOS-frozen resolved manifest | ✅ FIXED | Cleared + re-frozen with linux_amd64 pins. Pushed. |
| 4 | curl-impersonate macOS-only | ✅ FIXED | Added Linux x86_64-linux-gnu asset + SHA 5e77cb12...; installed, runs (8.23.0-IMPERSONATE Linux). Pushed. |
| 5 | cloakbrowser macOS build | ✅ INSTALLED | install-cloakbrowser.sh (npm) installed 0.6.3 + playwright-core on Linux. Runtime browser launch to be confirmed in use (may need CLOAKBROWSER_LICENSE_KEY for newer Chromium). |
| 6 | jwt-hack brew | ⚠️ via #1 route | Installs from GitHub once pulled; not auto-installed (on-demand). |
| 7 | nmap | ⚠️ manual | `sudo pacman -S nmap` |
| 8 | shasum | ✅ n/a | present on box |
| zap | arch-agnostic Java tarball | ⚠️ manual | `sudo pacman -S zaproxy` (2.17.0 in repo) |
| semgrep | pip-distributed | ⚠️ manual | `pipx install semgrep` or `sudo pacman -S semgrep` |

### Core scanners now working (ELF x86-64):
subfinder, dnsx, httpx, katana, nuclei, uncover, vulnx, interactsh-client,
naabu, ffuf, osv-scanner, gitleaks, syft, trivy (14) + curl-impersonate + cloakbrowser.

### Manual one-liners left (secondary tools, need your sudo):
- sudo pacman -S nmap zaproxy
- pipx install semgrep   (or: sudo pacman -S semgrep)

Commits pushed to fork: b7371df (host-aware installer), a2a5f3f (thinking off), c8b7a2e (theme).
