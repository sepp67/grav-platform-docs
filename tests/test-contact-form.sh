#!/bin/sh
# Affichage du formulaire, validation des champs requis et du honeypot,
# soumission valide -> redirection vers /contact/confirmation, via un SMTP
# factice local (Mailpit). Aucun e-mail réel n'est envoyé.
. "$(dirname "$0")/lib.sh"

CONTAINER="grav-platform-docs-test-contact"
MAILPIT="grav-platform-docs-test-mailpit"
NETWORK="grav-platform-docs-test-net"
PORT="18083"
MAILPIT_API_PORT="18025"
COOKIEJAR="$(mktemp)"
BODY_FILE="$(mktemp)"
HEADERS_FILE="$(mktemp)"

cleanup() {
  docker rm -f "$CONTAINER" "$MAILPIT" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
  rm -f "$COOKIEJAR" "$BODY_FILE" "$HEADERS_FILE"
}
trap cleanup EXIT
cleanup

docker network create "$NETWORK" >/dev/null
log "réseau de test $NETWORK créé"

docker run -d --name "$MAILPIT" --network "$NETWORK" --network-alias mailpit \
  -p "$MAILPIT_API_PORT:8025" \
  axllent/mailpit >/dev/null
log "SMTP factice (Mailpit) démarré"

docker run -d --name "$CONTAINER" --network "$NETWORK" -p "$PORT:80" \
  -e GRAV_ADMIN_USER=admin \
  -e GRAV_ADMIN_PASSWORD=ChangeMe123 \
  -e GRAV_ADMIN_EMAIL=admin@example.com \
  -v "$REPO_ROOT/tests/fixtures/email-private.test.php:/var/www/html/user/config/email-private.php:ro" \
  "$IMAGE" >/dev/null

wait_healthy "$CONTAINER" 30
log "conteneur applicatif healthy, SMTP factice pointé via email-private.php monté"

# submit_form <nom> <email> <message> <honeypot> — construit la requête à
# partir des champs cachés réellement rendus (nonce Grav inclus), jamais
# supposés. Écrit le code HTTP et l'en-tête Location dans HEADERS_FILE.
submit_form() {
  field_nom="$1"; field_email="$2"; field_message="$3"; field_honeypot="$4"

  curl -s -c "$COOKIEJAR" -b "$COOKIEJAR" -o "$BODY_FILE" "http://localhost:$PORT/contact"

  set --
  while IFS='=' read -r hname hvalue; do
    [ -n "$hname" ] || continue
    set -- "$@" --data-urlencode "${hname}=${hvalue}"
  done <<EOF
$(grep -oE '<input[^>]*type="hidden"[^>]*>' "$BODY_FILE" | \
    sed -E 's/.*name="([^"]*)".*value="([^"]*)".*/\1=\2/')
EOF

  curl -s -D "$HEADERS_FILE" -o /dev/null -b "$COOKIEJAR" -c "$COOKIEJAR" \
    -X POST "http://localhost:$PORT/contact" \
    "$@" \
    --data-urlencode "data[nom]=${field_nom}" \
    --data-urlencode "data[email]=${field_email}" \
    --data-urlencode "data[telephone]=" \
    --data-urlencode "data[message]=${field_message}" \
    --data-urlencode "data[honeypot]=${field_honeypot}"
}

response_location() {
  grep -i '^location:' "$HEADERS_FILE" | tr -d '\r' | awk '{print $2}'
}

response_code() {
  head -n1 "$HEADERS_FILE" | awk '{print $2}'
}

# --- 0. Affichage du formulaire ----------------------------------------------

curl -s -c "$COOKIEJAR" -o "$BODY_FILE" "http://localhost:$PORT/contact"
grep -qi 'name="[^"]*\[nom\]"' "$BODY_FILE" || fail "champ nom absent du formulaire"
grep -qi 'name="[^"]*\[email\]"' "$BODY_FILE" || fail "champ email absent du formulaire"
grep -qi 'name="[^"]*\[message\]"' "$BODY_FILE" || fail "champ message absent du formulaire"
grep -qi 'name="[^"]*\[honeypot\]"' "$BODY_FILE" || fail "champ honeypot absent du formulaire"
log "formulaire /contact : les champs attendus sont présents"

# --- 1. Champ obligatoire manquant (message vide) ---------------------------

submit_form "Test Invalide" "invalide@example.invalid" "" ""
loc="$(response_location)"
[ -z "$loc" ] || fail "soumission avec 'message' vide : redirigée vers $loc (validation non appliquée)"
log "soumission avec 'message' vide : pas de redirection (HTTP $(response_code)) — validation appliquée"

# --- 2. Honeypot rempli -------------------------------------------------------

submit_form "Test Honeypot" "honeypot@example.invalid" "Ceci est un test." "rempli-par-un-bot"
loc="$(response_location)"
[ -z "$loc" ] || fail "soumission avec honeypot rempli : redirigée vers $loc (rejet non appliqué)"
log "soumission avec honeypot rempli : rejetée (pas de redirection)"

# --- 3. Soumission valide -----------------------------------------------------

submit_form "Test Valide" "valide@example.invalid" "Ceci est un message de test envoyé via le SMTP factice." ""
loc="$(response_location)"
code="$(response_code)"
case "$loc" in
  */contact/confirmation) log "soumission valide : redirigée vers $loc (HTTP $code)" ;;
  *) fail "soumission valide : attendu une redirection vers /contact/confirmation, obtenu Location='$loc' (HTTP $code)" ;;
esac

log "vérification côté SMTP factice (Mailpit) — aucun e-mail réel envoyé"
sleep 1
mailpit_count="$(curl -s "http://localhost:$MAILPIT_API_PORT/api/v1/messages" | grep -o '"total":[0-9]*' | head -1 | cut -d: -f2)"
[ -n "$mailpit_count" ] && [ "$mailpit_count" -ge 1 ] \
  || fail "Mailpit n'a reçu aucun message pour la soumission valide"
log "Mailpit a bien reçu $mailpit_count message(s)"
