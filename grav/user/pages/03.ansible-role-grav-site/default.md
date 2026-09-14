---
title: "ansible-role-grav-site"
template: chapter
taxonomy:
    category: [docs]
---

`ansible-role-grav-site` (`sepp67.grav_site`) est le rôle Ansible atomique
qui déploie **exactement une instance Grav par invocation**, à partir d'une
image applicative dérivée de [`grav-runtime`](../02.grav-runtime). Cette
rubrique documente le dépôt figé au tag `v2.0.0` (commit
`1339e50bc20257fbb9f21953995c08262ae3043e`) — voir
`docs/documentation-sources.yml`.

Parcours de lecture recommandé :

1. [Vue d'ensemble](01.vue-ensemble) — responsabilité unique, ce que le
   rôle refuse de faire.
2. [Place dans l'architecture](02.place-dans-architecture) — les deux
   modes d'utilisation, contrats d'interface.
3. [Structure du dépôt](03.structure-du-depot) — arborescence figée au tag.
4. [Flux chronologique](04.flux-chronologique) — sommaire opérationnel
   complet, de `tasks/main.yml` à la traçabilité écrite sur l'hôte.
5. [Sections de code](05.sections-de-code) — chaque unité de
   responsabilité en détail, avec preuve.
6. [Configuration et interfaces](06.configuration-et-interfaces) —
   variables publiques, registres internes `_grav_*`.
7. [Données, secrets et persistance](07.donnees-secrets-persistance) —
   répertoires persistants, secrets, traçabilité.
8. [Tests et CI](08.tests-et-ci) — tests statiques, fonctionnels, Molecule ;
   ce qui a été réellement exécuté pour cette rubrique.
9. [Exploitation et diagnostic](09.exploitation-et-diagnostic) — commandes
   et diagnostic par symptôme, `.last_failure.log`.
10. [Adopter et étendre](10.adopter-et-etendre) — consommer le rôle depuis
    un autre dépôt Ansible.
11. [Référence](11.reference) — glossaire, index, limites connues.

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Rôle : sepp67.grav_site
Dernière vérification : 2026-09-12
Méthode : worktree Git détaché sur le tag (dépôt source non modifié)
```
