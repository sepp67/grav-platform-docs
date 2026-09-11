#!/bin/sh
# Aucun secret réel ni fichier de secret dans l'image construite.
. "$(dirname "$0")/lib.sh"

CONTAINER="grav-platform-docs-test-secrets-inspect"
EXPORT_FILE="$(mktemp)"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  rm -f "$EXPORT_FILE"
}
trap cleanup EXIT
cleanup

log "inspection du système de fichiers de l'image (conteneur non démarré)"
docker create --name "$CONTAINER" "$IMAGE" >/dev/null

docker export "$CONTAINER" -o "$EXPORT_FILE"

if tar -tf "$EXPORT_FILE" 2>/dev/null | grep -q 'user/config/email-private\.php$'; then
  fail "user/config/email-private.php présent dans l'image construite"
fi
log "user/config/email-private.php absent de l'image"

# Recherche limitée aux chemins que ce dépôt copie réellement dans l'image
# (thème enfant, plugin contact, configuration, pages seed) et au thème
# Learn2 téléchargé. Une recherche sur l'image entière donne des faux
# positifs : grav-runtime embarque des plugins/vendors tiers (api, email,
# login...) dont la documentation d'exemple contient déjà des adresses
# génériques comme "admin@example.com" ou des identifiants d'exemple, sans
# rapport avec un secret introduit par ce dépôt.
OUR_PATHS="var/www/html/user/themes/platform-docs-theme var/www/html/user/plugins/contact var/www/html/user/config var/www/html/user/pages"

if tar -xOf "$EXPORT_FILE" $OUR_PATHS 2>/dev/null | grep -aqE 'ChangeMe123|admin@example\.com|contact@lavallee\.tech'; then
  fail "une valeur de test/placeholder connue a été trouvée dans les chemins propres à ce dépôt"
fi
log "aucune valeur de test/placeholder connue trouvée dans les chemins propres à ce dépôt (thème enfant, plugin contact, config, pages)"
