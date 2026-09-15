---
title: "Sections de code"
template: docs
taxonomy:
    category: [docs]
---

## `grav/user/plugins/contact/contact.php` (416 lignes dans le tag `v1.1.0`, lu intégralement)

**Réécrit pour corriger SEC-GITES-001** (au commit `b27d7af`, 98 lignes —
voir [Référence](../11.reference) pour le constat d'origine). Conserve du
code partagé avec `projet-lavallee-website` : `loadEmailPrivateConfig()`,
le honeypot (champ **rendu** par le plugin Form de Grav, **lecture et
rejet** de sa valeur assurés par ce plugin contact — distinction
explicitement documentée dans le code lui-même). Structure du mécanisme
de routage corrigé, entièrement nouvelle :

- **`contactTable()`** (méthode privée) — **source de vérité unique** :
  produit une table structurée `identifiant public => libellé, type
  (gîte/général), page Grav, nom de compte, adresse déjà validée`. Le
  fournisseur d'options affichées, la validation de soumission et la
  résolution du destinataire lisent tous les trois **exactement cette
  même table**, jamais trois logiques recalculées séparément — propriété
  vérifiée par lecture directe du code, pas déduite.
- **Identifiant `general` réservé** — inséré dans la table **avant** tout
  parcours des pages de gîte (si `plugins.email.to` est syntaxiquement
  valide), et une page dont le slug vaudrait littéralement `general` est
  exclue en amont : aucune page de gîte ne peut jamais l'écraser.
- **`eligibleGitePages()`** — une page n'est candidate que si elle est
  enfant **direct** du sous-arbre configuré, `routable()` (combine déjà
  publication et routabilité côté Grav Core), du template métier attendu,
  dotée d'un identifiant public conforme à un format explicite
  (minuscules ASCII, chiffres, tiret simple), et d'un `proprietaire`
  renseigné. **`visible` n'intervient jamais** dans ce filtre : une fiche
  publiée, routable, retirée du sommaire reste contactable.
- **Collisions d'identifiant — échec fermé** : les pages éligibles sont
  regroupées par identifiant *avant* toute résolution d'adresse ; un
  identifiant porté par plus d'une page est exclu **intégralement**
  (aucune option, aucune résolution possible), indépendamment de l'ordre
  des pages et même si l'une d'elles aurait par ailleurs une adresse
  valide — jamais une priorité au premier arrivé.
- **Validation d'adresse** — `filter_var(..., FILTER_VALIDATE_EMAIL)`,
  déjà disponible en PHP, aucune dépendance ajoutée ; une adresse absente,
  vide ou syntaxiquement invalide exclut la page (ou l'option générale)
  de la table.
- **Rejet CR/LF applicatif** — `onFormValidationProcessed()` rejette
  désormais explicitement toute valeur contenant `\r` ou `\n` dans
  `email` (alimente l'en-tête Reply-To) ou `nom` (alimente le sujet),
  **avant tout traitement** — un message générique, sans jamais réafficher
  la valeur fautive. `message` n'est volontairement pas concerné (usage
  légitime d'une zone de texte, contenu échappé dans le gabarit HTML).
- **`Blueprint::addAllowedDynamicCallable()`** — le champ `gite` obtient
  ses options via `data-options@` (blueprint) ; ce Grav Core impose une
  allowlist des callables `Class::method` admissibles pour ce mécanisme —
  une seule callable statique y est enregistrée
  (`ContactPlugin::contactGiteOptionsProvider`), qui ne retourne que des
  paires identifiant/libellé public, jamais la page, le compte ni
  l'adresse.
- **Validation domaine additionnelle** (inchangée) dans
  `onFormValidationProcessed()` : si `date_arrivee` et `date_depart` sont
  toutes deux renseignées et que `date_depart < date_arrivee`, une
  `ValidationException` est levée avec un message dédié — rejet confirmé
  historiquement (Lot 7), HTTP 200, sans redirection.

Preuve de non-régression : `tests/test-contact-routing.sh`, 60 assertions
nommées, détail complet en [Tests et CI](../08.tests-et-ci).

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
l'architecture](../02.place-dans-architecture) pour le détail et l'historique
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
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b)
Fichiers principaux : grav/user/plugins/contact/contact.php,
  grav/user/plugins/calendrier-disponibilites/{calendrier-disponibilites.php,classes/*.php},
  grav/user/themes/gites-theme/templates/gerer-disponibilites.html.twig,
  grav/user/themes/gites-theme/templates/partials/{galerie-apercu,galerie-section,carte}.html.twig,
  tests/test-contact-routing.sh
Dernière vérification : 2026-09-15
```
