# syntax=docker/dockerfile:1
#
# Image applicative "grav-platform-docs", construite sur le runtime générique
# grav-runtime. Ne réimplémente jamais PHP, Nginx, Grav Core/Admin,
# l'entrypoint, le healthcheck ou le bootstrap admin : tout cela appartient
# exclusivement à grav-runtime.
#
# Version épinglée explicitement — jamais "latest". Le tag OCI publié par le
# workflow de grav-runtime (docker/metadata-action) omet le préfixe "v" du
# tag Git source ; la référence source réelle est le tag Git v1.0.4, commit
# e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4 (voir docs/documentation-sources.yml).
FROM ghcr.io/sepp67/grav-runtime:1.0.4

# --- Thème parent Learn2 : archive figée sur le commit du tag Git 1.8.3 ---
#
# Pas de submodule Git, pas d'installation GPM/Admin : un téléchargement
# épinglé sur un commit précis (pas une branche ni un tag "latest" mouvant),
# vérifié par SHA-256 avant extraction, échoue le build sur toute divergence.
# SHA-256 recalculé localement sur cette archive exacte (voir
# docs/documentation-sources.yml).
ARG LEARN2_COMMIT=22b7f1e2d4a024b105399f912124fc901f807d7a
ARG LEARN2_URL=https://github.com/getgrav/grav-theme-learn2/archive/${LEARN2_COMMIT}.tar.gz
ARG LEARN2_SHA256=e3cb9bf571ed5504675bb26dc1b3308542bd9c8e77fb2e6432c04373afb21449

RUN set -eu; \
    curl -fsSL "$LEARN2_URL" -o /tmp/learn2.tar.gz; \
    echo "${LEARN2_SHA256}  /tmp/learn2.tar.gz" | sha256sum -c -; \
    mkdir -p /tmp/learn2-extracted /var/www/html/user/themes/learn2; \
    tar -xzf /tmp/learn2.tar.gz -C /tmp/learn2-extracted; \
    DIR="$(find /tmp/learn2-extracted -mindepth 1 -maxdepth 1 -type d -name 'grav-theme-learn2-*' | head -n 1)"; \
    if [ -z "$DIR" ]; then echo "Learn2 archive layout not recognized" >&2; exit 1; fi; \
    cp -a "$DIR"/. /var/www/html/user/themes/learn2/; \
    rm -rf /tmp/learn2-extracted /tmp/learn2.tar.gz; \
    chown -R www-data:www-data /var/www/html/user/themes/learn2

# Code applicatif immuable : thème enfant (hérite de Learn2 par chaînage de
# flux, voir grav/user/themes/platform-docs-theme/platform-docs-theme.yaml),
# plugin métier (contact) et configuration versionnée non secrète.
COPY --chown=www-data:www-data grav/user/themes/     /var/www/html/user/themes/
COPY --chown=www-data:www-data grav/user/plugins/    /var/www/html/user/plugins/
COPY --chown=www-data:www-data grav/user/config/     /var/www/html/user/config/

# Contenu initial : copié dans le volume persistant par le mécanisme de seed
# de grav-runtime (/opt/grav-seed/), uniquement si le volume est vide au
# premier démarrage — jamais écrasé ensuite.
COPY --chown=www-data:www-data grav/user/pages/ /opt/grav-seed/pages/
