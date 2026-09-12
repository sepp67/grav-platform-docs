---
title: "Référence"
template: docs
taxonomy:
    category: [docs]
---

## Glossaire local

- **Seed** — contenu initial fourni par une image fille sous
  `/opt/grav-seed/`, copié une seule fois dans un répertoire persistant
  vide.
- **Bootstrap admin** — création optionnelle, au démarrage, du premier
  compte administrateur Grav.
- **Healthcheck technique** — `/healthz`, prouve que Nginx et PHP-FPM
  fonctionnent ensemble, sans jamais couvrir le rendu d'un site réel.
- **Image fille / image applicative** — image Docker qui déclare
  `FROM ghcr.io/sepp67/grav-runtime:<version>` et y ajoute du contenu
  métier.

## Index des fichiers structurants

| Fichier | Rôle |
|---|---|
| `Dockerfile` | construction de l'image — voir [Flux chronologique](../04.flux-chronologique) A |
| `docker/entrypoint.sh` | PID 1, supervision — voir Flux B |
| `docker/seed-init.sh` | copie non destructive d'un sous-répertoire seed |
| `docker/bootstrap-admin.sh` | création tri-state du compte admin |
| `docker/healthcheck.sh`, `docker/healthz.php` | healthcheck technique |
| `docker/nginx.conf`, `docker/php-fpm.conf` | configuration serveur |
| `docker/theme-overrides/quark2/` | surcharge ciblée d'un fichier du thème vendorisé |
| `.github/workflows/docker.yml` | build + publication GHCR sur tag |

## Index des commandes

Voir [Exploitation et diagnostic](../09.exploitation-et-diagnostic) pour la
table complète (build, démarrage, healthcheck, arrêt).

## Index des variables

Voir [Configuration et interfaces](../06.configuration-et-interfaces) pour
la table complète (ARGs de build, variables d'environnement).

## Documents normatifs

- `README.md` du dépôt (487 lignes au tag `v1.0.4`) — seul document
  normatif de ce dépôt ; pas de `docs/` séparé.

## Version et SHA documentés

```yaml
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Tags OCI publiés (observés en direct sur GHCR) : 1.0.4, 1.0, 1, latest — même digest
Image utilisée par grav-platform-docs : ghcr.io/sepp67/grav-runtime:1.0.4
PHP : 8.3 déclaré (ARG PHP_VERSION, Dockerfile) ; 8.3.33 observé lors du build local du 2026-09-12 — non garanti par le Dockerfile, voir Configuration et interfaces
Grav : 2.0.11 (Core + Admin), épinglé et vérifié par SHA-256
Architecture publiée : linux/amd64 uniquement
```

## Historique des mises à jour de cette rubrique

| Date | Lot | Changement |
|---|---|---|
| 2026-09-12 | Lot 3 | Rédaction initiale, à partir d'un worktree Git détaché sur le tag `v1.0.4` |

## Limites connues (reprises du README)

- `php:8.3-fpm-alpine` reste un tag mouvant jusqu'au patch et à la couche
  Alpine — pas pinné au digest exact.
- `getgrav.org` ne publie aucune somme de contrôle pour ses liens
  "latest" ; seule la release GitHub versionnée en fournit une, et c'est
  celle-là qui est vérifiée ici.
- `/healthz` ne couvre pas le rendu réel d'un site.
- Un seul conteneur pour Nginx et PHP-FPM — choix assumé, pas une
  limitation technique subie.

## Limites propres à cette rubrique (constatées pendant l'audit)

- `test/compose.yml`, référencé abondamment par le README, n'est pas
  versionné (gitignored) — absent du tag `v1.0.4` lui-même.
- Le commentaire du `Dockerfile` renvoie à
  `docker/theme-overrides/README.md`, qui n'existe pas dans ce tag.
- Les tests `3quater` à `3octies` et `7`-`8` du README n'ont pas été
  ré-exécutés dans ce Lot (voir [Tests et CI](../08.tests-et-ci)).
- Les logs détaillés du run GitHub Actions ayant publié `v1.0.4` ne sont
  plus accessibles (expirés) — seules les métadonnées du run (statut,
  durée, date) ont pu être observées.

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Dernière vérification : 2026-09-12
```
