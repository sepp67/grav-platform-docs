---
title: "Tests et CI"
template: docs
taxonomy:
    category: [docs]
---

## Niveaux de preuve — à ne pas confondre

1. **Comportement lu dans le code** — la majorité des affirmations de
   cette rubrique.
2. **Comportement couvert d'après le code du test** — le fichier de test
   a été lu ; ce qu'il vérifie est décrit d'après son propre contenu, pas
   déduit de son seul nom.
3. **Résultat consigné dans `docs/TEST-RESULTS.md`** — une affirmation du
   dépôt lui-même sur un run passé, distincte d'une exécution par ce Lot.
4. **Job CI observé comme réussi** — statut consulté en direct via
   `gh run view` sur le run du tag `v2.0.0`.
5. **Test réellement exécuté pendant ce Lot** — **oui, pour 7 des tests
   statiques** (lint, syntax-check, inventaire, et les 7 playbooks
   `tests/test_*.yml` sans Docker) : `ansible-core 2.17.14` et
   `community.docker 5.2.1` se sont révélés disponibles localement,
   exactement les versions que le dépôt documente comme testées ensemble
   (`requirements.yml`). Molecule n'est pas installé ; les tests
   fonctionnels (`test.yml`, `test_env_encoding.yml`, `test_standalone.yml`)
   exigent Docker natif ou une VM — non rejoués. Détail exact dans le
   rapport de Lot 4.1.

## Contrôles rejoués réellement dans ce Lot (worktree détaché sur `v2.0.0`)

| Commande | Résultat réel |
|---|---|
| `ansible-lint . playbooks/ inventories/ examples/` (commande exacte du README/Makefile) | `Passed: 0 failure(s), 0 warning(s) in 23 files processed of 29 encountered` |
| `ansible-playbook --syntax-check` sur `deploy.yml`, `check.yml`, `restart.yml`, `stop.yml` | les 4 valident (`playbook: playbooks/<nom>.yml`) |
| `ansible-inventory -i inventories/example/hosts.yml --list` | JSON valide, code de sortie 0 |
| `cd tests && ansible-playbook -i inventory test_assertions.yml` | **PASS** — `ok=949 changed=0 failed=0 rescued=30` ; message du rôle : *"46 scénarios d'assertion + 1 cas dérivé + 2 cas de référence effective + 5 cas de dérivation réseau vérifiés avec succès"* — confirme le comptage exact de 46 |
| `cd tests && ansible-playbook -i inventory test_traceability.yml` | **PASS** — `ok=84 changed=21 failed=0` |
| `cd tests && ansible-playbook -i inventory test_failure_log_lifecycle.yml` | **PASS** — `ok=13 changed=6 failed=0` |
| `cd tests && ansible-playbook -i inventory test_admin_guard.yml` | **PASS** — `ok=535 changed=64 failed=0 rescued=10` ; message : *"15 scénarios de garde avant mutation + 5 scénarios de vérification post-démarrage"* (confirme le nombre 20 cité par `CONFORMITE-REQ.md`, REQ-026) — couvre explicitement `started`/`stopped`/`restarted`, confirmant la matrice de la page [Flux chronologique](../04.flux-chronologique) |
| `cd tests && ansible-playbook -i inventory test_persistence_untouched.yml` | **PASS** — `ok=40 changed=5 failed=0` |
| `cd tests && ansible-playbook -i inventory test_no_secret_leak.yml` | **PASS** — `ok=11 changed=0 failed=0` |
| `cd tests && ansible-playbook -i inventory test_consume_via_requirements.yml` | **PASS** — `ok=16 changed=6 failed=0` ; installe réellement le rôle sous le nom `sepp67.grav_site` dans un `roles_path` temporaire, l'appelle, nettoie |

Tous ces contrôles sont non destructifs : ils n'écrivent que dans `/tmp`
ou un répertoire temporaire, jamais dans le worktree lui-même
(`git status --short` et `git clean -ndx` confirment un worktree propre
après coup, hors un répertoire `.ansible/` de cache).

## Matrice garanties / tests

