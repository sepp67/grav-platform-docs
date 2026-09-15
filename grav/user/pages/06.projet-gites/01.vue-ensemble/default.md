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
| Résolution du destinataire du formulaire | sélection **visible et obligatoire** parmi une liste fermée construite côté serveur, résolue exclusivement depuis cette même table serveur (corrigé dans `v1.1.0` — historiquement un champ caché prérempli, non revalidé à la soumission, voir [Référence](../11.reference)) | route fixe par défaut (`/contact`) | mécanisme partagé, usage différent — voir [Référence](../11.reference) |
| Tests | 8 scripts, dont `test-secrets.sh` (4 scénarios), `test-update-rollback.sh`, et `test-contact-routing.sh` (60 assertions nommées de routage/sécurité, corrigé et étendu dans `v1.1.0`) | 4 scripts, aucun test de secrets ni de routage dédié | `projet-gites` plus complet |
| Documentation interne | 7 fichiers `docs/*.md` détaillés (contrat runtime, politique de compatibilité, cycle de vie du seed, secrets, tests, release/rollback, notes de sécurité) | 1 fichier (`docs/architecture.md`) | `projet-gites` plus complet |

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

## État de ce dépôt au tag audité

Deux gîtes sont définis : l'un (« Chalet Wisches ») porte un contenu
éditorial complet et déjà rédigé ; le second (« Maison Taintrux ») est
**explicitement marqué comme contenu temporaire** dans sa propre page
(« à remplacer par les données réelles »), avec des valeurs numériques
non renseignées (capacité et nombre de chambres à `0`) — inchangé par la
correction SEC-GITES-001, qui ne touche pas ce contenu éditorial. La
documentation interne du dépôt certifie désormais sa compatibilité avec
`grav-runtime 1.0.4` (version réellement construite par le `Dockerfile`,
et réellement exercée par la suite de tests de ce même chantier) — voir
[Référence](../11.reference) pour le détail complet de la correction et
des constats résiduels.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b)
Fichiers principaux : README.md, Dockerfile, docs/architecture.md, docs/compatibility-policy.md,
  docs/security-notes.md
Dernière vérification : 2026-09-15
```
