---
title: "Flux chronologique"
template: docs
taxonomy:
    category: [docs]
---

Ce dépôt présente cinq chronologies structurellement différentes.
Chacune est recalculée directement depuis le code du commit audité
(`Dockerfile`, `contact.php`, workflows CI, `tests/*.sh`), jamais depuis un
titre de section ou un nom de test.

## A. Construction de l'image applicative (`docker build`)

Chemin : `Dockerfile`, lu en intégralité (22 lignes).

| # | Étape | Preuve |
|---|---|---|
| 1 | Image parente épinglée | `FROM ghcr.io/sepp67/grav-runtime:1.0.4` — jamais `latest` |
| 2 | Copie du code applicatif immuable : thème | `COPY grav/user/themes/ → /var/www/html/user/themes/` |
| 3 | Copie du code applicatif immuable : plugin (`contact`) | `COPY grav/user/plugins/ → /var/www/html/user/plugins/` |
| 4 | Copie du code applicatif immuable : traductions (chrome multilingue) | `COPY grav/user/languages/ → /var/www/html/user/languages/` |
| 5 | Copie de la configuration non secrète versionnée | `COPY grav/user/config/ → /var/www/html/user/config/` |
| 6 | Copie du contenu initial vers l'emplacement de **seed**, jamais directement dans un volume persistant | `COPY grav/user/pages/ → /opt/grav-seed/pages/` |
| 7 | Image résultante | `projet-lavallee:dev` (local) ou `ghcr.io/sepp67/projet-lavallee` (CI de release) |

**Propriété vérifiée** (commentaire du `Dockerfile`, confirmé par sa
structure) : ce fichier ne réimplémente **jamais** PHP, Nginx, Grav
Core/Admin, l'entrypoint, le healthcheck ou le bootstrap admin — chacune
de ses 4 instructions `COPY` cible exclusivement un sous-répertoire de
`user/`, jamais un chemin système.

**Propriétaire des fichiers** : `--chown=www-data:www-data` sur chaque
`COPY`, cohérent avec l'utilisateur d'exécution attendu par `grav-runtime`
(non revérifié directement dans ce dépôt, dépend du contrat du Lot 3).

## B. Premier démarrage

Chemin : mécanisme du **runtime** (`grav-runtime`, hors périmètre de ce
dépôt) déclenché par le contenu fourni par ce dépôt. Reconstruit et
**vérifié en direct** pendant ce lot (voir [Tests et CI](../08.tests-et-ci)).

| # | Étape | Preuve |
|---|---|---|
| 1 | Répertoires persistants initialement vides (`pages`, `accounts`, `data`, `images`) | premier `docker run` sans volume préexistant |
| 2 | Initialisation depuis `/opt/grav-seed/pages/` vers le volume `user/pages` vide | mécanisme du runtime (Lot 3), déclenché par la présence du seed fourni par ce dépôt à l'étape A.6 |
| 3 | Création ou validation du compte administrateur | variables `GRAV_ADMIN_USER`/`GRAV_ADMIN_PASSWORD`/`GRAV_ADMIN_EMAIL` — **vérifié en direct** : le destinataire du formulaire de contact a été résolu depuis le compte Grav **synthétique** `admin@example.com`, créé exclusivement dans l'environnement de test construit pour ce lot (jamais un compte ni un destinataire opérationnel), confirmant que la résolution passe bien par le compte et non par la valeur de repli (`plugins.email.to`) |
| 4 | Chargement de la configuration copiée à l'étape A.5 | `system.yaml` (thème actif, langues), `site.yaml`, `plugins/email.yaml` |
| 5 | Disponibilité du site | `/` → HTTP 302 vers `/fr` (langue par défaut préfixée, `include_default_lang: true`), `/fr` → HTTP 200 — **vérifié en direct** |

**Point de vigilance** : la présence du fichier `Dockerfile` ne prouve pas
son exécution ; l'étape 2-5 ci-dessus n'est affirmée que parce qu'elle a
été **observée en direct** pendant ce lot (conteneur jetable, sans volume
préexistant) — voir [Tests et CI](../08.tests-et-ci) pour le détail des
commandes exécutées.

## C. Redémarrage ou remplacement du conteneur

Vérifié en direct via `tests/test-persistence.sh`, rejoué pendant ce lot
(voir [Tests et CI](../08.tests-et-ci)).

