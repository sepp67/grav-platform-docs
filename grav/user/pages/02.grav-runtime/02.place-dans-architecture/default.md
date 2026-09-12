---
title: "Place dans l'architecture"
template: docs
taxonomy:
    category: [docs]
---

## En amont

- `php:8.3-fpm-alpine` (image tierce officielle) — base du `Dockerfile`.
  Non pinné au digest exact : un tag mouvant jusqu'au patch et à la couche
  Alpine (README "Limitations connues").
- La release GitHub versionnée de Grav
  (`github.com/getgrav/grav/releases/download/2.0.11/grav-admin-v2.0.11.zip`)
  — pas `getgrav.org`, qui ne publie aucune somme de contrôle pour ses liens
  "latest".

## En aval

Toute image applicative de la plateforme : `projet-lavallee-website`,
`projet-gites`, et ce dépôt (`grav-platform-docs`) lui-même — chacune
`FROM ghcr.io/sepp67/grav-runtime:<version>`. `grav-runtime` ne connaît
aucune d'entre elles : la dépendance est à sens unique.

## Dépendances absentes mais souvent supposées

- **Pas de dépendance à `ansible-role-grav-site`** : `grav-runtime` ne sait
  pas qu'un rôle de déploiement existe. Le README documente un "Contrat
  avec le futur rôle Ansible" — une intention, pas un couplage de code.
- **Pas de TLS** : port `80/tcp` uniquement. Un opérateur qui suppose que
  `grav-runtime` gère HTTPS se trompe — c'est le reverse proxy externe
  (`control-repository`, hors périmètre) qui en a la charge.
- **Pas de multi-conteneur** : Nginx et PHP-FPM tournent dans le même
  conteneur (choix assumé, README "Arrêt et supervision des processus") —
  ne pas supposer qu'ils sont orchestrables séparément par Compose.

## Diagramme local

```text
php:8.3-fpm-alpine (tiers)         release GitHub Grav 2.0.11 (tiers)
        │                                    │
        └──────────────┬─────────────────────┘
                        ▼
                  grav-runtime
                        │
                        │  FROM ghcr.io/sepp67/grav-runtime:<version>
                        ▼
      ┌─────────────────┼──────────────────┐
      ▼                 ▼                  ▼
projet-lavallee-  projet-gites      grav-platform-docs
website
```

Vue complète de la chaîne (jusqu'à la VM et le reverse proxy) : voir le
[diagramme de composants](../../01.architecture-globale/01.vue-ensemble).

## Tableau des contrats d'interface

| Interface | Producteur | Consommateur | Donnée échangée | Garantie | Hors contrat |
|---|---|---|---|---|---|
| Base d'image | `php:8.3-fpm-alpine` | `grav-runtime` | image de base taguée | extensions PHP installées à la construction (`gd`, `zip`, `intl`, `mbstring`, `opcache`) | pinning au digest exact (tag mouvant, voir Limitations) |
| Téléchargement de Grav | release GitHub `getgrav/grav` | `grav-runtime` | archive zip + SHA-256 publié par l'API GitHub Releases | build interrompu si le SHA-256 ne correspond pas | disponibilité de GitHub lui-même |
| Base pour image fille | `grav-runtime` | image applicative | image Docker taguée (`ghcr.io/sepp67/grav-runtime:X.Y.Z`) | contrat immuable/persistant (voir [Données, secrets et persistance](../07.donnees-secrets-persistance)), healthcheck `/healthz` | contenu métier, comptes, secrets, TLS |
| Démarrage | image fille | `entrypoint.sh` | variables d'environnement (`GRAV_ADMIN_*`, `GRAV_TIMEZONE`), contenu de `/opt/grav-seed/` | seed non destructif, bootstrap admin idempotent et strict | validation du contenu métier de l'image fille |

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : Dockerfile, README.md ("Contrat avec le futur rôle Ansible", "Limitations connues")
Dernière vérification : 2026-09-12
```