| Garantie | Test ou scénario | Méthode | Exécuté dans ce Lot | CI observée | Limite |
|---|---|---|---|---|---|
| Validation des variables avant toute mutation (T01) | `tests/test_assertions.yml` | statique, sans Docker — 46 scénarios `label:` rejouant `tasks/assert.yml` seul | **oui — PASS réel** (voir ci-dessus) | `static-checks` : `success` | README annonce "~35" — sous-estimation ; code, `TEST-RESULTS.md` et exécution de ce Lot concordent sur 46 |
| Installation Docker + idempotence (T02/T03) | `molecule test -s install` | Debian 12, Ubuntu 22.04, Ubuntu 24.04, conteneurs privilégiés + systemd, images figées par digest | non — Molecule non installé, conteneurs privilégiés hors périmètre | `molecule-install` : `success` | — |
| Déploiement / idempotence / mise à jour / rollback / persistance des 4 volumes (T04-T08) | `tests/test.yml` | fonctionnel, Docker natif — 4 phases, marqueur par volume, checksum du compte admin, journal `1→1→2→3` | non — nécessite un déploiement Docker réel, hors périmètre d'un audit sans déploiement | `test` : `success` | `TEST-RESULTS.md` documente ce résultat sur le run `33789033957` (commit `105e085`, branche `refonte/lot-9-release-preparation`) — **antérieur** au commit du tag `v2.0.0` ; le run propre au tag (`33888725974`, observé par ce Lot) est vert aussi, mais son détail `ok=`/`changed=` n'est pas dans `TEST-RESULTS.md` (section "Run final du HEAD définitif" laissée `à compléter`) |
| Bootstrap admin réel → compte créé (T09) | `molecule/deploy/tasks/t09_bootstrap_creates_account.yml` | Docker-in-Docker, image `grav-runtime:1.0.4` réelle | non — Molecule non installé | `molecule-deploy` : `success` | — |
| Accounts vide sans identifiants → échec avant mutation (T10) | `molecule/deploy/tasks/t10_no_creds_fails_before_mutation.yml` | idem | non | `molecule-deploy` : `success` | — |
| Compte existant → non recréé (T11) | `molecule/deploy/tasks/t11_existing_account_not_recreated.yml` | idem — nombre de fichiers, sha1, inode, mtime inchangés | non | `molecule-deploy` : `success` | — |
| Garde admin — couverture statique complète (T09/T10/T11 + états) | `tests/test_admin_guard.yml` | statique, sans Docker — 20 scénarios (15 garde + 5 vérification post-démarrage) | **oui — PASS réel** (voir ci-dessus) | `static-checks` : `success` | complète, sans Docker, la couverture fonctionnelle de T09-T11 |
| `grav_bind_address` : 127.0.0.1 / IPv4 LAN / 0.0.0.0 (T12/T13) | `molecule/deploy/tasks/t13_bind_address.yml` | Docker-in-Docker | non | `molecule-deploy` : `success` | "IPv4 LAN" testée sur l'IP du conteneur de bac à sable, pas une IPv4 physique |
| Absence de fausse mutation (recreate) (T14) | `molecule test -s digest`, état 2/3 | Docker-in-Docker | non | `molecule-digest` : `success` | — |
| Verdict santé `starting`→`healthy` / `unhealthy` immédiat (T15) | `molecule/deploy/tasks/t15_health_verdict.yml` | `unhealthy` provoqué avec `nginx:alpine` (sans `/healthcheck.sh`) | non | `molecule-deploy` : `success` | cas non représentatif d'une vraie panne applicative |
| `.last_failure.log` : contenu, permissions (T16) | `molecule/deploy/tasks/t16_rescue_no_secret_and_cleanup.yml` | sous-processus, capture la sortie Ansible d'un déploiement en échec | non | `molecule-deploy` : `success` | — |
| Cycle de vie de `.last_failure.log` — couverture statique | `tests/test_failure_log_lifecycle.yml` | statique, sans Docker | **oui — PASS réel** (voir ci-dessus) | `static-checks` : `success` | — |
| Redémarrage sans consultation du registre (T17) | `molecule/pull/tasks/t17_restart_no_registry.yml` | référence locale non résolvable + `docker events` | non | `molecule-pull` : `success` | — |
| `grav_force_pull: true` → tentative réelle (T18) | `molecule/pull/tasks/t18_force_pull.yml` | Docker-in-Docker | non | `molecule-pull` : `success` | — |
| Déploiement par digest + référence effective (T19) | `molecule/digest/tasks/t19_digest_deploy.yml` | 5 preuves déclarées (compose, `.Config.Image`, `.Image`, `RepoDigests`, absence de pseudo-référence) | non | `molecule-digest` : `success` | — |
| Traçabilité structurée sur déploiement réel (T20) | `molecule/digest/tasks/t20_traceability.yml` | Docker-in-Docker | non | `molecule-digest` : `success` | — |
| Traçabilité — couverture statique, idempotence/rollback A→B→A/digest | `tests/test_traceability.yml` | statique, sans Docker, `gather_facts: false` | **oui — PASS réel** (voir ci-dessus) | `static-checks` : `success` | — |
| `gather_facts: false` de bout en bout (T23) | assertion dans `molecule/digest/converge.yml` | Docker-in-Docker | non | `molecule-digest` : `success` | — |
| Deux instances isolées dans un même playbook (T21) | `molecule test -s multi_instance` | instance A par digest, B par tag, redéploiement de A sans effet de bord sur B | non | `molecule-multi-instance` : `success` | l'historique CI montre des échecs `T21` sur des commits **antérieurs** au tag (stabilisation de la fenêtre de healthcheck) — le run du tag `v2.0.0` est vert |
| Consommation via `requirements.yml` par nom installé (T22) | `tests/test_consume_via_requirements.yml` | statique, sans Docker — `git+file://<racine>` + SHA, résolution par `sepp67.grav_site` | **oui — PASS réel** (voir ci-dessus) | `static-checks` : `success` | référence dynamique (SHA local), ne teste pas la résolution réseau d'un vrai `git+https://` |
| Persistance intacte après les gardes administrateur | `tests/test_persistence_untouched.yml` | statique, sans Docker | **oui — PASS réel** (voir ci-dessus) | `static-checks` : `success` | — |
| Non-fuite des secrets | `tests/test_no_secret_leak.yml` | statique, sans Docker | **oui — PASS réel** (voir ci-dessus) | `static-checks` : `success` | — |
| Encodage des caractères spéciaux dans `grav.env` | `tests/test_env_encoding.yml` | fonctionnel, Docker natif | non — Docker natif requis pour un déploiement réel | `test` : `success` | — |
| Exécution réelle des playbooks autonomes | `tests/test_standalone.yml` | fonctionnel, sous-processus, déploiement réel | non — déploiement réel hors périmètre | `test` : `success` | — |

