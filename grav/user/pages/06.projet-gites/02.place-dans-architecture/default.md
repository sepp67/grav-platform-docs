---
title: "Place dans l'architecture"
template: docs
taxonomy:
    category: [docs]
---

## En amont

Une seule dépendance, de construction : l'image `grav-runtime`, épinglée
par tag explicite dans le `Dockerfile` — jamais `latest`. Le `Dockerfile`
référence `grav-runtime:1.0.4` ; `docs/compatibility-policy.md` du tag
`v1.1.0` certifie désormais cette même version `1.0.4`, sur la base de la
suite de tests de ce dépôt réellement exécutée contre elle. **Écart
historique résolu** : au commit `b27d7af` (Lot 7), cette même politique
citait encore `grav-runtime:1.0.2` — détail conservé pour mémoire en
[Référence](../11.reference).

## En aval

`ansible-role-grav-site`. La documentation interne de ce dépôt (sept
fichiers `docs/*.md`, tous lus intégralement) le cite désormais comme
`ansible-role-grav-site:2.0.0` dans le tag `v1.1.0` — aligné sur le tag
`v2.0.0` déjà audité au [Lot 4](../../03.ansible-role-grav-site).
Contrairement à `projet-lavallee-website`, dont `docs/architecture.md`
déclarait ce branchement « pas encore effectif », `projet-gites`
documente un exemple de déploiement Ansible complet et déjà rédigé
(`docs/release-and-rollback.md`), incluant désormais `grav_bind_address`
(devenu obligatoire depuis `v2.0.0`). Cette mise à jour a été **vérifiée
statiquement** (lecture du code et du guide de migration du rôle) —
**aucun déploiement Ansible réel** n'a été exécuté pour la produire, ce
que la documentation du tag `v1.1.0` indique elle-même explicitement.
**Écart historique résolu** : au commit `b27d7af`, ce même exemple citait
encore `ansible-role-grav-site:1.0.1` — le tag `v1.0.1` avait alors été
vérifié directement (worktree détaché, comparaison ciblée) : l'exemple
était bien compatible avec ce tag au moment de sa rédaction, et restait
majoritairement compatible avec `v2.0.0`, à une exception près
(`grav_bind_address`) — détail conservé pour mémoire en
[Référence](../11.reference).

## Chaîne de dépendance complète

```text
grav-runtime  →  projet-gites (ce dépôt)  →  ansible-role-grav-site  →  instance persistante
```

## Héritage de thème : chaînage `quark2`, contrairement à `lavallee-theme`

`gites-theme.yaml` déclare :

```yaml
streams:
  schemes:
    theme:
      type: ReadOnlyStream
      paths:
        - user://themes/gites-theme
        - user://themes/quark2
```

Le commentaire du fichier précise l'historique : une première tentative
utilisait la clé `extends@` au niveau du thème, abandonnée après un échec
constaté, remplacée par ce chaînage de flux (« mécanisme réellement
documenté dans le code source de Grav »). `gites-theme` ne définit
**aucun** `base.html.twig` propre — chaque template hérite du layout de
`quark2` via `{% extends 'partials/base.html.twig' %}`, résolu par le
chaînage de flux vers le thème parent. C'est l'inverse exact du choix fait
par `lavallee-theme` (entièrement autonome, voir [Lot
6](../../05.projet-lavallee-website/02.place-dans-architecture)).

## Ce que ce dépôt ne fait jamais (`docs/architecture.md`)

Reprendre PHP, Nginx, Grav Core, l'entrypoint, le healthcheck natif ou le
bootstrap admin (appartiennent à `grav-runtime`) ; générer ou committer un
Compose de production, ou dupliquer une tâche de déploiement (appartiennent
à `ansible-role-grav-site`) ; gérer un reverse proxy, TLS, DNS ou un
pare-feu (infrastructure externe).

## Frontières inter-dépôts

| Dépôt | Relation | Interdits |
|---|---|---|
| `grav-runtime` | image de base, épinglée par tag dans le `Dockerfile` | reconstruire PHP/Nginx/Grav Core/entrypoint/healthcheck ici |
| `ansible-role-grav-site` | consommateur prévu de l'image produite — documenté en détail (exemple de playbook complet), version référencée (`2.0.0`, alignée sur le tag déjà audité, compatibilité vérifiée statiquement seulement) | générer un Compose de production dans ce dépôt |
| `projet-lavallee-website` | autre application de la même architecture, aucune relation de code | dépendance croisée |
| infrastructure externe (reverse proxy, DNS, TLS) | aucune | toute gestion depuis ce dépôt |

## Politique de compatibilité — un mécanisme propre à ce dépôt

`docs/compatibility-policy.md` formalise une discipline **absente** de
`projet-lavallee-website` : chaque release doit déclarer explicitement
contre quelle version de `grav-runtime` elle a été certifiée, avec une
matrice tenue à jour et une liste de « changements du runtime à considérer
comme potentiellement incompatibles même si le numéro de version ne
l'indique pas ». Voir [Adopter et étendre](../10.adopter-et-etendre) pour la
procédure complète, et [Référence](../11.reference) pour le détail de la
certification `1.1.0`/`1.0.4` désormais enregistrée, et pour la période
antérieure (au commit `b27d7af`) où cette politique n'avait pas suivi le
passage de `1.0.2` à `1.0.4`.

## Tableau des contrats d'interface

| Interface | Producteur | Consommateur | Donnée échangée | Garantie | Hors contrat |
|---|---|---|---|---|---|
| Image de base | `grav-runtime` (tag Git/OCI) | `projet-gites` (`Dockerfile`) | `FROM ghcr.io/sepp67/grav-runtime:1.0.4` | toujours un tag explicite, jamais `latest` | contenu interne du runtime |
| Code applicatif immuable | ce dépôt | l'image produite | thème, plugins, configuration → `/var/www/html/user/{themes,plugins,config}/` | copié tel quel, jamais généré dynamiquement | logique du runtime lui-même |
| Contenu de seed | ce dépôt | mécanisme de seed de `grav-runtime` | `grav/user/pages/` → `/opt/grav-seed/pages/` | appliqué **uniquement** si le volume est vide au premier démarrage | toute réécriture d'un volume déjà peuplé |
| Image publiée | ce dépôt (`release.yml`) | `ansible-role-grav-site` (une fois déployé) | `ghcr.io/sepp67/projet-gites:<tag>` | version explicite exigée en production, `latest` explicitement refusé par le rôle (selon la doc de ce dépôt) | déploiement, secrets, healthcheck (relèvent du rôle) |
| Compte propriétaire de gîte | `grav-runtime`/Admin (création de compte) | plugin `contact` (`proprietaire_email()`) et plugin `calendrier-disponibilites` (`Permissions::canManage()`) | compte Grav désigné par `proprietaire` dans le frontmatter d'un gîte | résolution dynamique par nom d'utilisateur, jamais une adresse en clair | création du compte lui-même |

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b)
Fichiers principaux : docs/architecture.md, docs/compatibility-policy.md, docs/runtime-contract.md,
  docs/release-and-rollback.md, Dockerfile, grav/user/themes/gites-theme/gites-theme.yaml
Dernière vérification : 2026-09-15
```
