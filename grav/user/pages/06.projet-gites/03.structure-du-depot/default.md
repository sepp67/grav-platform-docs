---
title: "Structure du dépôt"
template: docs
taxonomy:
    category: [docs]
---

## Arborescence au commit `b27d7af`

```text
.
├── Dockerfile                image applicative, FROM grav-runtime:1.0.4 épinglé
├── .dockerignore              exclut secrets, comptes, fixtures de test, Ressources/ (absent du commit)
├── .gitignore                 exclut email-private.php, comptes, volumes locaux, docs/{cdr,context,...}
├── compose.dev.yml            développement local UNIQUEMENT (port 8080)
├── LICENSE                    MIT
├── README.md
├── docs/                      SIX fichiers de documentation interne détaillée (voir ci-dessous)
├── .github/workflows/
│   ├── ci.yml                 build + 4 tests rapides, sur chaque push/PR
│   └── release.yml            publication GHCR, sur tag v*.*.* uniquement
├── grav/user/
│   ├── config/
│   │   ├── system.yaml          thème actif (gites-theme)
│   │   ├── site.yaml            valeurs par défaut Grav NON personnalisées (voir Référence)
│   │   ├── media.yaml            vide
│   │   ├── gites-photos-taxonomie.yaml   6 catégories de photos
│   │   └── plugins/{api,calendrier-disponibilites,email,login}.yaml
│   ├── plugins/
│   │   ├── contact/               contact.php (routage par gîte) + contact.yaml
│   │   └── calendrier-disponibilites/
│   │       ├── calendrier-disponibilites.php   hook onPageInitialized + Twig
│   │       ├── blueprints.yaml
│   │       └── classes/{Availability,PeriodValidator,Permissions}.php
│   ├── themes/gites-theme/
│   │   ├── gites-theme.yaml       hérite de quark2 via chaînage streams
│   │   ├── blueprints/gite-item.yaml   onglet Admin "Galerie photographique"
│   │   ├── css/custom.css         (334 lignes)
│   │   ├── templates/             9 templates + 1 partial de formulaire + 4 partials
│   │   └── vendor/leaflet/         bibliothèque cartographique vendorisée (JS/CSS/images)
│   └── pages/                     5 sections (voir ci-dessous)
└── tests/
    ├── lib.sh, run-all.sh
    ├── test-{build,startup,app-presence,secrets,persistence,update-rollback}.sh   6 scripts
    ├── fixtures/email-private.{valid,invalid-nonarray,syntax-error}.php
    └── compose.test.yml            stack à 4 volumes, réservé à 2 des 6 tests
```

## Les six fichiers `docs/*.md` — absents de `projet-lavallee-website`

| Fichier | Contenu |
|---|---|
| `architecture.md` | les trois couches, ce que chacune possède/ne possède jamais |
| `runtime-contract.md` | synthèse du contrat exposé par `grav-runtime` (chemins, healthcheck, seed, variables, bootstrap, permissions, arrêt) |
| `compatibility-policy.md` | politique et matrice de certification de version envers `grav-runtime` |
| `seed-lifecycle.md` | classification du contenu initial, garanties du seed, méthodes de migration volontaire (non implémentées) |
| `secrets-and-config.md` | classification complète de `user/config`, mécanisme SMTP, structure attendue du secret |
| `testing.md` | détail de chaque script de test, ce qui est automatisé en CI |
| `release-and-rollback.md` | cycle complet développement → build → tag → publication → déploiement → mise à jour → rollback |

## Pages du seed (`grav/user/pages/`) — monolingue

| Dossier | Rôle |
|---|---|
| `01.home/` | page d'accueil, hérite du rendu `quark2`, liste les gîtes |
| `02.typography/` | page de démonstration standard de Grav/Quark2, **non retirée** — voir `docs/seed-lifecycle.md`, section « Point ouvert » |
| `03.gites/` | `redirect: /gites/gite-un` (pas de page de listing propre à cette route — le listing vit sur la page d'accueil) |
| `03.gites/01.gite-un/` + `01.photos/` | fiche complète, contenu éditorial rédigé |
| `03.gites/02.gite-deux/` + `01.photos/` | fiche **explicitement marquée temporaire** dans son propre contenu |
| `04.gerer/` | page de gestion des disponibilités, réservée aux propriétaires connectés (`visible: false`) |
| `05.contact/` + `01.confirmation/` | définition du formulaire partagé + page de confirmation |

## Aucun contenu métier hors ce périmètre

Vérifié par lecture directe de l'arborescence complète : pas de dossier
`roles/`, `collections/`, `inventories/` ou `playbooks/` — confirmant
l'absence de code Ansible dans ce dépôt, malgré une documentation détaillée
de son usage prévu (voir [Place dans l'architecture](../02.place-dans-architecture)).

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : git ls-tree -r b27d7af (listing complet du dépôt)
Dernière vérification : 2026-09-14
```
