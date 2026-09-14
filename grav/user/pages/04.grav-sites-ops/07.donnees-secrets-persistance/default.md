---
title: "Données, secrets et persistance"
template: docs
taxonomy:
    category: [docs]
---

## Ce dépôt ne détient aucune donnée persistante applicative

`grav-sites-ops` ne stocke ni contenu Grav, ni compte utilisateur métier,
ni fichier de site. Il déclare seulement des **références** vers des
états désirés ; les données persistantes vivent sur la VM cible, gérées
par le rôle (voir Lot 4).

## Le registre (`grav_sites`) : non secret, mais structurant

Champs obligatoires (`docs/REGISTRY-SCHEMA.md`) : `project_name`,
`image` (sans tag ni digest), `version` (jamais `latest`), `digest`
(`sha256:<64 hex>` ou vide), `container_name`, `base_directory`,
`bind_address` (IPv4 littérale), `http_port`. Champs optionnels : `state`,
`force_pull`, `manage_docker`, `site_check_path`, `extra_environment`.

Contraintes d'unicité vérifiées statiquement (`GSO-REQ-050`) :
`project_name`, `container_name`, `base_directory`, le couple
`(bind_address, http_port)`, et la correspondance exacte
registre ↔ hôtes de l'inventaire, avec disjonction stricte vis-à-vis de
`retired_grav_sites` (`GSO-REQ-052`).

**Absent délibérément du registre** : la version de `grav-runtime` (elle
est transitive, portée par l'image applicative — `GSO-REQ-011`/`155`), le
tag de l'image (seule la référence sans tag est stockée), tout secret, et
la variable de sélection de cible (`SITE` est un paramètre de commande,
jamais une donnée persistée).

## Le vault : un seul vault opérationnel global

`GSO-REQ-022` : un vault global unique, jamais un vault par site. Jamais
lu, copié ou déchiffré par la CI (`GSO-REQ-024`) — vérifié statiquement
par grep sur `.github/workflows/ci.yml` (aucune commande `ansible-vault`,
aucune variable d'environnement contenant un mot de passe de vault).

`.gitignore` exclut tout fichier de vault réel ; seul
`inventories/example/group_vars/all/vault.yml.example` est explicitement
réintroduit — un exemple non chiffré, aux valeurs synthétiques
(`GSO-REQ-098`).

Structure : `vault_grav_sites` (sites actifs) et
`vault_retired_grav_sites` (sites retirés), à **clés mutuellement
exclusives** (`GSO-REQ-073`) — un hôte ne peut jamais apparaître dans les
deux à la fois.

### Bootstrap administrateur : tri-état

`admin_user`/`admin_password`/`admin_email` doivent être **soit les trois
présents, soit les trois absents** (`GSO-REQ-062`) — jamais un
sous-ensemble, pour éviter un bootstrap partiel silencieusement incomplet.
Champs optionnels associés : `admin_fullname`, `admin_title`,
`admin_language`, `admin_type`. Ces champs ne vivent **que** dans le
vault (`GSO-REQ-203`/`024`) — leur présence dans le registre en clair est
un cas d'échec statique détecté par `gso_validate.py`.

### Secrets applicatifs : forme fermée

Chaque secret est `{name, content}` **uniquement** — la forme `src`
(référence à un fichier externe) est explicitement interdite
(`GSO-REQ-203`). `name` doit correspondre à
`^[A-Za-z0-9][A-Za-z0-9._-]*$`.

### Non-divulgation

Les validateurs (`gso_validate.py`) n'affichent jamais de valeur, y
compris en cas d'échec : seuls des noms de clés et des verdicts
apparaissent dans leurs sorties. Les tests utilisent des marqueurs
synthétiques du type `EXAMPLE-NOT-A-REAL-SECRET…`, jamais une valeur
plausible.

## Retrait / réactivation : déplacement, jamais duplication

Le retrait déplace l'entrée vault d'un site de `vault_grav_sites` vers
`vault_retired_grav_sites` (jamais une copie qui laisserait le secret
actif dans les deux dicts à la fois — cohérent avec la disjonction
`GSO-REQ-073`).

## Les deux registres de cycle de vie (documentaires)

| Fichier | Racine | Auto-chargé par Ansible ? | Contenu |
|---|---|---|---|
| `registry/retired-sites.yml` | `retired_grav_sites` | non | fiches de retrait, jamais un champ `status`, jamais `reactivated` |
| `registry/reactivated-sites.yml` | `reactivated_sites` | non | liste append-only d'événements, chacun référence son retrait via `previous_retirement` |

Une fiche de retrait obligatoire comprend : `project_name`,
`retired_at` (date ISO), `former_inventory_host`,
`former_ansible_host`, `former_base_directory`, `container_name`,
`last_deployment.{image,version,digest}`,
`preservation.{vm_status,vm_preserved,persistent_data_preserved,secrets_archived_in_vault}`,
`reason`.

**Append-only, à deux niveaux de preuve** :
- état courant : `gso_lifecycle.py --reactivated` valide la forme du
  fichier tel qu'il est aujourd'hui ;
- **inter-version** (la seule preuve qui démontre réellement l'absence de
  réécriture) : `scripts/lifecycle-history-check.sh` — seul endroit du
  dépôt qui invoque Git — extrait chaque paire de versions consécutives du
  fichier (`git log`, `git show`) et les fournit comme deux fichiers
  ordinaires à `gso_lifecycle.py --history-before`, qui les compare sans
  jamais consulter Git lui-même.

Ces deux registres ne sont **jamais** lus par un playbook Ansible comme
variables (`grep` confirmé sur `playbooks/`) — ce sont des artefacts de
gouvernance, validés a posteriori, jamais consommés en exécution.

## Persistance : ce que ce dépôt ne restaure jamais

Un `stop` ou un `rollback` d'image ne touche jamais les données
persistantes de la VM. `docs/OPERATIONS.md` le formule explicitement :
« Le rollback logiciel rétablit une version déclarée de l'image. Les
données persistantes restent dans leur état courant. Une restauration de
contenu constitue une opération différente, hors du rollback applicatif
automatique. » — voir [Exploitation et diagnostic](../09.exploitation-et-diagnostic).

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : docs/REGISTRY-SCHEMA.md, docs/VAULT-SCHEMA.md, docs/LIFECYCLE-SCHEMA.md, scripts/lib/gso_validate.py
Dernière vérification : 2026-09-14
```
