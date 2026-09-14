---
title: "Tests et CI"
template: docs
taxonomy:
    category: [docs]
---

## Commandes réellement exécutées pour cette rubrique

Dans le worktree détaché sur `v1.0.0`, sans installer de paquet système,
sans contacter de VM réelle :

```text
$ ansible --version           # confirmation : ansible-core 2.17.14 déjà présent
$ ansible-lint --version      # 26.4.0
$ yamllint --version          # 1.38.0
$ python3 -c "import yaml"    # PyYAML déjà présent
$ export GIT_PAGER=cat PAGER=cat
$ make test-reproducible < /dev/null
```

Résultat réel obtenu (35 tests, aucun échec) :

```text
========================================
Total : 35   Reussis : 35   Echecs : 0
NON EXECUTE (test fonctionnel local) : gso-t15-real-deploy — `make test-functional`
Tous les tests executes sont au vert.
```

`make test-functional` (GSO-T15, déploiement Docker réel) n'a **pas** été
exécuté pour ce lot : il exige un conteneur Docker éphémère et l'image
épinglée `ghcr.io/sepp67/grav-runtime:1.0.4`. Le [Lot 4](../../03.ansible-role-grav-site)
a déjà produit une preuve de démarrage fonctionnel équivalente sur la
même chaîne rôle+image ; relancer un déploiement Docker local ici
n'apportait pas d'information nouvelle au regard de l'effort, et
« ne contacte aucune VM réelle » laissait la question ouverte pour un
conteneur local — le choix a été de ne pas le lancer et de le déclarer
explicitement comme non exécuté plutôt que de laisser un doute.

## Discipline de preuve

Quatre statuts distincts sont utilisés dans ce document, jamais confondus :
**lu dans le code** (le fichier existe, son contenu a été lu), **test
présent** (le script de test existe dans `tests/`), **test exécuté par
moi** (résultat ci-dessus, sur ce tag, dans ce worktree), **rapporté par
`docs/TEST-RESULTS.md`** (résultat déclaré par les auteurs du dépôt, sur
un commit antérieur ou identique — voir écart en [Référence](../11.reference)).

## Matrice des tests et garanties

| Garantie | Test | Type | Exécuté localement (par moi) | CI observée | Limite |
|---|---|---|---|---|---|
| Registre valide (champs, unicité, disjonction retirés) | GSO-T06, T07 | statique | ✅ (`make test-reproducible`) | job `static` | aucune |
| Vault valide (correspondance, tri-état, forme secrets) | GSO-T07, T13 | statique + rôle-doublure | ✅ | job `translate` | doublure de rôle, pas le vrai rôle |
| Sélecteur fermé (8 règles) | GSO-T01, T02, plusieurs `gso-t*` dédiés | statique | ✅ | job `static` | — |
| Aucune dépendance vers control-repository | GSO-T23 | statique (grep ciblé) | ✅ | job `static` | ne détecte que les formes de référence prévues par le test |
| Aucune référence à grav-runtime/images dans le registre | GSO-T24 | statique | ✅ | job `static` | — |
| Traduction fermée registre+vault → `grav_*` | GSO-T13, T14, T16 | rôle-doublure (`spy-role`) | ✅ | job `translate` | observe la sortie de la traduction, ne déploie rien |
| Verrouillage de concurrence (flock, code 75) | `l4-concurrency-lock` | dynamique (subshells réels) | ✅ | job `translate` | pas de vraie exécution Ansible concurrente longue |
| Contrat CI fonctionnel documenté | `l4-ci-functional-contract` | documentaire/statique | ✅ | job `functional-contract` | vérifie la présence/cohérence du contrat, pas une exécution réelle |
| `restart`/`stop` ne mutent ni version ni digest ni fichier persistant | `l5-restart-stop` | rôle-doublure | ✅ | job `translate` | idem — observation de `grav_*` produits, pas de VM |
| Action fermée (une seule intention à la fois) | `l5-action-closed` | statique + doublure | ✅ | job `translate` | — |
| Classification de dérive (8 catégories) | GSO-T19, T20 | unitaire pur (`gso_classify.py`) | ✅ | job `drift` | fonction pure — ne teste pas la collecte `observe.yml` elle-même en conditions réelles |
| Non-destruction du rollback (pas de suppression de volume) | `l7-persistence-guard` | statique | ✅ | job `static` | garde documentaire/textuel, pas une preuve d'exécution d'un vrai rollback |
| Append-only inter-version des registres de cycle de vie | `l8-history-append-only` | dynamique (Git réel, `fetch-depth: 0` en CI) | ✅ | job `static` | dépend de l'historique Git disponible localement (non superficiel — vérifié) |
| Garde de migration documentaire | `l9-migration-doc-guard` | statique + fixtures synthétiques | ✅ | job `static` | vérifie la documentation et l'absence de script de migration, ne migre rien réellement |
| Mode `--check` non probant seul | `l10-check-mode` | statique/documentaire | ✅ | job `static` | — |
| Isolation multi-site de `check-all` | `l10-multisite-isolation` | statique | ✅ | job `static` | — |
| Nettoyage / non-persistance des tests | `l10-cleanup` | statique | ✅ | job `static` | — |
| CI bloquante (gate) | `l10-ci-blocking` | statique (inspection du YAML de la CI) | ✅ | job `static` | vérifie la déclaration, pas un vrai run bloqué observé par moi |
| Gardes d'acceptation (licence, SPDX, copyright) | `l11-acceptance-guards` | statique | ✅ | job `static` | — |
| Matrice de conformité cohérente (204 exigences) | `make matrix-check` | statique (génération + diff textuel) | ✅ (+ régénération manuelle dans un worktree séparé, Lot 5.1) | job `static` | vérifie la **cohérence interne** dépôt↔matrice, jamais que les 204 exigences ont été testées dynamiquement — voir analyse détaillée ci-dessous |
| Rôle réellement installable (`ansible-galaxy`) | GSO-T03 | dynamique, nécessite le rôle | non exécuté isolément (installation du rôle nécessaire à `run-all.sh`, faite automatiquement) | job `role` | pas revérifié séparément — recouvert par l'exécution globale |
| Déploiement fonctionnel réel (conteneur Docker + rôle + image épinglée) | **GSO-T15** | fonctionnel, nécessite Docker + image | ❌ non exécuté (voir ci-dessus) | **absent de la CI** (délibérément, par conception) | seule preuve dans `docs/TEST-RESULTS.md`, sur un commit antérieur au tag (voir [Référence](../11.reference)) |

