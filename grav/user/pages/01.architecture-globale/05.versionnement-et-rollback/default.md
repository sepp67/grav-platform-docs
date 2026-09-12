---
title: "Versionnement et rollback"
template: docs
taxonomy:
    category: [docs]
---

## Trois notions à ne pas confondre

- **Version déclarée** — ce que le registre de `grav-sites-ops` affirme
  vouloir pour une instance : les champs `version` et `digest` d'une entrée
  (`docs/REGISTRY-SCHEMA.md`). `digest` est optionnel (`""` par défaut) ;
  `version` ne doit jamais être `latest` (cahier §15).
- **Référence effective** — ce qu'`ansible-role-grav-site` calcule
  réellement à partir de ces champs : `grav_image:grav_version` si aucun
  digest n'est fourni, ou `grav_image@grav_digest` s'il l'est — un digest
  épingle un contenu d'image immuable, une version épingle un tag mouvant
  tant qu'il n'est pas republié.
- **Digest** — l'identifiant de contenu (`sha256:...`) d'une image précise.
  Deux instances déclarant la même `version` peuvent en théorie pointer vers
  des contenus différents si le tag a été republié ; deux instances
  déclarant le même `digest` pointent toujours vers exactement le même
  contenu.

## Comment une mise à jour est-elle déclarée et observée ?

Une mise à jour n'est jamais un ordre direct ("mets à jour ce site
maintenant") : c'est un **changement déclaratif**. On modifie `version` (ou
`digest`) dans le registre de `grav-sites-ops`, puis on invoque le
déploiement pour cette instance. `ansible-role-grav-site` compare l'état
actuel du conteneur à la référence désormais déclarée, tire la nouvelle
image si nécessaire, et redémarre le conteneur — sans toucher aux volumes
persistants (cahier §4.2).

L'observation se fait en deux temps, dans l'ordre : le healthcheck Docker
natif de `grav-runtime` (processus vivants), puis un contrôle HTTP
applicatif (`grav_site_check_path`) — un conteneur "healthy" au sens Docker
peut malgré tout servir une page d'erreur applicative ; les deux contrôles
sont donc distincts et tous deux nécessaires.

## Comment un rollback est-il déclaré et observé ?

Un rollback est **le même mécanisme que la mise à jour**, dans l'autre
sens : on redéclare l'ancienne `version` (ou l'ancien `digest`) dans le
registre, puis on redéploie. Rien ne distingue structurellement une "mise à
jour" d'un "rollback" pour `ansible-role-grav-site` : les deux sont des
changements de référence d'image, appliqués de façon identique.

Ce que ce rollback **restaure** : le code exécuté (thème, plugins,
configuration non secrète embarqués dans l'image). Ce qu'il **ne restaure
pas** : les données persistantes des volumes — si une régression a corrompu
ou supprimé du contenu éditorial après le déploiement de la version
défaillante, revenir à l'ancienne image ne fait pas réapparaître ce
contenu. Une régression de données suppose une restauration de sauvegarde,
hors du périmètre automatisé décrit ici (voir [Données, persistance et
secrets](../04.donnees-persistance-secrets)).

## Exemple

| Étape | Registre `grav-sites-ops` | Référence effective calculée par le rôle |
|---|---|---|
| État initial | `version: "1.2.0"`, `digest: ""` | `ghcr.io/sepp67/projet-lavallee-website:1.2.0` |
| Mise à jour déclarée | `version: "1.3.0"`, `digest: ""` | `ghcr.io/sepp67/projet-lavallee-website:1.3.0` |
| Rollback déclaré | `version: "1.2.0"`, `digest: ""` | `ghcr.io/sepp67/projet-lavallee-website:1.2.0` (à nouveau) |
| Épinglage strict (optionnel) | `digest: "sha256:…"` ajouté | `ghcr.io/sepp67/projet-lavallee-website@sha256:…` — insensible à une republication ultérieure du même tag |

---

```yaml
Sources documentées : grav-sites-ops (v1.0.0) — docs/REGISTRY-SCHEMA.md, docs/CONTRAT-ARCHITECTURAL.md ;
                       ansible-role-grav-site (v2.0.0) — README.md ("Variables"), tasks/main.yml
Dernière vérification : 2026-09-11
```
