---
title: "Structure du dépôt"
template: docs
taxonomy:
    category: [docs]
---

## Arborescence au tag `v1.0.4`

```text
.
├── Dockerfile                     construction de l'image (voir Flux chronologique A)
├── .dockerignore                  exclut test/, Ressources/, README.md du contexte de build
├── .gitignore
├── README.md                      contrat, variables, tests documentés (487 lignes)
├── docker/
│   ├── entrypoint.sh               PID 1 : permissions, seed, bootstrap, supervision (Flux B)
│   ├── seed-init.sh                copie non destructive d'un sous-répertoire seed
│   ├── bootstrap-admin.sh          création tri-state du compte admin
│   ├── healthcheck.sh              CMD du HEALTHCHECK Docker (appelle /healthz)
│   ├── healthz.php                 endpoint HTTP minimal, hors front-controller Grav
│   ├── nginx.conf                  routage, refus des fichiers sensibles
│   ├── php-fpm.conf                pool "www", tourne sous www-data
│   └── theme-overrides/quark2/     surcharge ciblée du thème vendorisé (footer)
├── .github/workflows/docker.yml    build + publication sur push de tag "vX.Y.Z"
└── test/
    ├── config/system.yaml          config minimale pour le harnais de test
    └── seed/pages/01.home/         page seed de test
```

Chaque dossier/fichier structurant est repris en détail dans [Sections de
code](../05.sections-de-code) (scripts) ou [Configuration et
interfaces](../06.configuration-et-interfaces) (fichiers de config).

## Écart constaté : `test/compose.yml`

Le `README.md` documente longuement un harnais `test/compose.yml`
(sections "Lancer l'image", "Tests"). Ce fichier **existe bien sur le
disque local** du mainteneur, mais **n'est pas suivi par Git** : le
`.gitignore` du dépôt contient `**/compose.yml` et `**/docker-compose.yml`.
Il est donc absent de l'arbre du tag `v1.0.4` (confirmé par `git ls-tree -r
v1.0.4`) et absent de toute archive ou clone frais de ce tag.

Conséquence pratique : quelqu'un qui clone `v1.0.4` pour la première fois
ne peut pas suivre littéralement la section "Tests" du README sans
recréer `test/compose.yml` lui-même à partir de sa description. Le contenu
de ce fichier est néanmoins repris fidèlement dans [Tests et
CI](../08.tests-et-ci) de cette rubrique, en le signalant explicitement
comme non versionné.

## Ce qui n'apparaît jamais dans ce dépôt

Aucun nom de site, domaine, adresse IP ou identifiant réel — vérifié par
lecture directe de chaque fichier ci-dessus (pas seulement par la
déclaration du README). Le dossier `Ressources/` mentionné par le README
("les deux projets sources ayant servi à l'analyse") n'est pas suivi par
Git (`.gitignore`) et n'a donc pas été inspecté : il est explicitement hors
du périmètre de ce qui compose l'image.

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : git ls-tree -r v1.0.4, .gitignore, README.md
Dernière vérification : 2026-09-12
```
