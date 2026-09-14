---
title: "Flux chronologique"
template: docs
taxonomy:
    category: [docs]
---

Ce dépôt n'a pas un seul flux d'exécution : il en a cinq, structurellement
différents. Les fusionner en une seule chronologie fabriquerait un ordre
qui n'existe dans aucun fichier. Chaque chronologie ci-dessous est
recalculée directement depuis le code du tag `v1.0.0` (playbooks, scripts,
`scripts/lib/*.py`), pas depuis les titres de section de `docs/OPERATIONS.md`.

## A. Validation d'une cible (`make validate SITE=<hôte>`)

Chemin : `scripts/validate-target.sh` → `gso_validate.py selector`.

| # | Étape | Fichier | Preuve |
|---|---|---|---|
| 1 | Entrée `make validate SITE=<hôte>` | `Makefile` | cible `validate` |
| 2 | Résolution du chemin racine/inventaire depuis l'emplacement **canonique** du script, jamais depuis le cwd | `gso_validate.py::repo_root()` | triple `os.path.dirname(os.path.realpath(__file__))` |
| 3 | `SITE` doit être défini, non vide | `gso_validate.py::validate_selector()` | étape 1 de l'algorithme |
| 4 | `SITE` doit correspondre à `^[a-z][a-z0-9-]*$` | idem | étape 2 |
| 5 | `SITE` ne doit **jamais** être un jeton global (`all`, `*`, `grav_servers`, `ungrouped`, `localhost`, `none`) | idem | étape 3, constante `GLOBAL_TOKENS` |
| 6 | `SITE` doit résoudre à **exactement un** hôte de `inventories/<contexte>/hosts.yml` | idem | étape 4 |
| 7 | Cohérence registre : présent dans `grav_sites`, absent de `retired_grav_sites` | idem | étape 5 |
| 8 | Cohérence vault, si le vault est résolvable localement | idem | étape 6 (dégradée proprement si le vault n'est pas fourni) |

**Premier contact réseau distant éventuel** : aucun à ce stade. Toute
cette chaîne est une validation **locale**, sans `ansible-playbook`, sans
`ssh`, sans `docker`. Le premier contact réseau possible n'intervient
qu'en aval, dans la chronologie B (étape 3b/4) ou C/D (sonde de
joignabilité). `validate` seul ne contacte jamais de machine.

**Refus vérifiés dans le code** (pas déduits du nom des tests) : une
cible absente, un jeton global, une cible qui résout plusieurs hôtes, une
cible retirée, sont chacun un chemin d'échec **distinct** dans
`validate_selector()`, chacun couvert par une entrée de `GSO-T*` dédiée
(voir [Tests et CI](../08.tests-et-ci)).

## B. Mutation d'un site (`deploy` | `restart` | `stop`)

Chemin : `scripts/{deploy,restart-site,stop-site}.sh` →
`scripts/lib/site-mutation.sh` → `playbooks/{deploy,restart,stop}-site.yml`
→ `_shared/mutate.yml` → `_shared/translate.yml` → `include_role`.

