#!/bin/sh
# Lot 10 — mise à jour d'image A→B puis rollback B→A : dans les deux sens,
# les 4 répertoires persistants (pages, accounts, data, images) ne sont
# jamais perdus, et le code servi correspond bien à l'image active à chaque
# étape. Aucun test de ce contrat n'existait jusqu'ici pour ce dépôt — les
# cinq autres dépôts de la plateforme le testent déjà chacun pour leur
# propre image (voir grav-runtime, ansible-role-grav-site, projet-gites).
#
# B est construite depuis une copie temporaire du dépôt (un marqueur ajouté
# au CSS du thème enfant) : ce script ne modifie jamais les fichiers réels
# du dépôt. Ce n'est pas un déploiement Ansible réel — seul le contrat
# propre de grav-platform-docs (image + 4 volumes) est exercé ici.
. "$(dirname "$0")/lib.sh"

cd "$REPO_ROOT"
COMPOSE="docker compose -f tests/compose.test.yml -p grav-platform-docs-test-update"
CONTAINER="grav-platform-docs-test-stack"
IMAGE_A="$IMAGE"
IMAGE_B="grav-platform-docs:test-update-b"
TMP_BUILD_DIR="$(mktemp -d)"

cleanup() {
  $COMPOSE down -v >/dev/null 2>&1 || true
  docker rmi "$IMAGE_B" >/dev/null 2>&1 || true
  rm -rf "$TMP_BUILD_DIR"
}
trap cleanup EXIT

log "construction de l'image B (version simulée) depuis une copie temporaire"
cp -a "$REPO_ROOT/." "$TMP_BUILD_DIR/"
echo "/* test-update-rollback marker */" >> "$TMP_BUILD_DIR/grav/user/themes/platform-docs-theme/css/custom.css"
docker build -t "$IMAGE_B" "$TMP_BUILD_DIR" -q >/dev/null || fail "construction de l'image B a échoué"

$COMPOSE down -v >/dev/null 2>&1 || true

log "démarrage avec l'image A ($IMAGE_A)"
GRAV_PLATFORM_DOCS_TEST_IMAGE="$IMAGE_A" $COMPOSE up -d >/dev/null
wait_healthy "$CONTAINER" 30

log "relevé de l'état des 4 répertoires persistants (premier démarrage)"
for dir in pages accounts data images; do
  docker exec "$CONTAINER" test -d "/var/www/html/user/$dir" \
    || fail "répertoire persistant user/$dir absent après le premier démarrage"
done

log "écriture de marqueurs de persistance (fixtures synthétiques, jamais dans le dépôt)"
docker exec "$CONTAINER" sh -c "echo update-marker-pages >> /var/www/html/user/pages/00.accueil/default.md"
docker exec "$CONTAINER" sh -c "echo update-marker-accounts > /var/www/html/user/accounts/.marker"
docker exec "$CONTAINER" sh -c "echo update-marker-data > /var/www/html/user/data/.marker"
docker exec "$CONTAINER" sh -c "echo update-marker-images > /var/www/html/user/images/.marker"

log "mise à jour vers l'image B (mêmes volumes)"
GRAV_PLATFORM_DOCS_TEST_IMAGE="$IMAGE_B" $COMPOSE up -d >/dev/null
wait_healthy "$CONTAINER" 30

for marker in "pages:update-marker-pages:/var/www/html/user/pages/00.accueil/default.md" \
              "accounts:update-marker-accounts:/var/www/html/user/accounts/.marker" \
              "data:update-marker-data:/var/www/html/user/data/.marker" \
              "images:update-marker-images:/var/www/html/user/images/.marker"; do
  dir="${marker%%:*}"; rest="${marker#*:}"; needle="${rest%%:*}"; path="${rest#*:}"
  docker exec "$CONTAINER" grep -q "$needle" "$path" \
    || fail "mise à jour A→B : données $dir perdues"
done

status="$(http_status "http://localhost:18085/")"
[ "$status" = "200" ] || fail "mise à jour A→B : page d'accueil attendue 200, obtenue $status"

new_css="$(curl -s "http://localhost:18085/user/themes/platform-docs-theme/css/custom.css")"
echo "$new_css" | grep -q "test-update-rollback marker" \
  || fail "mise à jour A→B : le nouveau code (CSS) n'est pas actif"

contact_status="$(http_status "http://localhost:18085/contact")"
[ "$contact_status" = "200" ] || fail "mise à jour A→B : /contact attendu 200, obtenu $contact_status"
log "mise à jour A→B : 4 volumes intacts, nouveau code actif, site et formulaire toujours accessibles"

log "rollback vers l'image A (mêmes volumes)"
GRAV_PLATFORM_DOCS_TEST_IMAGE="$IMAGE_A" $COMPOSE up -d >/dev/null
wait_healthy "$CONTAINER" 30

for marker in "pages:update-marker-pages:/var/www/html/user/pages/00.accueil/default.md" \
              "accounts:update-marker-accounts:/var/www/html/user/accounts/.marker" \
              "data:update-marker-data:/var/www/html/user/data/.marker" \
              "images:update-marker-images:/var/www/html/user/images/.marker"; do
  dir="${marker%%:*}"; rest="${marker#*:}"; needle="${rest%%:*}"; path="${rest#*:}"
  docker exec "$CONTAINER" grep -q "$needle" "$path" \
    || fail "rollback B→A : données $dir perdues"
done

rollback_css="$(curl -s "http://localhost:18085/user/themes/platform-docs-theme/css/custom.css")"
echo "$rollback_css" | grep -q "test-update-rollback marker" \
  && fail "rollback B→A : le marqueur de l'image B est encore actif — ancien code non réactivé"

status="$(http_status "http://localhost:18085/")"
[ "$status" = "200" ] || fail "rollback B→A : page d'accueil attendue 200, obtenue $status"
contact_status="$(http_status "http://localhost:18085/contact")"
[ "$contact_status" = "200" ] || fail "rollback B→A : /contact attendu 200, obtenu $contact_status"

log "rollback B→A : 4 volumes intacts, ancien code réactivé, site et formulaire toujours accessibles"
log "aucun secret versionné constaté dans ce scénario (mêmes garanties que test-secrets.sh, non rejoué ici)"
log "mise à jour et rollback validés sans perte de données"
