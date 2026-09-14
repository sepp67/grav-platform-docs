---
title: "Configuration et interfaces"
template: docs
taxonomy:
    category: [docs]
---

## Variables publiques (`defaults/main.yml`)

Toutes validées avant exécution par `tasks/assert.yml`. Aucune n'impose de
valeur métier.

### Entrées principales (obligatoires ou structurantes)

| Variable | Défaut | Obligatoire quand | Effet | Sensible |
|---|---|---|---|---|
| `grav_image` | `""` | toujours | dépôt d'image, sans tag ni digest incorporé | non |
| `grav_version` | `""` | toujours | tag de version — jamais `"latest"` | non |
| `grav_bind_address` | `""` | toujours (v2.0.0) | adresse d'écoute IPv4 stricte ou `0.0.0.0` | non |
| `grav_admin_user` / `_password` / `_email` | `""` | ensemble, si aucun compte persistant | bootstrap du premier compte | **mot de passe : oui** |
| `grav_state` | `started` | jamais seule | `started`/`stopped`/`restarted` | non |

### Facultatives (avec défaut raisonnable)

| Variable | Défaut | Effet |
|---|---|---|
| `grav_digest` | `""` | épinglage immuable optionnel (`sha256:` + 64 hex) |
| `grav_container_name` | `grav-site` | nom du conteneur/service |
| `grav_http_port` | `8080` | port hôte publié |
| `grav_secrets` | `[]` | fichiers secrets à monter |
| `grav_restart_policy` | `unless-stopped` | politique de redémarrage Docker |
| `grav_admin_type` | `""` | `admin`/`api`/`both` — vide laisse le runtime décider |
| `grav_timezone` | `""` | `date.timezone` PHP |
| `grav_extra_environment` | `{}` | variables d'environnement additionnelles |
| `grav_manage_docker` | `true` | installer Docker ou seulement le vérifier |
| `grav_force_pull` | `false` | `true` → `pull: always` |
| `grav_healthcheck_interval`/`_timeout`/`_start_period`/`_retries` | `30s`/`3s`/`10s`/`3` | miroir du `HEALTHCHECK` de l'image |
| `grav_deploy_wait_retries`/`_delay` | `60`/`5` | fenêtre d'attente du verdict Docker (≥120s imposé) |
| `grav_site_check_host` | `""` | override de l'adresse du contrôle HTTP |
| `grav_site_check_path`/`_status`/`_retries`/`_delay`/`_timeout` | `/`/`200`/`10`/`5`/`5` | contrôle HTTP applicatif |
| `grav_container_gid` | `82` | GID de `www-data` dans l'image — doit correspondre |

### Dérivées (calculées, surcharge dépréciée)

| Variable | Dérivée de | Statut |
|---|---|---|
| `grav_base_directory` | `grav_container_name` | racine de l'instance, surchargeable |
| `grav_pages_directory`/`_accounts_directory`/`_data_directory`/`_images_directory` | `grav_base_directory` | surcharge **acceptée et honorée**, mais **dépréciée** (avertissement si différente du chemin normal, retrait prévu en v3.0.0) |
| `grav_secret_directory` | `grav_base_directory` | idem |

### Internes (registres `_grav_*`, `vars/main.yml` — ne pas surcharger)

| Registre | Calculé à partir de | Utilisé par |
|---|---|---|
| `_grav_effective_reference` | `grav_image`, `grav_version`, `grav_digest` | `templates/docker-compose.yml.j2`, `tasks/version.yml` — source de vérité unique |
| `_grav_site_check_host` | `grav_site_check_host` ou `grav_bind_address` | `tasks/healthcheck.yml` |

D'autres faits `_grav_*` (préfixés) existent localement dans certains
fichiers de tâches (ex. `_grav_admin_account_present`,
`_grav_docker_apt_arch`) — internes à leur fichier, non destinés à être lus
ailleurs ni surchargés.

### Sensibles

`grav_admin_password` (jamais en argument CLI ni loggé côté runtime, `no_log`
sur les tâches qui la manipulent) ; le contenu de chaque entrée de
`grav_secrets` (`no_log: true` sur les tâches de dépôt).

### Dépréciées

Les 5 variables de répertoire dérivées (ci-dessus) : surcharge honorée,
avertissement émis, retrait prévu v3.0.0 (`docs/MIGRATION.md` §5).

## Règles de validation notables

- `grav_bind_address` : IPv4 littérale stricte ou `0.0.0.0` — **IPv6
  refusée** (voir [Sections de code](../05.sections-de-code) §2).
- `grav_image` : ni `@digest` ni `:tag` après le premier `/` (un port de
  registre avant le premier `/` reste autorisé).
- `grav_digest` : vide ou exactement `sha256:` + 64 hexadécimaux
  minuscules.
- Tri-state admin : `grav_admin_user`/`_password`/`_email` toutes définies
  ou toutes vides.
- `grav_extra_environment` : clés `^GRAV_[A-Z0-9_]+$`, jamais une clé déjà
  gérée explicitement (huit clés réservées, voir `assert.yml`).

## Version, digest et référence effective

| `grav_digest` | Référence effective (`_grav_effective_reference`) |
|---|---|
| vide | `{{ grav_image }}:{{ grav_version }}` |
| `sha256:…` | `{{ grav_image }}@{{ grav_digest }}` |

`grav_version` reste obligatoire dans les deux cas : label humain
(changelog, PR de promotion), même quand le digest garantit l'identité
exacte de l'image. Jamais de forme hybride `image:version@digest`.

## Exemple minimal (mode cible)

```yaml
roles:
  - role: grav_site
    vars:
      grav_image: "ghcr.io/sepp67/projet-gites"
      grav_version: "1.0.7"
      grav_bind_address: "192.168.1.10"
```

## Exemple avancé (avec digest et secret)

```yaml
roles:
  - role: grav_site
    vars:
      grav_image: "ghcr.io/sepp67/projet-gites"
      grav_version: "1.0.7"
      grav_digest: "sha256:2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"
      grav_bind_address: "192.168.1.10"
      grav_admin_user: "{{ vault_grav_admin_user }}"
      grav_admin_password: "{{ vault_grav_admin_password }}"
      grav_admin_email: "{{ vault_grav_admin_email }}"
      grav_secrets:
        - name: email-private.php
          content: "{{ vault_grav_email_private_php }}"
```

## Contrat de sortie

Un déploiement réussi (`grav_state != stopped`) laisse : un conteneur
`healthy` répondant sur `grav_bind_address:grav_http_port`,
`.deployed_state.yml` et `.deployed_version` à jour, et une ligne
supplémentaire dans `deployed_versions.log` si l'état contractuel a
changé.

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : defaults/main.yml, vars/main.yml, README.md ("Variables")
Dernière vérification : 2026-09-12
```