| # | Étape | Fichier | Détail vérifié |
|---|---|---|---|
| 1 | Entrée `make <cible> SITE=<hôte>` | `Makefile` | délègue au script `scripts/*.sh` |
| 2 | Sélecteur fermé (chronologie A entière, rejouée) | `site-mutation.sh` → `validate-target.sh` | échec = arrêt avant tout verrou |
| 3 | Acquisition du verrou de concurrence | `site-mutation.sh` | `exec 9>"$lock_base/${SITE}.lock"; flock -n 9 \|\| exit 75` |
| 4 | Invocation `ansible-playbook … --limit "$SITE"` sous le fd 9 encore ouvert | `site-mutation.sh` (`exec ansible-playbook …`) | le `exec` remplace le processus : le verrou est libéré par l'OS à la sortie du process ansible-playbook, quelle qu'en soit la cause |
| 5 | Assertion structurelle du playbook : un seul hôte, égal à `inventory_hostname`, jamais `all`/groupe/multiple | `_shared/mutate.yml` tâche 1 | `ansible.builtin.assert` |
| 6 | **Second préflight**, structurel, indépendant du premier (défense en profondeur) | `_shared/mutate.yml` tâche 2 → `gso_validate.py preflight` | `delegate_to: localhost`, `check_mode: false`, `no_log: true`, `failed_when: rc != 0` |
| 7 | Traduction fermée registre + vault → `grav_*` | `_shared/mutate.yml` tâche 3 → `_shared/translate.yml` | voir [Configuration et interfaces](../06.configuration-et-interfaces) pour la table complète |
| 8 | Invocation du rôle, exactement une fois | `_shared/mutate.yml` tâche 4 | `include_role: name: sepp67.grav_site` |
| 9 | Premier contact réseau réel avec la VM cible | **à l'intérieur du rôle** (hors périmètre de ce dépôt, voir Lot 4) | ce dépôt ne s'y substitue jamais |
| 10 | Libération du verrou | implicite, à la sortie du process `ansible-playbook` (étape 4) | pas une étape explicite du code — propriété du `exec` |
| 11 | Traitement de l'échec | `any_errors_fatal: true` sur les 3 playbooks de mutation | un échec à toute étape interrompt immédiatement ; le verrou est tout de même libéré par la sortie du process |

**Point de vigilance** : `stop` ne retire jamais un site du parc — il ne
fait que porter `grav_state: stopped` au rôle (voir [Vue
d'ensemble](../01.vue-ensemble), refus n°7, et [Adopter et
étendre](../10.adopter-et-etendre) pour la différence avec le retrait
documentaire).

**Vérification du verrou au niveau shell (Lot 5.1, relecture ligne à ligne
de `scripts/lib/site-mutation.sh`)** : le descripteur utilisé est le
numéro **9**, ouvert par `exec 9>"$lock_base/${SITE}.lock"` **dans le
processus bash de `site-mutation.sh` lui-même** (pas un sous-shell —
`exec N>fichier` sans commande modifie les descripteurs du shell
courant). L'acquisition (`flock -n 9`) a lieu **avant** tout lancement
d'`ansible-playbook`. Le processus qui hérite ensuite du descripteur est
`ansible-playbook` **lui-même** : `exec ansible-playbook …` (avec
commande, cette fois) remplace l'image du processus bash par celle
d'`ansible-playbook` **sans forker** — même PID, mêmes descripteurs de
fichier ouverts, fd 9 compris (bash n'positionne pas `close-on-exec` sur
un descripteur ouvert par une redirection numérotée manuelle). Le verrou
est donc tenu pendant **toute la durée d'exécution du playbook**, pas
seulement pendant l'acquisition. Sa libération est **implicite** : le
noyau ferme tous les descripteurs d'un processus qui se termine, quelle
que soit la cause (succès, échec, signal, `kill -9`) — aucun code de
nettoyage explicite n'existe ni n'est nécessaire. En cas d'échec de
l'acquisition (verrou déjà tenu par une autre exécution sur le même
site), le script sort en code **75** avant tout `ansible-playbook` — le
descripteur 9 reste ouvert (non acquis) mais se ferme normalement à la
sortie du script sans avoir jamais détenu le verrou. La formulation
« libération implicite par `exec` » est confirmée exacte par cette
relecture — elle n'est pas modifiée.

## C. Contrôle d'un site (`make check SITE=<hôte>`)

Chemin : `scripts/check-site.sh` → `scripts/lib/site-check.sh` →
`playbooks/check-site.yml` → `_shared/observe.yml`.

