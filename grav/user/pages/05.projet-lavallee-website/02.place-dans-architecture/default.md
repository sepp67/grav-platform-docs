---
title: "Place dans l'architecture"
template: docs
taxonomy:
    category: [docs]
---

## En amont

Une seule dépendance, **de construction** : l'image `grav-runtime`,
épinglée par tag explicite dans le `Dockerfile`
(`FROM ghcr.io/sepp67/grav-runtime:1.0.4`) — jamais `latest`, conformément
au commentaire du `Dockerfile` lui-même.

## En aval

`ansible-role-grav-site` — mais avec une nuance importante, propre à ce
dépôt et absente des dépôts déjà documentés : `docs/architecture.md`
déclare explicitement que ce branchement n'est « **pas encore branché sur
ce dépôt à ce stade** ». Aucun fichier de ce dépôt (playbook, inventaire,
référence de registre) ne prouve un branchement effectif au commit audité
— cette affirmation documentaire est cohérente avec l'absence totale de
toute trace d'intégration Ansible dans le code lui-même.

## Chaîne de dépendance complète

```text
grav-runtime  →  projet-lavallee-website (ce dépôt)  →  ansible-role-grav-site  →  VM cible
                                                              ▲
                                                     pas encore branché sur ce
                                                     dépôt au commit audité
                                                     (docs/architecture.md)
```

Ce dépôt est la **deuxième application concrète** de la même architecture
que `projet-gites` (README : « another application built on the same
architecture »).

## Différence structurelle avec `projet-gites`

D'après `docs/architecture.md` : `gites-theme` hérite du thème par défaut
de Grav (`quark2`, fourni par `grav-runtime`) via un chaînage de flux, et
ne redéfinit que quelques templates. `lavallee-theme` est au contraire
**entièrement autonome** — aucun `streams:` dans
`lavallee-theme.yaml`, confirmé par lecture directe du fichier. La maquette
d'origine était un design « terminal » sur mesure sans rapport avec la
mise en page par défaut de Grav ; chaîner vers `quark2` n'aurait apporté
aucune réutilisation utile. Tout le rendu vit dans
`templates/partials/base.html.twig` et `css/custom.css`.

## Ce que ce dépôt ne fait jamais (`docs/architecture.md`)

Reprendre PHP, Nginx, Grav Core, l'entrypoint, le healthcheck natif ou le
bootstrap admin (appartiennent à `grav-runtime`) ; générer ou committer un
Compose de production, ou dupliquer une tâche de déploiement (appartiendra
à `ansible-role-grav-site`) ; gérer un reverse proxy, TLS, DNS ou un
pare-feu (infrastructure externe).

## Frontières inter-dépôts

| Dépôt | Relation | Interdits |
|---|---|---|
| `grav-runtime` | image de base, épinglée par tag dans le `Dockerfile` | reconstruire PHP/Nginx/Grav Core/entrypoint/healthcheck ici |
| `ansible-role-grav-site` | consommateur prévu de l'image produite — **pas encore branché** au commit audité | générer un Compose de production dans ce dépôt |
| `projet-gites` | autre application de la même architecture, aucune relation de code | dépendance croisée |
| infrastructure externe (reverse proxy, DNS, TLS) | aucune | toute gestion depuis ce dépôt |

## Tableau des contrats d'interface

| Interface | Producteur | Consommateur | Donnée échangée | Garantie | Hors contrat |
|---|---|---|---|---|---|
| Image de base | `grav-runtime` (tag Git/OCI) | `projet-lavallee-website` (`Dockerfile`) | `FROM ghcr.io/sepp67/grav-runtime:1.0.4` | toujours un tag explicite, jamais `latest` | contenu interne du runtime |
| Code applicatif immuable | ce dépôt | l'image produite | thème, plugin, langues, configuration → `/var/www/html/user/{themes,plugins,languages,config}/` | copié tel quel, jamais généré dynamiquement | logique du runtime lui-même |
| Contenu de seed | ce dépôt | mécanisme de seed de `grav-runtime` | `grav/user/pages/` → `/opt/grav-seed/pages/` | appliqué **uniquement** si le volume persistant est vide au premier démarrage | toute réécriture d'un volume déjà peuplé |
| Image publiée | ce dépôt (`release.yml`) | `ansible-role-grav-site` (une fois branché) | `ghcr.io/sepp67/projet-lavallee:<tag>` | version explicite exigée en production | déploiement, secrets, healthcheck (relèvent du rôle) |
| Compte administrateur | `grav-runtime` (bootstrap) | plugin `contact` de ce dépôt (`proprietaire_email()`) | compte Grav désigné par `proprietaire` dans le frontmatter de `/contact` | résolution dynamique, jamais une adresse en clair dans le dépôt | création du compte lui-même |

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : docs/architecture.md, Dockerfile, grav/user/themes/lavallee-theme/lavallee-theme.yaml
Dernière vérification : 2026-09-14
```
