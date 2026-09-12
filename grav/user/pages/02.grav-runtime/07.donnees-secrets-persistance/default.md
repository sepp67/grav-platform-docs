---
title: "Données, secrets et persistance"
template: docs
taxonomy:
    category: [docs]
---

## Matrice

| Élément | Immuable ou persistant | Source | Destination | Propriétaire du cycle de vie | Sauvegarde requise | Secret |
|---|---|---|---|---|---|---|
| PHP-FPM, Nginx, Grav Core/Admin, `quark2` | immuable | release GitHub Grav + image de base | image Docker | mainteneur `grav-runtime` | non (reconstructible depuis les sources) | non |
| Scripts (`entrypoint.sh`, `seed-init.sh`, `bootstrap-admin.sh`, `healthcheck.sh`) | immuable | ce dépôt | image Docker | mainteneur `grav-runtime` | non | non |
| `user/themes`, `user/plugins` | immuable | image (runtime + image fille) | système de fichiers du conteneur | mainteneur `grav-runtime` (socle) + auteur de l'image fille (métier) | non | non |
| `/opt/grav-seed/` | immuable (défini par l'image fille) | image fille | système de fichiers du conteneur | auteur de l'image fille | non | non |
| `user/pages`, `user/accounts`, `user/data`, `user/images` | **persistant** | seed (premier démarrage) puis usage réel | volume monté | opérateur du déploiement | **oui** | non (sauf contenu métier qu'un site y placerait — hors périmètre de ce dépôt) |
| `user/config` | **persistant au sens du montage, mais versionné comme du code** | image fille (COPY) | système de fichiers du conteneur, ou volume en lecture seule pour les vrais secrets | auteur de l'image fille (config non secrète) / opérateur (secrets) | oui pour les fichiers secrets montés | **partiellement** — `security-private.php`, `email-private.php` n'appartiennent ni au runtime ni à l'image fille |
| `GRAV_ADMIN_PASSWORD` | ni immuable ni persistant dans ce dépôt | variable d'environnement fournie au démarrage | jamais écrite en clair (stdin uniquement vers la CLI) | opérateur du déploiement | non (à réinjecter si le conteneur est recréé sans compte encore créé) | **oui** |

## Ce qui est construit dans l'image

PHP-FPM, Nginx, Grav Core + Admin, `quark2`, les scripts de démarrage — tout
ce qui ne change jamais entre deux conteneurs lancés depuis la même image.

## Ce qui est initialisé une seule fois

Le contenu de `/opt/grav-seed/` (fourni par l'image fille), copié dans
chaque répertoire persistant **uniquement s'il est vide** au moment du
premier démarrage (voir [Sections de code](../05.sections-de-code) §4).

## Ce qui survit au remplacement du conteneur

Tout ce qui vit dans un volume monté (`user/pages`, `user/accounts`,
`user/data`, `user/images`) — à condition que le volume lui-même survive.
Remplacer le conteneur par une nouvelle version de l'image ne touche à
aucun de ces volumes.

## Ce qui ne doit jamais être commité

`GRAV_ADMIN_PASSWORD` (ou toute valeur réelle des trois variables admin en
dehors d'un test jetable), `security-private.php`, `email-private.php`, et
plus généralement tout fichier sous `user/config/` qui contiendrait un
identifiant SMTP, une clé ou un mot de passe réel — le README est explicite
sur ce point ("Configuration non secrète").

## Ce qu'un rollback logiciel restaure — et ne restaure pas

`grav-runtime` ne définit pas lui-même de mécanisme de rollback (c'est le
rôle d'`ansible-role-grav-site`, voir [Architecture globale — Versionnement
et rollback](../../01.architecture-globale/05.versionnement-et-rollback)).
Ce qui est garanti **au niveau de ce dépôt** : changer de version d'image
ne touche jamais aux volumes persistants — ni pour les peupler à nouveau
(le seed ne s'exécute que sur un répertoire vide), ni pour les vider.

## Qui a le droit de muter chaque donnée

- Le mainteneur de `grav-runtime` : le socle technique (image), jamais le
  contenu d'un volume persistant.
- L'auteur d'une image fille : `user/themes`, `user/plugins`, `user/config`
  non secret, et le contenu initial du seed — jamais un volume déjà peuplé.
- L'opérateur du déploiement : les secrets montés et les volumes
  persistants en fonctionnement.
- Grav lui-même (via son interface Admin) : les répertoires persistants
  pendant l'usage normal du site — pas `user/config` en production (voir
  README "Configuration non secrète", politique GitOps).

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : README.md ("Répertoires persistants", "Configuration non secrète"), Dockerfile, docker/entrypoint.sh
Dernière vérification : 2026-09-12
```
