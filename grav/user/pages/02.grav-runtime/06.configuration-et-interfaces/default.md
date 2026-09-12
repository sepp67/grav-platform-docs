---
title: "Configuration et interfaces"
template: docs
taxonomy:
    category: [docs]
---

## Arguments de build (`docker build --build-arg`)

| Variable | Source | Type | Défaut | Obligatoire quand | Effet | Sensible |
|---|---|---|---|---|---|---|
| `PHP_VERSION` | ARG Dockerfile | texte | `8.3` | jamais | tag de l'image de base `php:<version>-fpm-alpine` | non |
| `GRAV_VERSION` | ARG Dockerfile | texte | `2.0.11` | jamais | version de Grav Core + Admin vendorisée | non |
| `GRAV_ZIP_URL` | ARG Dockerfile | URL | release GitHub officielle pour `GRAV_VERSION` | jamais | source de l'archive Grav | non |
| `GRAV_ZIP_SHA256` | ARG Dockerfile | empreinte hex | empreinte publiée par l'API GitHub Releases pour `GRAV_VERSION` | jamais | vérification d'intégrité avant extraction | non — c'est une empreinte publique, pas un secret |

Ces quatre valeurs sont **liées entre elles** : changer `GRAV_VERSION` sans
mettre à jour `GRAV_ZIP_URL` et `GRAV_ZIP_SHA256` en cohérence ferait
échouer la vérification d'intégrité (ou, pire, vérifierait une version
différente de celle réellement voulue).

## Reproductibilité — ce qui est épinglé, ce qui ne l'est pas

Le tag `v1.0.4` **contrôle le contenu Grav**, mais n'est **pas
reproductible octet pour octet dans le temps**. Ces deux affirmations ne se
contredisent pas — elles portent sur des couches différentes de l'image :

| Élément | Épinglé par le Dockerfile ? | Conséquence |
|---|---|---|
| Version de Grav Core + Admin | **oui** — `GRAV_VERSION=2.0.11`, archive vérifiée par SHA-256 (`GRAV_ZIP_SHA256`) | reconstruire `v1.0.4` installe toujours exactement le même Grav |
| Version mineure de PHP | **oui** — `PHP_VERSION=8.3` | reconstruire `v1.0.4` utilise toujours la ligne `8.3.x` |
| Version corrective (patch) de PHP | **non** | `php:8.3-fpm-alpine` est un tag mouvant : reconstruire `v1.0.4` à une autre date peut obtenir un patch PHP différent |
| Couche de base Alpine | **non** | héritée du tag `php:8.3-fpm-alpine` au moment du build ; peut changer entre deux reconstructions |
| Paquets `apk` (`nginx`, `curl`, `unzip`, `su-exec`, libs image) | **non** — `apk add` sans version explicite | leur version exacte dépend du dépôt Alpine au moment du build |

**PHP 8.3.33 n'est ni une propriété immuable du tag `v1.0.4`, ni une
version garantie par le Dockerfile** : c'est la version **observée** lors
du build local réalisé pour ce Lot, le 2026-09-12
(`docker exec ... php -v`). Une reconstruction future du même tag, à une
autre date, peut légitimement produire une version corrective de PHP ou une
couche Alpine différente, sans que cela constitue une régression ni un
écart du Dockerfile lui-même — c'est une limite documentée du tag
`grav-runtime:v1.0.4`, pas une anomalie de `grav-platform-docs` ni de ce
Lot d'audit.

Pour un pinning strict de la base PHP, le README documente l'option de
faire pointer `FROM` sur un digest exact
(`php:8.3-fpm-alpine@sha256:...`) — non utilisé par `v1.0.4` lui-même.

## Variables d'environnement (exécution)

