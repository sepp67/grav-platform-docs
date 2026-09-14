---
title: "Flux chronologique"
template: docs
taxonomy:
    category: [docs]
---

Sommaire opérationnel de ce dépôt, reconstruit depuis `tasks/main.yml` et
les fichiers de tâches qu'il importe, au tag `v2.0.0`. Chaque étape renvoie
à son détail complet dans [Sections de code](../05.sections-de-code).

`tasks/main.yml` importe, dans cet ordre exact : `assert.yml` →
`admin_guard.yml` → (`docker.yml` **ou** `verify_docker.yml`) →
`directories.yml` → `secrets.yml` → `deploy.yml` → un bloc conditionnel
(`healthcheck.yml` → `verify_admin_account.yml` → `version.yml`).

| # | Étape | Fichier | Déclencheur / condition | Action | État produit | Échec possible |
|---:|---|---|---|---|---|---|
| 1 | Validation des variables | `assert.yml` | toujours, en premier | 16 assertions : identité (`grav_image`/`grav_version`), interdiction de `latest`, forme de `grav_image` (pas de tag/digest incorporé), forme de `grav_digest`, nom de conteneur, `grav_state`, port, **`grav_bind_address` obligatoire et IPv4 stricte**, fenêtre d'attente ≥ 120s, tri-state admin, `grav_admin_type`, clés de `grav_extra_environment`, absence de retour à la ligne dans les valeurs de `grav.env` | configuration jugée admissible, ou échec immédiat | toute assertion violée → message explicite, **aucune mutation n'a encore eu lieu** |
| 2a | Vérification de l'existence du répertoire des comptes | `admin_guard.yml` | **toujours** | `ansible.builtin.stat` sur `grav_accounts_directory` | fait `_grav_accounts_dir.stat` disponible | — |
| 2b | Recherche des fichiers de compte | `admin_guard.yml` | **seulement si** le répertoire existe **et** est de type `directory` (`_grav_accounts_dir.stat.exists` et `.isdir`) | `ansible.builtin.find` (`*.yaml`/`*.yml`, métadonnées seules, jamais le contenu) | fait `_grav_accounts_found.matched`, ou tâche non jouée (`skipping`) si la condition est fausse | — |
| 2c | Calcul de la présence d'un compte | `admin_guard.yml` | toujours | `_grav_admin_account_present` = `(_grav_accounts_found.matched \| default(0)) > 0` — le `default(0)` couvre le cas où 2b a été sautée | fait disponible, y compris quand 2b n'a pas tourné | — |
| 2d | Calcul du nombre de variables de bootstrap renseignées | `admin_guard.yml` | toujours | `_grav_admin_bootstrap_count` = nombre de `grav_admin_user`/`_password`/`_email` non vides | fait disponible | — |
| 2e | Exigence compte ou bootstrap complet | `admin_guard.yml` | **seulement si** `grav_state != 'stopped'` | `assert` que `_grav_admin_account_present` est vrai **ou** que `_grav_admin_bootstrap_count == 3` | déploiement autorisé à continuer, ou refusé | non évaluée du tout si `grav_state == stopped` ; sinon, aucun compte et bootstrap incomplet → échec **avant toute mutation** |
| 3a | Installation de Docker | `docker.yml` | si `grav_manage_docker: true` | vérifie OS (Debian/Ubuntu) et architecture (x86_64/aarch64), installe `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin` via le dépôt APT officiel, démarre et active le service | Docker Engine + Compose v2 opérationnels | OS/architecture non supportés → échec explicite avant toute installation |
| 3b | Vérification de Docker | `verify_docker.yml` | si `grav_manage_docker: false` | `docker version`, `docker compose version` | confirme Docker déjà opérationnel, ou échoue tôt | Docker absent/non fonctionnel → échec explicite ici, pas plus loin dans `deploy.yml` |
| 4 | Répertoires persistants | `directories.yml` | toujours, après 3a/3b | crée la racine de l'instance et les 4 répertoires persistants (`pages`, `accounts`, `data`, `images`), **sans mode ni propriétaire imposés** | répertoires prêts à être montés | — |
| 5 | Fichiers secrets | `secrets.yml` | toujours | valide chaque entrée de `grav_secrets` (nom, exactement `src` ou `content`), crée `grav_secret_directory` (`0750`, `root:grav_container_gid`), dépose chaque secret (`0640`) | secrets présents sur l'hôte, prêts à être montés en lecture seule | entrée invalide (ni `src` ni `content`, ou les deux) → échec avant dépôt |
| 6 | Rendu Compose et environnement | `deploy.yml` (1/2) | toujours | rend `docker-compose.yml` (générique, référence `_grav_effective_reference` calculée en `vars/main.yml`) et `grav.env` (`0600`, format `raw`) | fichiers de déploiement générés sur l'hôte | fichier modèle absent (jamais en pratique) |
| 7 | Démarrage / arrêt du conteneur | `deploy.yml` (2/2) | selon `grav_state` | si `!= stopped` : `docker compose` avec `pull: missing` ou `always` (si `grav_force_pull`), `recreate: auto` ; si `stopped` : arrêt sans suppression des volumes | conteneur dans l'état demandé | échec de pull/démarrage Docker |
| 8 | Attente du verdict de santé Docker | `healthcheck.yml` (1/3) | si `grav_state != stopped` | interroge `docker inspect .State.Health.Status` en boucle jusqu'à un verdict définitif (`healthy`/`unhealthy`, jamais `starting`) | verdict obtenu, dans la fenêtre bornée | fenêtre épuisée sans verdict définitif → échec |
| 9 | Verdict exigé "healthy" | `healthcheck.yml` (2/3) | après 8 | `assert` que le verdict est exactement `healthy` | confirmation technique | verdict `unhealthy` → **rescue immédiat**, aucune nouvelle tentative |
| 10 | Contrôle HTTP applicatif | `healthcheck.yml` (3/3) | après 9 | requête HTTP sur `_grav_site_check_host:grav_http_port` + chemin, jusqu'au code attendu | page réelle confirmée fonctionnelle | code inattendu après épuisement des tentatives → **rescue** |
| 11a | Succès : nettoyage du diagnostic | `clear_failure_diagnostic.yml` | si 8-10 réussissent | supprime `.last_failure.log` s'il existe (idempotent) | pas de diagnostic périmé | — |
| 11b | Échec : diagnostic et arrêt | `healthcheck.yml` (rescue) | si 8, 9 ou 10 échoue | capture `docker logs --tail 200` (jamais affiché), écrit `.last_failure.log` (`0600`, `root:root`), échoue avec un message actionnable | fichier de diagnostic sur l'hôte, tâche en échec | — (c'est la voie d'échec elle-même) |
| 12 | Vérification post-démarrage du compte | `verify_admin_account.yml` | si `grav_state != stopped` et 8-10 ont réussi | constate à nouveau (métadonnées seules) la présence d'un fichier de compte persistant | confirmation, ou échec | aucun fichier de compte après démarrage → échec, **aucune traçabilité n'est écrite** |
| 13 | Traçabilité | `version.yml` | si `grav_state != stopped` et 12 a réussi | fige l'horodatage, lit l'état précédent, détecte un changement d'état contractuel, écrit `.deployed_version` et `.deployed_state.yml` (toujours), ajoute une ligne à `deployed_versions.log` (**seulement si l'état contractuel a changé**) | traçabilité à jour | — |

