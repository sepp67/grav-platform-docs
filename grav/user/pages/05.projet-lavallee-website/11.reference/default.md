---
title: "Référence"
template: docs
taxonomy:
    category: [docs]
---

## Inventaire éditorial et multilingue

| Route logique | Template | FR | DE | EN | Visible | État |
|---|---|---:|---:|---:|---:|---|
| Accueil (`/`) | `homepage` | ✅ | ✅ | ✅ | oui | complet |
| Étude de cas Matrix | `etude-cas-matrix` | ✅ | ✅ | ✅ | oui | complet |
| Étude de cas flotte mobile | `etude-cas-flotte-mobile` | ✅ | ✅ | ✅ | oui | complet |
| Étude de cas Grav CMS | `etude-cas-grav` | ✅ | ✅ | ✅ | oui | complet |
| Réalisation : facturation | `page-simple` | ✅ | ✅ | ✅ | oui | **auto-déclarée incomplète** (`placeholder-note`, détails techniques et lien de dépôt manquants) |
| Mentions légales | `page-simple` | ✅ | ✅ | ✅ | oui | **auto-déclarée incomplète** (raison sociale, SIRET, adresse, hébergeur : tous entre crochets) |
| Index des articles | `articles-list` | ✅ | ✅ | ✅ | oui | complet |
| Article : MFA/Keycloak/privacyIDEA | `article` | ✅ | ✅ | ✅ | oui | complet, mais **sans `published_label`** dans les 3 langues — seul article sans bandeau de date affiché |
| Article : Nextcloud, rôle dédié | `article` | ✅ | ✅ | ✅ | oui | complet |
| Article : Proxmox staging/production | `article` | ✅ | ✅ | ✅ | oui | complet |
| Article : plateforme de déploiement réutilisable | `article` | ✅ | ✅ | ✅ | oui | complet, mais **dossier sans préfixe numérique** (`NN.`) — seule exception de la rubrique `articles/` |
| Contact | `contact` | ✅ | ✅ | ✅ | non (`visible: false`) | complet — **soumission réellement testée en FR uniquement** ; DE/EN présents et accessibles (HTTP 200, `test-app-presence.sh`), leur comportement de soumission est **déduit** du frontmatter, jamais soumis en direct — voir « Portée réelle des tests par langue » ci-dessous |
| Confirmation de contact | `page-simple` | ✅ | ✅ | ✅ | non (`visible: false`) | complet |

Chrome de l'interface (navigation, pied de page, libellés de formulaire,
sélecteur de langue) : les 3 fichiers `grav/user/languages/{fr,en,de}.yaml`
sont **structurellement parallèles**, clé pour clé — aucune clé manquante
détectée par lecture comparative complète.

## Portée réelle des tests par langue

Le formulaire de contact n'a été **réellement soumis** (les 7 charges de
sécurité + les 2 soumissions valides, voir [Flux chronologique, chronologie
D](04.flux-chronologique)) que contre la variante **française**
(`/fr/contact`). Aucune soumission réelle n'a été effectuée contre
`/de/contact` ni `/en/contact` pendant ce lot.

| Aspect | FR | DE | EN |
|---|---|---|---|
| Champs et 3 champs cachés présents dans le HTML rendu | testé en direct | déduit (structure de frontmatter identique) | déduit (structure de frontmatter identique) |
| Validation requise / XSS / CRLF / honeypot / e-mail invalide | testé en direct (7 charges) | **non testé** — déduit par analogie avec FR (même bloc `process`, même absence de logique de validation propre à ce dépôt au-delà du honeypot) | **non testé** — idem |
| Résolution du destinataire (`proprietaire_email()`) | testé en direct (`admin@example.com`) | **non testé** — le code de `resolveProprietaireEmail()` ne dépend pas de la langue active (il cherche `/contact`, sans préfixe), donc un comportement identique est **attendu**, mais non vérifié séparément pour la page `/de/contact`/`/en/contact` | **non testé** — idem |
| Redirection vers la confirmation | testé en direct (`/fr/contact/confirmation`) | **non testé** — la valeur `/de/contact/confirmation` est lue dans le frontmatter, jamais déclenchée en direct | **non testé** — idem |
| Accessibilité de la page (HTTP 200) | testé en direct | testé en direct (`test-app-presence.sh`, route `/de/contact`) | testé en direct (`test-app-presence.sh`, route `/en/contact`) |

## Constats détaillés