| Variable | Source | Type | Défaut | Obligatoire quand | Effet | Sensible |
|---|---|---|---|---|---|---|
| `GRAV_ADMIN_USER` | env | texte | aucun | avec `_PASSWORD` et `_EMAIL`, ou aucune des trois | nom du compte admin bootstrap | non (un nom d'utilisateur) |
| `GRAV_ADMIN_PASSWORD` | env | texte | aucun | idem | mot de passe du compte — jamais loggé, jamais en argument CLI | **oui** |
| `GRAV_ADMIN_EMAIL` | env | texte | aucun | idem | e-mail du compte | non |
| `GRAV_ADMIN_TYPE` | env | enum | `both` | jamais seule | arborescence de droits (`admin`, `api`, `both`) — valeur hors liste = échec du démarrage | non |
| `GRAV_ADMIN_FULLNAME` | env | texte | `Administrator` | jamais | nom complet du compte (champ obligatoire côté Grav) | non |
| `GRAV_ADMIN_LANGUAGE` | env | texte | défaut Grav (`en`) | jamais | langue du compte | non |
| `GRAV_ADMIN_TITLE` | env | texte | défaut Grav | jamais | titre du compte | non |
| `GRAV_TIMEZONE` | env | texte (fuseau IANA) | défaut de l'image PHP (UTC) | jamais | `date.timezone` PHP | non |

## Classement

- **Obligatoires (conditionnellement)** : `GRAV_ADMIN_USER` /
  `_PASSWORD` / `_EMAIL` — comme un seul triplet all-or-none, jamais
  individuellement.
- **Facultatives** : `GRAV_ADMIN_TYPE`, `GRAV_ADMIN_FULLNAME`,
  `GRAV_ADMIN_LANGUAGE`, `GRAV_ADMIN_TITLE`, `GRAV_TIMEZONE`.
- **Dérivées** : aucune — toutes les variables de ce dépôt sont des
  entrées directes, rien n'est calculé à partir d'une autre variable
  d'environnement.
- **Internes** : aucune variable d'environnement interne documentée ;
  l'état "seedé ou non" est lu directement sur le contenu des répertoires
  (voir [Sections de code](../05.sections-de-code) §4), pas via une
  variable ou un fichier d'état dédié.
- **Sensibles** : `GRAV_ADMIN_PASSWORD` uniquement.
- **Dépréciées ou interdites** : aucune trouvée dans ce dépôt — pas
  d'ancien nom de variable conservé pour rétrocompatibilité.

## Règles de validation

- `GRAV_ADMIN_USER`/`_PASSWORD`/`_EMAIL` : les trois définies ou aucune —
  toute autre combinaison arrête le démarrage (`exit 1`).
- `GRAV_ADMIN_TYPE` : doit être exactement `admin`, `api` ou `both` —
  toute autre valeur arrête le démarrage avant toute tentative de
  création de compte.
- Aucune validation de format sur `GRAV_ADMIN_EMAIL` (pas de vérification
  de syntaxe e-mail dans `bootstrap-admin.sh` — la CLI Grav sous-jacente
  peut ou non la faire, non vérifié dans ce Lot).

## Exemple minimal

```bash
docker run -d -p 8080:80 grav-runtime:test
```

Démarre sans aucun compte admin, sans seed (aucune image fille ajoutée) —
utile pour vérifier que le healthcheck répond, rien de plus.

## Exemple avancé

```bash
docker run -d -p 8080:80 \
  -e GRAV_ADMIN_USER=admin \
  -e GRAV_ADMIN_PASSWORD=ChangeMe123 \
  -e GRAV_ADMIN_EMAIL=admin@example.com \
  -e GRAV_ADMIN_TYPE=both \
  -e GRAV_TIMEZONE=Europe/Paris \
  -v pages_data:/var/www/html/user/pages \
  -v accounts_data:/var/www/html/user/accounts \
  -v data_data:/var/www/html/user/data \
  -v images_data:/var/www/html/user/images \
  grav-runtime:test
```

## Contrat de sortie

Un conteneur démarré avec succès répond `200` sur `/healthz` en moins de
2 secondes, sert `/` via le front controller Grav (`index.php`), et — si
le bootstrap a été demandé — expose un compte fonctionnel dans
`user/accounts/`.

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : Dockerfile, docker/bootstrap-admin.sh, docker/entrypoint.sh, README.md ("Variables d'environnement")
Dernière vérification : 2026-09-12
```
