---
title: "Configuration et interfaces"
template: docs
taxonomy:
    category: [docs]
---

## `grav/user/config/system.yaml`

```yaml
home: { alias: '/home' }
pages: { theme: lavallee-theme }
languages:
  supported: [fr, en, de]
  default_lang: fr
  include_default_lang: true
  include_default_lang_file_extension: false
```

`include_default_lang: true` explique le comportement observé en direct :
`/` répond HTTP 302 vers `/fr` (jamais un rendu direct sans préfixe de
langue) — confirmé par `tests/test-startup.sh` et rejoué pendant ce lot.

## `grav/user/config/site.yaml`

```yaml
title: Sébastien Lavallée
author: { name: Sébastien Lavallée, email: 'contact@example.com' }
metadata: { description: '...' }
```

`author.email` est une adresse **placeholder** (`contact@example.com`,
domaine réservé RFC 2606) — jamais l'adresse réelle du site
(`contact@lavallee.tech`, définie séparément dans `plugins/email.yaml`).
Cette valeur n'est utilisée par aucun template observé dans ce dépôt (grep
sur `site.author` : aucune occurrence dans `templates/`).

## `grav/user/config/plugins/email.yaml`

```yaml
from: contact@lavallee.tech
from_name: 'lavallee.tech'
to: contact@lavallee.tech
mailer: { engine: smtp }
content_type: text/html
```

`to` sert de **fallback** dans `resolveProprietaireEmail()` — jamais la
destination normale en fonctionnement nominal (qui résout vers le compte
`admin`, voir [Sections de code](05.sections-de-code)). Aucun identifiant
SMTP ici : `mailer.engine: smtp` sans `mailer.smtp.server/port/user/password`
— ces clés ne sont injectées qu'à l'exécution par
`loadEmailPrivateConfig()`, si le fichier hors dépôt existe.

## Interface publique consommée : `grav-runtime`

Ce dépôt ne connaît que les points de montage documentés par le contrat du
runtime (Lot 3) : `/var/www/html/user/{themes,plugins,languages,config}/`
pour le code immuable, `/opt/grav-seed/pages/` pour le contenu initial. Il
ne connaît ni la logique interne du runtime, ni son mécanisme de
healthcheck, ni son entrypoint.

## Table de traduction — variables d'environnement de démarrage

| Variable | Source (au commit audité) | Consommateur | Sensible |
|---|---|---|---|
| `GRAV_ADMIN_USER` | fournie à l'exécution (`compose.dev.yml`, tests, ou déploiement réel une fois branché) | bootstrap admin de `grav-runtime` | non (nom d'utilisateur) |
| `GRAV_ADMIN_PASSWORD` | idem | idem | **oui** — valeur de développement `ChangeMe123` explicitement jetable |
| `GRAV_ADMIN_EMAIL` | idem | idem, puis lu indirectement par `resolveProprietaireEmail()` via le compte créé | non, mais destinée à devenir l'adresse réelle du site en production |

Ce dépôt ne **définit** aucune de ces trois variables lui-même — il les
consomme telles que fournies par l'environnement d'exécution
(`compose.dev.yml` en développement, un mécanisme de déploiement réel une
fois `ansible-role-grav-site` branché).

## Interface Twig exposée : `proprietaire_email()`

| Aspect | Détail |
|---|---|
| Signature | `proprietaire_email(?string $route = null): ?string` |
| Enregistrement | `onTwigInitialized()`, fonction Twig globale |
| Paramètre par défaut | `/contact` |
| Utilisation observée dans ce dépôt | **sans argument**, dans les 3 variantes linguistiques de `06.contact/default*.md` (`to: "{{ proprietaire_email() }}"`) |
| Sortie | adresse e-mail du compte `proprietaire`, ou le fallback `plugins.email.to` |

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : grav/user/config/system.yaml, grav/user/config/site.yaml, grav/user/config/plugins/email.yaml,
  grav/user/plugins/contact/contact.php
Dernière vérification : 2026-09-14
```
