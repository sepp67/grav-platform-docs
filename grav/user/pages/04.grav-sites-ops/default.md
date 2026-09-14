---
title: "grav-sites-ops"
template: chapter
taxonomy:
    category: [docs]
---

`grav-sites-ops` est le dépôt d'**orchestration** qui décrit l'état désiré
d'un parc de sites Grav et invoque, pour chaque machine explicitement
sélectionnée, le rôle atomique [`ansible-role-grav-site`](../03.ansible-role-grav-site)
(`sepp67.grav_site`). Cette rubrique documente le dépôt figé au tag `v1.0.0`
(commit `48b9a59b956f73f10e5602b72a222dd71b4a3f3a`) — voir
`docs/documentation-sources.yml`.

**Écart connu, documenté dès cette page** : le README, `CHANGELOG.md` et
`docs/ACCEPTANCE.md` de ce tag affirment encore que « le tag `v1.0.0` est
prévu, non créé ». Ce tag **existe** pourtant, localement et sur le dépôt
distant, et pointe exactement sur ce commit. Le détail de cet écart —
comment un tag peut exister tout en étant décrit comme absent par le
contenu du commit qu'il désigne — est expliqué en
[Référence](11.reference).

Parcours de lecture recommandé :

1. [Vue d'ensemble](01.vue-ensemble) — responsabilité unique, ce que ce
   dépôt ne fait jamais.
2. [Place dans l'architecture](02.place-dans-architecture) — dépendance
   unique vers le rôle, frontières avec `grav-runtime`, les images
   applicatives et le `control-repository`.
3. [Structure du dépôt](03.structure-du-depot) — arborescence figée au tag.
4. [Flux chronologique](04.flux-chronologique) — cinq chronologies
   distinctes : validation d'une cible, mutation d'un site, contrôle d'un
   site, contrôle du parc, cycle de vie documentaire.
5. [Sections de code](05.sections-de-code) — chaque unité de
   responsabilité en détail, avec preuve.
6. [Configuration et interfaces](06.configuration-et-interfaces) —
   registre, vault, traduction vers l'interface publique du rôle.
7. [Données, secrets et persistance](07.donnees-secrets-persistance) —
   registre non secret, vault, registres de cycle de vie.
8. [Tests et CI](08.tests-et-ci) — 24 `GSO-T*` + tests non numérotés,
   CI à 6 jobs ; ce qui a été réellement exécuté pour cette rubrique.
9. [Exploitation et diagnostic](09.exploitation-et-diagnostic) — commandes
   `make`, contrôle de dérive, diagnostic par symptôme.
10. [Adopter et étendre](10.adopter-et-etendre) — ajouter un site au parc,
    migration depuis un ancien profil.
11. [Référence](11.reference) — glossaire, index, chronologie de la
    release, limites connues.

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Dernière vérification : 2026-09-14 (Lot 5.1)
Méthode : worktree Git détaché sur le tag (dépôt source non modifié)
```
