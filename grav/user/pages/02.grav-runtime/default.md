---
title: "grav-runtime"
template: chapter
taxonomy:
    category: [docs]
---

`grav-runtime` est le socle Docker générique sur lequel toutes les images
applicatives de la plateforme sont construites (voir [Architecture
globale](../01.architecture-globale)). Cette rubrique documente le
dépôt figé au tag `v1.0.4` (commit `e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4`)
— pas la branche `main`, qui lui est postérieure de 9 commits (voir
`docs/documentation-sources.yml`).

Parcours de lecture recommandé :

1. [Vue d'ensemble](01.vue-ensemble) — quel problème ce dépôt résout, ce
   qu'il refuse de faire.
2. [Place dans l'architecture](02.place-dans-architecture) — ce qui est en
   amont et en aval, les contrats d'interface.
3. [Structure du dépôt](03.structure-du-depot) — arborescence figée au tag.
4. [Flux chronologique](04.flux-chronologique) — sommaire opérationnel :
   construction de l'image, puis démarrage du conteneur.
5. [Sections de code](05.sections-de-code) — chaque unité de
   responsabilité en détail, avec preuve.
6. [Configuration et interfaces](06.configuration-et-interfaces) —
   arguments de build, variables d'environnement.
7. [Données, secrets et persistance](07.donnees-secrets-persistance) —
   ce qui est immuable, persistant, ou jamais versionné.
8. [Tests et CI](08.tests-et-ci) — ce qui est documenté, ce qui est
   automatisé, ce qui a été réellement exécuté pour cette rubrique.
9. [Exploitation et diagnostic](09.exploitation-et-diagnostic) — commandes
   et arbre de diagnostic par symptôme.
10. [Adopter et étendre](10.adopter-et-etendre) — créer une image
    applicative fille.
11. [Référence](11.reference) — glossaire, index, limites connues.

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Dernière vérification : 2026-09-12
Méthode : worktree Git détaché sur le tag (dépôt source non modifié)
```
