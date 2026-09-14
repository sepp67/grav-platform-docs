---
title: "Sections de code"
template: docs
taxonomy:
    category: [docs]
---

## `scripts/lib/gso_validate.py` (525 lignes, lu intégralement)

Le module partagé de validation statique. Quatre fonctions publiques :

- **`validate_registry()`** — valide `grav_sites` champ par champ :
  `image` sans tag ni digest (`GSO-REQ-010`), `version` non vide et jamais
  `latest` (`GSO-REQ-021`/`154`), `digest` au format `sha256:<64 hex>` ou
  chaîne vide, `bind_address` IPv4 littérale, `http_port` dans une plage
  valide, `base_directory` hors des répertoires utilisateur
  (`/home`,`/Users`,`/root`), unicité de `project_name`/`container_name`/
  `base_directory`/couple `(bind_address, http_port)`, correspondance
  hôtes ↔ registre, et disjonction avec `retired_grav_sites`
  (`GSO-REQ-052`).
- **`validate_vault()`** — correspondance à trois voies hôtes ==
  registre == vault ; interdiction de champs `admin_*` en clair dans le
  registre (ils ne vivent que dans le vault, `GSO-REQ-024`/`203`) ;
  validation tri-état de `admin_user`/`admin_password`/`admin_email`
  (les trois présents, ou les trois absents — jamais un sous-ensemble) ;
  secrets uniquement sous forme `name`+`content` (`src` refusé,
  `GSO-REQ-203`), nom conforme à `^[A-Za-z0-9][A-Za-z0-9._-]*$`.
- **`validate_selector()`** — l'algorithme du sélecteur fermé en 8 étapes
  numérotées (détaillé en [Flux chronologique, chronologie A](../04.flux-chronologique)).
- **`validate_preflight()`** (exposée via la sous-commande `preflight`) —
  compose `validate_registry` + `validate_vault` pour un seul hôte,
  appelée par `_shared/mutate.yml` comme second garde-fou structurel.

`repo_root()` calcule la racine du dépôt depuis l'emplacement
**canonique** du fichier source (`os.path.realpath(__file__)`, triple
`dirname`) — jamais depuis le répertoire courant, une variable
d'environnement ou un argument. Conséquence directement vérifiable :
le script produit le même résultat quel que soit le cwd depuis lequel il
est invoqué.

La classe `Reporter` centralise les sorties `PASS`/`FAIL`/`SKIP` — c'est
la source du format de sortie visible dans tous les tests `GSO-T*`.

## `scripts/lib/gso_classify.py` (232 lignes, lu intégralement)

Fonction pure `classify(data) -> catégorie`, sans effet de bord, jamais
d'accès disque/réseau — elle reçoit un JSON déjà collecté par
`observe.yml` et retourne une des 8 catégories de `CATEGORIES`. Ordre de
priorité de la décision (extrait fidèle du code, pas reconstruit) :

1. `real_error == 'unreachable'` → `UNREACHABLE`
2. état appliqué illisible/incohérent, ou erreur Docker/ambiguïté, ou
   référence désirée vide → `UNKNOWN`
3. rien d'appliqué et aucun conteneur → `NOT_DEPLOYED`
4. état appliqué présent mais conteneur absent → `NOT_DEPLOYED`
5. référence appliquée ≠ désirée, ou image réelle incompatible →
   `REFERENCE_DRIFT`
6. arrêt désiré : conteneur qui tourne → `CONFIG_DRIFT` ; sinon →
   `IN_SYNC`. Démarrage désiré et rien qui tourne → `STOPPED`
7. port réel ≠ port désiré → `CONFIG_DRIFT`
8. santé du conteneur : `unhealthy` → `UNHEALTHY` ; `healthy` →
   `IN_SYNC` ; `starting` → `UNKNOWN` ; sinon, repli sur le code HTTP
   observé (2xx/3xx → `IN_SYNC`, autre réponse → `UNHEALTHY`, aucune
   réponse → `UNKNOWN`)

`main()` lit le JSON sur `stdin` et **sort toujours en code 0** : classer
n'est jamais un échec en soi. C'est le playbook appelant
(`check-site.yml`) qui transforme un verdict `!= IN_SYNC` en échec via
son propre `assert` — la classification et le jugement de conformité
sont deux responsabilités séparées dans le code.

## `playbooks/_shared/mutate.yml` (45 lignes, lu intégralement)