## Les cinq scénarios Molecule, nommés et expliqués depuis leur contenu réel

- **`install`** (3 plateformes : Debian 12, Ubuntu 22.04, Ubuntu 24.04,
  images figées par digest) — installe Docker Engine + le plugin Compose
  via `tasks/docker.yml` sur un conteneur **sans Docker préinstallé**
  (`converge.yml` l'exige explicitement), puis rejoue `converge` une
  seconde fois pour vérifier l'idempotence (`changed=0`).
- **`deploy`** (Debian 12 seule — la logique testée est indépendante de
  la distribution une fois Docker installé) — `prepare.yml` installe
  Docker dans le conteneur puis force le storage-driver `vfs` du daemon
  imbriqué (l'overlay ne peut pas s'empiler), pré-tire deux versions
  réelles de `grav-runtime` (`1.0.4`, `1.0.3`) et vérifie que l'image
  contient bien le plugin `login` avant tout test de bootstrap (échec
  `BLOCKED — GRAV-RUNTIME CONTRACT` sinon, sans contournement) ;
  `converge.yml` enchaîne T09, T10, T11, T13, T15, T16.
- **`pull`** (Debian 12) — vérifie la politique de récupération d'image :
  un redémarrage avec l'image déjà présente ne consulte jamais le
  registre (T17), et `grav_force_pull: true` déclenche une tentative
  réelle (T18).
- **`digest`** (Debian 12) — déploie par `grav_digest`
  (`grav_image@sha256:...`), joue le rôle avec `grav_manage_docker: false`
  et `gather_facts: false` de bout en bout (T23), et vérifie la
  traçabilité structurée sur ce déploiement réel (T19, T20).
- **`multi_instance`** (Debian 12) — deux `include_role` du même rôle
  dans **un seul playbook** : instance A par digest (port 18191), instance
  B par tag (port 18192), marqueurs de données distincts, puis
  redéploiement de A avec vérification que B reste bit-à-bit identique
  (checksums et chemins de fichiers comparés avant/après) — isolation
  démontrée, pas seulement affirmée.

## CI réellement observée pour le tag `v2.0.0`

Via `gh run list`/`gh run view` (accès direct à l'API GitHub, pas une
lecture de `TEST-RESULTS.md`) :

- Run `33888725974`, déclenché par le push du tag `v2.0.0` lui-même,
  message `"docs(release): dater la version 2.0.0"`, 2026-09-04 (cohérent
  avec le commit `1339e50b...`).
- **8 jobs, tous `success`** : `lint`, `static-checks`, `test`,
  `molecule-install`, `molecule-deploy`, `molecule-pull`,
  `molecule-digest`, `molecule-multi-instance`. Durée totale : `7m35s`.
- Les noms de jobs observés correspondent exactement aux 5 scénarios
  Molecule + aux 3 jobs statiques/fonctionnels déclarés dans
  `.github/workflows/ci.yml` — aucun job orphelin, aucun scénario sans
  job.
- **Non observé** : le détail étape par étape (`gh run view --log` ne
  retourne aucune ligne dans cet environnement, quel que soit l'âge du
  run). Le statut `success` par job est une donnée structurée de l'API
  GitHub, pas une lecture de log.

## Écart de niveau de preuve — `docs/TEST-RESULTS.md` documente un autre run que le tag

`docs/TEST-RESULTS.md` est explicite sur ce point lui-même : le tableau
T01-T23 s'appuie sur le run `33789033957` (commit `105e085`, branche
`refonte/lot-9-release-preparation`) — **antérieur** au commit du tag
`v2.0.0` (`1339e50b...`) — et sa section "Run final du HEAD définitif"
est un espace réservé non rempli (`_(à compléter — run sur le HEAD
portant ce commit ; aucun commit après ce run.)_`). Ce Lot a comblé cet
espace par l'observation live du run réel du tag (`33888725974`, ci-
dessus, également vert sur les 8 jobs), et par l'exécution réelle en
local de 7 des tests statiques — sans réécrire `docs/TEST-RESULTS.md`
lui-même, qui reste un document du dépôt source.

