---
title: "Données, secrets et persistance"
template: docs
taxonomy:
    category: [docs]
---

## Matrice de classification des fichiers

| Élément | Versionné | Dans l'image | Dans le seed | Persistant | Secret | Responsable |
|---|---:|---:|---:|---:|---:|---|
| Thème métier (`gites-theme`) | oui | oui (`COPY grav/user/themes/`) | non | non (réécrit à chaque conteneur) | non | ce dépôt |
| Thème parent (`quark2`) | non — **fourni par `grav-runtime`**, jamais copié depuis ce dépôt | oui (déjà dans l'image de base) | non | non | non | `grav-runtime` |
| Plugins métier (`contact`, `calendrier-disponibilites`) | oui | oui (`COPY grav/user/plugins/`) | non | non | non | ce dépôt |
| Configuration (`system.yaml`, `site.yaml`, `plugins/*.yaml`) | oui | oui (`COPY grav/user/config/`) | non | non | non | ce dépôt |
| Pages (fiches de gîtes, accueil, contact…) | oui | non | oui (`/opt/grav-seed/pages/`) | oui, **après** le premier démarrage | non | ce dépôt (contenu initial) puis l'exploitant (contenu réel administré) |
| Photos des gîtes (`.jpg`) | oui | non | oui (avec les pages) | oui, comme les pages | non | ce dépôt (initial) puis l'exploitant |
| Périodes d'indisponibilité (`disponibilites.periodes_indisponibles`) | oui, **valeurs d'exemple** au commit audité | non | oui (dans le frontmatter des pages de gîte) | oui, modifiable ensuite via `/gerer` sans passer par Git | non | ce dépôt (exemple) puis le propriétaire du gîte (valeurs réelles) |
| Comptes (`user/accounts/`) | non (`.gitignore`) | non | non | oui, dès la création | **oui** (mots de passe hachés) | `grav-runtime` (création) puis le volume persistant |
| `email-private.php` | **non** (`.gitignore` + `.dockerignore`) | non | non | non, dans ce dépôt | **oui** | déploiement réel (`ansible-role-grav-site`) |
| Paramètres SMTP (`server`/`port`/`user`/`password`) | non | non | non | non, dans ce dépôt | **oui** | idem — jamais dans ce dépôt |
| `docker-compose.yml` déployé en production | non — n'existe pas dans ce dépôt | non | non | non applicable | non | `ansible-role-grav-site` |
| `grav.env` (variables de production) | non | non | non | non applicable | **oui**, si utilisé | `ansible-role-grav-site`, hors périmètre |
| `compose.dev.yml` | oui | non applicable | non applicable | non applicable | non — identifiants de test triviaux et jetables en clair | ce dépôt, développement uniquement |
| Artefacts de build (couches Docker intermédiaires) | non applicable | non applicable | non applicable | non — recréées à chaque build | non par construction, **vérifié activement** par `test-secrets.sh` (export + historique des couches) | pipeline de build |

## Secrets — cas particulier documenté : une régression historique réellement survenue

`tests/test-secrets.sh` recherche explicitement, dans le filesystem final
de l'image **et** dans l'historique complet de ses couches, un hôte SMTP
précis désigné dans son propre commentaire comme « l'hôte SMTP OVH qui
était hardcodé dans `email.yaml` avant la migration Phase 2 » — c'est-à-dire
qu'un identifiant technique réel a, à un moment de l'historique de ce
projet, été committé en clair avant d'être retiré et déplacé vers le
mécanisme de secret. Ce test constitue une **garde de non-régression**
active contre le retour de cette valeur précise, pas une recherche
générique de tout secret possible (limite assumée explicitement par
`docs/testing.md`).

## Persistance : ce que ce dépôt ne gère jamais

Confirmé par lecture complète du `Dockerfile` (aucune primitive de
volume) et par observation directe : un redémarrage **et** un changement
d'image (mise à jour ou rollback) conservent les 4 répertoires
persistants — vérifiés en direct dans les deux cas (voir [Flux
chronologique, chronologies B et C](../04.flux-chronologique)).

## Comptes propriétaires : donnée métier, pas de la configuration

Les identifiants (`proprio-gite-1`, `proprio-gite-2`) référencés dans le
frontmatter des pages de gîte sont des **noms d'utilisateur attendus**,
pas des comptes réellement créés par ce dépôt — aucun fichier
`user/accounts/*.yaml` n'existe dans le dépôt (gitignoré). Leur création
relève entièrement de l'exploitation (Admin Grav ou bootstrap Ansible),
hors périmètre de ce dépôt.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b)
Fichiers principaux : Dockerfile, .gitignore, .dockerignore, tests/test-secrets.sh, docs/secrets-and-config.md
Dernière vérification : 2026-09-15
```