Séquence commune aux trois intentions de mutation, quatre tâches
strictement ordonnées : assertion structurelle sur `ansible_limit` →
second préflight (`gso_validate.py preflight`, `no_log: true`) →
`include_tasks: translate.yml` → `include_role: sepp67.grav_site`. Voir
le détail complet en [Flux chronologique, chronologie B](../04.flux-chronologique).

## `playbooks/_shared/translate.yml` (59 lignes, lu intégralement)

Le point de passage obligé entre données déclaratives et interface
publique du rôle — voir la table complète en [Configuration et
interfaces](../06.configuration-et-interfaces). Deux `set_fact` distincts :
un premier sans `no_log` pour les champs non secrets du registre, un
second avec `no_log: true` pour le bootstrap administrateur et les
secrets applicatifs — cette séparation est **structurelle dans le
fichier**, pas une convention documentée seulement.

## `playbooks/_shared/observe.yml` (163 lignes, lu intégralement)

Collecte en lecture seule des trois états (désiré/appliqué/réel) —
détaillé en [Flux chronologique, chronologie C](../04.flux-chronologique).
Aucune tâche de ce fichier n'a de `changed_when` implicite à `true` :
chaque tâche de collecte est soit intrinsèquement idempotente
(`slurp`, `stat`, `uri` GET, `docker inspect` via `command`), soit
neutralisée explicitement (`ignore_errors`/`ignore_unreachable`).

## `scripts/lib/site-mutation.sh` (60 lignes, lu intégralement)

Le mécanisme de verrouillage — voir chronologie B. Point notable :
`exec ansible-playbook …` **remplace** le processus shell courant plutôt
que de le lancer en sous-processus. C'est ce qui garantit que le
descripteur de fichier 9 (le verrou `flock`) reste ouvert pendant toute
la durée d'exécution du playbook et est automatiquement fermé — donc le
verrou relâché — par le noyau dès que ce processus se termine, y compris
en cas de crash ou de signal, sans code de nettoyage explicite.

## `scripts/lifecycle-history-check.sh` (82 lignes, lu intégralement)

Le seul script du dépôt qui invoque Git directement. Refuse explicitement
un dépôt superficiel (`git rev-parse --is-shallow-repository`) — un clone
`--depth` tronqué produirait une preuve d'append-only incomplète mais
apparemment réussie ; le script préfère échouer bruyamment. Reconstruit
chaque paire de versions consécutives d'un fichier via `git log --format=%H`
et `git show <sha>:<file>`, extraites dans un répertoire temporaire
nettoyé par `trap`.

## `scripts/lib/gso_lifecycle.py` (473 lignes, lu intégralement — Lot 5.1)

Validateur **strictement en lecture seule** (docstring du fichier,
`GSO-REQ-026`/`095`/`107`) des deux registres documentaires. N'importe
que des primitives partagées de `gso_validate.py` (`Reporter`, `SITE_RE`,
`is_doc_addr`, `load_yaml`) — il ne modifie pas ce fichier.

**Entrées** : quatre chemins, toujours passés explicitement en argument,
jamais déduits du cwd — `--retired` (`retired-sites.yml`),
`--reactivated` (`reactivated-sites.yml`), `--registry` (optionnel, active
la disjonction avec le registre actif), `--vault` (optionnel, active la
disjonction avec le vault), `--history-before` (optionnel, version
antérieure de `reactivated-sites.yml`, exige `--reactivated`).

**`validate_retired()`** — racine strictement `{retired_grav_sites}` (une
clé racine inconnue est un échec) ; par fiche : clé conforme à
`^[a-z][a-z0-9-]*$`, 9 champs obligatoires présents et aucun champ
inconnu, **aucun champ `status`** ni `status: reactivated` (contrat §21.9
— vérifié explicitement, pas par omission), `retired_at` est une date ISO
valide, `former_ansible_host` est une adresse de documentation (TEST-NET
ou privée — jamais une IP publique réelle), `former_base_directory` est
un chemin absolu ; sous-objet `last_deployment` : exactement
`image`/`version`/`digest`, aucun `latest` ; sous-objet `preservation` :
exactement les 4 champs attendus, `vm_status` ∈
`{stopped, running, unknown}`, les 3 autres champs booléens stricts.

**`validate_reactivated()`** — racine strictement `{reactivated_sites}` ;
chaque valeur doit être une **liste non vide** d'événements (pas un objet
unique) ; par événement : 4 champs obligatoires, aucun champ inconnu,
`reactivated_at` date ISO valide ; `previous_retirement` doit contenir au
moins `retired_at`+`reason`, tolère aussi tout champ valide d'une fiche
de retrait (une copie complète y est autorisée par le contrat §7.7) ;
vérifie `retired_at ≤ reactivated_at` pour chaque événement ; vérifie que
les événements d'une même clé sont en ordre chronologique **dans l'état
courant examiné**.