| # | Étape | Fichier | Détail vérifié |
|---|---|---|---|
| 1 | Sélecteur fermé (chronologie A, rejouée) | `site-check.sh` → `validate-target.sh` | identique à B, étape 2 |
| 2 | **Aucun verrou acquis** | `scripts/lib/site-check.sh` (lu en entier) | absence confirmée par lecture directe — pas d'appel `flock` sur ce chemin |
| 3 | `ansible-playbook check-site.yml --limit <hôte>` | `check-site.yml` | assertion : un seul hôte via `--limit` |
| 4 | Construction de l'état **désiré** | `_shared/observe.yml` | depuis `grav_sites[inventory_hostname]` (registre), aucune lecture VM |
| 5 | Sonde de joignabilité | idem | `ansible.builtin.raw: "true"`, `ignore_unreachable`/`ignore_errors` |
| 6 | Si joignable : collecte de l'état **appliqué** | idem | `slurp` de `.deployed_state.yml`, `stat` de `.last_failure.log` (existence/date seulement, jamais le contenu) |
| 7 | Collecte de l'état **réel** | idem | `docker inspect <container>` + `uri` GET sur le point de contrôle HTTP (statuts larges, jamais en échec de tâche) |
| 8 | Classification pure | `_shared/observe.yml` (pipe JSON) → `gso_classify.py` | `delegate_to: localhost`, fonction pure, toujours code retour 0 |
| 9 | Verdict et code de sortie | `check-site.yml` | `assert: _gso_verdict.category == 'IN_SYNC'` — un site non conforme fait échouer le playbook (code ≠ 0) |
| 10 | Aucune mutation | confirmé par lecture de `observe.yml` et `check-site.yml` en entier | aucune tâche `set_fact` sur `grav_*`, aucun `include_role`, aucun verrou |

## D. Contrôle du parc (`make check-all`)

Chemin : `scripts/check-all.sh` → `scripts/lib/site-check.sh
check-all.yml` → `playbooks/check-all.yml` → `_shared/observe.yml` par hôte.

| # | Étape | Fichier | Détail vérifié |
|---|---|---|---|
| 1 | Validation de cohérence déclarative du registre, **avant** tout contact VM | `scripts/lib/site-check.sh` → `gso_validate.py registry` | `--context production`, purement statique |
| 2 | `ansible-playbook check-all.yml` **sans** `--limit` restrictif | `check-all.yml` | assertion : absence de `--limit` restrictif (sélection = tous les hôtes actifs de l'inventaire) |
| 3 | `any_errors_fatal: false` | `check-all.yml` | un hôte en échec/injoignable n'arrête pas le parcours des autres |
| 4 | `_shared/observe.yml` rejoué **indépendamment** par hôte | `check-all.yml` | même logique que C, isolation native d'Ansible par hôte (pas de variable partagée entre hôtes) |
| 5 | Agrégation des non-conformités | `check-all.yml` | filtre Jinja sur `_gso_noncompliant`, `run_once: true` |
| 6 | Verdict global | idem | assertion finale sur l'ensemble agrégé |

**Isolation** : chaque contrôle d'hôte est indépendant (`observe.yml`
n'écrit aucune variable partagée entre hôtes ; les faits Ansible sont par
hôte par construction). **Comportement en cas d'échec d'un site** : il
est classé (`UNREACHABLE` ou une autre catégorie de dérive), compté dans
l'agrégat, mais ne stoppe pas le contrôle des autres sites —
`any_errors_fatal: false` en est la preuve directe.

## E. Cycle de vie documentaire (retrait / réactivation)

Chemin : **aucun playbook, aucun script d'action** — confirmé par lecture
intégrale de `playbooks/` et `scripts/` : rien n'écrit dans
`registry/retired-sites.yml` ni `registry/reactivated-sites.yml`. Ce sont
des opérations Git **manuelles**, uniquement validées a posteriori.

