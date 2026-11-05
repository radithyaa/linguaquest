#!/usr/bin/env bash
# Menjalankan API LanguQuest dengan konfigurasi lingkungan pengembangan lokal.
# Pemakaian: ./scripts/run_api.sh            (foreground)
#            ./scripts/run_api.sh --bg       (background, log ke /tmp/lq_api.log)
set -euo pipefail

cd "$(dirname "$0")/.."

export DATABASE_URL="${DATABASE_URL:-postgres://linguaquest:linguaquest@127.0.0.1:5433/linguaquest}"
export REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6380}"
export JWT_SECRET="${JWT_SECRET:-dev-secret-linguaquest}"
export PORT="${PORT:-8090}"
export HOST="${HOST:-0.0.0.0}"
export LQ_DEMO_DATA="${LQ_DEMO_DATA:-1}"
export RUST_LOG="${RUST_LOG:-lq_api=info,lq_db=info}"
# Hindari bloat artefak build saat ruang disk terbatas.
export CARGO_PROFILE_DEV_DEBUG="${CARGO_PROFILE_DEV_DEBUG:-0}"

cargo build -p lq_api

if [ "${1:-}" = "--bg" ]; then
  pkill -f 'target/(debug|release)/lq_api' 2>/dev/null || true
  sleep 1
  nohup ./target/debug/lq_api > /tmp/lq_api.log 2>&1 &
  echo "API berjalan di latar belakang (log: /tmp/lq_api.log)"
  sleep 3
  curl -s "http://127.0.0.1:${PORT}/v1/health" && echo
else
  exec ./target/debug/lq_api
fi
