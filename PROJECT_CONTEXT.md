# PeakCut on Oracle Cloud Free Tier - Complete Project Context

## 📋 Executive Summary

This document provides full context for deploying **PeakCut** (an open-source AI video clipping tool for Twitch/Kick/YouTube streams) on **Oracle Cloud Free Tier** using Ampere A1 ARM instances. All code, scripts, and configurations are ready in the GitHub fork.

---

## ✅ What Has Been Executed (Completed)

### 1. Repository Setup & Customization
- ✅ **Forked** original repo (`haziqahmedqasmi/PeakCut`) to `AndyDope/PeakCut`
- ✅ **Custom branding** applied (blue theme #2563EB instead of orange):
  - `web/auth.html` - Login/signup page with new colors, logo filter, updated hero text
  - `web/landing.html` - Landing page with new color scheme
- ✅ **Git workflow configured** for upstream updates:
  - `upstream` remote points to original repo
  - `main` branch = production (custom changes + upstream)
  - Rebase strategy documented in `CUSTOM_CHANGES.md`

### 2. GitHub Actions CI/CD Pipeline
- ✅ **Workflow created**: `.github/workflows/deploy.yml`
  - Triggers: Push to `main` + scheduled every 6 hours
  - Actions: Fetch upstream → Rebase → Push to fork → SSH deploy to Oracle
  - Uses `appleboy/ssh-action` for deployment

### 3. Oracle Infrastructure (Provisioned)
- ✅ **VCN** created: `ocid1.vcn.oc1.ap-mumbai-1.amaaaaaa4ol4peqaylxzi7b6nio6lo564odlcjvew3sd4lrzkalz25pizzlq`
- ✅ **Internet Gateway** created and attached
- ✅ **Public Subnet** created: `ocid1.subnet.oc1.ap-mumbai-1.aaaaaaaagpj3lqlhb5j754rhxlbcese3yy5e36u2zssg4axnw3jvdo3rrsza`
- ✅ **Route Table** updated with IGW route (0.0.0.0/0 → IGW)
- ✅ **Security List** ready (needs ingress rules for 80, 443, 22)
- ✅ **Block Volume (150 GB)** created: `ocid1.volume.oc1.ap-mumbai-1.abrg6ljrhkta6p7uyktewxhsp5jwu5lp6orvjtaq5am5sillmko4fwbr4haq`

### 4. Deployment Scripts
- ✅ **Oracle update script**: `deploy/update.sh` - pulls latest from fork, rebuilds Docker, prunes images
- ✅ **OCI CLI commands**: `deploy/oci-commands.sh` - complete provisioning commands
- ✅ **Documentation**: `CUSTOM_CHANGES.md` - tracks all customizations for rebase safety

### 5. GitHub Secrets (Partially Configured)
- ✅ **GH_PAT** = configured (personal access token with `repo` scope)
- ⏳ **ORACLE_SSH_KEY** = needs private key content from `oci_keys/id_ed25519`
- ⏳ **ORACLE_HOST** = needs instance public IP (waiting for instance creation)

---

## ⏳ What Remains (Pending)

### 1. Ampere A1 Instance Creation
**Status**: ❌ **Out of capacity** in ap-mumbai-1 (Free Tier limitation)
```bash
# Retry this command periodically until capacity available:
oci compute instance launch \
  --availability-domain epvz:AP-MUMBAI-1-AD-1 \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaay5w7nj6sodclqfduwusu7mczmdqqvuiaqtdzzehfww6xqw6j6naq \
  --shape VM.Standard.A1.Flex \
  --shape-config '{"ocpus": 4, "memory_in_gbs": 24}' \
  --image-id ocid1.image.oc1.ap-mumbai-1.aaaaaaaaq2j3dpwyvy6ejkdrdiwv2jbcfzd6hbykhp6jt2j7qvymalh6sjba \
  --subnet-id ocid1.subnet.oc1.ap-mumbai-1.aaaaaaaagpj3lqlhb5j754rhxlbcese3yy5e36u2zssg4axnw3jvdo3rrsza \
  --assign-public-ip true \
  --ssh-authorized-keys-file /Users/anirudhdoiphode/Documents/dev/proj/Clippin/oci_keys/id_ed25519.pub \
  --display-name peakcut-server \
  --region ap-mumbai-1
```

### 2. Post-Instance Steps
- Attach Block Volume to instance
- Get public IP → set as `ORACLE_HOST` GitHub Secret
- Configure Security List ingress rules (80, 443, 22 from your IP)
- On instance: format/mount volume, install Docker, deploy PeakCut
- Grant yourself admin: `docker compose exec app python -m studio.admin grant you@domain.com`

---

## 📦 Complete Plan (End-to-End)

### Phase 1: Repository & Customization
1. Fork `haziqahmedqasmi/PeakCut` to your GitHub
2. Clone fork locally
3. Add `upstream` remote: `git remote add upstream https://github.com/haziqahmedqasmi/PeakCut.git`
4. Customize branding (colors, logos, text) in `web/auth.html`, `web/landing.html`
5. Commit & push to your fork's `main`

### Phase 2: GitHub Actions Setup
1. Add workflow: `.github/workflows/deploy.yml` (provided)
2. Add GitHub Secrets:
   - `GH_PAT` - Personal Access Token with `repo` scope
   - `ORACLE_SSH_KEY` - Private key content (not path!)
   - `ORACLE_HOST` - Instance public IP (after creation)

### Phase 3: Oracle Infrastructure
1. **Prerequisites**: OCI CLI configured with API key
2. Create VCN + Internet Gateway + Public Subnet + Route Table
3. Create 150 GB Block Volume
4. Create Ampere A1 Flex instance (4 OCPU, 24 GB RAM) - **wait for capacity**
5. Attach Block Volume
6. Configure Security Lists (80, 443, 22 restricted to your IP)

### Phase 4: Instance Deployment
```bash
# On Oracle instance:
ssh ubuntu@<PUBLIC_IP>
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu
newgrp docker
sudo apt update && sudo apt install -y docker-compose-plugin

# Format & mount volume
sudo mkfs.ext4 /dev/oracleoci/oraclevdb
sudo mkdir -p /mnt/peakcut-data
echo "/dev/oracleoci/oraclevdb /mnt/peakcut-data ext4 defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Deploy
cd /opt
git clone https://github.com/YOUR_USERNAME/PeakCut.git peakcut
cd peakcut
cp .env.example .env
# Edit .env with your values
mkdir -p secrets
docker compose up -d --build

# Make yourself admin
docker compose exec app python -m studio.admin grant you@yourdomain.com
```

### Phase 5: Automation & Maintenance
- GitHub Actions auto-deploys on push + every 6 hours
- Manual update: `git fetch upstream && git rebase upstream/main && git push origin main --force-with-lease`
- Backups: Daily DB dump, weekly data tar.gz (add to crontab)

---

## 🖥️ What Your Friend Needs to Run This

### Prerequisites (Their Machine)
| Requirement | Details |
|-------------|---------|
| **GitHub Account** | To fork repo and run Actions |
| **Oracle Cloud Free Tier Account** | Sign up at cloud.oracle.com |
| **OCI CLI** | Install & configure with their tenancy |
| **SSH Key Pair** | `ssh-keygen -t ed25519` (public key for instance, private for GitHub Secret) |
| **Domain (optional)** | For custom domain; else use Oracle public IP |
| **AI API Keys** | At least one: Gemini, OpenAI, Grok, Claude, or OpenRouter |

### Their `.env` Values to Configure
```bash
# Required
PEAKCUT_DOMAIN=theirdomain.com  # or leave blank for IP
POSTGRES_PASSWORD=strong_random_password
COMPOSE_PROFILES=own-https
PEAKCUT_ACCOUNTS=1

# At least one AI provider
PEAKCUT_AI_PROVIDER=gemini
PEAKCUT_AI_MODELS=gemini-1.5-flash
PEAKCUT_AI_KEY=their_gemini_api_key

# Google OAuth (optional)
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx

# Email/SMTP (optional, for password reset)
PEAKCUT_SMTP_HOST=smtp.gmail.com
PEAKCUT_SMTP_PORT=587
PEAKCUT_SMTP_USER=xxx
PEAKCUT_SMTP_PASSWORD=xxx
PEAKCUT_SMTP_FROM=xxx
```

### GitHub Secrets They Must Add
| Secret | Source |
|--------|--------|
| `GH_PAT` | Their GitHub PAT (Settings → Developer settings → PAT, `repo` scope) |
| `ORACLE_SSH_KEY` | `cat ~/.ssh/id_ed25519` (private key content) |
| `ORACLE_HOST` | Instance public IP (after they create it) |

### Oracle Resources They'll Create
- VCN (10.0.0.0/16)
- Internet Gateway
- Public Subnet (10.0.1.0/24)
- Route Table (0.0.0.0/0 → IGW)
- Security List (ingress: 80, 443, 22 from their IP)
- 150 GB Block Volume
- Ampere A1 Flex Instance (4 OCPU, 24 GB RAM)

---

## 💰 Cost Breakdown (Oracle Free Tier)

| Resource | Free Tier Limit | Our Usage | Cost |
|----------|-----------------|-----------|------|
| Ampere A1 Compute | 4 OCPUs, 24 GB RAM | 4 OCPUs, 24 GB | **$0** |
| Block Volume | 200 GB | 150 GB | **$0** |
| Network Egress | 10 TB/month | ~1-5 GB/month | **$0** |
| **Total** | | | **$0/month** |

---

## 📁 Key Files in Fork (AndyDope/PeakCut)

```
PeakCut/
├── web/
│   ├── auth.html          # Custom branded login page
│   └── landing.html       # Custom branded landing page
├── .github/workflows/
│   └── deploy.yml         # Auto-update + deploy workflow
├── deploy/
│   ├── update.sh          # Runs on Oracle: git pull + docker rebuild
│   └── oci-commands.sh    # Complete OCI CLI provisioning commands
├── CUSTOM_CHANGES.md      # Documents all customizations for rebase
└── ... (rest of PeakCut)
```

---

## 🔄 Upstream Update Workflow (Critical)

```bash
# 1. Fetch upstream changes
git fetch upstream

# 2. Rebase your main onto upstream/main
git checkout main
git rebase upstream/main

# 3. Resolve conflicts (your custom files in web/ should NOT conflict)
#    If core files conflict, keep your changes or merge carefully

# 4. Test locally
docker compose up -d --build

# 5. Push to fork (triggers GitHub Actions deploy)
git push origin main --force-with-lease
```

**Golden Rules** (from `CUSTOM_CHANGES.md`):
1. Never commit to upstream/main
2. Keep custom changes isolated to `web/` templates
3. Test before pushing
4. Document changes in `CUSTOM_CHANGES.md`

---

## 🚀 Quick Start for Your Friend

```bash
# 1. Fork & clone
git clone https://github.com/THEIR_USERNAME/PeakCut.git
cd PeakCut

# 2. Add upstream
git remote add upstream https://github.com/haziqahmedqasmi/PeakCut.git

# 3. Customize branding (optional - edit web/auth.html, web/landing.html)

# 4. Push to their fork
git add . && git commit -m "custom: my branding" && git push origin main

# 5. Set up Oracle (run commands from deploy/oci-commands.sh)
#    - Configure OCI CLI first
#    - Create VCN, subnet, IGW, volume
#    - Create instance (wait for capacity)

# 6. Add GitHub Secrets
#    - GH_PAT, ORACLE_SSH_KEY, ORACLE_HOST

# 7. Deploy on instance (commands in deploy/oci-commands.sh Step 6)

# 8. Done! Visit https://theirdomain.com or http://<oracle-ip>
```

---

## 📞 Support Resources

- **PeakCut Original Repo**: https://github.com/haziqahmedqasmi/PeakCut
- **PeakCut Docs**: See `DEPLOY.md`, `AGENTS.md` in repo
- **Oracle Free Tier Docs**: https://www.oracle.com/cloud/free/
- **OCI CLI Reference**: https://docs.oracle.com/iaas/tools/oci-cli/latest/oci_cli_docs/

---

## 📝 Notes for Your Friend

1. **Ampere capacity** is the main bottleneck - may need to retry instance creation over days/weeks
2. **No domain needed** - works with Oracle public IP (Caddy will use self-signed cert or HTTP)
3. **AI keys required** for full functionality - at least one provider
4. **SMTP optional** - only needed for email verification/password reset
5. **Google OAuth optional** - email/password works without it
6. **Backups are critical** - set up cron jobs for DB + data volume
7. **Monitor disk space** - 150 GB fills up with video data over time

---

**Document Version**: 1.0
**Last Updated**: 2026-11-23
**Fork**: https://github.com/AndyDope/PeakCut
**Original**: https://github.com/haziqahmedqasmi/PeakCut