| # | Étape | Réalisée par | Fichier concerné |
|---|---|---|---|
| 1 | Site actif | opérateur (déjà dans `grav_sites`) | `registry/*.yml` (hors ce dépôt figé, dans l'inventaire réel) |
| 2 | Décision de retrait (hors dépôt) | opérateur | — |
| 3 | Retrait de l'entrée de `grav_sites` (édition manuelle + commit Git) | opérateur | registre actif |
| 4 | Ajout d'une fiche à `retired_grav_sites` (champs obligatoires, jamais de champ `status`) | opérateur | `registry/retired-sites.yml` |
| 5 | Déplacement de l'entrée vault correspondante vers `vault_retired_grav_sites` | opérateur | vault opérationnel (hors dépôt) |
| 6 | Validation a posteriori de la cohérence (disjonction registre actif / retiré, vault) | `gso_lifecycle.py`, `gso_validate.py` | lecture seule |
| 7 | Vérification append-only **inter-version** (jamais de réécriture d'une fiche existante) | `scripts/lifecycle-history-check.sh` → `gso_lifecycle.py --history-before` | le wrapper shell extrait chaque paire de versions consécutives du fichier via `git log`/`git show` et les passe à `gso_lifecycle.py` comme deux fichiers ordinaires ; `gso_lifecycle.py` lui-même ne consulte jamais Git — voir précision ci-dessous |
| 8 | (Éventuel) décision de réactivation (hors dépôt) | opérateur | — |
| 9 | Ajout d'un événement à `reactivated_sites` (jamais une modification de la fiche de retrait — `previous_retirement` la référence) | opérateur | `registry/reactivated-sites.yml` |
| 10 | Réintégration de l'entrée dans `grav_sites` (et vault) | opérateur | registre actif |

**Distinction essentielle** : ceci documente une **procédure**, pas une
automatisation. `grav-sites-ops` ne lit jamais `registry/*.yml` comme
variables Ansible (confirmé par grep sur `playbooks/` : aucune référence
à ces chemins). Les scripts `gso_lifecycle.py`/`lifecycle-history-check.sh`
**valident** une procédure déjà exécutée manuellement ; ils ne
l'exécutent jamais eux-mêmes, ne suppriment ni ne redéploient aucun site
(voir [Vue d'ensemble](../01.vue-ensemble), refus n°7-8, et
`docs/LIFECYCLE-SCHEMA.md`, section « Ce que le validateur ne fait
jamais » — confirmé par lecture intégrale du fichier au Lot 5.1, aucun
`open(..., 'w')`, aucun `subprocess`, aucune primitive Ansible).

**Précision sur l'étape 7 — qui consulte Git, et qui ne le fait pas**
(Lot 5.1) : `gso_lifecycle.py` ne lance lui-même **aucune** commande Git
ni aucun sous-processus (confirmé par lecture intégrale du fichier). Avec
`--history-before`, il reçoit un **chemin de fichier** représentant l'état
antérieur de `reactivated-sites.yml`, et sa fonction
`validate_append_only()` compare ce fichier déjà chargé à l'état courant
(`--reactivated`) : elle exige qu'une entrée historique préexistante reste
un **préfixe exact** de la nouvelle liste. C'est le **script appelant**,
`scripts/lifecycle-history-check.sh` — seul endroit du dépôt qui touche à
Git — qui obtient ce fichier « avant » en interrogeant l'historique
(`git log --format=%H -- <fichier>`, puis `git show <sha>:<fichier>`) et
l'écrit dans un répertoire temporaire avant d'invoquer
`gso_lifecycle.py` dessus.

**Précision sur l'étape 6** (Lot 5.1) : la cible réellement invocable
`make lint-lifecycle` appelle `gso_lifecycle.py` **sans**
`--registry`/`--vault` (`Makefile`, lu en intégralité) — cet appel-là
valide donc le schéma et l'historique append-only des deux registres
documentaires, mais **n'active pas** la disjonction avec le registre actif
et le vault. La disjonction (étape 6, second volet) n'est exercée que
lorsque ces deux options sont fournies explicitement — ce que fait
`GSO-T22` sur des fixtures, mais pas la cible `make` telle qu'invocable
telle quelle.

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : scripts/lib/gso_validate.py, scripts/lib/site-mutation.sh, scripts/lib/site-check.sh,
  playbooks/_shared/{mutate,translate,observe}.yml, playbooks/check-all.yml, docs/OPERATIONS.md, docs/LIFECYCLE-SCHEMA.md,
  scripts/lib/gso_lifecycle.py (lu intégralement, Lot 5.1)
Dernière vérification : 2026-09-14 (Lot 5.1)
```
