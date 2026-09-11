#!/bin/sh
# Validations syntaxiques statiques : PHP (php -l), shell (sh -n), YAML
# (parsing réel), et whitespace du diff Git (git diff --check).
#
# markdownlint : non exécuté — aucun outil (markdownlint, markdownlint-cli2,
# npx/node/npm) n'est disponible sur cette machine sans installation
# durable (npm install -g ou équivalent), ce qui n'a pas été fait. Aucune
# affirmation de conformité Markdown n'est faite par ce script.
#
# Twig : non validé par un outil statique dédié — aucun linter Twig
# autonome (twig-lint, twigcs) n'est disponible, et Composer n'est pas
# installé sur cette machine. Les quatre templates du thème enfant sont en
# revanche RÉELLEMENT rendus par le moteur Twig de Grav pendant
# test-startup.sh / test-app-presence.sh / test-contact-form.sh (exécution
# réelle, pas une recherche textuelle) : toute erreur de syntaxe Twig y
# provoquerait une page d'erreur PHP / un code HTTP différent de celui attendu.
. "$(dirname "$0")/lib.sh"

FAILED=0

# --- PHP : php -l -------------------------------------------------------------
# php n'est pas installé sur l'hôte ; utilisé depuis l'image applicative
# elle-même (PHP 8.3, /usr/local/bin/php), qui doit déjà avoir été
# construite par test-build.sh.

log "php -l sur les fichiers PHP propres au projet"
php_files="$(find "$REPO_ROOT/grav" -name '*.php' -not -path '*/vendor/*')"
if [ -z "$php_files" ]; then
  fail "aucun fichier PHP trouvé sous grav/ — vérification suspecte"
fi
for f in $php_files; do
  rel="${f#"$REPO_ROOT"/}"
  out="$(docker run --rm --entrypoint php -v "$REPO_ROOT:/src:ro" "$IMAGE" -l "/src/$rel" 2>&1)"
  if ! echo "$out" | grep -q "No syntax errors detected"; then
    echo "$out" >&2
    log "[FAIL] php -l : $rel"
    FAILED=1
  else
    log "php -l OK : $rel"
  fi
done

# --- Shell : sh -n -------------------------------------------------------------

log "sh -n sur les scripts shell du projet"
for f in "$REPO_ROOT"/tests/*.sh; do
  rel="${f#"$REPO_ROOT"/}"
  if ! sh -n "$f" 2>&1; then
    log "[FAIL] sh -n : $rel"
    FAILED=1
  else
    log "sh -n OK : $rel"
  fi
done

# --- YAML : parsing réel --------------------------------------------------------

log "parsing réel des fichiers YAML (python3 + PyYAML)"
yaml_files="$(find "$REPO_ROOT" \( -name '*.yaml' -o -name '*.yml' \) -not -path "$REPO_ROOT/.git/*" -not -path "$REPO_ROOT/doc/*")"
for f in $yaml_files; do
  rel="${f#"$REPO_ROOT"/}"
  if ! python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]))" "$f" 2>&1; then
    log "[FAIL] parsing YAML : $rel"
    FAILED=1
  else
    log "parsing YAML OK : $rel"
  fi
done

if command -v yamllint >/dev/null 2>&1; then
  log "yamllint (informatif, disponible sur cette machine — non bloquant sur le style)"
  for f in $yaml_files; do
    rel="${f#"$REPO_ROOT"/}"
    yamllint -d relaxed "$f" || log "yamllint : avertissements sur $rel (voir ci-dessus, non bloquant)"
  done
else
  log "yamllint non disponible — étape informative ignorée"
fi

# --- git diff --check -----------------------------------------------------------

log "git diff --check (erreurs d'espace dans le diff)"
cd "$REPO_ROOT"
if ! git diff --check; then
  log "[FAIL] git diff --check a signalé des erreurs d'espace"
  FAILED=1
else
  log "git diff --check OK"
fi

if [ "$FAILED" -ne 0 ]; then
  fail "au moins une validation syntaxique a échoué (voir ci-dessus)"
fi

log "toutes les validations syntaxiques disponibles ont réussi"