- **Lien LinkedIn cassé** — `templates/partials/base.html.twig` :
  `href="www.linkedin.com/in/sébastien-clem-592a57411"`, sans schéma
  `https://`. Un navigateur résout ce chemin comme **relatif** à la page
  courante (p. ex. `https://lavallee.tech/fr/www.linkedin.com/in/...`),
  jamais vers LinkedIn. Présent à l'identique dans les 3 langues (le lien
  vit dans le layout partagé, pas dans une page traduite).
- **L'e-mail de contact n'est localisé sur aucun des deux axes que ce
  dépôt contrôle : ni le sujet, ni le corps** — écart vérifié précisément :
  - le **sujet** (`subject: "[Contact lavallee.tech] Nouveau message de
    {{ form.value.nom }}"`) est un texte littéral **identique et en
    français** dans les 3 fichiers `06.contact/default.{md,en.md,de.md}` ;
  - le **corps** (`forms/contact-email.html.twig`, un fichier **unique**,
    non décliné par langue) est également en français, quelle que soit
    la langue de la page qui l'inclut ;
  - la **redirection** de confirmation, elle, **est** correctement
    localisée par variante (`/fr\|de\|en/contact/confirmation`) —
    vérifiée en direct pour FR, déduite pour DE/EN (voir tableau
    ci-dessus) ;
  - les **messages d'erreur de validation** affichés en cas de rejet
    (XSS, saisie invalide, champ requis) proviennent de Grav Core, pas de
    ce dépôt, et ont été observés **en français** lors des tests — menés
    uniquement contre `/fr/contact` ; leur langue réelle sur `/de/contact`
    ou `/en/contact` n'a pas été vérifiée et n'est pas déductible du code
    de ce dépôt (dépend du comportement interne de Grav Core, hors
    périmètre de lecture de ce lot) ;
  - conclusion : un visiteur anglophone ou germanophone dont la
    soumission aboutit reçoit une notification par e-mail entièrement en
    français (sujet et corps), mais est redirigé vers une page de
    confirmation dans sa propre langue.
- **`published_label` absent de l'article MFA/Keycloak, dans les 3
  langues** — les 3 autres articles portent tous ce champ ; celui-ci ne
  l'a dans aucune langue, donc n'affiche jamais le bandeau « Publié le… ».
- **Formats de date hétérogènes entre articles** — `01.mfa` (FR) utilise
  un timestamp Unix brut (`date: 1782086400`) ; ses variantes DE/EN
  utilisent `date: 2026-06-22` (ISO) mais aussi, de façon plus notable,
  `published: 22. Juni 2026` / `published: June 22, 2026` — une **chaîne
  de caractères** assignée à la clé réservée `published` de Grav (qui
  attend normalement un booléen ou une absence de valeur), là où les 3
  autres articles utilisent `published_label` (une clé libre, non
  réservée) pour le même usage d'affichage. La version FR de cet article
  utilise, elle, `published: true` — un booléen correctement formé.
  `02.nextcloud-…` et `03.proxmox-…` utilisent un format `DD-MM-YYYY`
  (`date: 22-06-2026`) ; `grav-plateforme-de-deploiement-reutilisable`
  utilise `DD-MM-YYYY HH:MM` (`date: '23-08-2026 12:00'`). **Vérifié en
  direct** : malgré cette hétérogénéité, les 3 variantes linguistiques de
  l'article MFA/Keycloak répondent chacune HTTP 200
  (`test-app-presence.sh`) — la valeur `published` non booléenne
  n'empêche donc pas l'accès direct à la page. Son éventuelle absence du
  **listing** des articles (`.published` en tant que filtre de collection)
  n'a **pas** été vérifiée indépendamment pendant ce lot — limite de
  preuve assumée.
- **Deux techniques de lien interne coexistent** dans le même thème :
  liens codés en dur avec préfixe de langue explicite dans le contenu
  Markdown de la page d'accueil (`/fr/etudes-de-cas/matrix`, correct
  uniquement parce que chaque variante linguistique a sa propre valeur
  codée en dur) contre liens relatifs à `base_url` dans les templates
  d'étude de cas (`{{ base_url }}/etudes-de-cas/matrix`, résolu
  dynamiquement). Aucune des deux formes n'est fautive isolément, mais la
  coexistence est une incohérence de convention, pas une architecture
  délibérée documentée comme telle.
- **Slugs de route non traduits** — `etudes-de-cas`, `realisations`,
  `articles`, `mentions-legales`, `contact` restent en français dans les 3
  langues (`/en/etudes-de-cas/matrix`, pas `/en/case-studies/matrix`).
  Constat factuel, pas nécessairement une erreur : Grav n'offre pas de
  traduction de route par défaut sans mécanisme dédié, absent de ce dépôt.
