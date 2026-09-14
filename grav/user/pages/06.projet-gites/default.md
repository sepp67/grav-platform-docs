---
title: "projet-gites"
template: chapter
taxonomy:
    category: [docs]
---

`projet-gites` est la couche **applicative** du site de location de gîtes :
thème `gites-theme` (hérité de `quark2`), deux plugins métier (`contact`,
`calendrier-disponibilites`), configuration non secrète et contenu initial
pour deux gîtes, construits sur l'image générique
[`grav-runtime`](../02.grav-runtime). C'est la première application
concrète de cette architecture (`projet-lavallee-website` en est la
seconde), déjà citée en référence dans le [contrat d'architecture
globale](../01.architecture-globale) et dans la rubrique
[projet-lavallee-website](../05.projet-lavallee-website).

**Ce dépôt ne possède aucun tag applicatif** au moment de cet audit. Cette
rubrique fige donc son périmètre sur un **commit précis**, jamais sur « la
branche `main` actuelle » :

```yaml
Branche informative : main
Commit documenté : b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
```

Toute affirmation de cette rubrique vaut pour ce commit exact — voir
`docs/documentation-sources.yml` pour le détail du périmètre lu.

**Écart notable, documenté dès cette page** : la documentation propre de ce
dépôt (`docs/compatibility-policy.md`) certifie explicitement
`grav-runtime 1.0.2` comme seule version compatible connue — mais le
`Dockerfile` du même commit référence `grav-runtime:1.0.4`. Cet écart entre
la matrice de compatibilité déclarée et le code réel est documenté en
détail dans [Référence](11.reference).

Parcours de lecture recommandé :

1. [Vue d'ensemble](01.vue-ensemble) — responsabilité unique, comparaison
   rapide avec `projet-lavallee-website`.
2. [Place dans l'architecture](02.place-dans-architecture) — dépendance
   vers `grav-runtime`, héritage `quark2`, frontière avec
   `ansible-role-grav-site`.
3. [Structure du dépôt](03.structure-du-depot) — arborescence au commit
   audité, six fichiers de documentation interne.
4. [Flux chronologique](04.flux-chronologique) — cinq chronologies :
   construction de l'image, premier démarrage, redémarrage/mise à jour,
   parcours d'un visiteur, développement/test/publication.
5. [Sections de code](05.sections-de-code) — plugin `contact`, plugin
   `calendrier-disponibilites` (trois classes), thème, avec preuve.
6. [Configuration et interfaces](06.configuration-et-interfaces) —
   `system.yaml`, `site.yaml`, plugin Email, taxonomie photos.
7. [Données, secrets et persistance](07.donnees-secrets-persistance) —
   matrice de classification des fichiers.
8. [Tests et CI](08.tests-et-ci) — six scripts de test (dont
   `test-secrets.sh` et `test-update-rollback.sh`, absents de
   `projet-lavallee-website`), exécutés réellement pendant ce lot.
9. [Exploitation et diagnostic](09.exploitation-et-diagnostic) — build,
   démarrage, mise à jour/rollback, diagnostic par symptôme.
10. [Adopter et étendre](10.adopter-et-etendre) — développement local,
    certification de compatibilité, cycle de vie du contenu initial.
11. [Référence](11.reference) — audit du routage du formulaire, inventaire
    éditorial, audit des données personnelles, écarts constatés.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e (branche main, aucun tag applicatif)
Dernière vérification : 2026-09-14
Méthode : worktree Git détaché sur le commit (dépôt source non modifié)
```