| # | Étape | Preuve |
|---|---|---|
| 1 | Volumes déjà peuplés (`pages`, `accounts`, `data`, `images`) | 4 volumes Docker nommés, distincts, montés par `compose.test.yml`/`compose.dev.yml` |
| 2 | Absence de nouveau seed | le mécanisme de seed du runtime ne s'active que si le volume est vide (étape B.2) — un volume déjà peuplé n'est jamais réinitialisé |
| 3 | Conservation des pages, comptes, données et images | un marqueur écrit dans chacun des 4 répertoires **survit** à un redémarrage du même conteneur — vérifié en direct |
| 4 | Remplacement du code immuable par celui de la nouvelle image | le thème, le plugin, les langues et la configuration (étapes A.2-A.5) sont réécrits à chaque nouveau conteneur depuis l'image — jamais lus depuis un volume persistant |

## D. Soumission du formulaire de contact

Chemin : `contact.php` (94 lignes, lu en intégralité) + `06.contact/default.md`
(frontmatter) + `forms/contact-email.html.twig`. **Vérifié en direct** via
une soumission réelle contre un SMTP factice (Mailpit) — voir [Tests et
CI](../08.tests-et-ci) pour les commandes exactes et [Référence](../11.reference)
pour les constats détaillés (échappement, injection, CSRF).

