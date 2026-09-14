---
title: "Configuration et interfaces"
template: docs
taxonomy:
    category: [docs]
---

## Trois sources, jamais confondues

| Source | Fichier(s) | Contenu | Chargement |
|---|---|---|---|
| Inventaire | `inventories/<contexte>/hosts.yml` | groupe `grav_servers`, `ansible_host` par entrée | Ansible, standard |
| Registre | `grav_sites` (group_vars) | état désiré non secret par site | Ansible, standard (`group_vars`/`host_vars`) |
| Vault | `vault_grav_sites` (chiffré) | bootstrap admin + secrets applicatifs par site | Ansible Vault, jamais ouvert par la CI |

`inventories/example/` est un jeu **entièrement fictif** (réseau
TEST-NET-1 `192.0.2.0/24`, RFC 5737) — jamais une valeur à réutiliser en
production.

## Table de traduction registre + vault → interface du rôle

Source exacte : `playbooks/_shared/translate.yml`, lu en intégralité.

| Donnée GSO | Source | Validation | Variable transmise au rôle | Sensible | Chargement |
|---|---|---|---|---|---|
| Intention d'action | `_gso_intent` (fixée par le playbook appelant) | `assert` : `deploy`\|`restart`\|`stop` | — (pilote `grav_state`, non transmise telle quelle) | non | fixée en dur par le playbook |
| Image | `grav_sites[hôte].image` | `gso_validate.py` (sans tag/digest) | `grav_image` | non | registre |
| Version | `grav_sites[hôte].version` | non vide, jamais `latest` | `grav_version` | non | registre |
| Digest | `grav_sites[hôte].digest` | `sha256:<64 hex>` ou vide | `grav_digest` | non | registre (`default('')`) |
| Nom du conteneur | `grav_sites[hôte].container_name` | unicité (`GSO-REQ-050`) | `grav_container_name` | non | registre |
| Répertoire de base | `grav_sites[hôte].base_directory` | hors répertoires utilisateur, unicité | `grav_base_directory` | non | registre |
| Adresse de liaison | `grav_sites[hôte].bind_address` | IPv4 littérale (`GSO-REQ-065`) | `grav_bind_address` | non | registre |
| Port HTTP | `grav_sites[hôte].http_port` | plage valide, unicité du couple (adresse,port) | `grav_http_port` | non | registre (`\| int`) |
| État désiré | calculé | — | `grav_state` | non | **valeur calculée**, jamais copiée telle quelle : `restarted` si intention `restart`, `stopped` si `stop`, sinon `grav_sites[hôte].state \| default('started')` |
| Pull forcé | `grav_sites[hôte].force_pull` | optionnel, booléen | `grav_force_pull` | non | registre (`default(false)`) |
| Gestion Docker | `grav_sites[hôte].manage_docker` | optionnel, booléen | `grav_manage_docker` | non | registre (`default(true)`) |
| Chemin de contrôle applicatif | `grav_sites[hôte].site_check_path` | optionnel | `grav_site_check_path` | non | registre (`default('/')`) |
| Environnement additionnel | `grav_sites[hôte].extra_environment` | optionnel, dict | `grav_extra_environment` | non | registre (`default({})`) |
| Identifiant admin | `vault_grav_sites[hôte].admin_user` | tri-état (les 3 présents ou absents) | `grav_admin_user` | **oui** | vault (`no_log: true`) |
| Mot de passe admin | `vault_grav_sites[hôte].admin_password` | tri-état | `grav_admin_password` | **oui** | vault (`no_log: true`) |
| E-mail admin | `vault_grav_sites[hôte].admin_email` | tri-état | `grav_admin_email` | **oui** | vault (`no_log: true`) |
| Nom complet / titre / langue / type admin | `vault_grav_sites[hôte].admin_{fullname,title,language,type}` | optionnels | `grav_admin_{fullname,title,language,type}` | **oui** | vault (`no_log: true`) |
| Secrets applicatifs | `vault_grav_sites[hôte].secrets[]` | forme `name`+`content` uniquement, nom conforme à la regex | `grav_secrets` | **oui** | vault (`no_log: true`) |

**Paramètres internes non transmis au rôle** : `_gso_intent` lui-même
(consommé uniquement pour calculer `grav_state`), et toute clé du
registre ou du vault absente de la liste `translate.yml` — la traduction
est **fermée** : aucune variable `grav_*` n'est produite en dehors de
cette liste exhaustive, et aucune valeur globale ni repli implicite n'est
introduit hors des `default(...)` explicitement listés ci-dessus.

Aucune valeur d'exemple issue de `inventories/example/` n'est reproduite
ici — cette table documente des **noms de champs et des règles**, jamais
une valeur opérationnelle réelle ni même une valeur d'exemple concrète.

## Interface publique consommée : `sepp67.grav_site`

`grav-sites-ops` ne connaît que les noms de variables `grav_*` ci-dessus
et le comportement documenté du rôle (Lot 4). Il ne connaît ni les noms
de tâches internes du rôle, ni sa structure de fichiers, ni son
`molecule/`.

## `ansible.cfg`

```ini
roles_path = ./roles
collections_path = ./collections
```

Aucun inventaire par défaut n'est déclaré, et `[inventory]
unparsed_is_failed` n'est délibérément **pas** activé — un commentaire du
fichier explique ce choix (permettre un inventaire vide sans échec bloquant
dans certains contextes de test).

## `requirements.yml`

```yaml
roles:
  - name: sepp67.grav_site
    src: git+https://github.com/sepp67/ansible-role-grav-site.git
    version: "v2.0.0"
collections:
  - name: community.docker
    version: ">=5.0.0,<6.0.0"
```

Le rôle est épinglé par **tag Git explicite**, jamais une branche — le
même tag `v2.0.0` documenté au [Lot 4](../../03.ansible-role-grav-site).

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : playbooks/_shared/translate.yml, ansible.cfg, requirements.yml, docs/REGISTRY-SCHEMA.md, docs/VAULT-SCHEMA.md
Dernière vérification : 2026-09-14
```
