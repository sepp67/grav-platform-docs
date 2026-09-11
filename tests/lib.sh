#!/bin/sh
# Fonctions partagées par les scripts de tests/. Chaque script source ce
# fichier puis échoue explicitement (exit != 0) au premier écart constaté.

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${GRAV_PLATFORM_DOCS_TEST_IMAGE:-grav-platform-docs:test}"

log() {
  echo "[test] $1"
}

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

wait_healthy() {
  container="$1"
  retries="${2:-30}"
  i=0
  while [ "$i" -lt "$retries" ]; do
    status="$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "missing")"
    if [ "$status" = "healthy" ]; then
      return 0
    fi
    if [ "$status" = "unhealthy" ]; then
      fail "conteneur $container passé 'unhealthy' au lieu de 'healthy'"
    fi
    i=$((i + 1))
    sleep 2
  done
  fail "conteneur $container non 'healthy' après ${retries} tentatives (dernier statut: $status)"
}

http_status() {
  curl -s -o /dev/null -w '%{http_code}' "$1"
}

http_body() {
  curl -s "$1"
}
