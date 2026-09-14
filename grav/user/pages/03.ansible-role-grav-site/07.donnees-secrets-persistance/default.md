---
title: "Données, secrets et persistance"
template: docs
taxonomy:
    category: [docs]
---

## Matrice

| Élément | Immuable ou persistant | Source | Destination | Propriétaire du cycle de vie | Sauvegarde requise | Secret |
|---|---|---|---|---|---|---|
| `docker-compose.yml`, `grav.env` | régénérés à chaque exécution du rôle | rendu de templates | racine de l'instance sur l'hôte | ce rôle | non (reconstructibles) | `grav.env` : oui, `0600` |
| 4 répertoires persistants (`pages`, `accounts`, `data`, `images`) | **persistant**, indépendant du cycle de vie du conteneur | créés par `directories.yml` (vides), peuplés par le seed de `grav-runtime` | bind mounts sur l'hôte | opérateur du déploiement | **oui** | non (sauf contenu applicatif y placé — hors périmètre du rôle) |
| Fichiers secrets (`grav_secrets`) | persistant, jamais régénéré par le rôle | `src` (fichier du contrôleur) ou `content` (inline) | `grav_secret_directory`, `0640 root:grav_container_gid` | opérateur du déploiement (vaultise la source) | oui | **oui** |
| `.deployed_version`, `.deployed_state.yml` | régénérés à chaque exécution (quand le bloc de traçabilité s'exécute) | calculés (`_grav_effective_reference`, horodatage) | racine de l'instance | ce rôle | non (reconstructibles depuis l'état déclaré) | non |
| `deployed_versions.log` | **append-only**, jamais réécrit ni tronqué | ajout conditionnel (état contractuel changé) | racine de l'instance | ce rôle | oui, si l'historique importe | non |
| `.last_failure.log` | transitoire — écrit sur échec, supprimé au retour au vert | `docker logs --tail 200` du conteneur | racine de l'instance, `0600 root:root` | ce rôle | non | **potentiellement** (logs applicatifs) — jamais affiché dans Ansible |

## Ce qui est construit à chaque exécution

`docker-compose.yml`, `grav.env`, `.deployed_version`, `.deployed_state.yml`
— tous régénérés, jamais lus pour décider d'un comportement (sauf l'état
précédent de `.deployed_state.yml`, lu uniquement pour détecter un
changement avant d'écrire le journal).

## Ce qui est initialisé une seule fois

Le contenu des 4 répertoires persistants n'est **jamais** initialisé par ce
rôle : c'est le mécanisme de seed de `grav-runtime` (côté conteneur) qui le
fait, uniquement si un répertoire est vide au premier démarrage. Le rôle
se contente de créer des répertoires vides et de les monter.

## Ce qui survit à un redéploiement

Les 4 répertoires persistants et `deployed_versions.log` (append-only) —
**"ne sont jamais recréés, vidés ni resynchronisés par un déploiement, une
mise à jour, un redémarrage ou un rollback"** (README "Persistance").

## Ce qui ne doit jamais être commité

Tout `vault.yml` réel (seul `vault.yml.example` doit exister — vérifié par
un garde-fou CI dédié) ; le contenu réel d'un secret `grav_secrets` ; une
adresse RFC 1918 dans `inventories/` (garde-fou CI) ; toute référence au
`control-repository` ou à un chemin de développement local (garde-fou CI).

## Ce qu'un rollback restaure — et ne restaure pas

Un rollback est "le redéploiement explicite d'une référence d'image
antérieure" (README "Rollback") : remettre `grav_version` à sa valeur
précédente et rejouer le rôle. **Le rôle ne compare pas la chronologie des
versions** : il applique l'état demandé, quel qu'il soit.

Ce que ce rollback restaure : l'**image** et sa configuration de
déploiement (Compose, `grav.env`). Ce qu'il **ne restaure jamais** : le
contenu des volumes persistants. Si la version antérieure est incompatible
avec des données écrites par une version plus récente, le comportement
n'est pas garanti — une restauration complète (image + configuration +
sauvegarde des volumes) est une opération distincte, explicitement hors du
rôle.

## Qui a le droit de muter chaque donnée

- Ce rôle : `docker-compose.yml`, `grav.env`, fichiers secrets (dépôt
  initial et mises à jour de leur contenu source), fichiers de traçabilité
  — jamais le contenu des 4 répertoires persistants.
- `grav-runtime` (dans le conteneur) : le contenu des 4 répertoires
  persistants, en fonctionnement normal du site.
- L'opérateur : les valeurs de `grav_secrets` et du Vault, la décision de
  changer `grav_version`/`grav_digest`.

## Contrat administrateur (rappel)

| Fichier de compte persistant | Variables admin | `grav_state` | Résultat |
|---|---|---|---|
| présent | absentes | `started`/`restarted` | déploiement autorisé |
| présent | les trois | `started`/`restarted` | autorisé, compte **non recréé** |
| absent | les trois | `started`/`restarted` | bootstrap autorisé |
| absent | aucune | `started`/`restarted` | **échec bloquant avant mutation** |
| absent ou présent | partielles (1-2 sur 3) | tout état | **échec** |
| absent | aucune | `stopped` | autorisé — `stopped` n'impose aucun bootstrap |

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : README.md ("Persistance", "Rollback", "Contrat administrateur"), tasks/secrets.yml, tasks/version.yml, tasks/admin_guard.yml
Dernière vérification : 2026-09-12
```