## `docs/COMPLIANCE-MATRIX.md` : analyse complète (Lot 5.1, 257 lignes lues intégralement)

**Nombre exact d'exigences et méthode de comptage** : 204 lignes
`| GSO-REQ-NNN | ... |`, numérotées en continu de `GSO-REQ-001` à
`GSO-REQ-204`, sans trou ni doublon (vérifié par lecture séquentielle
complète, pas seulement par le total annoncé). Ce compte est **structurel** :
il correspond exactement au nombre de clés du dictionnaire `LOT` que le
générateur construit depuis `_LOTS` (12 lots, `L0` à `L11`) — la matrice
ne peut pas contenir un nombre différent sans que le code source du
générateur change en même temps.

**Répartition des cinq statuts**, comptée directement dans le fichier :

| Statut | Nombre |
|---|---|
| Satisfait et testé | 138 |
| Satisfait | 15 |
| Établi / documenté | 47 |
| Partiel | 2 |
| Non encore démontré (L11) | 2 |
| **Total** | **204** |

Les 2 « Non encore démontré » sont `GSO-REQ-158` (tag sur un SHA à CI
globale verte — voir l'écart de tag en [Référence](../11.reference)) et
`GSO-REQ-188` (migration réelle) — cohérent avec les deux domaines
« BLOCKED » de `docs/ACCEPTANCE.md`.

**Absence d'exigence orpheline / de doublon** : chaque numéro de `_LOTS`
a une entrée dans `ENTRY` (sauf le repli générique documenté dans le
code, qui ne s'active pour aucun numéro réel au tag audité) ; aucun
numéro n'apparaît dans deux lots à la fois (vérifié par la construction
même de `LOT`, qui est un dictionnaire — une seconde affectation à la
même clé écraserait silencieusement la première, ce qui n'est structurellement
pas le cas ici puisque `_LOTS` répartit les 204 numéros sans
chevauchement).

**Correspondance avec le contrat architectural** : les intitulés de la
colonne « Intitulé » proviennent d'une extraction par expression régulière
de `docs/CONTRAT-ARCHITECTURAL.md` — un intitulé absent du contrat
casserait `_titles()` avec une clé manquante. Le contrat lui-même n'a été
lu qu'au travers de cette extraction et de citations ponctuelles dans
d'autres documents (`docs/GOVERNANCE.md`, `docs/ACCEPTANCE.md`) — il n'a
**pas** été lu intégralement pour ce lot ; cette limite reste assumée.

**Distinction documentaire / statique / fonctionnelle** : les 138 lignes
« Satisfait et testé » citent un ou plusieurs identifiants `GSO-T*`/`l*-*`
— mais, comme détaillé en [Sections de code](../05.sections-de-code), cette
citation est une **table tenue à la main**, jamais vérifiée
automatiquement contre l'existence réelle du test cité. Les 47 lignes
« Établi / documenté » pointent vers un fichier `docs/*.md` — une preuve
purement textuelle. Les 15 « Satisfait » et 2 « Partiel » couvrent des
mécanismes jugés démontrés indirectement ou incomplètement. **Aucune de
ces 204 lignes ne constitue, à elle seule, la preuve qu'un test a été
exécuté** — seule l'exécution réelle rapportée dans `docs/TEST-RESULTS.md`
ou observée directement par ce Lot (§08, tableau ci-dessus) en fait foi.

**Commit/date de référence** : le fichier ne porte pas sa propre date ;
son contenu est cohérent avec le commit `48b9a59b` (204 exigences,
statuts `GSO-REQ-158`/`188` encore « Non encore démontré », `main =
d69a05a poussé` cité dans la synthèse — une référence à un commit
**antérieur** au commit du tag lui-même, cohérent avec le constat déjà
fait en [Référence](../11.reference) que plusieurs documents du tag ont été
rédigés avant sa finalisation).

**Cohérence avec `docs/TEST-RESULTS.md` et `docs/ACCEPTANCE.md`** : les
quatre verdicts séparés (construction acceptée / publication effectuée /
release bloquée / migration bloquée) sont cohérents entre les trois
documents — aucune fusion de périmètres observée. Aucun placeholder
n'apparaît dans `COMPLIANCE-MATRIX.md` lui-même (contrairement à
`docs/TEST-RESULTS.md`, qui porte un espace réservé non rempli pour le
run CI du HEAD définitif — voir [Référence](../11.reference)).

