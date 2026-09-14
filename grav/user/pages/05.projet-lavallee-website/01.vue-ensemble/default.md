---
title: "Vue d'ensemble"
template: docs
taxonomy:
    category: [docs]
---

## Quel problème ce dépôt résout-il ?

`grav-runtime` fournit un socle Grav générique, mais aucun contenu : ni
thème, ni pages, ni fonctionnalité propre à un site. `projet-lavallee-website`
fournit la couche applicative complète du site lavallee.tech — construite
comme une image Docker dérivée, jamais comme une configuration appliquée
après coup.

## Qui l'utilise ?

Un pipeline de build (`docker build`, localement ou en CI) qui produit une
image `ghcr.io/sepp67/projet-lavallee`, ensuite consommée par
`ansible-role-grav-site` lors d'un déploiement réel. Aucun autre dépôt ne
lit le code source de `projet-lavallee-website` directement.

## Que reçoit-il et que produit-il ?

| | |
|---|---|
| Entrée | l'image `grav-runtime` épinglée (`FROM ghcr.io/sepp67/grav-runtime:1.0.4`), le code applicatif versionné (thème, plugin, langues, configuration, pages initiales) |
| Sortie | une image Docker autonome, prête à être déployée, contenant le code applicatif immuable et un contenu initial de seed |

## Quelle est sa responsabilité exclusive ?

Fournir le code et le contenu **propres à ce site** : thème
`lavallee-theme`, contenu trilingue, plugin `contact`, configuration
Grav non secrète. Rien de générique (PHP, Nginx, Grav Core) et rien du
mécanisme de déploiement.

## Que refuse-t-il de faire ? (README, section « What it does not do »)

- fournir ou maintenir PHP ;
- fournir ou maintenir Nginx ;
- fournir Grav Core ;
- contenir des secrets SMTP de production ;
- implémenter la logique de déploiement en production ;
- gérer les données persistantes en production après l'initialisation ;
- gérer le DNS, le TLS ou le reverse proxy.

## Fiche synthétique

| Champ | Contenu |
|---|---|
| Type de composant | image applicative Grav (thème + contenu + configuration) |
| Entrée principale | code versionné de ce dépôt, image `grav-runtime` épinglée |
| Sortie principale | image Docker `ghcr.io/sepp67/projet-lavallee` |
| Dépendance directe | **uniquement** `grav-runtime`, épinglé par tag explicite dans le `Dockerfile` |
| Données persistantes | non, dans l'image elle-même — seul un contenu de **seed** initial est fourni |
| Secrets | jamais suivis par Git ; `email-private.php` chargé, s'il existe, hors dépôt |
| Déclencheur | `docker build` (local) ou push d'un tag `v*.*.*` (CI de release) |

## Quand utiliser ce dépôt ?

Pour construire, faire évoluer ou tester localement le code applicatif du
site lavallee.tech, indépendamment de tout déploiement réel.

## Quand ne pas l'utiliser ?

Pour déployer une instance en production (relève d'`ansible-role-grav-site`,
non encore branché sur ce dépôt à la date auditée — voir [Place dans
l'architecture](02.place-dans-architecture)) ; pour modifier le runtime
générique (relève de `grav-runtime`) ; pour gérer l'exposition Internet du
site (hors périmètre absolu de ce dépôt).

## État de ce dépôt au commit audité

Le commit documenté (`c4341ca7`) ne porte **aucun tag applicatif** — le
workflow `release.yml` ne se déclenche que sur un tag `v[0-9]+.[0-9]+.[0-9]+`
ou un déclenchement manuel, et aucun de ces deux événements ne s'est encore
produit à cette date. `docs/architecture.md` du dépôt le confirme
explicitement : le branchement vers `ansible-role-grav-site` n'est « pas
encore » effectif. Voir [Référence](11.reference) pour le détail des écarts
constatés entre ces déclarations et le code.

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : README.md, Dockerfile, docs/architecture.md
Dernière vérification : 2026-09-14
```