- **Dossier d'article sans préfixe numérique** — voir [Structure du
  dépôt](03.structure-du-depot). Effet réel : **aucun**, sur l'ordre
  affiché à l'utilisateur (`articles-list.html.twig` et `homepage.html.twig`
  trient explicitement par `header.date`, ignorant l'ordre de dossier par
  défaut) — mais reste une incohérence de convention de nommage au niveau
  du dépôt.

## Écarts entre README/Dockerfile/CI/comportement observé

| Source | Affirmation | Code/comportement réel | Écart |
|---|---|---|---|
| `docs/architecture.md` | branchement vers `ansible-role-grav-site` « pas encore » effectif | aucune trace Ansible dans le dépôt (confirmé) | **aucun** — cohérence confirmée |
| README | image publiée sous `ghcr.io/sepp67/projet-lavallee` | `release.yml` : `IMAGE_NAME: ${{ github.repository_owner }}/projet-lavallee` → résout à `sepp67/projet-lavallee` si le dépôt appartient à `sepp67` | cohérent, sous réserve du propriétaire réel du dépôt GitHub (non vérifié indépendamment) |
| README | « Tested & Supported » : tests couvrent build, démarrage, présence, routes multilingues, **formulaire de contact**, persistance | `tests/` ne contient **aucun** test de soumission réelle du formulaire — `test-app-presence.sh` vérifie uniquement la présence du champ `nom` dans le HTML | **écart réel** : le README annonce une couverture du « contact form presence », ce qui est exact (présence, pas soumission) — mais un lecteur pressé pourrait comprendre « testé » comme « soumission vérifiée », ce qui n'est pas le cas dans ce dépôt |
| `compose.dev.yml` | port `8080` | confirmé, et distinct des ports de test (`18080`-`18082`) et de l'audit de ce lot (`18095`-`18097`) | aucun |
| `ci.yml` | « inerte tant que ce dépôt n'a pas de remote Git » | cohérent avec l'absence de run CI observable pour ce lot | aucun |
| Version de `grav-runtime` | `1.0.4`, épinglée | identique au tag documenté au [Lot 3](../02.grav-runtime) | cohérent |
| Présence d'un tag applicatif | **aucun**, au commit audité | confirmé : `git tag --points-at c4341ca7` ne retourne rien (vérifié dans le worktree) | conforme aux instructions de ce lot, pas une anomalie |

## Glossaire

| Terme | Définition |
|---|---|
| Seed | contenu initial copié dans `/opt/grav-seed/pages/`, appliqué uniquement si le volume `user/pages` est vide au premier démarrage |
| Code applicatif immuable | thème, plugin, langues, configuration — réécrits à chaque nouveau conteneur, jamais lus depuis un volume persistant |
| `proprietaire` | clé de frontmatter de `/contact` désignant le nom du compte Grav dont l'adresse sert de destinataire réel |
| Honeypot | champ caché destiné aux robots ; son remplissage rejette la soumission — **pas** une protection complète contre le spam (un robot qui ignore le champ n'est pas arrêté) |
| Nonce de formulaire | jeton anti-CSRF généré par le Form plugin de Grav Core, vérifié en direct dans le HTML rendu, non implémenté par ce dépôt |

## Limites de preuve de cette rubrique

- Aucun run CI distant n'a été observé (pas d'accès à l'historique GitHub
  Actions de ce dépôt) — toute affirmation sur `ci.yml`/`release.yml`
  repose uniquement sur la lecture des fichiers YAML.
- L'appartenance de l'article MFA/Keycloak (DE/EN) au **listing** filtré
  par `.published` n'a pas été vérifiée indépendamment de sa page directe.
- Le contrat de déploiement avec `ansible-role-grav-site` n'est pas
  vérifiable : il n'existe pas encore pour ce dépôt.
- La résolution de `{{ base_url }}/mentions-legales` (sans préfixe de
  langue explicite dans le template) n'a pas été testée séparément pour
  les 3 langues — seul le comportement global multilingue a été vérifié
  via `test-app-presence.sh`, qui teste les chemins déjà préfixés
  (`/fr/mentions-legales`, etc.), pas ce lien précis du footer.
- Le propriétaire réel du dépôt GitHub (`sepp67`) n'a pas été vérifié
  indépendamment — seule la cohérence interne du workflow est confirmée.

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : README.md, grav/user/pages/**/*.md (frontmatters, lus intégralement),
  grav/user/themes/lavallee-theme/templates/partials/base.html.twig, grav/user/languages/{fr,en,de}.yaml
Dernière vérification : 2026-09-14
```
