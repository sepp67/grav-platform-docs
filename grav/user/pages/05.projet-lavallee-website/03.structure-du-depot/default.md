---
title: "Structure du dépôt"
template: docs
taxonomy:
    category: [docs]
---

## Arborescence au commit `c4341ca7`

```text
.
├── Dockerfile                image applicative, FROM grav-runtime:1.0.4 épinglé
├── .dockerignore              exclut secrets, comptes, données d'exécution
├── .gitignore                 exclut email-private.php, comptes, volumes locaux
├── compose.dev.yml            développement local UNIQUEMENT (port 8080)
├── LICENSE                    MIT
├── README.md
├── docs/
│   └── architecture.md        vue des trois couches, différence avec projet-gites
├── .github/workflows/
│   ├── ci.yml                 build + smoke tests, sur chaque push/PR
│   └── release.yml            publication GHCR, sur tag v*.*.* uniquement
├── grav/user/
│   ├── config/
│   │   ├── system.yaml         thème actif, langues (fr/en/de)
│   │   ├── site.yaml            titre, auteur, métadonnées
│   │   └── plugins/email.yaml   from/to non secrets, engine: smtp
│   ├── languages/{fr,en,de}.yaml
│   ├── plugins/contact/
│   │   ├── contact.php          honeypot + résolution du destinataire + chargement SMTP
│   │   └── contact.yaml
│   ├── themes/lavallee-theme/
│   │   ├── lavallee-theme.yaml  autonome (pas de chaînage streams)
│   │   ├── css/custom.css       (410 lignes)
│   │   └── templates/           10 templates + 1 partial de formulaire
│   └── pages/                   6 sections × 3 langues (seed initial)
└── tests/
    ├── lib.sh                  fonctions partagées (wait_healthy, http_status)
    ├── run-all.sh               build → startup → app-presence → persistence
    ├── test-build.sh
    ├── test-startup.sh
    ├── test-app-presence.sh
    ├── test-persistence.sh
    └── compose.test.yml         stack à 4 volumes, réservé à test-persistence.sh
```

## Pages du seed (`grav/user/pages/`)

| Dossier | Rôle | Langues |
|---|---|---|
| `01.home/` | page d'accueil (hero, expertise, flagships, notes techniques, CTA contact) | fr/en/de |
| `02.etudes-de-cas/{01.matrix,02.flotte-mobile,03.grav}/` | trois études de cas | fr/en/de |
| `03.realisations/02.facturation/` | une réalisation, **explicitement marquée incomplète** | fr/en/de |
| `04.mentions-legales/` | mentions légales, **explicitement marquée incomplète** (champs entre crochets) | fr/en/de |
| `05.articles/` + 4 sous-dossiers | index des articles + 4 articles techniques | fr/en/de |
| `06.contact/` + `01.confirmation/` | définition du formulaire (`visible: false`) + page de confirmation | fr/en/de |

**Anomalie de nommage relevée** : `05.articles/grav-plateforme-de-deploiement-reutilisable/`
est le seul dossier d'article **sans préfixe numérique** (`NN.`), à la
différence de `01.mfa-keycloak-privacyidea/`, `02.nextcloud-…/` et
`03.proxmox-…/` qui suivent tous la convention. Voir [Référence](../11.reference)
pour l'analyse de son effet sur le tri.

## Aucun contenu métier hors ce périmètre

Vérifié par lecture directe de l'arborescence complète : pas de dossier
`roles/`, `collections/`, `inventories/` ou `playbooks/` — confirmant
l'absence de tout branchement Ansible au commit audité (cohérent avec
`docs/architecture.md`, voir [Place dans l'architecture](../02.place-dans-architecture)).

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : git ls-tree -r c4341ca (listing complet du dépôt)
Dernière vérification : 2026-09-14
```
