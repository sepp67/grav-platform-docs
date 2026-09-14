---
title: "Configuration et interfaces"
template: docs
taxonomy:
    category: [docs]
---

## `grav/user/config/system.yaml`

```yaml
home: { alias: '/home' }
pages: { theme: gites-theme }
```

Aucune clé `languages:` — confirme l'absence de tout mécanisme
multilingue dans ce dépôt.

## `grav/user/config/site.yaml` — jamais personnalisé

```yaml
title: Grav
author: { name: Joe Bloggs, email: 'joe@example.com' }
metadata: { description: 'Grav is an easy to use, yet powerful, open source flat-file CMS' }
```

Ce sont les valeurs **par défaut du squelette Grav**, jamais éditées —
`docs/secrets-and-config.md` le confirme explicitement : « Contient encore
des valeurs par défaut Grav non pertinentes (`Joe Bloggs`) — nettoyage
éditorial possible, hors périmètre de cette migration ». Aucun template
observé dans ce dépôt ne lit `site.author` (recherche complète dans
`templates/`) — cette configuration reste donc sans effet visible pour un
visiteur, mais figure telle quelle dans le fichier versionné.

## `grav/user/config/plugins/email.yaml`

```yaml
from: admin@lavallee.tech
from_name: 'Site Gîtes'
to: admin@lavallee.tech
mailer: { engine: smtp }
content_type: text/html
```

`to` sert de **fallback** dans `resolveProprietaireEmail()` — utilisé
concrètement quand la route `gite` soumise ne résout à aucun propriétaire
valide (vérifié en direct, voir [Référence](../11.reference)).

## `grav/user/config/gites-photos-taxonomie.yaml`

Six catégories fixes (`salon`, `cuisine`, `chambres`, `salle_de_bain`,
`exterieurs`, `autres`), consommées par `gite-photos.html.twig` pour
grouper les photos par espace, et par le blueprint Admin
(`gite-item.yaml`) pour peupler le sélecteur `.espace`. Les deux endroits
utilisent **la même liste de clés** — cohérence vérifiée par lecture
comparative directe des deux fichiers.

## `grav/user/config/plugins/api.yaml`

```yaml
popularity: { salt: 1b6de9684790171217416a92aa792eee2e0e588e53449792f1251cc3b36f95a4 }
```

`docs/secrets-and-config.md` classe ce `salt` comme « généré
automatiquement par Grav Admin — pas un secret d'authentification »,
donc conservé versionné. Il n'a pas été revérifié par ce lot si ce salt
sert à autre chose que la fonctionnalité de popularité (hors périmètre
de lecture du code de `grav-runtime`).

## `grav/user/config/plugins/login.yaml`

```yaml
user_registration: { options: { send_notification_email: true, send_welcome_email: true } }
```

Active des e-mails automatiques du plugin `login` de `grav-runtime` lors
d'une inscription — mécanisme non ré-audité au niveau code (appartient à
`grav-runtime`).

## `grav/user/config/plugins/calendrier-disponibilites.yaml`

Vide (`{}`) — le plugin n'a aucune configuration statique ; tout son
comportement dépend des en-têtes de page (`proprietaire`,
`disponibilites.periodes_indisponibles`) et des requêtes POST reçues.

## Table de traduction — variables d'environnement de démarrage

| Variable | Source | Consommateur | Sensible |
|---|---|---|---|
| `GRAV_ADMIN_USER`/`_PASSWORD`/`_EMAIL` | fournie à l'exécution | bootstrap admin de `grav-runtime` | mot de passe : **oui**, valeur de développement explicitement jetable |
| `GRAV_ADMIN_FULLNAME`/`_TITLE`/`_LANGUAGE` | optionnelle, fournie à l'exécution | bootstrap admin de `grav-runtime`, hors périmètre de ce dépôt | non |

Ce dépôt ne définit aucune de ces variables lui-même — il les consomme
telles que fournies par l'environnement d'exécution.

## Interface Twig exposée : `proprietaire_email()` et `disponibilites_periodes()`

| Fonction | Signature | Enregistrement | Comportement |
|---|---|---|---|
| `proprietaire_email` | `(?string $giteRoute): ?string` | `contact.php::onTwigInitialized()` | résout un compte Grav depuis une route de page — voir [Référence](../11.reference) pour l'audit complet du routage |
| `disponibilites_periodes` | `(page) => array` | `calendrier-disponibilites.php::onTwigInitialized()` | délègue à `Availability::getUnavailablePeriods($page)`, lecture seule |

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : grav/user/config/{system,site}.yaml, grav/user/config/plugins/*.yaml,
  grav/user/config/gites-photos-taxonomie.yaml, docs/secrets-and-config.md
Dernière vérification : 2026-09-14
```