**`validate_append_only()`** — la preuve inter-version (`GSO-REQ-181`) :
compare deux documents `before`/`after`. Pour chaque clé déjà présente
dans `before` : doit encore exister dans `after` (sinon échec —
« clé historique supprimée ») ; sa liste d'événements dans `after` doit
commencer par une copie **exacte** de sa liste dans `before` (`a_events[:
len(b_events)] == b_events`) — tout écart (réécriture, réordonnancement,
suppression, insertion rétroactive) est un échec explicite ; les
événements ajoutés à la fin doivent être chronologiquement postérieurs au
dernier événement déjà présent. Purement en lecture : cette fonction ne
compare que deux objets déjà chargés en mémoire, n'écrit jamais.

**`validate_disjonction()`** — vérifie, quand `--registry`/`--vault` sont
fournis : aucune clé simultanément active (`grav_sites`) et retirée
(`GSO-REQ-052`) ; une clé réactivée actuellement active n'est pas
retirée ; aucune clé en double entre `vault_grav_sites` et
`vault_retired_grav_sites` ; aucun projet retiré ne conserve d'entrée
dans `vault_grav_sites` (`GSO-REQ-073`) ; un projet dont
`secrets_archived_in_vault: true` doit avoir une entrée dans
`vault_retired_grav_sites` ; aucun site actif présent dans
`vault_retired_grav_sites`. Cas particulier `§21.9` : une clé à la fois
retirée et réactivée n'est légitime que si son retrait **courant** est
postérieur à sa dernière réactivation (retrait après réactivation =
site retiré une seconde fois, cas valide).

**Détection de secrets et de chemins locaux** (`_scan_no_secret_no_local`,
appliquée aux deux fichiers) : toute clé à connotation de secret
(`password`, `token`, `api_key`, `secret`, etc., à l'exclusion explicite
de `secrets_archived_in_vault` qui est un booléen de schéma, pas un
secret) portant une **valeur** non vide est un échec ; tout chemin
`/home/`, `/Users/`, `/root/` littéral dans une valeur est un échec.

**Codes de retour** : la fonction `_finish()` retourne `1` si `r.errors`
est non vide, `0` sinon — cohérent avec le principe « échoue fermé » du
docstring. Aucune sortie ne révèle de valeur, seulement des libellés de
contrôle (`PASS`/`FAIL`, hérités de `Reporter`).

**Ce qu'il ne modifie jamais** (confirmé par lecture complète, pas
seulement par le docstring) : aucun appel à `open(..., 'w')`, aucun appel
à `subprocess`, aucune primitive Ansible, aucune ouverture de vault
chiffré. Il ne fait que lire deux à quatre fichiers YAML et comparer des
structures en mémoire.

**Tests qui l'exercent** : GSO-T21 vérifie statiquement qu'aucune
primitive d'écriture ou de sous-processus n'apparaît dans son code
source ; GSO-T22 exerce `validate_disjonction()` et l'algorithme
append-only sur des fixtures ; `l8-history-append-only` exerce
`validate_append_only()` de bout en bout via le wrapper Git, avec des
mini-dépôts jetables (transition valide, réécriture refusée, suppression
refusée, dépôt superficiel refusé, commit initial toléré) — voir [Tests
et CI](../08.tests-et-ci).

**Point de vigilance** : ce module ne **réalise** aucune opération de
cycle de vie. Il ne retire ni ne réactive jamais un site — il valide,
après coup, des fichiers déjà modifiés manuellement par un opérateur (voir
[Flux chronologique, chronologie E](../04.flux-chronologique)). `make
lint-lifecycle` l'invoque d'ailleurs **sans** `--registry`/`--vault` : cet
appel-là ne vérifie donc que le schéma et l'append-only des deux
registres documentaires, pas leur disjonction avec le registre/vault
actifs.

## `scripts/lib/gso_compliance.py` (301 lignes, lu intégralement — Lot 5.1)

Génère ou vérifie `docs/COMPLIANCE-MATRIX.md`. **Read-only** de son propre
aveu (docstring) : il n'écrit jamais de fichier lui-même — `render()`
retourne une chaîne, c'est `make matrix` (côté shell) qui la redirige
vers le fichier.

