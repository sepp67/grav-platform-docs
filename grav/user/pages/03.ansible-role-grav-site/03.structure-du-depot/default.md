---
title: "Structure du dépôt"
template: docs
taxonomy:
    category: [docs]
---

## Arborescence au tag `v2.0.0`

```text
.
├── defaults/main.yml           variables publiques et leurs valeurs par défaut
├── vars/main.yml                dérivés internes _grav_* (référence effective, hôte de contrôle)
├── meta/main.yml                galaxy_info (rôle "grav_site", namespace sepp67, plateformes)
├── tasks/
│   ├── main.yml                 orchestre l'ensemble — voir Flux chronologique
│   ├── assert.yml                validation complète des variables
│   ├── admin_guard.yml           garde administrateur avant mutation
│   ├── docker.yml                installation Docker (si grav_manage_docker)
│   ├── verify_docker.yml         vérification Docker (sinon)
│   ├── directories.yml           répertoires persistants
│   ├── secrets.yml               fichiers secrets
│   ├── deploy.yml                rendu Compose/env, (dé)marrage du conteneur
│   ├── healthcheck.yml           attente santé Docker + contrôle HTTP + diagnostic
│   ├── clear_failure_diagnostic.yml  nettoyage du diagnostic d'échec au retour au vert
│   ├── verify_admin_account.yml  vérification post-démarrage du compte
│   └── version.yml               traçabilité (.deployed_state.yml, .deployed_version, journal)
├── templates/
│   ├── docker-compose.yml.j2     Compose générique, générié
│   ├── grav.env.j2                variables d'environnement du conteneur
│   └── deployed_state.yml.j2      état de déploiement structuré
├── playbooks/                    couche autonome : deploy.yml, check.yml, restart.yml, stop.yml
├── inventories/example/          inventaire d'exemple, non opérationnel (IP RFC 5737)
├── examples/                     exemple de consommation en mode cible
├── ansible.cfg, Makefile          couche autonome (résolution de rôle, points d'entrée)
├── tests/                         tests statiques et fonctionnels (Docker requis pour certains)
├── molecule/                      scénarios Molecule (install, deploy, digest, multi_instance, pull)
├── docs/
│   ├── MIGRATION.md               ruptures v1.0.1 → v2.0.0
│   ├── CONFORMITE-REQ.md          conformité exigence par exigence
│   └── TEST-RESULTS.md            résultats T01-T23
├── CHANGELOG.md
└── .github/workflows/ci.yml       lint, static-checks, test, 5 jobs Molecule
```

Chaque fichier de `tasks/` et `templates/` est repris en détail dans
[Sections de code](../05.sections-de-code).

## Deux couches dans un seul dépôt

Ce dépôt **est** le rôle (`tasks/`, `defaults/`, `templates/`, `meta/` à sa
racine) et fournit *en plus* une couche d'exploitation autonome
(`playbooks/`, `Makefile`, `inventories/example/`). `ansible.cfg` ne
définit `roles_path` que pour un éventuel rôle tiers ajouté via
`requirements.yml` — il n'intervient jamais dans la résolution de ce rôle
lui-même, qui se fait par chemin relatif (`{{ playbook_dir }}/..`).

## Aucun contenu métier

Vérifié par lecture directe : aucun thème, plugin, page ou média n'est
présent dans ce dépôt. Les seules données applicatives visibles sont des
exemples explicitement fictifs (`inventories/example/`, adresses RFC 5737
non routables ; `examples/site.yml.example`, non exécutable tel quel).

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : git ls-tree -r v2.0.0, README.md ("Résolution du rôle")
Dernière vérification : 2026-09-12
```
