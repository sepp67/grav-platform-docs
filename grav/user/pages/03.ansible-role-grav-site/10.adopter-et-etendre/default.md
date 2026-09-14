---
title: "Adopter et étendre"
template: docs
taxonomy:
    category: [docs]
---

## 1. Prérequis

Ansible-core `>=2.17,<2.18`, la collection `community.docker`
(`>=5.0.0,<6.0.0`), les privilèges root sur la cible (`become: true`), un
plugin Docker Compose supportant `env_file: format: raw`.

## 2. Exemple minimal (mode cible)

```yaml
# requirements.yml du dépôt appelant
roles:
  - name: grav_site
    src: git+https://github.com/sepp67/ansible-role-grav-site.git
    version: "v2.0.0"
```

```yaml
# playbook du dépôt appelant
- hosts: grav_servers
  become: true
  roles:
    - role: grav_site
      vars:
        grav_image: "ghcr.io/sepp67/projet-gites"
        grav_version: "1.0.7"
        grav_bind_address: "192.168.1.10"
```

Repris quasiment à l'identique de `examples/site.yml.example` de ce dépôt.
`name: grav_site` ci-dessus est un **alias local** choisi par l'appelant ;
le nom réellement **installé** par `ansible-galaxy` (dérivé de
`meta/main.yml` : `namespace: sepp67`, `role_name: grav_site`) est
`sepp67.grav_site` — c'est ce nom que `docs/MIGRATION.md` §13 recommande
d'utiliser directement dans les rôles (`roles: [sepp67.grav_site]`), sans
alias, pour éviter toute ambiguïté.

**Ne jamais cibler `v1.0.0` ou `v1.0.1`** avec un profil écrit pour
`2.0.0` : ces tags sont antérieurs à la refonte et n'ont pas le même
contrat d'interface (`grav_bind_address` optionnel, pas de
`grav_digest`, etc.) — suivre `docs/MIGRATION.md` avant de monter en
version.

## 3. Validation locale

`make preflight ARGS="-i <inventaire> --ask-vault-pass"` avant tout
déploiement réel — sept vérifications en lecture seule (voir [Exploitation
et diagnostic](../09.exploitation-et-diagnostic)). En amont, un
`ansible-playbook --syntax-check -i <inventaire> playbooks/deploy.yml`
(ou `check.yml`/`restart.yml`/`stop.yml`) valide la syntaxe sans toucher
à la cible — **exécuté réellement pendant le Lot 4.1** sur les 4
playbooks de ce dépôt, tous valides. `playbooks/check.yml` lui-même sert
de "syntax/état" en continu : il rejoue `tasks/assert.yml` puis
`tasks/healthcheck.yml` du rôle (`include_role` + `tasks_from`, aucune
tâche réimplémentée) sur une instance déjà déployée, sans aucune mutation.

## 4. Personnalisation autorisée

- Toutes les variables de [Configuration et
  interfaces](../06.configuration-et-interfaces) : image, version, digest,
  réseau, healthcheck, secrets, GID du conteneur.
- Ajustement du timing (`grav_healthcheck_*`, `grav_deploy_wait_*`,
  `grav_site_check_*`) sans reconstruire l'image.

## 5. Détails internes à ne pas dépendre

- Les registres `_grav_*` de `vars/main.yml` — internes, non destinés à
  être lus ou surchargés par un dépôt appelant.
- L'ordre exact des fichiers de tâches importés par `tasks/main.yml` —
  documenté ici pour comprendre le comportement, pas comme une interface
  stable au sens contractuel (seules les variables publiques le sont,
  README "Utilisation comme rôle réutilisable").
- Le format interne de `.deployed_state.yml` — "purement documentaire :
  ne pilote aucune logique du rôle" (commentaire de `tasks/version.yml`).

## 6. Comportements configurables

`grav_manage_docker` (installer ou seulement vérifier Docker),
`grav_force_pull` (politique de pull), `grav_admin_type` (arbre de
permissions du compte bootstrapé), `grav_extra_environment` (échappatoire
vers de futures variables `grav-runtime`).

## 7. Intégration à la plateforme

Ce rôle est déjà conçu pour être consommé par un orchestrateur de parc (le
futur `grav-sites-ops`) sans aucune modification : c'est exactement le mode
cible documenté ci-dessus. Voir [Architecture globale — Responsabilités et
frontières](../../01.architecture-globale/02.responsabilites-et-frontieres)
pour la table de traduction registre déclaratif → variables publiques de ce
rôle.

## 8. Exploitation

Voir [Exploitation et diagnostic](../09.exploitation-et-diagnostic).

## 9. Mise à jour

Changer `grav_version` (et éventuellement `grav_digest`) puis rejouer le
rôle — aucune autre action requise. Le rôle ne compare pas la chronologie
des versions : il applique l'état demandé, quel qu'il soit. Une mise à
jour "derrière un digest identique" (ex. `1.0.7` → `1.0.8`, même
`sha256`) actualise quand même `declared_version` et ajoute une ligne au
journal — c'est l'état contractuel qui est comparé, pas seulement la
référence Docker (voir [Flux chronologique](../04.flux-chronologique),
"Chaîne causale de `grav_digest`").

## 10. Rollback — distinct d'une restauration

Remettre l'ancienne valeur de `grav_version`/`grav_digest`, rejouer le
rôle : techniquement le **même mécanisme** qu'une mise à jour, dans
l'autre sens. Le rôle garantit uniquement le retour de l'**image** et de
sa configuration de déploiement (Compose, `grav.env`). **Il ne restaure
aucune donnée** : les volumes persistants restent en l'état ; si la
version antérieure est incompatible avec des données écrites par la
version plus récente, le comportement n'est pas garanti (README
"Rollback (manuel — n'est pas une restauration)"). Une restauration
complète (image + configuration + sauvegarde des volumes) est une
opération distincte, hors du rôle — voir [Données, secrets et
persistance](../07.donnees-secrets-persistance).

## 11. Limites

- Docker installable automatiquement sur Debian/Ubuntu uniquement ;
  x86_64/aarch64 uniquement.
- Aucune authentification registre : l'image doit être publique.
- IPv4 uniquement pour `grav_bind_address` en v2.0.0.
- Les 5 variables de répertoire dérivées restent surchargeables mais sont
  dépréciées (retrait prévu v3.0.0).
- Ne pas cibler les tags `v1.0.0`/`v1.0.1` avec un profil `2.0.0` (voir
  §2 ci-dessus et [Référence](../11.reference)).

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : README.md ("Utilisation comme rôle réutilisable", "Préflight"), examples/site.yml.example, docs/MIGRATION.md (§13), playbooks/check.yml, meta/main.yml
Dernière vérification : 2026-09-12
```
