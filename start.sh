#!/usr/bin/env bash
# Starts Postgres (docker compose), the API server, and one frontend app of your choice.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

API_PID=""

cleanup() {
  if [ -n "$API_PID" ] && kill -0 "$API_PID" 2>/dev/null; then
    echo ""
    echo "Stopping API server..."
    kill "$API_PID" 2>/dev/null
    wait "$API_PID" 2>/dev/null
  fi
}
trap cleanup EXIT INT TERM

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' is required but not found on PATH." >&2
    exit 1
  fi
}

ensure_env() {
  local dir="$1"
  if [ ! -f "$dir/.env" ] && [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
    echo "Created $dir/.env from .env.example"
  fi
}

require docker
require bun

ensure_env api
ensure_env database

echo "Starting Postgres (docker compose)..."
docker compose up -d

echo "Waiting for Postgres to be healthy..."
POSTGRES_CID="$(docker compose ps -q postgres)"
until [ "$(docker inspect -f '{{.State.Health.Status}}' "$POSTGRES_CID" 2>/dev/null)" = "healthy" ]; do
  sleep 1
done
echo "Postgres is ready."

echo "Installing root workspace dependencies (api, database)..."
bun install

echo "Applying database schema..."
(cd database && bun run push)

echo "Starting API server..."
(cd api && bun run dev) &
API_PID=$!
sleep 1

echo ""
echo "Select a frontend app to run:"
echo "  1) management  (SvelteKit web, role: management)"
echo "  2) vendor      (SvelteKit web, role: vendor)"
echo "  3) customer_app (Flutter, role: customer)"
echo "  4) vendor_app   (Flutter, role: vendor)"
read -rp "Enter choice [1-4]: " CHOICE

run_svelte_app() {
  local dir="$1"
  ensure_env "$dir"
  echo "Installing $dir dependencies..."
  (cd "$dir" && bun install)
  (cd "$dir" && bun run dev)
}

run_flutter_app() {
  local dir="$1"
  require flutter
  (cd "$dir" && flutter run)
}

case "$CHOICE" in
  1) run_svelte_app management ;;
  2) run_svelte_app vendor ;;
  3) run_flutter_app customer_app ;;
  4) run_flutter_app vendor_app ;;
  *)
    echo "Invalid choice: $CHOICE" >&2
    exit 1
    ;;
esac
