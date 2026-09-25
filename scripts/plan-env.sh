#!/usr/bin/env bash
# Initialize and plan the environment locally.
# Defaults to "dev" (the only env in this learning repo).
# Usage: ./scripts/plan-env.sh          # plans dev
#        ./scripts/plan-env.sh dev      # same
# Later: pass another folder name once you add environments/<name>/
set -euo pipefail

ENV="${1:-dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/environments/$ENV"

if [ ! -d "$DIR" ]; then
  echo "Environment folder not found: $DIR"
  echo "This repo currently has: environments/dev"
  exit 1
fi

cd "$DIR"
terraform init -input=false -backend-config=backend.hcl
terraform plan -input=false -var-file=terraform.tfvars -out=tfplan
