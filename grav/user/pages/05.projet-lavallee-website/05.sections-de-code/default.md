---
title: "Sections de code"
template: docs
taxonomy:
    category: [docs]
---

## `grav/user/plugins/contact/contact.php` (94 lignes, lu intégralement)

Classe `ContactPlugin`, un seul événement d'amorçage
(`onPluginsInitialized`) qui : (1) charge `email-private.php`
inconditionnellement, (2) active deux écouteurs supplémentaires
(`onTwigInitialized`, `onFormValidationProcessed`).

- **`onFormValidationProcessed()`** — filtre d'abord sur
  `$form->getName() !== 'contact-form'` (ignore tout autre formulaire du
  site) ; si `honeypot` a une valeur non vide, lève une
  `ValidationException` avec un message générique en français
  (« Votre demande n'a pas pu être traitée. »), quelle que soit la langue
  de la page — voir [Référence](../11.reference).
- **`onTwigInitialized()`** — enregistre la fonction Twig
  `proprietaire_email`, pointant vers `resolveProprietaireEmail()`.
- **`resolveProprietaireEmail(?string $route = null)`** — route par défaut
  `/contact` ; cherche la page (`$this->grav['pages']->find(...)`) ; sans
  page trouvée → fallback `plugins.email.to` ; lit `header['proprietaire']`
  → sans valeur → fallback ; charge le compte Grav correspondant
  (`$this->grav['accounts']->load($username)`) → sans compte existant →
  fallback ; retourne `$user['email']` s'il existe, sinon fallback. Chaque
  étape testée en direct pendant ce lot (voir [Flux chronologique,
  chronologie D](../04.flux-chronologique)).
- **`loadEmailPrivateConfig()`** — résout `user://config/email-private.php`
  via le locator Grav ; fichier absent → retour silencieux (aucune
  erreur) ; sinon `require` le fichier (un tableau PHP attendu), et injecte
  chaque paire clé/valeur sous `plugins.email.mailer.smtp.{clé}` — sans
  valider la forme du tableau au-delà d'un `is_array()`. Aucune validation
  de type sur les clés individuelles : une clé inattendue produirait
  simplement une entrée de configuration ignorée par le mailer, pas une
  erreur.

**Commentaire du fichier lui-même** : « Repris du même mécanisme que
`projet-gites`, mais simplifié : un seul site, un seul propriétaire, pas de
routage par gîte » — confirme une filiation directe avec le mécanisme déjà
documenté pour `projet-gites` (non encore audité dans cette documentation,
réservé à un lot ultérieur).

## `grav/user/pages/06.contact/default.md` (+ `.en.md`/`.de.md`) — définition du formulaire

Chaque variante linguistique définit **indépendamment** : les champs
(`nom`, `email`, `telephone`, `message`, `honeypot`), les libellés
traduits, et surtout le bloc `process` — **identique dans sa structure**
entre les 3 langues, mais avec un sujet et un corps d'e-mail **toujours en
français** (`"[Contact lavallee.tech] Nouveau message de {{ form.value.nom }}"`
et `forms/contact-email.html.twig`, tous deux non paramétrés par langue) —
seule la **redirection** (`/fr\|de\|en/contact/confirmation`) est
correctement localisée par variante. Voir l'inventaire complet en
[Référence](../11.reference).

## `grav/user/themes/lavallee-theme/templates/partials/base.html.twig` (69 lignes, lu intégralement)

Layout racine. Points structurants :

- `<html lang="{{ grav.language.getLanguage()|default('fr') }}">` — langue
  HTML correcte par page.
- Boucle `page.translatedLanguages` utilisée **deux fois**, de façon
  cohérente : pour les balises `<link rel="alternate" hreflang>` et pour
  le sélecteur de langue visible — les deux utilisent
  `grav.language.getLanguageURLPrefix(lang_code)`, jamais un chemin en
  dur.
- Footer : `© {{ "now"|date("Y") }} Sébastien Clem` — nom légal réel, par
  contraste avec le titre/auteur du site (« Sébastien Lavallée », un nom
  commercial). Cohérent avec `04.mentions-legales` (voir plus bas), qui
  explique cette distinction ; pas une incohérence.
- Lien LinkedIn du footer : `href="www.linkedin.com/in/sébastien-clem-592a57411"`
  — **sans schéma `https://`**, donc un lien **relatif cassé** dans un
  navigateur (voir [Référence](../11.reference)).
- `mentions-legales` référencé via `{{ base_url }}/mentions-legales`
  (préfixe de langue non explicite — dépend de la résolution de
  `base_url` par Grav, non revérifiée indépendamment ici).

## `grav/user/themes/lavallee-theme/templates/homepage.html.twig` (36 lignes, lu intégralement)

Insère un bloc calculé (3 derniers articles publiés, triés par
`header.date` décroissant) à l'emplacement du marqueur littéral
`<!-- notes-techniques:latest-articles -->` présent dans le contenu Markdown
de `01.home/default*.md`, via
`page.content|replace({...})|raw`. Inclut aussi le formulaire de contact
partagé (`forms('contact-form')`) dans une section `#contact` — **seconde**
inclusion du même formulaire, en plus de la page `/contact` dédiée.

## `grav/user/themes/lavallee-theme/templates/{article,articles-list}.html.twig`

Tri identique dans les deux templates :
`|sort((a, b) => (b.header.date ? b.header.date|date('U') : 0) <=> ...)`
— dupliqué entre `homepage.html.twig`, `articles-list.html.twig` (pas
factorisé en macro/include), mais fonctionnellement identique dans les
trois emplacements. `article.html.twig` n'affiche un bandeau de date que
si `page.header.published_label` est renseigné — absent sur l'article
`01.mfa-keycloak-privacyidea` (voir [Référence](../11.reference)).

## `grav/user/themes/lavallee-theme/templates/etude-cas-{matrix,flotte-mobile,grav}.html.twig`

Trois templates quasi identiques (diff confirmé : seules `body_class`,
l'invite `statusbar_content`, `footer_suffix` et `footer_links` varient),
chacun se contentant de `{{ page.content|raw }}` pour le contenu — aucune
structure imposée au-delà du header/footer communs.

## `forms/contact-email.html.twig` (9 lignes, lu intégralement)

Corps HTML de l'e-mail de notification. Chaque valeur utilisateur est
échappée explicitement (`|e`), le message est en plus passé par `|nl2br`.
Contenu entièrement en français, non paramétré par la langue du
visiteur — voir chronologie D et [Référence](../11.reference).

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : grav/user/plugins/contact/contact.php, grav/user/pages/06.contact/default*.md,
  grav/user/themes/lavallee-theme/templates/partials/base.html.twig,
  grav/user/themes/lavallee-theme/templates/{homepage,article,articles-list}.html.twig,
  grav/user/themes/lavallee-theme/templates/forms/contact-email.html.twig
Dernière vérification : 2026-09-14
```
