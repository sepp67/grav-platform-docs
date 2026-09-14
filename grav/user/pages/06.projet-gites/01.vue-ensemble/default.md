---
title: "Vue d'ensemble"
template: docs
taxonomy:
    category: [docs]
---

## Quel problème ce dépôt résout-il ?

`grav-runtime` fournit un socle Grav générique sans aucun contenu ni thème
métier. `projet-gites` fournit la couche applicative complète d'une
plateforme de mise en relation directe entre propriétaires de gîtes et
vacanciers : deux fiches de gîte détaillées, un formulaire de contact
routé vers le bon propriétaire, un calendrier de disponibilités
auto-administrable par chaque propriétaire, et une galerie photo.

## Qui l'utilise ?

Un pipeline de build (`docker build`, localement ou en CI) qui produit une
image `ghcr.io/sepp67/projet-gites`, ensuite consommée par
`ansible-role-grav-site` lors d'un déploiement réel. Aucun autre dépôt ne
lit le code source de `projet-gites` directement.

## Que reçoit-il et que produit-il ?

| | |
|---|---|
| Entrée | l'image `grav-runtime` épinglée, le code applicatif versionné (thème, deux plugins métier, configuration, contenu initial de deux gîtes) |
| Sortie | une image Docker autonome, publiée avec des tags SemVer explicites sur GHCR |

## Quelle est sa responsabilité exclusive ?

Fournir le code et le contenu **propres à ce site** : thème `gites-theme`,
plugins `contact` et `calendrier-disponibilites`, configuration Grav non
secrète, contenu initial. Rien de générique (PHP, Nginx, Grav Core) et
rien du mécanisme de déploiement.

## Que refuse-t-il de faire ? (README, section « What it does not do »)

- fournir ou maintenir PHP ;
- fournir ou maintenir Nginx ;
- fournir Grav Core ;
- contenir des secrets de production ;
- implémenter la logique de déploiement en production ;
- gérer les données persistantes en production après l'initialisation ;
- gérer le DNS, le TLS ou le reverse proxy.

## Comparaison rapide avec `projet-lavallee-website`

Les deux dépôts partagent la même architecture d'image applicative
(construite sur `grav-runtime`, consommée par `ansible-role-grav-site`),
mais avec un métier et des choix techniques différents. Détail complet en
[Place dans l'architecture](../02.place-dans-architecture) ; ce tableau ne
couvre que les traits distinctifs les plus visibles :

| Élément | `projet-gites` | [`projet-lavallee-website`](../../05.projet-lavallee-website) | Commun ou spécifique |
|---|---|---|---|
| Thème | `gites-theme`, **hérite** de `quark2` via chaînage `streams` | `lavallee-theme`, **entièrement autonome** | spécifique aux deux |
| Langues | **monolingue** (français uniquement, aucun dossier `languages/`) | trilingue (FR/DE/EN) | spécifique aux deux |
| Plugins métier | `contact` **+** `calendrier-disponibilites` (avec auto-administration côté propriétaire) | `contact` seul | spécifique à `projet-gites` |
| Résolution du destinataire du formulaire | route du gîte fournie par un **champ caché rempli par le visiteur** (`form.value('gite')`), sans valeur par défaut | route fixe par défaut (`/contact`) | mécanisme partagé, usage différent — voir [Référence](../11.reference) |
| Tests | 6 scripts, dont `test-secrets.sh` (4 scénarios) et `test-update-rollback.sh` | 4 scripts, aucun test de secrets dédié | `projet-gites` plus complet |
| Documentation interne | 6 fichiers `docs/*.md` détaillés (contrat runtime, politique de compatibilité, cycle de vie du seed, secrets, tests, release/rollback) | 1 fichier (`docs/architecture.md`) | `projet-gites` plus complet |

## Fiche synthétique

| Champ | Contenu |
|---|---|
| Type de composant | image applicative Grav (thème hérité + 2 plugins métier + contenu) |
| Entrée principale | code versionné de ce dépôt, image `grav-runtime` épinglée |
| Sortie principale | image Docker `ghcr.io/sepp67/projet-gites` |
| Dépendance directe | **uniquement** `grav-runtime`, épinglé par tag explicite dans le `Dockerfile` |
| Données persistantes | non, dans l'image elle-même — un contenu de **seed** initial est fourni pour deux gîtes |
| Secrets | jamais suivis par Git ; `email-private.php` chargé, s'il existe, hors dépôt |
| Déclencheur | `docker build` (local) ou push d'un tag `v*.*.*` (CI de release) |

## Quand utiliser ce dépôt ?

Pour construire, faire évoluer ou tester localement le code applicatif du
site de gîtes, indépendamment de tout déploiement réel.

## Quand ne pas l'utiliser ?

Pour déployer une instance en production (relève d'`ansible-role-grav-site`) ;
pour modifier le runtime générique (relève de `grav-runtime`) ; pour gérer
l'exposition Internet du site (hors périmètre absolu de ce dépôt) ; pour
comprendre le mécanisme de réservation en ligne — **il n'en existe pas** :
la mise en relation reste manuelle, par e-mail ou téléphone (voir la page
de confirmation du formulaire).

## État de ce dépôt au commit audité

Deux gîtes sont définis : l'un (« Chalet Wisches ») porte un contenu
éditorial complet et déjà rédigé ; le second (« Maison Taintrux ») est
**explicitement marqué comme contenu temporaire** dans sa propre page
(« à remplacer par les données réelles »), avec des valeurs numériques
non renseignées (capacité et nombre de chambres à `0`). La documentation
interne du dépôt certifie sa compatibilité avec `grav-runtime 1.0.2` alors
que le `Dockerfile` référence `1.0.4` — voir [Référence](../11.reference)
pour le détail complet de cet écart et des autres constats.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : README.md, Dockerfile, docs/architecture.md, docs/compatibility-policy.md
Dernière vérification : 2026-09-14
```
