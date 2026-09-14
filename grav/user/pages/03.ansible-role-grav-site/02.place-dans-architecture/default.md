---
title: "Place dans l'architecture"
template: docs
taxonomy:
    category: [docs]
---

## En amont

- Une image applicative déjà **publiée** sur un registre (GHCR ou autre),
  dérivée de `grav-runtime` — le rôle ne construit jamais cette image, il
  ne fait que la référencer (`grav_image`, `grav_version`, `grav_digest`).
- `community.docker` (`>=5.0.0,<6.0.0`) et Ansible-core (`>=2.17,<2.18`) —
  dépendances techniques, déclarées dans `requirements.yml` et
  `meta/main.yml`.

## En aval

Une VM cible (Debian/Ubuntu si `grav_manage_docker: true`, tout OS avec
Docker déjà installé sinon). Le futur `grav-sites-ops` consomme ce rôle en
mode cible ; le `control-repository` (reverse proxy, TLS, DNS) reste
**parallèle**, jamais appelé par ce rôle.

## Deux façons d'utiliser ce dépôt

### Mode cible (rôle réutilisable)

Consommé par un dépôt Ansible tiers via `requirements.yml`, épinglé sur un
tag Git :

```yaml
roles:
  - name: grav_site
    src: git+https://github.com/sepp67/ansible-role-grav-site.git
    version: "v2.0.0"
```

Le dépôt appelant fournit l'inventaire, les valeurs propres au site et à
la VM, et les secrets. Il **ne dépend jamais de l'arborescence interne**
de ce rôle (README "Utilisation comme rôle réutilisable").

### Mode autonome

Ce dépôt fournit, depuis sa propre racine, une couche d'exploitation
générique (`ansible.cfg`, `playbooks/`, `Makefile`,
`inventories/example/`) qui **appelle ce même rôle**, sans dupliquer sa
logique — `playbooks/deploy.yml` référence le rôle par chemin relatif
(`{{ playbook_dir }}/..`), jamais par son nom, ce qui fonctionne quel que
soit le nom du dossier de clonage. Aucune VM n'est ciblée par défaut : un
inventaire explicite est toujours requis.

**Les deux modes exécutent exactement la même séquence de tâches** — voir
[Flux chronologique](../04.flux-chronologique). Aucune branche de code ne
distingue "mode autonome" de "mode cible" à l'intérieur du rôle lui-même.

## Dépendances absentes mais souvent supposées

- **Pas de dépendance vers `grav-sites-ops`** : ce rôle n'a aucune
  connaissance d'un registre de sites ni d'une orchestration multi-VM. Un
  test dédié (`test_consume_via_requirements.yml`, T22) vérifie que le
  rôle reste consommable depuis un projet tiers sans rien connaître de
  lui.
- **Pas de dépendance vers `control-repository`** : un garde-fou CI
  (`.github/workflows/ci.yml`) recherche explicitement toute référence à
  `control-repo` ou à un chemin de développement local (`/home/...`) et
  fait échouer le build si trouvée.
- **Pas de choix de version de `grav-runtime`** : cette version est figée
  dans le `Dockerfile` de l'image applicative — le rôle ne la voit jamais.

## Tableau des contrats d'interface

| Interface | Producteur | Consommateur | Donnée échangée | Garantie | Hors contrat |
|---|---|---|---|---|---|
| Référence d'image | image applicative publiée (GHCR) | ce rôle | `grav_image`, `grav_version`, `grav_digest` (variables) | jamais construite localement ; jamais `latest` (refusé par `assert.yml`) | authentification registre (pas d'implémentation de `docker login`) |
| Invocation (mode cible) | dépôt appelant (futur `grav-sites-ops`) | ce rôle | variables publiques `grav_*`, tag Git épinglé (`requirements.yml`) | interface stable par version de tag ; aucune dépendance à l'arborescence interne | tâches internes, registres `_grav_*`, noms de fichiers de tâches |
| Contrat `grav-runtime` | `grav-runtime` (image) | ce rôle | port `80/tcp`, `HEALTHCHECK` natif `/healthz`, comportement tri-state du bootstrap admin, 4 répertoires persistants | le rôle s'appuie sur ce contrat sans le remettre en cause | le rôle ne réimplémente jamais l'entrypoint ni le bootstrap |
| Déploiement | ce rôle | VM cible | conteneur Docker, fichiers de traçabilité, secrets déposés | idempotence, non-écrasement des volumes persistants, garde admin avant mutation | reverse proxy, TLS, DNS, pare-feu |
| Exposition | VM cible | `control-repository` (parallèle) | adresse/port bind local (`grav_bind_address`, `grav_http_port`) | aucune — relation manuelle, hors automatisation | tout déclenchement automatique depuis ce rôle |

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : README.md, meta/main.yml, requirements.yml, tests/test_consume_via_requirements.yml
Dernière vérification : 2026-09-12
```
