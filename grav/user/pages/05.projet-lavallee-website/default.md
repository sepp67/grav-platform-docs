---
title: "projet-lavallee-website"
template: chapter
taxonomy:
    category: [docs]
---

`projet-lavallee-website` est la couche **applicative** du site lavallee.tech :
thème `lavallee-theme`, contenu trilingue (FR/DE/EN), plugin `contact` et
configuration non secrète, construits sur l'image générique
[`grav-runtime`](../02.grav-runtime). C'est la deuxième application concrète
de la même architecture que `projet-gites`, documentée à titre de référence
dans le [contrat d'architecture globale](../01.architecture-globale).

**Ce dépôt ne possède aucun tag applicatif** au moment de cet audit. Cette
rubrique fige donc son périmètre sur un **commit précis**, jamais sur « la
branche `main` actuelle » :

```yaml
Branche informative : main
Commit documenté : c4341ca77270565969e1e801e11a8fda72e5b402
```

Toute affirmation de cette rubrique vaut pour ce commit exact — voir
`docs/documentation-sources.yml` pour le détail du périmètre lu.

Parcours de lecture recommandé :

1. [Vue d'ensemble](01.vue-ensemble) — responsabilité unique, ce que ce
   dépôt ne fait jamais.
2. [Place dans l'architecture](02.place-dans-architecture) — dépendance
   vers `grav-runtime`, frontière avec `ansible-role-grav-site`.
3. [Structure du dépôt](03.structure-du-depot) — arborescence au commit
   audité.
4. [Flux chronologique](04.flux-chronologique) — cinq chronologies
   distinctes : construction de l'image, premier démarrage, redémarrage,
   soumission du formulaire, développement et publication.
5. [Sections de code](05.sections-de-code) — thème, plugin `contact`,
   templates, avec preuve.
6. [Configuration et interfaces](06.configuration-et-interfaces) —
   `system.yaml`, `site.yaml`, plugin Email, langues.
7. [Données, secrets et persistance](07.donnees-secrets-persistance) —
   matrice de classification des fichiers.
8. [Tests et CI](08.tests-et-ci) — tests exécutés réellement pendant ce
   Lot, y compris une soumission réelle du formulaire via un SMTP factice.
9. [Exploitation et diagnostic](09.exploitation-et-diagnostic) — build,
   démarrage, diagnostic par symptôme.
10. [Adopter et étendre](10.adopter-et-etendre) — développement local,
    contrat de déploiement, responsabilités exclues.
11. [Référence](11.reference) — inventaire éditorial multilingue, écarts
    constatés, limites de preuve.

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402 (branche main, aucun tag applicatif)
Dernière vérification : 2026-09-14
Méthode : worktree Git détaché sur le commit (dépôt source non modifié)
```
