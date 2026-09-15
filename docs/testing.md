# Tests

Détail de ce que couvre chaque script de `tests/`. Pour simplement lancer
les tests, voir le [`README.md`](../README.md) (`sh tests/run-all.sh`).

## Structure

```text
tests/
├── lib.sh                 # helpers partagés (wait_healthy, log, fail, http_status)
├── fixtures/
│   └── email-private.test.php   # SMTP factice (Mailpit), jamais un secret réel
├── test-build.sh
├── test-syntax.sh
├── test-startup.sh
├── test-app-presence.sh
├── test-contact-form.sh
├── test-secrets.sh
├── test-update-rollback.sh # Lot 10 — mise à jour A→B et rollback B→A, 4 volumes
├── compose.test.yml        # utilisé uniquement par test-update-rollback.sh
└── run-all.sh              # orchestrateur, s'arrête au premier échec
```

Chaque script échoue explicitement (code de sortie non nul) au premier
écart constaté.

## Ce que couvre chaque script

| Script | Couvre |
|---|---|
| `test-build.sh` | Le `docker build` de l'image applicative réussit. |
| `test-syntax.sh` | `php -l` sur les fichiers PHP du projet (exécuté depuis l'image construite, `php` n'étant pas installé sur l'hôte) ; `sh -n` sur tous les scripts de `tests/` ; parsing réel de tous les fichiers YAML du dépôt (python3 + PyYAML, et `yamllint` en complément informatif s'il est disponible) ; `git diff --check` (erreurs d'espace). Markdown et Twig : voir la note dédiée ci-dessous. |
| `test-startup.sh` | Démarrage, état `healthy`, page d'accueil en HTTP 200 (bootstrap admin fourni — voir note ci-dessous). |
| `test-app-presence.sh` | Thème `platform-docs-theme` actif (fond Learn2 chargé), les sept rubriques de premier niveau (Architecture globale, les cinq dépôts, Contact) apparaissent dans la navigation, les deux liens du header (`lavallee.tech` → `https://lavallee.tech/en`, `GitHub` → `https://github.com/sepp67`) sont présents avec `target="_blank" rel="noopener noreferrer"`, la page de confirmation n'apparaît pas dans le menu. |
| `test-internal-links.sh` | Explore chaque page publiée et vérifie que tout lien interne de contenu (zone `#body-inner`, pas la barre latérale) répond HTTP 200 — garde de non-régression ajoutée au Lot 8 après la découverte de 99 liens internes cassés. |
| `test-contact-form.sh` | Formulaire affiché sur `/contact` avec ses champs (nom, e-mail, téléphone, message, honeypot) ; soumission avec champ obligatoire manquant rejetée ; soumission avec honeypot rempli rejetée ; soumission valide, via un SMTP factice local (Mailpit, aucun e-mail réel envoyé), redirige vers `/contact/confirmation` et le message est reçu par le SMTP factice. **Ajouté au Lot 10.1** : rejet applicatif CRLF (`grav/user/plugins/contact/contact.php::onFormPrepareValidation()`) — six cas séparés (CR, LF, CRLF × nom, email), chacun vérifie l'absence de redirection vers la confirmation, le message d'erreur générique, l'absence de la valeur fautive dans la réponse HTTP, et l'absence de tout message SMTP supplémentaire reçu par Mailpit. |
| `test-secrets.sh` | Aucune valeur de test/placeholder connue dans les couches de l'image exportée ; `user/config/email-private.php` absent de l'image (jamais construit, voir `.dockerignore`). |
| `test-update-rollback.sh` | **Ajouté au Lot 10.** Mise à jour d'image A→B puis rollback B→A (image B construite depuis une copie temporaire avec un marqueur CSS, jamais les fichiers réels du dépôt) : les 4 répertoires persistants (`pages`, `accounts`, `data`, `images`) ne sont jamais perdus ; le code actif correspond bien à l'image en service à chaque étape ; site et formulaire de contact restent accessibles après chaque bascule. |

## Note sur le bootstrap admin dans les tests

`test-startup.sh`, `test-app-presence.sh` et `test-contact-form.sh`
démarrent le conteneur avec `GRAV_ADMIN_USER`/`_PASSWORD`/`_EMAIL`
renseignées, comme le fait `ansible-role-grav-site` en déploiement réel.
Sans ces variables, le plugin Admin de `grav-runtime` redirige lui-même
toutes les pages du site vers `/admin` tant qu'aucun compte n'existe — un
comportement natif de Grav Admin, pas un défaut de cette image (voir la même
note dans `projet-gites/docs/testing.md` et `projet-lavallee-website/tests/test-startup.sh`).

## SMTP factice

`test-contact-form.sh` démarre un conteneur Mailpit
(`axllent/mailpit`, capture SMTP sur le port 1025, API HTTP sur 8025) sur le
même réseau Docker que le conteneur applicatif, puis monte un
`email-private.php` de test (`tests/fixtures/email-private.test.php`)
pointant vers ce SMTP factice. Aucun identifiant, hôte ou destinataire réel
n'intervient dans ce test.

## Validation Markdown et Twig

- **Markdown** : `markdownlint` non exécuté. Aucun outil (`markdownlint`,
  `markdownlint-cli2`, `npx`/`node`/`npm`) n'est disponible sur la machine
  de développement sans installation durable (par exemple `npm install
  -g`), ce qui n'a pas été fait. À statuer au Lot 8 (cohérence transverse) —
  installer l'outil dans l'environnement de CI plutôt que sur le poste de
  développement, ou documenter son absence de façon permanente.
- **Twig** : aucun linter Twig autonome (`twig-lint`, `twigcs`) n'est
  disponible et Composer n'est pas installé sur cette machine ; aucune
  recherche textuelle n'est présentée comme une validation. Les quatre
  templates du thème enfant (`base.html.twig`, `header-links.html.twig`,
  `contact.html.twig`, `contact-email.html.twig`) sont en revanche
  **réellement rendus** par le moteur Twig de Grav pendant
  `test-startup.sh`, `test-app-presence.sh` et `test-contact-form.sh` — une
  erreur de syntaxe Twig y ferait échouer ces tests (page d'erreur PHP au
  lieu du code HTTP attendu), ce qui constitue une validation par exécution
  réelle, pas une recherche de motif.

## Intégration continue et publication (CI/CD)

Deux workflows GitHub Actions, ajoutés au Lot 10.1, séparés par
responsabilité — aucun des deux ne remplace `sh tests/run-all.sh` en local,
qu'ils exécutent tous les deux tels quels :

- **`.github/workflows/ci.yml`** — déclenché sur toute pull request vers
  `main` et tout push sur `main`. Un seul job (`test`) : checkout, puis
  `sh tests/run-all.sh` (qui construit l'image lui-même via
  `test-build.sh`, en premier). Permissions minimales
  (`contents: read`, `packages: read` — ce dernier uniquement pour tirer
  l'image de base privée `ghcr.io/sepp67/grav-runtime`). **Ne publie
  jamais d'image, sur aucun registre.**
- **`.github/workflows/release.yml`** — déclenché par un push de tag
  `vX.Y.Z`, **ou manuellement** (`workflow_dispatch`, ajouté au Lot 10.2 —
  validation seule, jamais de publication, voir plus bas). Deux jobs
  séparés : `test` (vérifie explicitement le format SemVer strict du tag
  au-delà du simple motif de déclenchement — ou d'une valeur simulée
  fournie en entrée sur `workflow_dispatch`, faute de vrai tag — puis
  exécute la suite complète `sh tests/run-all.sh`) et `publish`
  (`needs: test` — ne peut donc jamais démarrer avant que `test` ait
  réussi), qui construit et pousse
  `ghcr.io/sepp67/grav-platform-docs:X.Y.Z` avec
  `docker/metadata-action` (`pattern={{version}}` uniquement — aucune
  entrée `latest`, `major` ou `major.minor` n'est jamais générée), les
  labels OCI `source`/`revision`/`version`/`created`, et écrit le digest
  publié dans le résumé du job (`$GITHUB_STEP_SUMMARY`). Permissions
  minimales et différenciées par job (`test` : lecture seule ; `publish` :
  `packages: write` uniquement là où c'est nécessaire).

  **`workflow_dispatch` = validation sans publication.** Le job `publish`
  porte une condition explicite,
  `if: github.event_name == 'push' && github.ref_type == 'tag'` : un
  déclenchement manuel a toujours `github.event_name == 'workflow_dispatch'`,
  jamais `'push'`, donc `publish` ne s'exécute structurellement jamais
  depuis ce déclencheur — y compris si l'exécution manuelle cible un ref de
  type tag dans l'interface GitHub. Utile pour vérifier que `test` (build +
  suite complète) passe avant de pousser un vrai tag, sans risque de
  publication accidentelle. N'ajoute aucune connexion GHCR en écriture :
  la connexion en lecture seule du job `test` (nécessaire pour tirer
  `grav-runtime`) reste inchangée, qu'il s'agisse d'un tag réel ou d'un
  déclenchement manuel.

**Vérifié aux Lots 10.1 et 10.2, sans pousser aucun tag ni déclencher
aucune exécution GitHub réelle** : syntaxe YAML (parsing PyYAML +
`yamllint`), validation sémantique GitHub Actions complète via
`actionlint` (avec intégration `shellcheck` sur les blocs `run:`) — zéro
erreur signalée par l'un ou l'autre, y compris après l'ajout du
`workflow_dispatch` ; déclencheurs, permissions et noms exacts des jobs
relus directement dans les fichiers ; absence de toute entrée `latest`
confirmée par recherche textuelle (seules occurrences : le nom de runner
`ubuntu-latest`, sans rapport, et les commentaires expliquant l'absence
volontaire) ; présence de `needs: test` sur le job `publish` ; logique de
validation SemVer du tag rejouée directement en shell hors CI, avec la
valeur `1.0.0` obtenue pour un tag simulé `v1.0.0` (le défaut de l'entrée
`simulated_tag` de `workflow_dispatch`) et rejet confirmé pour plusieurs
formats invalides (`v1.0`, `1.0.0`, `v1.0.0-rc.1`, `v01.0.0`, etc.) ; la
condition `if` du job `publish` rejouée pour les trois combinaisons
possibles d'événement/type de ref (`push`+tag → s'exécute ;
`workflow_dispatch`+branche → ignoré ; `workflow_dispatch`+tag → ignoré,
c'est `event_name` qui tranche, pas `ref_type` seul). **Ceci constitue une
validation statique, jamais une exécution GitHub Actions réelle** : la CI distante elle-même (comportement réel des
runners GitHub, accès réseau, résolution des actions tierces à leur
version épinglée, comportement de `docker/build-push-action` et
`docker/metadata-action` en conditions réelles) ne sera vérifiable qu'une
fois ces fichiers effectivement poussés sur GitHub — ce qui n'a pas été
fait dans ce lot (voir la règle d'arrêt du rapport de ce lot). De même, le
digest de l'image `v1.0.0` réellement publiée sur GHCR n'existera qu'après
ce push et cette exécution : il ne sera pas enregistré dans ce dépôt, mais
dans `grav-sites-ops` (registre de version déployée) et dans les preuves
GitHub elles-mêmes (résumé du job `publish`, page du paquet GHCR) — jamais
dans `docs/` de ce dépôt, pour ne pas dupliquer une source de vérité qui
doit rester le registre et GitHub.

## Dette de validation visuelle

**VISUAL-001** — Vérification manuelle ou automatisée avant la première
release (non bloquante pour les lots suivants, bloquante avant toute
release) :

- accueil desktop ;
- accueil mobile ;
- menu latéral ouvert et fermé ;
- page documentaire profonde (au moins une sous-page à 2 niveaux) ;
- header et liens externes ;
- formulaire de contact ;
- page de confirmation ;
- débordements des tableaux et blocs de code (aucun ne doit forcer un
  défilement horizontal de la page entière).

Rien dans ce dépôt ne vérifie aujourd'hui ces points par capture d'écran ou
par un outil de rendu — seule la structure HTML/CSS a été vérifiée (voir le
rapport du Lot 1).

**Zoom — distinction terminologique (corrigée au Lot 10.2).** Le Lot 10.1
avait qualifié `document.documentElement.style.zoom` de « zoom navigateur
réel », ce qui est inexact : trois notions distinctes existent —

- **zoom navigateur** (`Ctrl` + `+`, réglage persistant par site au niveau
  du chrome du navigateur) : c'est celui que WCAG 1.4.4/1.4.10 vise
  réellement ; jamais automatisé avec succès dans cet environnement (voir
  `docs/architecture.md`, A11Y-003, pour le détail des méthodes essayées
  et leur échec) — **contrôle manuel réel effectué par l'utilisateur**
  hors de cette session automatisée (100 % et 200 %). **Décision humaine
  enregistrée au Lot 10.3 : aucun défaut bloquant constaté pendant ce
  contrôle réel**, sans détail page par page dans ce dépôt. Conséquence :
  A11Y-009 et A11Y-010 (trouvées uniquement via le contrôle CSS
  complémentaire ci-dessous) ne sont pas reproduites par ce contrôle réel
  et sont requalifiées en simples observations du contrôle CSS, pas en
  défauts confirmés au zoom navigateur réel — voir `docs/architecture.md`
  pour le détail ;
- **zoom CSS** (`document.documentElement.style.zoom`, propriété non
  standard mais gérée par les moteurs Chromium) : déclenche un vrai
  reflow de mise en page, contrairement à un `transform: scale` — un
  **contrôle complémentaire**, jamais une preuve de zoom navigateur réel,
  utilisé ici uniquement parce que l'alternative n'a pas pu être
  automatisée ;
- **viewport réduit** (simple redimensionnement de fenêtre) : ne simule
  ni l'un ni l'autre — c'était l'erreur du Lot 10, déjà corrigée au
  Lot 10.1.

Le contrôle CSS complémentaire a été exécuté aux Lots 10.1 et 10.2 sur six
pages représentatives (accueil, page profonde, tableau large, bloc de
code, glossaire, formulaire) et sur quatre largeurs (320, 375, 768,
1440 px) au Lot 10.2 — captures jetables, jamais commitées, résultat
consigné dans `docs/architecture.md` (A11Y-003, A11Y-008 fermé, A11Y-009 et
A11Y-010 requalifiées au Lot 10.3 en observations non bloquantes du
contrôle CSS seul). Ni l'un ni l'autre ne remplace VISUAL-001 pour les
points non couverts (menu mobile, page de confirmation, etc.). Le menu
mobile lui-même reste couvert par A11Y-011 (ordre de tabulation),
confirmée et explicitement acceptée au Lot 10.3 comme dette non bloquante
pour v1.0.0, à corriger dans une version ultérieure — **aucune
certification WCAG globale n'est revendiquée** par l'un ou l'autre de ces
contrôles.

## Ce qui n'est pas automatisé à ce stade

Pas de test de dérive `grav-sites-ops` (déploiement hors périmètre de ce
dépôt — cahier §2), pas de `markdownlint` ni de linter Twig (voir
ci-dessus). Le test de persistance du seed (première initialisation puis
redémarrage sans écrasement) est couvert par `test-app-presence.sh`, qui
redémarre le même conteneur et vérifie l'absence de réinitialisation — pas
par un script dédié. La mise à jour/rollback d'image **est** désormais
testée (`test-update-rollback.sh`, Lot 10) — la seconde version testée est
simulée (marqueur CSS), pas une release réellement publiée, ce que
`docs/architecture.md`/le rapport du Lot 10 précisent explicitement.
Vérification visuelle : voir VISUAL-001 ci-dessus — une recette manuelle
partielle a été réalisée au Lot 10 (captures jetables, jamais commitées),
dont le résultat est consigné dans le rapport de ce lot, pas dans ce
fichier.
