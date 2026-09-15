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

Cette rubrique fige son périmètre sur le tag Git publié **`v1.1.0`**
(commit `7309bd1968c1f9a4ede93098d624cea46243aa0b`), jamais sur « la
branche `main` actuelle » :

```yaml
Tag publié : v1.1.0
Commit du tag : 7309bd1968c1f9a4ede93098d624cea46243aa0b
Image publiée : ghcr.io/sepp67/projet-gites:1.1.0
Digest OCI (index) : sha256:bc68dd751a2d3154a8cd27788111d3d7d4ff9fd2a4174b882a77f1cb5e24eb34
```

Toute affirmation de cette rubrique vaut pour ce tag exact — voir
`docs/documentation-sources.yml` pour le détail du périmètre lu et la
correspondance vérifiée entre le commit Git et l'image publiée.

**SEC-GITES-001 : corrigé et publié.** L'audit initial (Lot 7, commit
`b27d7af`) avait confirmé un constat de sécurité sur le routage du
formulaire de contact. Il a depuis été corrigé (sélection visible et
obligatoire, résolue exclusivement côté serveur) et publié dans ce même
tag `v1.1.0` — fiche de synthèse, chronologie complète de la correction et
statut détaillé dans [Référence](11.reference). Les écarts de version
constatés lors de l'audit initial (`grav-runtime`, `ansible-role-grav-site`)
sont également résolus dans ce tag ; une dette purement documentaire,
sans effet de sécurité, subsiste dans deux fichiers du dépôt — voir
[Référence](11.reference).

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
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b)
Dernière vérification : 2026-09-15
Méthode : worktrees Git détachés (dépôt source jamais modifié) ; image
  publiée vérifiée directement sur GHCR (digest, étiquette de révision)
```
