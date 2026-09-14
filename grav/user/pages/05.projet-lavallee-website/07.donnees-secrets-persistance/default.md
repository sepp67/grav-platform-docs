---
title: "Données, secrets et persistance"
template: docs
taxonomy:
    category: [docs]
---

## Matrice de classification des fichiers

| Élément | Versionné | Dans l'image | Dans le seed | Persistant après démarrage | Secret | Responsable du cycle de vie |
|---|---:|---:|---:|---:|---:|---|
| Thème `lavallee-theme` | oui | oui (`COPY grav/user/themes/`) | non | non (réécrit à chaque conteneur) | non | ce dépôt |
| Plugin `contact` | oui | oui (`COPY grav/user/plugins/`) | non | non | non | ce dépôt |
| Traductions (`languages/{fr,en,de}.yaml`) | oui | oui (`COPY grav/user/languages/`) | non | non | non | ce dépôt |
| Configuration Grav (`system.yaml`, `site.yaml`, `email.yaml`) | oui | oui (`COPY grav/user/config/`) | non | non | non | ce dépôt |
| Pages (`grav/user/pages/`) | oui | non | oui (`/opt/grav-seed/pages/`) | oui, **après** le premier démarrage (copiées dans le volume, puis modifiables en production) | non | ce dépôt (contenu initial) puis l'exploitant (contenu réel) |
| Images/médias des articles (`*.png` sous `pages/`) | oui | non | oui (avec les pages) | oui, comme les pages | non | ce dépôt (initial) puis l'exploitant |
| Comptes (`user/accounts/`) | non (`.gitignore`) | non | non | oui, dès la création (bootstrap admin) | **oui** (mots de passe hachés) | `grav-runtime` (création) puis le volume persistant |
| Données applicatives (`user/data/`) | non | non | non | oui | dépend du contenu (non déterminé par ce dépôt) | l'exploitant |
| `email-private.php` | **non** (`.gitignore` + `.dockerignore`) | non | non | non, dans ce dépôt — fourni hors dépôt à l'exécution | **oui** (identifiants SMTP) | déploiement réel (`ansible-role-grav-site`, une fois branché) ou opérateur local |
| Paramètres SMTP (`server`/`port`/`user`/`password`) | non | non | non | non, dans ce dépôt | **oui** | idem — jamais dans ce dépôt |
| `docker-compose.yml` déployé en production | non — n'existe pas dans ce dépôt | non | non | non applicable | non | `ansible-role-grav-site` (une fois branché, non confirmé au commit audité) |
| `grav.env` (variables d'environnement de production) | non — pas de fichier de ce nom dans ce dépôt | non | non | non applicable | **oui**, si utilisé | déploiement réel, hors périmètre de ce dépôt |
| `compose.dev.yml` (développement local) | oui | non applicable (fichier d'orchestration, pas un artefact d'image) | non applicable | non applicable | non — identifiants de test triviaux et jetables en clair | ce dépôt, développement uniquement |

**Distinction des responsables, telle que déterminable au commit audité** :
tout ce qui est « Dans l'image » est produit par **ce dépôt** au moment du
`docker build`. Tout ce qui touche au bootstrap admin, au healthcheck ou à
l'entrypoint est produit par `grav-runtime` (non ré-audité ici, voir Lot
3). Aucun fichier de ce dépôt n'est produit par `ansible-role-grav-site` ou
injecté par `grav-sites-ops` — cohérent avec l'absence de branchement
constatée en [Place dans l'architecture](../02.place-dans-architecture) :
ni `docker-compose.yml` de production, ni `grav.env`, ni aucun mécanisme
d'injection de secret ne sont visibles dans ce dépôt lui-même.

## `.gitignore` et `.dockerignore` — cohérence croisée

Les deux fichiers excluent **les mêmes catégories** (secrets applicatifs,
comptes, données d'exécution, artefacts locaux), avec une différence de
portée attendue : `.dockerignore` exclut en plus `.git/` et `exemple/`
(non pertinents pour l'image), tandis que `.gitignore` conserve par
prudence des chemins de volumes qui « ne devraient normalement jamais
apparaître » dans l'arborescence versionnée (commentaire du fichier).

## Persistance : ce que ce dépôt ne gère jamais

`docs/architecture.md` et le README sont explicites : « ne gère pas les
données persistantes de production après l'initialisation ». Confirmé par
lecture complète du `Dockerfile` (aucune primitive de volume, aucun
mécanisme de sauvegarde) et par observation directe (voir [Flux
chronologique, chronologie C](../04.flux-chronologique)) : un redémarrage
conserve les 4 répertoires persistants sans aucune intervention de ce
dépôt.

## Secrets — jamais versionnés, jamais dans l'image

Vérifié par double garde-fou cohérent (`.gitignore` + `.dockerignore`) et
par test direct (`tests/test-secrets.sh`, absent de ce dépôt — cette
vérification appartient à `grav-platform-docs` lui-même, pas à
`projet-lavallee-website` ; aucun test équivalent n'existe dans ce dépôt,
voir [Tests et CI](../08.tests-et-ci)). Le seul mécanisme d'injection de
secret observé est le chargement conditionnel de `email-private.php` par
`contact.php`, jamais un mécanisme propre à ce dépôt.

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : Dockerfile, .gitignore, .dockerignore, grav/user/plugins/contact/contact.php,
  compose.dev.yml, tests/compose.test.yml
Dernière vérification : 2026-09-14
```
