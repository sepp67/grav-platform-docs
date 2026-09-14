---
title: "Référence"
template: docs
taxonomy:
    category: [docs]
---

## Glossaire local

- **Référence effective** (`_grav_effective_reference`) — l'image Docker
  réellement déployée : `grav_image:grav_version` ou
  `grav_image@grav_digest`.
- **Garde administrateur** — vérification, avant toute mutation, qu'un
  fichier de compte persistant existe ou que le bootstrap complet est
  fourni.
- **Verdict de santé** — statut Docker définitif (`healthy`/`unhealthy`),
  distinct de "starting" (transitoire) et distinct du contrôle HTTP
  applicatif.
- **État contractuel** — le triplet `declared_version`/`digest`/`effective_reference`
  dont un changement déclenche une nouvelle ligne dans
  `deployed_versions.log`.
- **Mode cible / mode autonome** — consommation via `requirements.yml` par
  un dépôt tiers, ou exploitation directe depuis la racine de ce dépôt.

## Index des fichiers structurants

| Fichier | Rôle |
|---|---|
| `tasks/main.yml` | orchestre l'ensemble — voir [Flux chronologique](../04.flux-chronologique) |
| `tasks/assert.yml` | validation complète |
| `tasks/admin_guard.yml` | garde administrateur |
| `tasks/docker.yml` / `verify_docker.yml` | installation / vérification Docker |
| `tasks/directories.yml`, `secrets.yml` | répertoires et secrets |
| `tasks/deploy.yml` | rendu Compose/env, (dé)marrage |
| `tasks/healthcheck.yml`, `clear_failure_diagnostic.yml` | santé, diagnostic |
| `tasks/verify_admin_account.yml`, `version.yml` | vérification post-démarrage, traçabilité |
| `vars/main.yml` | registres internes `_grav_*` |
| `defaults/main.yml` | interface publique complète |

## Index des commandes

Voir [Exploitation et diagnostic](../09.exploitation-et-diagnostic).

## Index des variables

Voir [Configuration et interfaces](../06.configuration-et-interfaces).

## Documents normatifs

`README.md` (579 lignes au tag `v2.0.0`), `docs/MIGRATION.md`,
`docs/CONFORMITE-REQ.md`, `docs/TEST-RESULTS.md`, `CHANGELOG.md` — tous
lus intégralement (Lot 4.1). `docs/CONFORMITE-REQ.md` synthétise **63
exigences `REQ-*`** : 60 `CONFORME`, 1 `CONFORME (périmètre 2.0.0)`
(REQ-017, IPv6 hors périmètre), 2 `NON APPLICABLE` (REQ-039b, transformation
en collection Ansible — décision de contrat reportée ; REQ-052, exposition
publique — hors connaissance du rôle). Aucune exigence `NON-COMPLIANT` ni
`TEST GAP`.

## Version et SHA documentés

```yaml
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Rôle : sepp67.grav_site
Run CI observé pour ce tag : 33888725974 — 8 jobs, tous success, 7m35s (2026-09-04)
Ansible-core requis (meta/main.yml, requirements-test.txt) : >=2.17,<2.18
Ansible-core réellement disponible dans l'environnement d'audit : 2.17.14
community.docker requis (requirements.yml) : >=5.0.0,<6.0.0
community.docker réellement disponible dans l'environnement d'audit : 5.2.1
Combinaison testée par le mainteneur (commentaire requirements.yml) : community.docker 5.2.1 / ansible-core 2.17.14 — identique à l'environnement d'audit
```

## Historique des mises à jour de cette rubrique

| Date | Lot | Changement |
|---|---|---|
| 2026-09-12 | Lot 4 | Rédaction initiale, à partir d'un worktree Git détaché sur le tag `v2.0.0` |
| 2026-09-12 | Lot 4.1 | Lecture complète de `docs/MIGRATION.md`, `docs/CONFORMITE-REQ.md`, `docs/TEST-RESULTS.md`, `playbooks/check.yml`, des configurations Molecule et de `Makefile`/`requirements.yml` ; exécution réelle de 7 tests statiques et de `ansible-lint`/`--syntax-check`/`ansible-inventory` (voir [Tests et CI](../08.tests-et-ci)) ; correction de la chronologie de la garde administrateur et de la chaîne causale de `grav_digest` (voir [Flux chronologique](../04.flux-chronologique)) |

## Limites connues (reprises du README, `docs/MIGRATION.md`, `docs/CONFORMITE-REQ.md`)

- Installation de Docker limitée à Debian/Ubuntu (Bullseye retirée des
  plateformes officielles en v2.0.0 — reste possible techniquement via
  `grav_manage_docker: false`, mais ni testée ni garantie).
- Aucune authentification registre (`docker login` non implémenté) —
  l'image doit être publique.
- `grav_bind_address` : IPv4 uniquement en v2.0.0 (REQ-017), IPv6 refusée
  avec un message explicite — réexamen possible en 2.1.0 avec
  `ansible.utils` + `netaddr`.
- Couverture Molecule multi-distribution limitée à `install` (3
  plateformes) ; `deploy`/`digest`/`pull`/`multi_instance` : Debian 12
  uniquement.
- `T13` "IPv4 LAN" exercé sur l'IP d'un conteneur de bac à sable, pas une
  IPv4 de réseau physique.
- **Tags `v1.0.0`/`v1.0.1`** : antérieurs à la refonte `2.0.0`, à ne
  **jamais** utiliser comme cible pour un profil écrit pour `2.0.0`
  (`docs/MIGRATION.md` §13) — un profil `1.x` doit suivre le guide de
  migration avant de passer à `v2.0.0`.

## Limites propres à cette rubrique (constatées pendant l'audit)

- Les fichiers `verify.yml` de chaque scénario Molecule (autres que
  `install`) n'ont pas été lus ligne à ligne — seuls `molecule.yml`,
  `converge.yml` et (pour `deploy`) `prepare.yml` l'ont été.
- Les fichiers `tests/_*.yml` (helpers partagés entre plusieurs tests
  statiques) n'ont pas été lus individuellement.
- Molecule lui-même n'a pas pu être exécuté (non installé dans
  l'environnement d'audit, et l'installer aurait été une modification
  durable hors périmètre) ; les tests fonctionnels nécessitant un
  déploiement Docker réel (`test.yml`, `test_env_encoding.yml`,
  `test_standalone.yml`) n'ont pas été rejoués — voir [Tests et
  CI](../08.tests-et-ci) pour le détail exact et les raisons précises.

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Dernière vérification : 2026-09-12
```
