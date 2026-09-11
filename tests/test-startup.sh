#!/bin/sh
# Démarrage, état "healthy", page d'accueil en HTTP 200.
. "$(dirname "$0")/lib.sh"

CONTAINER="grav-platform-docs-test-startup"
PORT="18081"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cleanup
log "démarrage d'un conteneur jetable (sans volumes) depuis $IMAGE"
# GRAV_ADMIN_* fournies : reproduit un déploiement réel. Sans ces variables,
# le plugin Admin de grav-runtime redirige lui-même "/" vers "/admin" tant
# qu'aucun compte n'existe — comportement natif de Grav Admin.
docker run -d --name "$CONTAINER" -p "$PORT:80" \
  -e GRAV_ADMIN_USER=admin \
  -e GRAV_ADMIN_PASSWORD=ChangeMe123 \
  -e GRAV_ADMIN_EMAIL=admin@example.com \
  "$IMAGE" >/dev/null

wait_healthy "$CONTAINER" 30
log "conteneur healthy"

status="$(http_status "http://localhost:$PORT/")"
[ "$status" = "200" ] || fail "page d'accueil (/) : attendu 200, obtenu $status"
log "page d'accueil (/) : HTTP $status"
