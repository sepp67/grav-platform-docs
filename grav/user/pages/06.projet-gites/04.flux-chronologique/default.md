---
title: "Flux chronologique"
template: docs
taxonomy:
    category: [docs]
---

Cinq chronologies structurellement différentes, recalculées directement
depuis le code du commit audité.

## A. Construction de l'image applicative

Chemin : `Dockerfile` (22 lignes, lu intégralement).

| # | Étape | Preuve |
|---|---|---|
| 1 | Image `grav-runtime` parente épinglée | `FROM ghcr.io/sepp67/grav-runtime:1.0.4` |
| 2 | Copie du thème (métier, `gites-theme`) — le thème **parent** `quark2` n'est **jamais** copié depuis ce dépôt | `COPY grav/user/themes/ → /var/www/html/user/themes/` ; `quark2` est déjà présent dans l'image `grav-runtime` elle-même |
| 3 | Copie des plugins métier (`contact`, `calendrier-disponibilites`) | `COPY grav/user/plugins/ → /var/www/html/user/plugins/` |
| 4 | Copie de la configuration non secrète versionnée | `COPY grav/user/config/ → /var/www/html/user/config/` |
| 5 | Copie du contenu initial vers l'emplacement de seed | `COPY grav/user/pages/ → /opt/grav-seed/pages/` |
| 6 | Image résultante | `projet-gites:dev` (local) ou `ghcr.io/sepp67/projet-gites` (CI de release) |

**Aucune langue copiée** (pas de `COPY grav/user/languages/`) : ce dépôt
est monolingue, à la différence de `projet-lavallee-website`.

## B. Premier démarrage

Vérifié en direct pendant ce lot (voir [Tests et CI](08.tests-et-ci)).

| # | Étape | Preuve |
|---|---|---|
| 1 | Répertoires persistants initialement vides (`pages`, `accounts`, `data`, `images`) | premier `docker run` sans volume préexistant |
| 2 | Seed indépendant par répertoire — `docker/seed-init.sh` (dans `grav-runtime`, hors code de ce dépôt) traite chacun des quatre séparément | `docs/runtime-contract.md` : « destination vide → copie… destination déjà peuplée → aucune copie » |
| 3 | Comptes : aucun compte baké dans l'image elle-même — **vérifié en direct** (`test-secrets.sh`, cas « aucune variable `GRAV_ADMIN_*` fournie ») | `user/accounts` vide dans une image fraîche sans bootstrap |
| 4 | Permissions : `www-data`, uid/gid 82, corrigées par l'entrypoint du runtime si nécessaire (idempotent) | `docs/runtime-contract.md`, non ré-audité au niveau code ici (relève de `grav-runtime`, Lot 3) |
| 5 | Disponibilité du site | `/` → HTTP 200 directement (**pas** de redirection de langue, contrairement à `projet-lavallee-website`) — **vérifié en direct** |

**Point de vigilance** : sans les trois variables `GRAV_ADMIN_*`, le
plugin Admin de `grav-runtime` redirige **toutes** les pages du site vers
`/admin` (comportement natif de Grav Admin, pas un défaut de ce dépôt —
confirmé par `docs/testing.md` et par le commentaire de `test-app-presence.sh`).
`ansible-role-grav-site` fournit toujours ces trois variables en
déploiement réel selon la documentation de ce dépôt.

## C. Redémarrage et mise à jour

**Vérifié en direct, dans les deux sens** (mise à jour A→B **et** rollback
B→A) via `tests/test-update-rollback.sh`, rejoué pendant ce lot — voir
[Tests et CI](08.tests-et-ci) pour le détail des commandes.

| # | Étape | Preuve |
|---|---|---|
| 1 | Conservation des 4 volumes à travers un changement d'image | marqueurs écrits dans `pages`/`accounts` avant la mise à jour, **retrouvés intacts** après le passage à l'image B puis après le rollback vers l'image A |
| 2 | Remplacement de l'immuable (thème, plugins, configuration) | le nouveau code (CSS modifié dans l'image B de test) devient actif immédiatement après le changement d'image, **sans action sur les volumes** |
| 3 | Contenu qui n'est **jamais** reseedé | `docs/seed-lifecycle.md` : « aucune étape du cycle de vie de l'image… ne réinvoque une copie vers un volume déjà peuplé » — confirmé en direct : le marqueur ajouté à `user/pages/01.home/default.md` avant la mise à jour reste présent après |
| 4 | Conséquence d'une modification effectuée depuis Admin | toute page éditée via `/admin` vit dans le volume `user/pages`, **jamais** dans l'image — une mise à jour d'image ultérieure ne l'écrase ni ne la synchronise ; elle reste strictement locale à cette instance tant qu'aucune migration volontaire n'est appliquée (voir [Adopter et étendre](10.adopter-et-etendre)) |

