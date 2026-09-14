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
| `test-contact-form.sh` | Formulaire affiché sur `/contact` avec ses champs (nom, e-mail, téléphone, message, honeypot) ; soumission avec champ obligatoire manquant rejetée ; soumission avec honeypot rempli rejetée ; soumission valide, via un SMTP factice local (Mailpit, aucun e-mail réel envoyé), redirige vers `/contact/confirmation` et le message est reçu par le SMTP factice. |
| `test-secrets.sh` | Aucune valeur de test/placeholder connue dans les couches de l'image exportée ; `user/config/email-private.php` absent de l'image (jamais construit, voir `.dockerignore`). |

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

## Ce qui n'est pas automatisé à ce stade

Pas de test de mise à jour/rollback d'image (pas encore de seconde version
publiée), pas de test de dérive `grav-sites-ops` (déploiement hors périmètre
de ce dépôt — cahier §2), pas de `markdownlint` ni de linter Twig (voir
ci-dessus), pas de vérification visuelle (voir VISUAL-001). Le test de
persistance du seed (première initialisation puis redémarrage sans
écrasement) est couvert par `test-app-presence.sh`, qui redémarre le même
conteneur et vérifie l'absence de réinitialisation — pas par un script
dédié.
