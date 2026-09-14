---
title: "Place dans l'architecture"
template: docs
taxonomy:
    category: [docs]
---

## En amont

Rien, au sens d'une dépendance de construction : `grav-sites-ops` ne
construit ni ne consomme aucune image. Sa seule dépendance **déclarée**
est le rôle `sepp67.grav_site`, épinglé par tag Git dans `requirements.yml`
(`version: "v2.0.0"`) — exactement le même tag audité au [Lot
4](../../03.ansible-role-grav-site).

## En aval

Une VM cible du réseau local, atteinte **uniquement** via l'invocation du
rôle. Le `control-repository` (reverse proxy, TLS, DNS) n'est ni en amont
ni en aval : il est **parallèle**, sans aucune relation Ansible, Git ou CI
avec ce dépôt.

## Chaîne de dépendance complète

```text
grav-runtime  →  projet-gites | projet-lavallee  →  ansible-role-grav-site  →  VM cible
                                                          ▲
                                                          │  requirements.yml (tag épinglé v2.0.0)
                                                   grav-sites-ops
```

`grav-sites-ops` ne connaît que l'**interface publique** du rôle (ses
variables `grav_*`). Il ne connaît ni `grav-runtime`, ni les images
applicatives, ni la manière dont le rôle les consomme.

## Ce que ce dépôt ne fait jamais (rappel `docs/ARCHITECTURE.md`)

- construire, tester ou publier une image (`grav-runtime`, `projet-*`) ;
- provisionner une VM ;
- reproduire la logique interne du rôle ;
- orchestrer un service autre que Grav ;
- dépendre du `control-repository`.

## Frontières inter-dépôts

| Dépôt | Relation | Interdits |
|---|---|---|
| `ansible-role-grav-site` | consommé via `requirements.yml` (tag `v2.0.0`) | modification depuis ce dépôt |
| `grav-runtime`, `projet-*` | fournissent les images référencées dans le registre — **jamais nommées ici autrement que par leur référence d'image** | build/publish ici |
| `control-repository` | **aucune** | dépendance Ansible/Git/CI/exécution, sous quelque forme |

Cette absence de dépendance vers `grav-runtime` et les dépôts applicatifs
n'est pas qu'une déclaration : le registre `grav_sites.yml` ne contient
jamais de version de `grav-runtime` (elle est **transitive**, portée par
l'image applicative — voir [Configuration et
interfaces](../06.configuration-et-interfaces)), et un garde-fou statique
(`GSO-T23`) recherche activement toute référence au `control-repository`
dans le code, les inventaires et la CI.

## Frontière LAN / exposition Internet

`grav-sites-ops` déploie des instances **joignables sur le réseau local**
(`bind_address` IPv4 du registre). Il ne configure ni reverse proxy, ni
TLS, ni DNS : l'exposition publique d'un site est une décision et une
opération **séparées**, portées par le `control-repository`, jamais
déclenchées par ce dépôt (`GSO-REQ-183` : « le cycle de vie local d'un
site et son exposition publique DOIVENT rester deux décisions
opérationnelles distinctes »).

## Tableau des contrats d'interface

| Interface | Producteur | Consommateur | Donnée échangée | Garantie | Hors contrat |
|---|---|---|---|---|---|
| Version du rôle | `ansible-role-grav-site` (tag Git) | `grav-sites-ops` | `requirements.yml` : `sepp67.grav_site`, `version: "v2.0.0"` | toujours un tag explicite, jamais une branche flottante | contenu interne du rôle |
| Traduction registre → rôle | `grav-sites-ops` (`playbooks/_shared/translate.yml`) | `sepp67.grav_site` | variables `grav_*` (voir [Configuration et interfaces](../06.configuration-et-interfaces)) | traduction fermée, aucune valeur globale, aucun repli | logique de déploiement elle-même |
| Invocation du rôle | `grav-sites-ops` | `sepp67.grav_site` | `include_role: sepp67.grav_site`, exactement une fois par mutation | sélecteur + verrou + préflight déjà passés | tâches internes du rôle |
| Déploiement | `sepp67.grav_site` | VM cible | conteneur Docker, fichiers de traçabilité | contrat du rôle (voir Lot 4) | reverse proxy, TLS, DNS |
| Exposition | VM cible | `control-repository` (parallèle) | adresse/port bind local | aucune — relation manuelle, hors automatisation | tout déclenchement automatique depuis `grav-sites-ops` |

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : docs/ARCHITECTURE.md, docs/GOVERNANCE.md, requirements.yml, tests/gso-t23-no-control-repository.sh
Dernière vérification : 2026-09-14
```