**Sources** : `docs/CONTRAT-ARCHITECTURAL.md`, dont `_titles()` extrait
par expression régulière (`\*\*GSO-REQ-(\d{3})\s*[—-]\s*([^.*]+?)\.\*\*`)
l'intitulé d'une ligne exigence — la syntaxe attendue dans le contrat est
donc précisément `**GSO-REQ-NNN — Intitulé.**`. Un dictionnaire Python
`_LOTS` **codé en dur dans le fichier** associe chaque lot (`L0`…`L11`) à
la liste de ses numéros `GSO-REQ`, à plat (204 numéros au total, aucun
doublon ni trou entre 001 et 204 — vérifiable directement en comptant les
entrées de `LOT`). Un second dictionnaire, `ENTRY`, également codé en
dur, associe à chaque numéro un couple **(preuve principale, statut)** —
c'est une table tenue **à la main** par les auteurs du dépôt, pas générée
depuis les tests eux-mêmes : rien dans le code ne vérifie qu'une preuve
citée (p. ex. « GSO-T06 ») correspond réellement à un test qui existe ou
qui a été exécuté.

**Format d'une exigence** : `(preuve: str, statut: str)`, `statut` ∈
`{T, S, D, P, N}`, traduits par le dictionnaire `LABEL` (repris ici mot
pour mot) : `T` = « Satisfait et testé », `S` = « Satisfait », `D` =
« Établi / documenté », `P` = « Partiel », `N` = « Non encore démontré
(L11) ».

**`render()`** — pour chaque numéro de `LOT` (donc chaque exigence
listée dans `_LOTS`) : si une entrée `ENTRY` existe, l'utilise ; sinon
(cas de repli, qui ne devrait jamais s'activer d'après un commentaire du
code) attribue une preuve générique. Compte les statuts (`Counter`),
construit la synthèse et le tableau détaillé, **trié par numéro**. Le
texte produit est **entièrement déterministe** : à code et à
`CONTRAT-ARCHITECTURAL.md` inchangés, deux exécutions produisent un texte
identique (aucune donnée temporelle, aucun aléa, confirmé en Lot 5.1 par
une génération dans un worktree séparé — voir §5 du rapport).

**Mode `--check`** — relit `docs/COMPLIANCE-MATRIX.md` sur disque,
compte les lignes commençant par `| GSO-REQ-` (doit valoir exactement
`204`), puis compare le texte régénéré au texte sur disque **au caractère
près** (`on_disk.strip() != text.strip()`). Absence de fichier, nombre de
lignes différent, ou moindre écart textuel → code de sortie `1`. Sinon
`0`. **Ce contrôle ne relit ni n'exécute aucun test** : il vérifie
uniquement que le fichier généré et le fichier commité sont
**identiques**, c'est-à-dire que `ENTRY`/`_LOTS`/le contrat n'ont pas
changé sans régénération de la matrice.

**Limite du contrôle, à ne jamais présenter autrement** : `make
matrix-check` prouve la **cohérence interne** du dépôt (la matrice reflète
le code source du générateur), jamais que les 204 exigences ont été
**réellement testées**. La distinction entre « présent dans la matrice »,
« preuve déclarée dans `ENTRY` », « test existant », « test exécuté », et
« conformité effectivement démontrée » n'est faite nulle part par le
code lui-même — elle appartient entièrement à la discipline éditoriale
des auteurs du dépôt en tenant `ENTRY` à jour. Ce document distingue ces
cinq niveaux explicitement en [Référence](../11.reference) et [Tests et
CI](../08.tests-et-ci), précisément pour ne pas laisser la matrice seule
faire office de preuve d'exécution.

**Tests qui l'exercent** : `l10-ci-blocking` et `l11-acceptance-guards`
appellent tous deux `python3 scripts/lib/gso_compliance.py --check` et
vérifient son code de sortie ; `l11-acceptance-guards` vérifie en outre
que `docs/COMPLIANCE-MATRIX.md` compte exactement 204 lignes
`| GSO-REQ-`. Aucun test n'exerce `render()` en mode génération
(`make matrix`, sans `--check`) autrement que par comparaison manuelle —
c'est ce que le Lot 5.1 a fait séparément (§5 du rapport), dans un
worktree temporaire, sans jamais écrire dans le dépôt source.

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : scripts/lib/gso_validate.py, scripts/lib/gso_classify.py, playbooks/_shared/*.yml,
  scripts/lib/site-mutation.sh, scripts/lifecycle-history-check.sh, scripts/lib/gso_lifecycle.py,
  scripts/lib/gso_compliance.py (les deux derniers lus intégralement au Lot 5.1, 2026-09-14)
Dernière vérification : 2026-09-14 (Lot 5.1)
```