## Ce que ce Lot a fait

Lu intégralement : `tasks/*.yml`, `vars/main.yml`, `defaults/main.yml`,
`templates/*.j2`, `README.md`, `meta/main.yml`, `CHANGELOG.md`,
`.github/workflows/ci.yml`, `docs/MIGRATION.md`, `docs/CONFORMITE-REQ.md`,
`docs/TEST-RESULTS.md`, `playbooks/*.yml`, `Makefile`, `requirements.yml`,
`molecule/*/molecule.yml`, `molecule/*/converge.yml`,
`molecule/deploy/prepare.yml`, `tests/test_assertions.yml` et
`tests/test_consume_via_requirements.yml` (en tête et logique). **Exécuté
réellement** : `ansible-lint`, `--syntax-check` × 4, `ansible-inventory`,
et 7 playbooks de `tests/` (voir tableau ci-dessus). **Observé en
direct** : le run CI du tag `v2.0.0` (statuts de jobs, pas les logs).

**N'a pas été fait** : Molecule (non installé, conteneurs privilégiés
hors périmètre) ; les tests fonctionnels nécessitant un déploiement
Docker réel (`test.yml`, `test_env_encoding.yml`, `test_standalone.yml`) ;
lecture ligne à ligne des fichiers `verify.yml` de chaque scénario
Molecule autres que `install` ; lecture des fichiers `tests/_*.yml`
(helpers partagés). Détail exact et raisons précises dans le rapport de
Lot 4.1.

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : docs/TEST-RESULTS.md, docs/CONFORMITE-REQ.md, .github/workflows/ci.yml, molecule/*/converge.yml, tests/test_assertions.yml, tests/test_admin_guard.yml
Dernière vérification : 2026-09-12
```
