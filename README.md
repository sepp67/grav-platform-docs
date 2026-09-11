# grav-platform-docs

Image applicative Grav qui documente l'architecture et le fonctionnement de
la plateforme de déploiement de Sébastien Lavallée : `grav-runtime`,
`ansible-role-grav-site`, `grav-sites-ops`, `projet-lavallee-website` et
`projet-gites`.

Construite sur [`grav-runtime`](https://github.com/sepp67/grav-runtime), avec
le thème [Learn2](https://github.com/getgrav/grav-theme-learn2) comme thème
parent. Ne réimplémente jamais PHP, Nginx, Grav Core/Admin, l'entrypoint, le
healthcheck ou le bootstrap admin.

Ce dépôt ne modifie aucun des cinq dépôts qu'il documente et n'est pas
déployé par ce lot (voir `docs/architecture.md`).

## Développement local

Prérequis : Docker et Docker Compose.

```sh
docker compose -f compose.dev.yml up -d --build
```

Le site est accessible sur <http://localhost:8080/>. Identifiants admin de
test (`compose.dev.yml`) : `admin` / `ChangeMe123` — jetables, jamais à
réutiliser ailleurs qu'en local.

Arrêt et suppression des volumes de test :

```sh
docker compose -f compose.dev.yml down -v
```

## Tests

```sh
sh tests/run-all.sh
```

Détail de ce que couvre chaque script : voir [`docs/testing.md`](docs/testing.md).

## Documentation de ce dépôt

- [`docs/architecture.md`](docs/architecture.md) — comment ce dépôt est
  construit (intégration de Learn2, thème enfant, header).
- [`docs/contact-form.md`](docs/contact-form.md) — mécanisme du formulaire
  de contact et audit de compatibilité avant réutilisation.
- [`docs/testing.md`](docs/testing.md) — détail des tests.
- [`docs/documentation-sources.yml`](docs/documentation-sources.yml) —
  manifeste des sources documentées (URL, référence, commit, périmètre
  audité pour chacun des cinq dépôts, et pour le thème Learn2).

## État du contenu éditorial

Les pages de documentation des cinq dépôts et de la rubrique « Architecture
globale » sont à ce stade des placeholders explicites (« Documentation à
rédiger depuis le commit `<SHA>` »), rédigés lot par lot à partir du code
réel — voir le cahier de construction.