## Note sur l'étape 6 : la référence effective n'est pas une tâche

`_grav_effective_reference` (`grav_image:grav_version` ou
`grav_image@grav_digest`) est un **fait calculé une fois**, dans
`vars/main.yml`, disponible dès le chargement du rôle — ce n'est pas une
tâche exécutée à un moment précis de la séquence. Le template Compose et
`tasks/version.yml` lisent tous deux cette même valeur ; il n'y a qu'une
seule source de vérité (`vars/main.yml`, commentaire explicite).

## Branches significatives

- **`grav_manage_docker` true/false** : étape 3a (installation) ou 3b
  (vérification), jamais les deux.
- **`grav_state` started/restarted/stopped** : `stopped` ne saute ni la
  vérification `stat` du répertoire des comptes, ni le calcul de
  `_grav_admin_account_present`/`_grav_admin_bootstrap_count`, ni la
  validation tri-state (étapes 1, 2a-2d, toujours exécutées) — seule
  l'**assertion finale** de la garde (étape 2e) et le bloc 8-13
  (healthcheck, vérification admin, traçabilité) sont conditionnés à
  `grav_state != stopped`. Voir le tableau détaillé ci-dessous. `stopped`
  déclenche par ailleurs un simple arrêt à l'étape 7 ;
  `started`/`restarted` suivent la séquence complète.
- **`grav_digest` renseigné/absent** : ne déclenche aucune étape
  supplémentaire, mais se propage à travers plusieurs points de lecture
  directe et indirecte — voir la section dédiée ci-dessous.
- **`grav_force_pull` true/false** : change uniquement le paramètre `pull`
  de l'étape 7 (`always` vs `missing`) — un redémarrage sans
  `grav_force_pull` ne consulte jamais le registre.
- **Premier déploiement / compte persistant existant** : sans fichier de
  compte, l'étape 2e exige les 3 variables admin (bootstrap à l'étape 7
  par le runtime) ; avec un fichier déjà présent, les 3 variables restent
  acceptées mais le runtime ne recrée jamais le compte.
- **`grav_secrets` par `src`/`content`** : étape 5 traite les deux
  sources de façon symétrique, résultat identique sur l'hôte (`0640`,
  `root:grav_container_gid`).