| # | Étape | Détail vérifié |
|---|---|---|
| 1 | Rendu du formulaire | `{% include 'forms/form.html.twig' with { form: forms('contact-form') } %}` — `forms/form.html.twig` n'appartient **pas** à ce dépôt (fourni par le Form plugin de Grav Core, dans `grav-runtime`) ; inclus deux fois : sur `/contact` et dans la section `#contact` de la page d'accueil, via la **même** définition partagée |
| 2 | Champs cachés générés par Grav Core, jamais par ce dépôt | `__form-name__`, `__unique_form_id__`, `form-nonce` (avec `data-nonce-action="form"`) — **observés en direct** dans le HTML rendu |
| 3 | Validation des champs requis (`nom`, `email`, `message`) | soumission avec `message` vide → pas de redirection, HTTP 200, formulaire ré-affiché — **vérifié en direct** |
| 4 | Rejet d'une charge de type script avant tout traitement, sur un champ texte (`nom` **et** `message`) | soumission avec `<script>…</script>` dans `nom` → rejetée, message « Erreurs XSS probablement détectées dans le champ 'Nom' » ; la même charge dans `message` → rejetée, message « …dans le champ 'Message' » — **vérifié en direct pour les deux champs** ; entrée refusée avant toute construction d'e-mail, aucun message produit. Mécanisme non identifié précisément dans le code de ce dépôt (aucun filtre de ce type dans `contact.php` ni dans les templates) — attribué par **déduction** à une validation de Grav Core (`type: text`/`type: textarea`), non vérifiée par lecture de son code source |
| 5 | Rejet d'une saisie multi-ligne dans un champ `type: text` (`nom`) | soumission avec un retour à la ligne dans `nom` → rejetée, message « Saisie non valide "Nom" » — **vérifié en direct** ; entrée refusée avant tout traitement, aucun message produit. Mécanisme attribué **par déduction** à Grav Core, non confirmé par lecture de son code source |
| 5bis | Une saisie multi-ligne dans le champ `email` (`type: email`), elle, n'est **pas rejetée par le formulaire** | soumission avec un retour à la ligne dans `email` → **acceptée** (HTTP 302, redirection vers la confirmation), **contrairement** au champ `nom` — voir la ligne « CRLF dans email » du tableau de preuve ci-dessous pour ce qu'il advient ensuite de cette valeur |
| 6 | Honeypot | `onFormValidationProcessed` : si `form.value('honeypot')` est non vide **et** `form.getName() === 'contact-form'`, lève une `ValidationException` — soumission avec honeypot rempli → pas de redirection, message générique (« Votre demande n'a pas pu être traitée. ») — **vérifié en direct**, mécanisme identifié précisément : ce dépôt (`contact.php`) |
| 7 | `resolveProprietaireEmail()` — résolution du destinataire réel | route par défaut `/contact` (paramètre non fourni dans `to: "{{ proprietaire_email() }}"`) ; cherche la page, lit `header['proprietaire']` (`admin`), charge le compte Grav `admin`, retourne son adresse e-mail si le compte existe **et** a une adresse — sinon `plugins.email.to` (`contact@lavallee.tech`) |
| 8 | Chargement de `email-private.php`, avant tout traitement de formulaire | `onPluginsInitialized()` appelle `loadEmailPrivateConfig()` **inconditionnellement**, dès l'initialisation du plugin — pas seulement lors d'une soumission de formulaire ; absence de fichier → retour silencieux, aucune erreur |
| 9 | Appel du plugin Email (Grav Core) | `to`, `reply_to: form.value('email')`, `subject`, `body` — 4 clés du bloc `process.email` du frontmatter |
| 10 | Template du message | `forms/contact-email.html.twig` : champs échappés via `|e` ; le sujet (`{{ form.value.nom }}`, sans `|e` explicite) est protégé par l'**autoescape Twig par défaut**, confirmé en direct (un `&` dans le nom ressort `&amp;` dans le sujet reçu) |
| 11 | Redirection vers la confirmation | `redirect: /fr/contact/confirmation` (FR), `/de/contact/confirmation` (DE), `/en/contact/confirmation` (EN) — chaque variante linguistique de la page porte sa **propre** redirection localisée — **vérifié en direct** pour FR |
| 12 | Chemins d'échec | validation requise échouée, XSS détecté, saisie multi-ligne rejetée, ou honeypot rempli → HTTP 200, pas de redirection, notice d'erreur affichée dans la langue de l'interface Grav Core (pas nécessairement celle du site) |

### Tableau de preuve — chaque charge testée en direct, résultat exact

Sept soumissions rejouées **individuellement** (session propre par test :
un `GET` du formulaire, extraction des 3 champs cachés de **cette même**
réponse, puis un seul `POST`), contre un conteneur jetable et un SMTP
factice (Mailpit) sur un port et un réseau Docker dédiés à ce contrôle.
Colonne « Résultat formulaire » : ce que l'utilisateur reçoit. Colonne
« E-mail capturé » : si Mailpit a reçu un message pour cette soumission.
Colonne « Valeur observée » : ce que contient réellement ce message, le
cas échéant. Une charge n'est **jamais** qualifiée de « rejetée » si un
e-mail a malgré tout été produit — voir la ligne CRLF/email ci-dessous,
seul cas où l'entrée est acceptée par le formulaire puis neutralisée plus
loin dans la chaîne.

| Test | Charge et champ | Résultat formulaire | E-mail capturé | Valeur observée | Mécanisme responsable |
|---|---|---|---|---|---|
| XSS dans `nom` | `<script>alert(1)</script>` | HTTP 200, pas de redirection, « Erreurs XSS probablement détectées dans le champ 'Nom' » | **non** | — | non identifié dans le code de ce dépôt ; **déduction** : validation de Grav Core sur `type: text` |
| XSS dans `message` | `<script>alert(document.cookie)</script>` | HTTP 200, pas de redirection, « Erreurs XSS probablement détectées dans le champ 'Message' » | **non** | — | idem, **déduction** : Grav Core, `type: textarea` |
| CRLF dans `email` | `valide@example.invalid\r\nBcc: attacker@example.invalid` | HTTP 302 → `/fr/contact/confirmation` (**acceptée** par le formulaire) | **oui** | En-têtes réels du message capturé : aucun `Reply-To:`, aucun `Bcc:` — la valeur n'a **pas** été utilisée pour construire un en-tête, elle a été silencieusement omise comme `Reply-To`. La valeur brute (avec le retour à la ligne littéral) apparaît en revanche dans le **corps** HTML de l'e-mail (ligne « E-mail : »), sans conséquence d'en-tête puisqu'un retour à la ligne dans un corps HTML n'est qu'un saut visuel | entrée acceptée par le formulaire (mécanisme non identifié — **déduction** : validation `type: email` de Grav Core, insuffisamment stricte pour rejeter cette valeur) ; neutralisation de l'en-tête `Reply-To` attribuée **par déduction** à la bibliothèque d'e-mail sous-jacente à Grav Core (PHPMailer, non vérifié par lecture de son code) |
| CRLF dans `nom` (utilisé par le sujet) | `Test\r\nBcc: attacker@example.invalid` | HTTP 200, pas de redirection, « Saisie non valide "Nom" » | **non** | — | non identifié dans le code de ce dépôt ; **déduction** : Grav Core, `type: text` |
| Honeypot rempli | `rempli-par-un-bot` | HTTP 200, pas de redirection, « Votre demande n'a pas pu être traitée. » | **non** | — | **identifié avec certitude** : `contact.php::onFormValidationProcessed()`, dans ce dépôt |
| E-mail syntaxiquement invalide | `pas-une-adresse` | HTTP 200, pas de redirection, « Saisie non valide "E-mail" » | **non** | — | non identifié dans le code de ce dépôt ; **déduction** : validation de format de Grav Core, `type: email` |
| Soumission nominale | `nom="Jean Dupont"`, `email="valide@example.invalid"`, `message="Message de test nominal."` | HTTP 302 → `/fr/contact/confirmation` | **oui** | `To: admin@example.com` (compte de test synthétique, voir [Référence](../11.reference)) ; sujet et corps conformes aux valeurs soumises, caractères spéciaux correctement échappés (vérifié séparément avec `&`, `<b>`, apostrophes et guillemets dans une soumission distincte) | traduction du frontmatter (`process.email`) + Twig autoescape ; ce dépôt pour le contenu, Grav Core pour l'envoi |

**Ce que ce tableau ne permet pas d'affirmer** : que Grav Core ou
PHPMailer sont, en général, invulnérables à toute forme d'injection
d'en-tête ou de XSS — seules les charges listées ci-dessus, dans ce
contexte précis, ont été testées. Aucune lecture du code source de Grav
Core ou de la bibliothèque d'e-mail sous-jacente n'a été effectuée pour ce
lot ; toute attribution de mécanisme à ces composants est explicitement
qualifiée de **déduction** ci-dessus, jamais présentée comme confirmée par
lecture de code.

## E. Développement et publication

Chemin : `compose.dev.yml`, `.github/workflows/{ci,release}.yml`, `tests/run-all.sh`.

| # | Étape | Preuve |
|---|---|---|
| 1 | Développement local | `docker compose -f compose.dev.yml up -d --build` — port `8080`, identifiants admin fixes et jetables (`ChangeMe123`), 4 volumes nommés séparés (jamais un bind-mount de `user/`) |
| 2 | Build local reproductible | `docker build --pull` avec 3 tentatives (`tests/test-build.sh`) — **exécuté réellement** pendant ce lot |
| 3 | Tests disponibles | `tests/run-all.sh` : build → startup → app-presence → persistence, séquentiels, arrêt au premier échec (`set -eu`) — **exécutés réellement** pendant ce lot |
| 4 | Workflow CI (`ci.yml`) | déclenché sur tout push/PR ; build + 3 des 4 tests (`test-persistence.sh` **exclu**, documenté comme "non bloquant pour ce workflow" car scénario plus long) ; login GHCR en lecture seule (pour tirer `grav-runtime`) ; « inerte tant que ce dépôt n'a pas de remote Git » (commentaire du fichier) |
| 5 | Conditions de publication (`release.yml`) | déclenché **uniquement** par un tag `v[0-9]+.[0-9]+.[0-9]+` ou un déclenchement manuel (`workflow_dispatch`) — jamais sur un simple push de `main` |
| 6 | Tags OCI produits | `{{version}}`, `{{major}}.{{minor}}`, `{{major}}` (tags sémantiques) **+ `latest`** — mais uniquement `enable: startswith(github.ref, 'refs/tags/v')`, donc `latest` n'est produit qu'au moment d'une release taguée, jamais sur un simple commit ; `push:` lui-même suit la même condition |
| 7 | Relation avec `grav-sites-ops` et `ansible-role-grav-site` | **aucune** au commit audité — l'image publiée par `release.yml` n'est référencée par aucun registre ni inventaire observé dans les dépôts déjà documentés (Lots 4 et 5) ; le nom d'image `ghcr.io/sepp67/projet-lavallee` n'apparaît dans aucun fichier de `grav-sites-ops` ou `ansible-role-grav-site` |

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : Dockerfile, grav/user/plugins/contact/contact.php, grav/user/pages/06.contact/default*.md,
  grav/user/themes/lavallee-theme/templates/forms/contact-email.html.twig, .github/workflows/{ci,release}.yml,
  tests/*.sh
Dernière vérification : 2026-09-14
```