### Résultat de `make matrix-check` (Lot 5.1)

Commande exécutée, depuis le worktree détaché sur `v1.0.0` :

```text
$ python3 scripts/lib/gso_compliance.py --check
OK    docs/COMPLIANCE-MATRIX.md : 204 exigences, à jour
$ echo "exit: $?"
exit: 0
```

Le worktree est resté propre après cette commande (`git status
--porcelain` vide) : `--check` ne modifie rien, conformément à sa
définition dans le code.

Pour tester la **génération** (`make matrix`, mutante par nature), un
**second worktree temporaire séparé** a été créé sur le même tag
(`git worktree add --detach … v1.0.0`), afin de ne jamais risquer d'écrire
dans le worktree d'audit principal ni dans le dépôt source :

```text
$ python3 scripts/lib/gso_compliance.py > /tmp/.../matrix-generated.md
$ diff -u docs/COMPLIANCE-MATRIX.md /tmp/.../matrix-generated.md
$ echo "diff exit: $?"
diff exit: 0
```

**Diff obtenu** : vide — la matrice régénérée est **byte pour byte**
identique au fichier commité. Ce worktree temporaire a ensuite été
supprimé (`git worktree remove --force`), et le dépôt source `6-grav-sites-ops`
vérifié inchangé (seul le changement `.gitignore` préexistant, sans
rapport, subsiste).

**Conclusion permise** : au tag `v1.0.0`, le générateur est déterministe
et son résultat correspond exactement au fichier commité — la matrice
n'a pas dérivé de son générateur.

**Conclusion que ce contrôle ne permet PAS de tirer** : que les 204
exigences ont été testées dynamiquement, que chaque preuve citée dans
`ENTRY` correspond à un test qui existe réellement et qui a été exécuté
récemment, ou que la matrice reflète un état plus récent que le commit du
tag — ces trois questions relèvent d'une lecture séparée du code des
tests eux-mêmes (faite pour un échantillon, voir [Sections de
code](../05.sections-de-code)), jamais de `make matrix`/`matrix-check` seuls.

## CI : six jobs, un seul gate

`.github/workflows/ci.yml` (165 lignes, lu en intégralité) :

| Job | Contenu | Dépend de |
|---|---|---|
| `static` | 24 étapes nommées : GSO-T01/T02/T04-T12/T23/T24, `l7-persistence-guard`, GSO-T21/T22, `l8-history-append-only`, `make lint-lifecycle`, `l9-migration-doc-guard`, `l10-*` (4 étapes), `make matrix-check`, `l11-acceptance-guards` | — |
| `role` | GSO-T03 uniquement | — |
| `translate` | GSO-T13/T14/T16, `l4-concurrency-lock`, `l5-restart-stop`, `l5-action-closed`, GSO-T17/T18 | — |
| `drift` | GSO-T19, T20 | — |
| `functional-contract` | `l4-ci-functional-contract` (aucune installation de rôle nécessaire) | — |
| `conformance` | message de succès uniquement | `static`, `role`, `translate`, `drift`, `functional-contract` |

`GSO-T15` est **délibérément absent** de la CI (un commentaire du fichier
l'explique : il exige une image Docker réelle non disponible dans le
contexte CI standard du dépôt) — son exécution reste une obligation
**locale**, documentée comme condition de release (`docs/TESTING.md` :
« GSO-T15 doit être vert avant toute future autorisation de release »).

Le checkout du job `static` utilise `fetch-depth: 0` spécifiquement pour
que `l8-history-append-only` dispose de l'historique Git complet.

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : .github/workflows/ci.yml, docs/TESTING.md, docs/TEST-RESULTS.md, tests/run-all.sh,
  scripts/lib/gso_compliance.py (lu intégralement), docs/COMPLIANCE-MATRIX.md (lu intégralement, 257 lignes)
Dernière vérification : 2026-09-14 (Lot 5.1)
```
