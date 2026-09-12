---
title: "Adopter et étendre"
template: docs
taxonomy:
    category: [docs]
---

## 1. Prérequis

Docker, et une décision de contenu métier (thème, plugins, pages) pour la
future image fille. Aucune connaissance d'Ansible n'est requise :
`grav-runtime` n'a aucune dépendance vers `ansible-role-grav-site`.

## 2. Exemple minimal

```dockerfile
FROM ghcr.io/sepp67/grav-runtime:1.0.4

COPY grav/user/themes/mon-theme  /var/www/html/user/themes/mon-theme
COPY grav/user/plugins/mon-plugin /var/www/html/user/plugins/mon-plugin
COPY grav/user/config /var/www/html/user/config

COPY grav/user/pages    /opt/grav-seed/pages
COPY grav/user/accounts /opt/grav-seed/accounts
```

Repris quasiment à l'identique dans les trois images filles existantes
(`projet-lavallee-website`, `projet-gites`, `grav-platform-docs`) — voir
`docs/documentation-sources.yml` pour leurs commits respectifs.

## 3. Validation locale

`docker build`, puis `docker run` avec les volumes persistants, puis
`curl /healthz`. `grav-platform-docs` (ce dépôt) documente une suite de
tests de fumée complète appliquant ce principe
(`tests/test-build.sh`, `tests/test-startup.sh`) — un modèle réutilisable
pour toute nouvelle image fille.

## 4. Personnalisation autorisée

- Ajouter un thème, des plugins, de la configuration non secrète : via
  `COPY` dans le `Dockerfile` de l'image fille — jamais par volume.
- Hériter de `quark2` par chaînage de flux (`theme://`, voir
  `gites-theme.yaml`) plutôt que de le revendoriser.
- Choisir son propre mécanisme de seed (`/opt/grav-seed/<sous-dossier>`)
  indépendamment pour chaque type de contenu.

## 5. Détails internes à ne pas dépendre

- Le nom exact des scripts (`entrypoint.sh`, `seed-init.sh`,
  `bootstrap-admin.sh`) et leur emplacement (`/entrypoint.sh` à la racine,
  pas sous `/usr/local/bin`) — non garantis stables entre versions
  mineures.
- La structure interne du thème `quark2` au-delà du point d'extension
  documenté (chaînage de flux) — le remplacer directement casserait ce
  mécanisme pour toute image qui en hérite.
- Le fait que Nginx et PHP-FPM tournent dans le même conteneur — un choix
  d'implémentation, pas un contrat.

## 6. Comportements configurables

Toutes les variables listées en [Configuration et
interfaces](../06.configuration-et-interfaces) : bootstrap admin, type
d'accès admin, fuseau horaire.

## 7. Intégration à la plateforme

Publier l'image fille sur GHCR, avec une version épinglée de
`grav-runtime` (jamais `latest` — voir [Tests et CI](../08.tests-et-ci)).
La suite (registre `grav-sites-ops`, déploiement par
`ansible-role-grav-site`) est hors périmètre de ce dépôt — voir
[Architecture globale — Parcours d'adoption](../../01.architecture-globale/06.parcours-adoption).

## 8. Exploitation

Voir [Exploitation et diagnostic](../09.exploitation-et-diagnostic).

## 9. Mise à jour

Publier une nouvelle version de `grav-runtime` (nouveau tag `vX.Y.Z`) ne
met à jour aucune image fille automatiquement : chaque image fille doit
elle-même republier avec un nouveau `FROM` — épingler une version
explicite est précisément ce qui rend ce choix possible et volontaire (pas
subi via `latest`).

## 10. Rollback

Revenir à une version antérieure de `grav-runtime` dans le `FROM` d'une
image fille, puis reconstruire et republier cette image fille. Ne
restaure jamais, à lui seul, le contenu d'un volume persistant.

## 11. Limites

- `php:8.3-fpm-alpine` reste un tag mouvant jusqu'au patch exact — un
  pinning strict suppose de fixer le digest (README "Limitations
  connues").
- Une seule architecture CPU construite (`linux/amd64`) — pas de support
  documenté ou testé pour `arm64`.
- Le healthcheck ne couvre jamais le rendu applicatif réel — voir
  [Sections de code](../05.sections-de-code) §7.

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : README.md ("Créer une image applicative fille", "Contrat avec le futur rôle Ansible")
Dernière vérification : 2026-09-12
```
