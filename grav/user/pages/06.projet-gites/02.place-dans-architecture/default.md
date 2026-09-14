---
title: "Place dans l'architecture"
template: docs
taxonomy:
    category: [docs]
---

## En amont

Une seule dépendance, de construction : l'image `grav-runtime`, épinglée
par tag explicite dans le `Dockerfile` — jamais `latest`. **Constat
important** : le `Dockerfile` référence `grav-runtime:1.0.4`, mais
`docs/architecture.md` et `docs/compatibility-policy.md` de ce même
commit citent `grav-runtime:1.0.2` comme version certifiée — un écart
documentaire réel, détaillé en [Référence](11.reference).

## En aval

`ansible-role-grav-site`. La documentation interne de ce dépôt (six
fichiers `docs/*.md`, tous lus intégralement) le cite systématiquement
comme `ansible-role-grav-site:1.0.1` — une référence de version
**différente** du tag `v2.0.0` déjà audité au [Lot
4](../03.ansible-role-grav-site). Contrairement à `projet-lavallee-website`,
dont `docs/architecture.md` déclarait ce branchement « pas encore
effectif », `projet-gites` documente un exemple de déploiement Ansible
complet et déjà rédigé (`docs/release-and-rollback.md`). Le tag `v1.0.1`
existe réellement et a été **vérifié directement** pour ce lot (worktree
détaché, comparaison ciblée) : l'exemple était bien compatible avec ce
tag au moment de sa rédaction, et reste majoritairement compatible avec
`v2.0.0`, à une exception près (`grav_bind_address`, devenu obligatoire) —
détail complet en [Référence](11.reference).

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
6](../05.projet-lavallee-website/02.place-dans-architecture)).

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
| `ansible-role-grav-site` | consommateur prévu de l'image produite — documenté en détail (exemple de playbook complet), version référencée (`1.0.1`) différente du tag `v2.0.0` déjà audité | générer un Compose de production dans ce dépôt |
| `projet-lavallee-website` | autre application de la même architecture, aucune relation de code | dépendance croisée |
| infrastructure externe (reverse proxy, DNS, TLS) | aucune | toute gestion depuis ce dépôt |

## Politique de compatibilité — un mécanisme propre à ce dépôt

`docs/compatibility-policy.md` formalise une discipline **absente** de
`projet-lavallee-website` : chaque release doit déclarer explicitement
contre quelle version de `grav-runtime` elle a été certifiée, avec une
matrice tenue à jour et une liste de « changements du runtime à considérer
comme potentiellement incompatibles même si le numéro de version ne
l'indique pas ». Voir [Adopter et étendre](10.adopter-et-etendre) pour la
procédure complète, et [Référence](11.reference) pour la vérification que
cette politique n'a, au commit audité, pas été respectée pour le passage
de `1.0.2` à `1.0.4`.

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
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : docs/architecture.md, docs/compatibility-policy.md, docs/runtime-contract.md,
  Dockerfile, grav/user/themes/gites-theme/gites-theme.yaml
Dernière vérification : 2026-09-14
```
