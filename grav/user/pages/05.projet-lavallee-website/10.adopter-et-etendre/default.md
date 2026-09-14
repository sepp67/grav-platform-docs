---
title: "Adopter et étendre"
template: docs
taxonomy:
    category: [docs]
---

## Développement local

```bash
docker compose -f compose.dev.yml up -d --build
```

Site : `http://localhost:8080` — Admin : `http://localhost:8080/admin`.
Identifiants (`admin` / `ChangeMe123`) définis en clair dans
`compose.dev.yml`, explicitement documentés comme jetables et réservés au
développement (commentaire du fichier). Volumes nommés séparés pour
`pages`/`accounts`/`data`/`images` — jamais un bind-mount global de `user/`.

```bash
docker compose -f compose.dev.yml down -v
```

## Build et publication GHCR

Build local : `docker build -t <tag> .`. Publication réelle réservée au
workflow `release.yml`, déclenché uniquement par un tag `v[0-9]+.[0-9]+.[0-9]+`
ou un déclenchement manuel — jamais par un simple push. Voir [Flux
chronologique, chronologie E](04.flux-chronologique) pour le détail complet
des tags OCI produits.

## Contrat de déploiement (tel qu'il existe au commit audité)

Ce dépôt produit une image ; il ne déploie rien lui-même. Le contrat
attendu avec `ansible-role-grav-site` (variables `grav_*`, healthcheck,
montage des volumes) est celui déjà documenté pour `projet-gites` — non
encore vérifié pour `projet-lavallee-website` puisque `docs/architecture.md`
déclare ce branchement **pas encore effectif**. Toute affirmation sur ce
contrat spécifique à ce dépôt serait une extrapolation, pas une preuve —
volontairement absente de cette page.

## Responsabilités exclues (rappel)

Ne fournit ni ne maintient PHP, Nginx ou Grav Core (relèvent de
`grav-runtime`) ; ne génère ni ne committe de Compose de production
(relèvera d'`ansible-role-grav-site`) ; ne gère ni le DNS, ni le TLS, ni le
reverse proxy (infrastructure externe) ; ne gère pas les données
persistantes de production après l'initialisation.

## Étendre ce dépôt (constat, pas une recommandation)

Ajouter une page suit le même schéma observé pour les pages existantes :
un dossier `NN.slug/` avec trois fichiers `default.md`/`default.en.md`/
`default.de.md`, un `template:` valide (`page-simple`, `article`, ou un
template dédié). Le seul écart de convention observé dans ce dépôt lui-même
(dossier d'article sans préfixe numérique) est documenté en [Structure du
dépôt](03.structure-du-depot) et [Référence](11.reference) — signalé, pas
corrigé (dépôt source non modifié par cette documentation).

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : compose.dev.yml, .github/workflows/release.yml, docs/architecture.md
Dernière vérification : 2026-09-14
```
