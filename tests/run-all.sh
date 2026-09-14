#!/bin/sh
# Orchestrateur : exécute les scripts de tests/ dans l'ordre, s'arrête au
# premier échec.
set -eu
cd "$(dirname "$0")"

for script in test-build.sh test-syntax.sh test-startup.sh test-app-presence.sh test-internal-links.sh test-contact-form.sh test-secrets.sh; do
  echo "=== $script ==="
  sh "$script"
done

echo "=== tous les tests ont réussi ==="
