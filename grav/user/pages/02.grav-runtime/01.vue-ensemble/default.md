---
title: "Vue d'ensemble"
template: docs
taxonomy:
    category: [docs]
---

## Quel problème ce dépôt résout-il ?

Chaque site Grav de la plateforme a besoin des mêmes briques techniques :
PHP-FPM, Nginx, Grav Core, Grav Admin, un mécanisme de démarrage, un
healthcheck. Sans `grav-runtime`, chaque image applicative (site des gîtes,
lavallee.tech, ce site documentaire) réimplémenterait sa propre version de
ces briques — au prix d'incohérences et d'un correctif à répéter partout en
cas de faille.

## Qui l'utilise ?

Des images applicatives filles, jamais un humain ou un opérateur
directement : `grav-runtime` seul ne contient aucun contenu de site (README
"Ce que l'image ne contient pas"). Il n'est utile qu'en `FROM` d'une image
qui ajoute un thème, des plugins et des pages.

## Que reçoit-il et que produit-il ?

| | |
|---|---|
| Entrée | des arguments de build (`PHP_VERSION`, `GRAV_VERSION`, `GRAV_ZIP_URL`, `GRAV_ZIP_SHA256`) et, au démarrage, des variables d'environnement (`GRAV_ADMIN_*`, `GRAV_TIMEZONE`) |
| Sortie | une image Docker exécutable, et à l'exécution : un conteneur qui sert HTTP sur le port `80`, avec un point de contrôle technique `/healthz` |

## Quelle est sa responsabilité exclusive ?

Fournir Grav (Core + Admin) dans Nginx + PHP-FPM, démarré et supervisé de
façon générique et idempotente, avec un mécanisme de seed non destructif
pour le contenu initial d'une image fille — rien de plus.

## Que refuse-t-il de faire ?

- contenir un thème métier, un plugin métier, une page, un secret, un
  compte, une adresse IP ou un domaine réel (README "Ce que l'image ne
  contient pas") ;
- déployer quoi que ce soit sur une VM, gérer un registre de sites, un
  reverse proxy, TLS ou le DNS (hors périmètre, voir [Architecture
  globale](../../01.architecture-globale/02.responsabilites-et-frontieres)) ;
- garantir qu'une page réelle d'un site fille se rend correctement — son
  healthcheck est technique, pas applicatif (voir [Flux
  chronologique](../04.flux-chronologique) et [Sections de
  code](../05.sections-de-code)).

## Fiche synthétique

| Champ | Contenu |
|---|---|
| Type de composant | runtime |
| Entrée principale | arguments de build ; variables d'environnement au démarrage |
| Sortie principale | image Docker publiée sur GHCR ; conteneur HTTP sur le port 80 |
| Dépendance directe | aucune vers la plateforme — dépend de `php:8.3-fpm-alpine` (image tierce) et d'une release GitHub officielle de Grav |
| Données persistantes | non, dans l'image elle-même — définit le *mécanisme* pour les images filles (`/opt/grav-seed/`, répertoires `user/pages`, `user/accounts`, `user/data`, `user/images`) |
| Secrets | aucun dans l'image ; les identifiants admin sont des variables d'environnement fournies au démarrage, jamais une valeur par défaut |
| Déclencheur | `docker build` (construction) ; démarrage du conteneur, `ENTRYPOINT ["/entrypoint.sh"]` (exécution) |

## Quand utiliser ce dépôt ?

Comme base (`FROM ghcr.io/sepp67/grav-runtime:<version>`) de toute nouvelle
image applicative Grav de la plateforme.

## Quand ne pas l'utiliser ?

Pour un site Grav hors de cette plateforme sans en revoir le contrat
(politique GitOps sur `user/config`, absence de TLS interne, healthcheck
technique uniquement) ; pour tester une fonctionnalité de Grav Admin qui
dépend d'un plugin non inclus dans le bundle Admin officiel (voir la liste
en [Configuration et interfaces](../06.configuration-et-interfaces)).

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : README.md, Dockerfile
Dernière vérification : 2026-09-12
```
