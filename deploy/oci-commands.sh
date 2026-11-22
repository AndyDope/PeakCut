# PeakCut Oracle Cloud Infrastructure - OCI CLI Commands
# Run these commands after configuring OCI CLI with your tenancy
# Your tenancy details (from .env):
# OCI_TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaay5w7nj6sodclqfduwusu7mczmdqqvuiaqtdzzehfww6xqw6j6naq
# OCI_COMPARTMENT_OCID=ocid1.tenancy.oc1..aaaaaaaay5w7nj6sodclqfduwusu7mczmdqqvuiaqtdzzehfww6xqw6j6naq
# OCI_REGION=ap-mumbai-1

# =============================================================================
# STEP 1: Discover required OCIDs (run once)
# =============================================================================

# Get Availability Domain
oci iam availability-domain list --region ap-mumbai-1
# Pick one AD name (e.g., "AD-1", "AD-2", "AD-3") -> set AD_NAME variable

# Get Ubuntu 24.04 ARM64 Image OCID for Ampere A1 Flex
oci compute image list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaay5w7nj6sodclqfduwusu7mczmdqqvuiaqtdzzehfww6xqw6j6naq \
  --region ap-mumbai-1 \
  --operating-system "Ubuntu" \
  --operating-system-version "24.04" \
  --shape "VM.Standard.A1.Flex" \
  --query "data[0].id" \
  --output text
# Save as UBUNTU_IMAGE_OCID

# Get Subnet OCID (public subnet in your VCN)
oci network subnet list \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaay5w7nj6sodclqfduwusu7mczmdqqvuiaqtdzzehfww6xqw6j6naq \
  --region ap-mumbai-1 \
  --query "data[?\"lifecycle-state\"=='AVAILABLE' && \"prohibit-public-ip-on-vnic\"==\`false\`].{id:id, name:\"display-name\"}" \
  --output table
# Pick a public subnet -> set SUBNET_OCID variable

# Get your SSH public key path
# Default: ~/.ssh/id_rsa.pub or use the one in oci_keys/id_ed25519.pub

# =============================================================================
# STEP 2: Create Ampere A1 Instance (4 OCPU, 24 GB RAM)
# =============================================================================

# Replace these variables with values from Step 1:
# AD_NAME="AD-1"                    # e.g., "AD-1"
# UBUNTU_IMAGE_OCID="ocid1.image..." # From Step 1
# SUBNET_OCID="ocid1.subnet..."     # From Step 1
# SSH_KEY_FILE="~/.ssh/id_rsa.pub"  # or /Users/anirudhdoiphode/Documents/dev/proj/Clippin/oci_keys/id_ed25519.pub

oci compute instance launch \
  --availability-domain ${AD_NAME} \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaay5w7nj6sodclqfduwusu7mczmdqqvuiaqtdzzehfww6xqw6j6naq \
  --shape VM.Standard.A1.Flex \
  --shape-config '{"ocpus": 4, "memory_in_gbs": 24}' \
  --image-id ${UBUNTU_IMAGE_OCID} \
  --subnet-id ${SUBNET_OCID} \
  --assign-public-ip true \
  --ssh-authorized-keys-file ${SSH_KEY_FILE} \
  --display-name peakcut-server \
  --region ap-mumbai-1

# Save the instance OCID from output -> INSTANCE_OCID

# =============================================================================
# STEP 3: Create and Attach 150 GB Block Volume
# =============================================================================

# Create volume
oci bv volume create \
  --availability-domain ${AD_NAME} \
  --compartment-id ocid1.tenancy.oc1..aaaaaaaay5w7nj6sodclqfduwusu7mczmdqqvuiaqtdzzehfww6xqw6j6naq \
  --size-in-gbs 150 \
  --display-name peakcut-data \
  --region ap-mumbai-1

# Save volume OCID from output -> VOLUME_OCID

# Attach to instance
oci compute volume-attachment attach \
  --instance-id ${INSTANCE_OCID} \
  --volume-id ${VOLUME_OCID} \
  --type paravirtualized \
  --region ap-mumbai-1

# =============================================================================
# STEP 4: Configure Security Lists (allow 80, 443, 22)
# =============================================================================

# Get the subnet's security list OCID
oci network subnet get --subnet-id ${SUBNET_OCID} --region ap-mumbai-1 --query "data.\"security-list-ids\"" --output text
# Save as SECURITY_LIST_OCID (may be multiple, pick the main one)

# Add ingress rules to security list
# Rule 1: HTTP (80)
oci network security-list update \
  --security-list-id ${SECURITY_LIST_OCID} \
  --ingress-security-rules '[{"protocol":"6","source":"0.0.0.0/0","tcp-options":{"destination-port-range":{"max":80,"min":80}},"description":"HTTP for Caddy"}]' \
  --force \
  --region ap-mumbai-1

# Rule 2: HTTPS (443)
oci network security-list update \
  --security-list-id ${SECURITY_LIST_OCID} \
  --ingress-security-rules '[{"protocol":"6","source":"0.0.0.0/0","tcp-options":{"destination-port-range":{"max":443,"min":443}},"description":"HTTPS for Caddy"}]' \
  --force \
  --region ap-mumbai-1

# Rule 3: SSH (22) - restrict to your IP
# Replace YOUR_IP with your actual public IP (e.g., 203.0.113.0/32)
oci network security-list update \
  --security-list-id ${SECURITY_LIST_OCID} \
  --ingress-security-rules '[{"protocol":"6","source":"YOUR_IP/32","tcp-options":{"destination-port-range":{"max":22,"min":22}},"description":"SSH restricted"}]' \
  --force \
  --region ap-mumbai-1

# =============================================================================
# STEP 5: On the Instance - Format and Mount Block Volume
# =============================================================================

# SSH into the instance:
# ssh ubuntu@<INSTANCE_PUBLIC_IP>

# Then run these commands ON THE INSTANCE:
# sudo mkfs.ext4 /dev/oracleoci/oraclevdb
# sudo mkdir -p /mnt/peakcut-data
# echo "/dev/oracleoci/oraclevdb /mnt/peakcut-data ext4 defaults 0 0" | sudo tee -a /etc/fstab
# sudo mount -a

# Verify mount:
# df -h /mnt/peakcut-data

# =============================================================================
# STEP 6: Deploy PeakCut (after SSH into instance)
# =============================================================================

# On the instance:
# curl -fsSL https://get.docker.com | sh
# sudo usermod -aG docker ubuntu
# newgrp docker
# sudo apt update && sudo apt install -y docker-compose-plugin

# cd /opt
# git clone https://github.com/AndyDope/PeakCut.git peakcut
# cd peakcut
# cp .env.example .env
# # Edit .env with your values (see deployment plan)
# mkdir -p secrets
# docker compose up -d --build

# # Make yourself admin
# docker compose exec app python -m studio.admin grant you@yourdomain.com

# =============================================================================
# REQUIRED GITHUB SECRETS (add to your fork: AndyDope/PeakCut)
# =============================================================================
# ORACLE_HOST        = <INSTANCE_PUBLIC_IP>
# ORACLE_SSH_KEY     = <PRIVATE_KEY_CONTENT> (contents of ~/.ssh/id_rsa or id_ed25519)
# GH_PAT             = <GITHUB_PERSONAL_ACCESS_TOKEN> with repo scope
# 
# The workflow will auto-deploy on every push to main and every 6 hours