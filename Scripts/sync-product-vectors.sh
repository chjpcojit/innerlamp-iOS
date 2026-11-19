#!/usr/bin/env bash
# Copies the product's shared memorial vectors into the iOS test fixtures.
# Source of truth: innerlamp-be docs/product/memorial/rules (product spec v1.0, 2026-11-16).
# EN: Run from the repo root. Never hand-edit the copied files.
# VI: Chạy từ gốc repo. Không sửa tay các file đã chép.
set -euo pipefail

SOURCE_DIR="${1:-../innerlamp/docs/product/memorial/rules}"
DEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/InnerLampTests/Fixtures"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Vector source not found: $SOURCE_DIR" >&2
  echo "Usage: Scripts/sync-product-vectors.sh [path-to-innerlamp/docs/product/memorial/rules]" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
for name in death-date-conversion next-anniversary anniversary-ordinal; do
  cp "$SOURCE_DIR/$name.json" "$DEST_DIR/$name.json"
  echo "copied $name.json"
done