**Rollback = mise à jour, du point de vue du mécanisme** : `docs/release-and-rollback.md`
le formule explicitement — « un rollback est, du point de vue du rôle,
une mise à jour comme une autre » — même garantie de non-perte de
données, entièrement **manuel** (l'opérateur choisit la version cible).

## D. Parcours d'un visiteur

Chemin : `gite-item.html.twig` → formulaire partagé → `contact.php`. **Le
mécanisme de routage diffère structurellement de `projet-lavallee-website`**
— voir l'audit détaillé en [Référence](11.reference).

| # | Étape | Détail vérifié |
|---|---|---|
| 1 | Consultation d'une fiche de gîte | `/gites/gite-un` ou `/gites/gite-deux` — page `gite-item`, rendu hérité de `quark2` |
| 2 | Page concernée et propriétaire associé | `page.header.proprietaire` (`proprio-gite-1` ou `proprio-gite-2`) — lu directement du frontmatter, jamais transmis en clair au visiteur |
| 3 | Ouverture du formulaire | `{% set contact_form = forms('contact-form') %} {% do contact_form.setData('gite', page.route) %}` — le champ caché `gite` est pré-rempli **côté serveur** avec la route de la page actuelle |
| 4 | Soumission | POST vers la même page, traité par le Form plugin de Grav Core |
| 5 | Sélection du destinataire | `proprietaire_email(form.value('gite'))` — **le paramètre de route vient directement de la valeur soumise dans le champ caché**, pas d'une valeur recalculée côté serveur à la soumission |
| 6 | Confirmation | `redirect: /contact/confirmation` — route unique, monolingue |

**Vérifié en direct (Lot 7)** : un visiteur peut, en modifiant un champ
cependant qualifié de « caché », changer le destinataire réel du
message — confirmé empiriquement en environnement de test, avec des
comptes synthétiques. Ce constat est référencé **SEC-GITES-001** ; sa
fiche de synthèse (nature, impact, portée, statut) figure en
[Référence](11.reference). La procédure de reproduction complète et les
preuves détaillées ne sont volontairement pas publiées ici — elles sont
conservées dans un rapport de sécurité séparé, hors de ce dépôt
documentaire public.

## E. Développement, test et publication

| # | Étape | Preuve |
|---|---|---|
| 1 | Développement local | `docker compose -f compose.dev.yml up -d --build` — port `8080`, 4 volumes nommés séparés |
| 2 | Build local reproductible | `docker build --pull`, 3 tentatives (`tests/test-build.sh`) — **exécuté réellement** pendant ce lot |
| 3 | Tests disponibles | **6 scripts** (`build`, `startup`, `app-presence`, `secrets`, `persistence`, `update-rollback`) — les 6 **exécutés réellement** pendant ce lot, 0 échec |
| 4 | Workflow CI (`ci.yml`) | déclenché sur tout push/PR ; exécute 4 des 6 scripts (`build`, `startup`, `app-presence`, `secrets`) — `persistence` et `update-rollback` **exclus**, réservés à une exécution manuelle avant release |
| 5 | Conditions de publication (`release.yml`) | déclenché **uniquement** par un tag SemVer (`v[0-9]+.[0-9]+.[0-9]+`) ou un déclenchement manuel |
| 6 | Tags OCI produits | `{{version}}`, `{{major}}.{{minor}}`, `{{major}}` + `latest` (uniquement sur tag poussé, même mécanisme que `projet-lavallee-website`) |
| 7 | Relation ultérieure avec `grav-sites-ops` | **aucune constatée** au commit audité — le nom d'image `ghcr.io/sepp67/projet-gites` n'apparaît dans aucun fichier des dépôts `grav-sites-ops`/`ansible-role-grav-site` déjà documentés (Lots 4 et 5) ; `docs/release-and-rollback.md` documente un exemple de playbook Ansible complet, mais contre `ansible-role-grav-site:1.0.1` — une version différente du tag `v2.0.0` déjà audité |

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : Dockerfile, docs/{runtime-contract,seed-lifecycle,release-and-rollback}.md,
  grav/user/themes/gites-theme/templates/gite-item.html.twig, grav/user/plugins/contact/contact.php,
  tests/test-update-rollback.sh
Dernière vérification : 2026-09-14
```
