#!/bin/sh
# Thème actif, navigation complète, liens du header, page de confirmation
# absente du menu, et non-écrasement du seed sur un redémarrage.
. "$(dirname "$0")/lib.sh"

CONTAINER="grav-platform-docs-test-presence"
PORT="18082"
VOL_PREFIX="grav-platform-docs-test-presence"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  for v in pages accounts data images; do
    docker volume rm "${VOL_PREFIX}_${v}" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT
cleanup

for v in pages accounts data images; do
  docker volume create "${VOL_PREFIX}_${v}" >/dev/null
done

log "démarrage d'un conteneur avec volumes nommés (première initialisation)"
docker run -d --name "$CONTAINER" -p "$PORT:80" \
  -e GRAV_ADMIN_USER=admin \
  -e GRAV_ADMIN_PASSWORD=ChangeMe123 \
  -e GRAV_ADMIN_EMAIL=admin@example.com \
  -v "${VOL_PREFIX}_pages:/var/www/html/user/pages" \
  -v "${VOL_PREFIX}_accounts:/var/www/html/user/accounts" \
  -v "${VOL_PREFIX}_data:/var/www/html/user/data" \
  -v "${VOL_PREFIX}_images:/var/www/html/user/images" \
  "$IMAGE" >/dev/null

wait_healthy "$CONTAINER" 30

home_body="$(http_body "http://localhost:$PORT/")"

echo "$home_body" | grep -qi "Documentation de la plateforme Grav" \
  || fail "page d'accueil : contenu attendu absent"
log "page d'accueil : contenu réel présent"

for section in "Architecture globale" "grav-runtime" "ansible-role-grav-site" "grav-sites-ops" "projet-lavallee-website" "projet-gites" "Glossaire commun"; do
  echo "$home_body" | grep -qi "$section" \
    || fail "navigation : rubrique '$section' absente de la page rendue"
done
log "navigation : les huit rubriques de premier niveau visibles sont présentes"

# Contact reste une page fonctionnelle (voir plus bas), mais volontairement
# masquée du sommaire (visible: false) depuis le Lot 8 — Glossaire commun
# occupe la dernière position visible à sa place.
echo "$home_body" | grep -qi ">Contact<" \
  && fail "Contact apparaît dans le menu (visible: false attendu depuis le Lot 8)"
log "Contact absent du menu (page fonctionnelle cachée du sommaire)"

# Vérification stricte par lien : href absolu exact, target="_blank" et
# rel="noopener noreferrer" sur la même balise <a> (pas une simple présence
# de sous-chaîne ailleurs dans la page).

lavallee_link="$(echo "$home_body" | grep -F '>lavallee.tech<')"
[ -n "$lavallee_link" ] || fail "lien lavallee.tech absent du header"
echo "$lavallee_link" | grep -qF 'href="https://lavallee.tech/en"' \
  || fail "lien lavallee.tech : href exact incorrect (attendu https://lavallee.tech/en), obtenu: $lavallee_link"
echo "$lavallee_link" | grep -qF 'target="_blank"' \
  || fail "lien lavallee.tech : target=\"_blank\" absent"
echo "$lavallee_link" | grep -qF 'rel="noopener noreferrer"' \
  || fail "lien lavallee.tech : rel=\"noopener noreferrer\" absent"
log "lien lavallee.tech : href=https://lavallee.tech/en, target=_blank, rel=noopener noreferrer"

github_link="$(echo "$home_body" | grep -F '>GitHub<')"
[ -n "$github_link" ] || fail "lien GitHub absent du header"
echo "$github_link" | grep -qF 'href="https://github.com/sepp67"' \
  || fail "lien GitHub : href exact incorrect (attendu https://github.com/sepp67), obtenu: $github_link"
echo "$github_link" | grep -qF 'target="_blank"' \
  || fail "lien GitHub : target=\"_blank\" absent"
echo "$github_link" | grep -qF 'rel="noopener noreferrer"' \
  || fail "lien GitHub : rel=\"noopener noreferrer\" absent"
log "lien GitHub : href=https://github.com/sepp67, target=_blank, rel=noopener noreferrer"

contact_body="$(http_body "http://localhost:$PORT/contact")"
echo "$contact_body" | grep -qi 'name="data\[nom\]"' || fail "champ nom absent du formulaire"
echo "$contact_body" | grep -qi 'name="data\[email\]"' || fail "champ email absent du formulaire"
log "page /contact : formulaire présent"

echo "$home_body" | grep -qi ">Confirmation<" \
  && fail "la page de confirmation apparaît dans le menu (visible: false attendu)"
log "page de confirmation absente du menu"

pages_count_before="$(docker exec "$CONTAINER" find /var/www/html/user/pages -type f | wc -l)"

log "redémarrage du même conteneur (mêmes volumes) — vérification du non-écrasement du seed"
docker restart "$CONTAINER" >/dev/null
wait_healthy "$CONTAINER" 30

pages_count_after="$(docker exec "$CONTAINER" find /var/www/html/user/pages -type f | wc -l)"
[ "$pages_count_before" = "$pages_count_after" ] \
  || fail "nombre de fichiers dans user/pages changé après redémarrage ($pages_count_before -> $pages_count_after) : le seed a été rejoué"
log "user/pages inchangé après redémarrage ($pages_count_after fichiers) : seed non rejoué"

status="$(http_status "http://localhost:$PORT/")"
[ "$status" = "200" ] || fail "page d'accueil après redémarrage : attendu 200, obtenu $status"
log "page d'accueil après redémarrage : HTTP $status"
