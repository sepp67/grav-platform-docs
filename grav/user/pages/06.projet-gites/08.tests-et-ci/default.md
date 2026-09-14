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
chaque propriétaire réellement testé**, **workflow lu**, **run CI observé**
(aucun ici), **comportement seulement déduit**.

## Commandes réellement exécutées pour cette rubrique

Dans le worktree détaché sur le commit `b27d7af`, aucun paquet système
installé, aucune VM contactée, ports dynamiques (`18099`, `18030` pour
Mailpit) sans conflit avec les ports propres du dépôt (`18080`-`18083`) ni
avec un éventuel `projet-gites-dev` (vérifié absent pendant ce lot) :

```text
$ sh tests/run-all.sh
```

Résultat réel obtenu — **6/6 tests du dépôt réussis** :

```text
test-build.sh          → [PASS] docker build réussi
test-startup.sh        → conteneur healthy ; / → HTTP 200 (pas de redirection de langue)
test-app-presence.sh   → thème + quark2 + plugins métier présents ; seed appliqué ;
                          « Nos gîtes » présent dans le rendu ; /gites/gite-un, /gites/gite-deux,
                          /contact → 200 ; photo-1.jpg → 200 ; /admin → 200
test-secrets.sh        → sentinelle de fixture absente (filesystem final ET historique des
                          couches) ; hôte SMTP historique absent ; aucun compte baké ;
                          4 scénarios email-private.php (absent/valide/invalide/syntax-error) —
                          le cas syntax-error produit bien HTTP 500, comme documenté
test-persistence.sh    → 4 marqueurs survivent à un redémarrage
test-update-rollback.sh → mise à jour A→B : données intactes, nouveau code actif ;
                          rollback B→A : données intactes, ancien code réactivé
Tous les tests ont réussi.
```

**Audit du routage du formulaire**, non couvert par les tests du dépôt
lui-même (ceux-ci ne vérifient que la présence du formulaire, jamais une
soumission) — conteneur jetable et SMTP factice sur un réseau dédié, avec
des comptes Grav **synthétiques**, jamais des comptes ni des adresses
réels. Ce contrôle a confirmé un constat de sécurité, référencé
**SEC-GITES-001** : la résolution du destinataire suit une donnée
transmise par le client, pas la page réellement consultée. Fiche de
synthèse, portée exacte du constat et statut en [Référence](../11.reference)
— procédure de reproduction et preuves détaillées conservées dans un
rapport de sécurité séparé, hors de ce dépôt documentaire public.

## Matrice des tests et garanties

| Garantie | Test | Type | Exécuté réellement (par moi) | CI observée | Limite |
|---|---|---|---|---|---|
| Build reproductible | `test-build.sh` | dynamique, Docker | ✅ | job `test` de `ci.yml` (lu, non observé en exécution) | 3 tentatives avec délai |
| Démarrage, healthy, HTTP 200 | `test-startup.sh` | dynamique, Docker | ✅ | idem | conteneur jetable sans volume |
| Présence applicative (thème + parent, plugins, seed, routes, media, admin) | `test-app-presence.sh` | dynamique, Docker | ✅ | idem | vérifie la présence du formulaire, **pas** une soumission réelle |
| Secrets (4 scénarios + filesystem final + historique des couches + logs) | `test-secrets.sh` | dynamique, Docker (export/save) | ✅ | idem | recherche de motifs connus, pas une recherche exhaustive (limite assumée par `docs/testing.md`) |
| Persistance des 4 volumes après redémarrage | `test-persistence.sh` | dynamique, Docker Compose | ✅ | **non** — exclu de `ci.yml` | — |
| Mise à jour et rollback (A→B→A) | `test-update-rollback.sh` | dynamique, Docker Compose, build d'une image B temporaire | ✅ | **non** — exclu de `ci.yml` | l'image B est un marqueur CSS ajouté, pas un vrai changement fonctionnel |
| Routage du formulaire vers le bon propriétaire — cas nominal et falsifié | **aucun test dédié dans ce dépôt** | dynamique, Docker + Mailpit + comptes synthétiques, construit pour ce lot | ✅ (audit Lot 7 uniquement, hors suite du dépôt) | absent | ce dépôt ne couvre pas du tout ce scénario, y compris le cas nominal, par ses propres tests |
| Validation de cohérence des dates (`date_arrivee`/`date_depart`) | **aucun test dédié dans ce dépôt** | dynamique, construit pour ce lot | ✅ | absent | un seul cas testé (dates inversées) |

## CI : deux workflows, jamais le même déclencheur

`.github/workflows/ci.yml` (lu intégralement) — job unique `test`,
exécute **4 des 6** scripts (`build`, `startup`, `app-presence`,
`secrets`) sur tout push/PR — `persistence` et `update-rollback` restent
réservés à une exécution manuelle avant release (`docs/testing.md`), avec
une note explicite : « leur automatisation en CI est un raffinement
possible, non bloquant ».

`.github/workflows/release.yml` (lu intégralement) — déclenché
**uniquement** par un tag SemVer ou un déclenchement manuel, même
structure que `projet-lavallee-website` (tags OCI via
`docker/metadata-action`, `latest` conditionné au tag).

**Aucun run CI n'a été observé en direct** pour ce lot — toute affirmation
sur `ci.yml`/`release.yml` repose uniquement sur la lecture des fichiers
YAML.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : tests/*.sh, docs/testing.md, .github/workflows/{ci,release}.yml
Dernière vérification : 2026-09-14
```