- **Healthcheck healthy/starting/unhealthy** : `starting` fait boucler
  l'étape 8 (dans la fenêtre bornée) ; `unhealthy` sort immédiatement vers
  le rescue, sans attendre la fin de la fenêtre.
- **Succès / bloc rescue** : chemins 11a et 11b, mutuellement exclusifs.

## Garde administrateur selon `grav_state` — détail exact

| Contrôle | `started` | `restarted` | `stopped` | Fichier |
|---|---:|---:|---:|---|
| Vérification de l'existence du répertoire avec `stat` | oui | oui | **oui** | `admin_guard.yml` — toujours exécutée, aucune condition |
| Recherche des fichiers de compte avec `find` | si le répertoire existe (type `directory`) | si le répertoire existe | si le répertoire existe | `admin_guard.yml` — conditionnée à l'état du répertoire, pas à `grav_state` |
| Validation tri-state (les 3 variables admin ou aucune) | oui | oui | **oui** | `assert.yml` — aucune condition `when`, s'applique toujours |
| Exigence compte **ou** bootstrap complet (assertion finale) | oui | oui | **non** | `admin_guard.yml` — seule cette tâche porte `when: grav_state != 'stopped'` |
| Vérification post-démarrage (`verify_admin_account.yml`) | oui | oui | **non** | `tasks/main.yml` — bloc entier (healthcheck + vérification + traçabilité) sous `when: grav_state != 'stopped'` |

Autrement dit : avec `grav_state: stopped`, un état admin partiel (1 ou 2
variables sur 3) **échoue quand même**, dès `assert.yml`, avant même que
`admin_guard.yml` ne soit atteint — c'est la validation tri-state, pas la
garde elle-même, qui bloque ce cas. Ce que `stopped` évite réellement,
c'est l'**exigence** d'un compte ou d'un bootstrap complet quand aucun
compte n'existe : arrêter une instance jamais initialisée est autorisé.
La recherche `find`, elle, ne dépend jamais de `grav_state` : elle dépend
uniquement de l'existence du répertoire des comptes sur l'hôte.

## Lectures directes et indirectes de `grav_digest`

`grav_digest` est lu **directement** à cinq endroits, et se propage
**indirectement** via `_grav_effective_reference` à cinq autres :

```text
grav_digest
├── directement lu par :
│   ├── defaults/main.yml            (définition de l'entrée publique, défaut "")
│   ├── tasks/assert.yml             (validation du format : "" ou sha256:+64 hex)
│   ├── vars/main.yml                (calcul de _grav_effective_reference)
│   ├── templates/deployed_state.yml.j2  (écrit le champ "digest" tel quel)
│   └── tasks/version.yml            (compare le digest à l'état précédent)
└── indirectement, via _grav_effective_reference :
    ├── templates/docker-compose.yml.j2  (clé "image:" du service)
    ├── tasks/deploy.yml                 (pull + démarrage du conteneur réel)
    ├── templates/deployed_state.yml.j2  (champ "effective_reference")
    ├── tasks/version.yml                (comparaison de la référence effective à l'état précédent)
    └── tasks/version.yml                (journalisation conditionnelle dans deployed_versions.log)
```

Représentation pédagogique équivalente :

```text
grav_digest
├── validation (tasks/assert.yml)
├── calcul de la référence effective (vars/main.yml)
│   └── Compose (templates/docker-compose.yml.j2) → pull (tasks/deploy.yml) → conteneur réel
└── traçabilité (tasks/version.yml, templates/deployed_state.yml.j2)
    ├── champ "digest" (copié tel quel)
    ├── champ "effective_reference" (dérivé)
    ├── comparaison avec l'état précédent (declared_version + digest + effective_reference)
    └── journalisation dans deployed_versions.log si l'un des trois champs a changé
```

**`vars/main.yml` n'est donc pas le seul point de lecture directe** :
c'est le seul endroit où `grav_digest` est **combiné** à `grav_image` et
`grav_version` pour produire une référence — mais `defaults/main.yml`,
`tasks/assert.yml`, `templates/deployed_state.yml.j2` et `tasks/version.yml`
lisent tous la variable elle-même, chacun pour un usage distinct (valeur
par défaut, validation de forme, écriture telle quelle, comparaison).

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : tasks/main.yml, tasks/assert.yml, tasks/admin_guard.yml, tasks/deploy.yml, tasks/healthcheck.yml, tasks/verify_admin_account.yml, tasks/version.yml, vars/main.yml, defaults/main.yml, templates/docker-compose.yml.j2, templates/deployed_state.yml.j2
Preuve d'exécution (Lot 4.1) : tests/test_admin_guard.yml (20 scénarios, started/stopped/restarted, PASS réel)
Dernière vérification : 2026-09-12
```
