#!/bin/sh
# Explore chaque page publiée (déduites de grav/user/pages/) et vérifie que
# tout lien interne présent dans le contenu (pas la barre latérale générée
# par le thème) répond HTTP 200. Garde de non-régression : un lot antérieur
# a laissé passer 99 liens internes cassés (mauvaise profondeur de "../"
# dans un lien relatif Markdown) sans qu'aucun test existant ne le détecte —
# voir Lot 8 de la construction de ce site.
. "$(dirname "$0")/lib.sh"

CONTAINER="grav-platform-docs-test-links"
PORT="18084"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup

log "démarrage d'un conteneur jetable (sans volumes) depuis $IMAGE"
docker run -d --name "$CONTAINER" -p "$PORT:80" \
  -e GRAV_ADMIN_USER=admin \
  -e GRAV_ADMIN_PASSWORD=ChangeMe123 \
  -e GRAV_ADMIN_EMAIL=admin@example.com \
  "$IMAGE" >/dev/null
wait_healthy "$CONTAINER" 30

log "vérification de tous les liens internes de contenu (body-inner)"
python3 "$REPO_ROOT/tests/lib/check_internal_links.py" "http://localhost:$PORT" "$REPO_ROOT/grav/user/pages" \
  || fail "des liens internes cassés ont été détectés (voir le détail ci-dessus)"
log "tous les liens internes de contenu répondent HTTP 200"
