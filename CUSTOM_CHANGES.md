# Custom Changes for PeakCut Fork

This document tracks all customizations made to the PeakCut fork (AndyDope/PeakCut) to maintain them during upstream rebases.

## Branding Customizations

### Color Scheme
Changed from PeakCut's orange theme (#FF8B33) to a blue theme (#2563EB):
- Primary brand: `#2563EB` (blue-600)
- Primary hover: `#3B82F6` (blue-500)
- Deep: `#1D4ED8` (blue-700)
- Soft: `#EFF6FF` (blue-50)
- Line brand: `#BFDBFE` (blue-200)
- Frame colors updated to slate palette

### Files Modified
| File | Changes | Conflict Risk |
|------|---------|---------------|
| `web/auth.html` | Color scheme, logo filter, hero text | Low |
| `web/landing.html` | Color scheme, theme-color meta tag | Low |

### Specific Changes

#### web/auth.html
- Updated CSS custom properties (lines 13-16) to blue theme
- Added `style="filter: brightness(0) invert(1);"` to logo for dark sidebar
- Changed hero h1 text: "Clips from every stream" → "Clip every stream"

#### web/landing.html
- Updated CSS custom properties (lines 30-33) to blue theme
- Changed meta theme-color from `#FF8B33` to `#2563EB`

## Git Workflow for Upstream Updates

### Repository Structure
```
AndyDope/PeakCut (fork)
├── main branch          # Production: custom changes + upstream
├── upstream branch      # Read-only mirror of haziqahmedqasmi/PeakCut main
└── custom branch        # Isolated custom changes (reference)
```

### Update Process
```bash
# 1. Fetch latest upstream
git fetch upstream

# 2. Rebase main onto upstream/main
git checkout main
git rebase upstream/main

# 3. Resolve conflicts (custom files should NOT conflict)
#    If conflicts in core files, keep custom changes or merge carefully

# 4. Test locally
docker compose up -d --build

# 5. Push to fork
git push origin main --force-with-lease
```

### Automation
- **GitHub Actions** (`.github/workflows/deploy.yml`): Runs every 6 hours + on push to main
- Rebases onto upstream, pushes to fork, SSH deploys to Oracle

## Deployment Scripts

### Oracle Update Script (`deploy/update.sh`)
```bash
#!/bin/bash
set -e
cd /opt/peakcut
git fetch origin
git reset --hard origin/main
docker compose up -d --build
docker image prune -f
echo "Update complete: $(date)"
```

### OCI CLI Commands (`deploy/oci-commands.sh`)
Complete infrastructure provisioning commands using your tenancy OCIDs.

## Secrets Required for GitHub Actions
Add to your fork (AndyDope/PeakCut) → Settings → Secrets → Actions:
- `ORACLE_HOST` - Instance public IP
- `ORACLE_SSH_KEY` - Private key content (id_ed25519 or id_rsa)
- `GH_PAT` - Personal Access Token with `repo` scope

## Upstream Rebase Strategy
1. **Never commit to upstream/main** - only to your fork's main
2. **Keep custom changes isolated** - only modify `web/` templates
3. **Test before pushing** - run `docker compose up -d --build` locally
4. **Document changes** - this file tracks all customizations

## Files Safe to Customize (Low Conflict Risk)
- `web/auth.html` - Login/signup page
- `web/landing.html` - Landing page
- `web/index.html` - Main app (careful - large file)
- `studio/auth.py` - Add OAuth providers
- `.env.example` - Document custom env vars
- `deploy/Caddyfile` - Custom Caddy config

## Files to Avoid Modifying (High Conflict Risk)
- `studio/server.py` - Core routing
- `studio/jobs.py` - Video pipeline
- `studio/live.py` - Live recording
- `studio/db.py` - Schema changes need migrations
- `Dockerfile` - Base image, dependencies

---

**Last Updated**: 2026-11-22
**Fork**: https://github.com/AndyDope/PeakCut
**Upstream**: https://github.com/haziqahmedqasmi/PeakCut