---
title: "Sections de code"
template: docs
taxonomy:
    category: [docs]
---

## `grav/user/plugins/contact/contact.php` (98 lignes, lu intégralement)

Structure proche de `projet-lavallee-website` (même `loadEmailPrivateConfig()`,
même honeypot), avec **deux différences structurelles** :

- **`resolveProprietaireEmail(?string $giteRoute)`** — le paramètre est
  **nullable mais sans valeur par défaut** (pas de `= null`). Il n'existe
  aucun appel dans ce dépôt qui omette l'argument (le seul point d'appel,
  `05.contact/default.md`, passe toujours `form.value('gite')`, potentiellement
  une chaîne vide mais jamais littéralement absente). Le corps de la
  fonction gère explicitement le cas d'une chaîne vide (`!$giteRoute` est
  vrai pour `''`, retourne le fallback), donc ce détail reste sans
  conséquence observée dans ce dépôt — voir [Référence](11.reference) pour
  la discussion complète du routage.
- **Validation domaine additionnelle** dans `onFormValidationProcessed()` :
  si `date_arrivee` et `date_depart` sont toutes deux renseignées et que
  `date_depart < date_arrivee`, une `ValidationException` est levée avec
  un message dédié. **Vérifié en direct** : rejet confirmé, HTTP 200, sans
  redirection, message « La date de départ doit être postérieure ou égale
  à la date d'arrivée. » — rendu par Grav dans une bannière de classe CSS
  `toast toast-error`, **différente** de la classe `notices error` utilisée
  pour les rejets détectés par la validation interne de Grav Core (XSS,
  format) — deux mécanismes de rendu distincts pour deux origines de rejet
  distinctes.

## `grav/user/plugins/calendrier-disponibilites/` — 4 fichiers, lus intégralement

**`calendrier-disponibilites.php`** (114 lignes) — hook unique
`onPluginsInitialized`, qui `require_once` explicitement les 3 classes
(pas d'autoloader PSR-4 configuré pour ce plugin), puis active
`onPageInitialized` et `onTwigInitialized`. `onPageInitialized()` ne
traite que les requêtes `POST` sur le template `gerer-disponibilites`,
avec une tâche (`task`) parmi une liste fermée
(`calendrier.add_period`/`calendrier.remove_period`) — toute autre valeur
est ignorée silencieusement. Vérifie un nonce (`Utils::verifyNonce($nonce,
'calendrier-form')`) **avant** toute autre logique métier.

**`classes/Permissions.php`** (16 lignes) — **le point d'autorisation
réel**, invoqué depuis `Availability::setUnavailablePeriods()` : exige
`$user->authenticated` **et** `$user->username === $page->header()['proprietaire']`.
C'est cette classe, pas le gabarit Twig, qui constitue la frontière de
sécurité effective — voir la nuance ci-dessous.

**`classes/Availability.php`** (48 lignes) — `getUnavailablePeriods()`/
`setUnavailablePeriods()` (cette dernière appelle `Permissions::canManage()`
avant toute écriture). Contient une méthode privée
**`readHeaderFromDisk()`** dotée d'un commentaire de bloc précis et
directement pertinent pour comprendre un comportement non intuitif :
elle **contourne délibérément** le cache compilé de Grav
(`Page::header()`) en relisant l'en-tête YAML directement depuis le
fichier source, parce que deux écritures rapprochées via `Page::save()`
« peuvent ne pas être visibles l'une pour l'autre… sous PHP-FPM » — un
problème que plusieurs tentatives d'invalidation du cache Grav n'ont pas
résolu de façon fiable, et dont l'une (`Cache::deleteAll()`) **casse la
validation des nonces de formulaire** (effet de bord documenté
explicitement dans le code, pas déduit).

**`classes/PeriodValidator.php`** (24 lignes) — trois méthodes statiques
pures : `overlaps()` (détection de chevauchement par comparaison de
bornes), `isValidDate()` (format `Y-m-d` strict via
`DateTimeImmutable::createFromFormat`, avec revalidation du format en
sortie pour rejeter les dates invalides que PHP « corrigerait »
silencieusement), `isChronological()`.

## `grav/user/themes/gites-theme/templates/gerer-disponibilites.html.twig` (62 lignes, lu intégralement)

**Nuance de sécurité précise** : le gabarit masque le formulaire de
gestion si `not grav.user.authenticated`, et ne propose l'action que si un
gîte appartenant à l'utilisateur connecté est trouvé (boucle Twig
équivalente à celle du plugin PHP). **Cette vérification côté gabarit
est un affichage, pas une garantie** — une requête `POST` directe vers
cette page, sans jamais charger ce template, atteindrait quand même
`onPageInitialized()` du plugin. La garantie réelle est **entièrement
côté serveur PHP** : `Permissions::canManage()` (authentification **et**
correspondance de propriétaire), vérifiée par lecture du code, pas
supposée depuis le gabarit.

## `grav/user/themes/gites-theme/gites-theme.yaml`

Chaînage vers `quark2` via `streams.schemes.theme` — voir [Place dans
l'architecture](02.place-dans-architecture) pour le détail et l'historique
documenté (tentative `extends@` abandonnée).

## `grav/user/themes/gites-theme/templates/partials/{galerie-apercu,galerie-section}.html.twig`

Logique de sélection des 5 photos « vitrine » (`galerie-apercu.html.twig`) :
complète d'abord par les photos explicitement marquées `vitrine` (triées),
puis complète jusqu'à 5 avec les photos restantes si nécessaire. Utilise
le système de dérivés d'image de Grav (`resize()`, `derivatives()`,
`srcset`) pour un rendu responsive. `galerie-section.html.twig` reçoit sa
variable `gite` par héritage de contexte Twig implicite (`include` sans
`only`), pas par un passage explicite dans le bloc `with` — comportement
Twig standard, pas une omission.

## `grav/user/themes/gites-theme/templates/partials/carte.html.twig`

Charge la bibliothèque Leaflet **vendorisée localement**
(`theme://vendor/leaflet/`), mais les tuiles cartographiques elles-mêmes
sont chargées depuis `https://{s}.tile.openstreetmap.org` — une
dépendance réseau externe **à l'affichage**, pour toute fiche de gîte dont
les coordonnées sont non nulles.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : grav/user/plugins/contact/contact.php,
  grav/user/plugins/calendrier-disponibilites/{calendrier-disponibilites.php,classes/*.php},
  grav/user/themes/gites-theme/templates/gerer-disponibilites.html.twig,
  grav/user/themes/gites-theme/templates/partials/{galerie-apercu,galerie-section,carte}.html.twig
Dernière vérification : 2026-09-14
```
