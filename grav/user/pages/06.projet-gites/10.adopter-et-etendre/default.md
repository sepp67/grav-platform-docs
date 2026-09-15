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
Identifiants jetables (`admin` / `ChangeMe123`), 4 volumes nommés séparés.

```bash
docker compose -f compose.dev.yml down -v
```

## Cycle de vie du contenu initial — ce que garantit le seed

`docs/seed-lifecycle.md` (lu intégralement) formalise une distinction
absente de `projet-lavallee-website` : le contenu de `grav/user/pages/`
dans ce dépôt n'est **ni du code ni une donnée persistante au sens
strict** — c'est un contenu éditorial initial, copié **une seule fois**
dans le volume `user/pages` au tout premier démarrage. Conséquence
opérationnelle explicite : « une correction dans `grav/user/pages` du
dépôt Git ne se propage qu'aux **nouvelles** instances. Un site déjà
déployé ne reçoit jamais cette correction automatiquement, quelle que
soit la version d'image installée ensuite. »

### Méthodes pour une migration de contenu volontaire (non implémentées)

Si une correction doit un jour être propagée à un site déjà déployé,
`docs/seed-lifecycle.md` liste quatre approches possibles, **aucune
automatique** : script de migration versionné exécuté via `docker exec`,
commande Grav dédiée pour un champ précis, tâche Ansible **hors du rôle
générique** (jamais dans `ansible-role-grav-site` lui-même), ou procédure
manuelle documentée (`docker cp` + sauvegarde préalable).

### Différence mise à jour du thème/plugin vs. mise à jour du contenu

Une mise à jour d'image change le **code** (thème, plugins, configuration)
immédiatement et pour tous les sites qui adoptent la nouvelle version —
vérifié en direct. Elle ne touche **jamais** le contenu déjà administré
dans `user/pages` (pages de gîtes déjà éditées, disponibilités déjà
saisies) : ces deux mises à jour suivent des mécanismes et des rythmes
totalement indépendants.

### Sauvegarde avant synchronisation ou migration

Aucune des méthodes de migration volontaire ci-dessus n'est présentée
comme sûre sans sauvegarde préalable du volume concerné — `docs/seed-lifecycle.md`
le formule comme une action manuelle et explicite de l'opérateur à chaque
fois, jamais une garantie automatique de ce dépôt ou du rôle Ansible. **Git
et le volume persistant ne sont jamais synchronisés automatiquement**,
dans aucun sens : une correction Git n'atteint pas un site déployé, et une
modification faite depuis `/admin` (ou via `/gerer`) n'est jamais reportée
dans Git.

## Certification de compatibilité avant mise à jour du runtime

`docs/compatibility-policy.md` impose : rejouer `tests/run-all.sh` **et**
vérifier un rendu réel (pas seulement build + healthy) avant d'adopter une
nouvelle version de `grav-runtime` dans le `Dockerfile`, puis mettre à
jour la matrice de compatibilité **avant** de taguer une nouvelle release.
**Dans le tag `v1.1.0`**, cette matrice enregistre une ligne `1.1.0`
certifiant `grav-runtime 1.0.4` — la version réellement construite par le
`Dockerfile`, et réellement exercée par `tests/run-all.sh` dans le même
chantier que la correction SEC-GITES-001. Au commit `b27d7af` (Lot 7),
cette procédure n'avait pas produit un état cohérent — voir
[Référence](../11.reference) pour la chronologie complète.

## Contrat de déploiement (documenté, aligné sur le rôle `v2.0.0`, vérifié statiquement seulement)

`docs/release-and-rollback.md` fournit un exemple complet de playbook
Ansible (`grav_image`, `grav_version`, `grav_container_name`,
`grav_bind_address`, `grav_http_port`, `grav_admin_*`, `grav_secrets`) —
désormais contre `ansible-role-grav-site:2.0.0`, aligné sur le tag déjà
audité au Lot 4, avec `grav_bind_address` ajouté explicitement (devenu
obligatoire depuis `v2.0.0`). Cet alignement a été **vérifié
statiquement** (lecture du code et du guide de migration du rôle) —
**aucun déploiement Ansible réel** n'a été exécuté pour le produire, ce
que la documentation du dépôt indique elle-même. Au commit `b27d7af`, cet
exemple citait encore `ansible-role-grav-site:1.0.1` ; une vérification
ciblée contre le tag `v1.0.1` réel avait alors confirmé que l'exemple
était compatible au moment de sa rédaction, et restait majoritairement
compatible avec `v2.0.0` — à l'exception, déjà identifiée, de
`grav_bind_address`. Comparaison complète et chronologie en
[Référence](../11.reference).

## Responsabilités exclues (rappel)

Ne fournit ni ne maintient PHP, Nginx ou Grav Core (relèvent de
`grav-runtime`) ; ne génère ni ne committe de Compose de production
(relève d'`ansible-role-grav-site`) ; ne gère ni le DNS, ni le TLS, ni le
reverse proxy ; ne gère pas les données persistantes de production après
l'initialisation ; n'implémente aucun système de réservation en ligne ni
de paiement.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b)
Fichiers principaux : docs/seed-lifecycle.md, docs/compatibility-policy.md, docs/release-and-rollback.md
Dernière vérification : 2026-09-15
```
