#!/bin/bash
set -e

cd /opt/peakcut

# Pull latest from YOUR fork (not upstream directly)
git fetch origin
git reset --hard origin/main

# Rebuild and restart (preserves data volumes)
docker compose up -d --build

# Clean up old images
docker image prune -f

echo "Update complete: $(date)"