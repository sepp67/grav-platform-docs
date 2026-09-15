---
title: "Tests et CI"
template: docs
taxonomy:
    category: [docs]
---

## Discipline de preuve

Distinction maintenue tout au long de cette page : **test présent dans le
dépôt**, **test réellement exécuté pendant ce lot**, **build réellement
exécuté**, **démarrage réellement exécuté**, **test de persistance
réellement exécuté**, **formulaire réellement soumis**, **routage vers
chaque propriétaire réellement testé**, **workflow lu**, **run CI observé
en direct** (deux runs identifiés par leur numéro exact, voir plus bas),
**comportement seulement déduit**.

## Commandes réellement exécutées pour cette rubrique

Lot 7 (commit `b27d7af`) puis Lot 9 (tag `v1.1.0`, commit `7309bd1`) :
worktrees Git détachés, aucun paquet système installé, aucune VM
contactée, ports dynamiques dédiés sans conflit avec un éventuel
`projet-gites-dev` (vérifié absent à chaque fois) :

```text
$ sh tests/run-all.sh
```

Résultat réel obtenu au tag `v1.1.0` — **8/8 tests du dépôt réussis** :

```text
test-build.sh                  → [PASS] docker build réussi
test-startup.sh                → conteneur healthy ; / → HTTP 200 (pas de redirection de langue)
test-app-presence.sh           → thème + quark2 + plugins métier présents ; seed appliqué ;
                                  « Nos gîtes » présent dans le rendu ; /gites/gite-un, /gites/gite-deux,
                                  /contact → 200 ; photo-1.jpg → 200 ; /admin → 200
test-contact-routing.sh        → 60 assertions nommées : routage nominal vers chaque propriétaire
                                  synthétique, option générale explicite, 11 entrées invalides rejetées,
                                  nonce/honeypot/CRLF rejetés, réservation de l'identifiant général et
                                  collisions exclues (ordre normal et inversé, triplet), éligibilité
                                  approfondie, adresses invalides, matrice XSS/CRLF détaillée — 0 e-mail
                                  envoyé sur chaque cas de rejet
test-contact-routing-cleanup.sh → 5 cas de non-régression du nettoyage de fichiers temporaires,
                                  sans conteneur Docker
test-secrets.sh                → sentinelle de fixture absente (filesystem final ET historique des
                                  couches) ; hôte SMTP historique absent ; aucun compte baké ;
                                  4 scénarios email-private.php (absent/valide/invalide/syntax-error) —
                                  le cas syntax-error produit bien HTTP 500, comme documenté
test-persistence.sh            → 4 marqueurs survivent à un redémarrage
test-update-rollback.sh        → mise à jour A→B : données intactes, nouveau code actif ;
                                  rollback B→A : données intactes, ancien code réactivé
Tous les tests ont réussi.
```

**Rejoué une seconde fois directement contre l'image réellement publiée**
(`ghcr.io/sepp67/projet-gites:1.1.0`, tirée de GHCR — pas une
reconstruction locale) pour `test-contact-routing.sh` et
`test-secrets.sh` : mêmes résultats, réussis.

**Historique — audit du routage du formulaire (Lot 7, avant correction)** :
non couvert par les tests du dépôt à l'époque (ceux-ci ne vérifiaient que
la présence du formulaire, jamais une soumission) — conteneur jetable et
SMTP factice sur un réseau dédié, avec des comptes Grav **synthétiques**,
jamais des comptes ni des adresses réels. Ce contrôle avait confirmé le
constat **SEC-GITES-001**, depuis corrigé et couvert par
`test-contact-routing.sh` lui-même. Fiche de synthèse, chronologie
complète de la correction et statut en [Référence](../11.reference) —
procédure de reproduction et preuves détaillées du constat d'origine
restent conservées dans un rapport de sécurité séparé, hors de ce dépôt
documentaire public.

## Matrice des tests et garanties

| Garantie | Test | Type | Exécuté réellement (par moi) | CI observée | Limite |
|---|---|---|---|---|---|
| Build reproductible | `test-build.sh` | dynamique, Docker | ✅ | ✅ verte (runs de fusion et de publication, voir ci-dessous) | 3 tentatives avec délai |
| Démarrage, healthy, HTTP 200 | `test-startup.sh` | dynamique, Docker | ✅ | ✅ | conteneur jetable sans volume |
| Présence applicative (thème + parent, plugins, seed, routes, media, admin) | `test-app-presence.sh` | dynamique, Docker | ✅ | ✅ | vérifie la présence du formulaire, **pas** une soumission réelle |
| Routage du formulaire, sécurité, collisions (60 assertions) | `test-contact-routing.sh` | dynamique, Docker + Mailpit jetable | ✅ — deux fois (source reconstruite, puis image publiée) | ✅ | environnement jetable, comptes/pages synthétiques uniquement |
| Nettoyage des fichiers temporaires du test précédent | `test-contact-routing-cleanup.sh` | rapide, sans Docker | ✅ | ✅ | — |
| Secrets (4 scénarios + filesystem final + historique des couches + logs) | `test-secrets.sh` | dynamique, Docker (export/save) | ✅ — deux fois (source, puis image publiée) | ✅ | recherche de motifs connus, pas une recherche exhaustive (limite assumée par `docs/testing.md`) |
| Persistance des 4 volumes après redémarrage | `test-persistence.sh` | dynamique, Docker Compose | ✅ | **non** — exclu de `ci.yml` | — |
| Mise à jour et rollback (A→B→A) | `test-update-rollback.sh` | dynamique, Docker Compose, build d'une image B temporaire | ✅ | **non** — exclu de `ci.yml` | l'image B est un marqueur CSS ajouté, pas un vrai changement fonctionnel |
| Validation de cohérence des dates (`date_arrivee`/`date_depart`) | intégrée à `test-contact-routing.sh` | dynamique | ✅ | ✅ | un seul cas testé (dates inversées) |

## CI : deux workflows, jamais le même déclencheur — runs réellement observés

`.github/workflows/ci.yml` (lu intégralement) — job unique `test`,
exécute **5 des 8** scripts (`build`, `startup`, `app-presence`,
`contact-routing`, `contact-routing-cleanup`, `secrets`) sur tout
push/PR — `persistence` et `update-rollback` restent réservés à une
exécution manuelle avant release (`docs/testing.md`).

`.github/workflows/release.yml` (lu intégralement) — déclenché
**uniquement** par un tag SemVer ou un déclenchement manuel, même
structure que `projet-lavallee-website` (tags OCI via
`docker/metadata-action`, `latest` conditionné au tag — jamais à
recommander en déploiement).

**Runs CI distants réellement observés pour ce lot** (`gh run view`,
identifiants exacts) :

| Run | Déclencheur | Commit | Résultat |
|---|---|---|---|
| `34949874668` | push sur `main` (fusion) | `c052f21` | ✅ succès — les 5 étapes rapides, dont `test-contact-routing.sh` et son nettoyage |
| `34950442842` | push du tag `v1.1.0` (« Build and publish projet-gites ») | `7309bd1` | ✅ succès — image poussée sur GHCR |

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b)
Fichiers principaux : tests/*.sh, docs/testing.md, .github/workflows/{ci,release}.yml
Dernière vérification : 2026-09-15
```
