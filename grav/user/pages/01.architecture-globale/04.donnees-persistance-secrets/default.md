---
title: "Données, persistance et secrets"
template: docs
taxonomy:
    category: [docs]
---

## Où vivent la configuration, les secrets et les données persistantes ?

Chaque composante de la chaîne a le droit de muter une catégorie de données
précise, et une seule. Ce tableau résume la répartition immuable/persistante
telle que définie par le contrat de `grav-runtime` (cahier §4.2) et
appliquée identiquement par chaque image applicative :

| Élément | Statut | Vit dans | Qui l'écrit |
|---|---|---|---|
| PHP-FPM, Nginx, Grav Core/Admin, entrypoint, healthcheck | immuable | l'image `grav-runtime` | mainteneur `grav-runtime` |
| Thème, plugins métier, traductions, configuration non secrète | immuable | l'image applicative (`grav/user/themes`, `grav/user/plugins`, `grav/user/config`) | auteur de l'image applicative |
| Pages, comptes, données, images **initiales** | seed non destructif | `/opt/grav-seed/` dans l'image → copié dans le volume persistant **uniquement s'il est vide** au premier démarrage | auteur de l'image applicative (le contenu), `grav-runtime` (le mécanisme de copie) |
| Pages, comptes, données, images **en fonctionnement** | persistant | volumes Docker (nommés en local, gérés par `ansible-role-grav-site` en production) | l'application elle-même (rédaction éditoriale, formulaires, admin Grav) |
| Secrets SMTP (`email-private.php`) | jamais dans un dépôt ni dans une image | injecté au déploiement par `ansible-role-grav-site` (`grav_secrets`), ou monté manuellement en développement | opérateur du déploiement |
| Registre déclaratif du parc (image, version, digest, ports...) | versionné, **non secret** | dépôt `grav-sites-ops` | opérateur `grav-sites-ops` |
| Inventaire et vault de production | hors dépôt | stockage séparé, non versionné dans `grav-sites-ops` (cahier §8.3) | opérateur `grav-sites-ops` |

## Ce qu'un rollback logiciel restaure — et ce qu'il ne restaure pas

Cette distinction est reprise en détail sur la page dédiée
([Versionnement et rollback](../05.versionnement-et-rollback)) : un
changement de version déclarée change le code exécuté, jamais les données
persistantes des volumes. Une régression de contenu (page supprimée par
erreur, par exemple) n'est donc pas corrigée par un rollback logiciel — elle
suppose une restauration de sauvegarde, qui reste hors du périmètre
automatisé de cette chaîne.

## Qui a le droit de muter quelle donnée

- Un auteur d'image applicative peut changer le thème, les plugins et la
  configuration non secrète — jamais les comptes ou données d'une instance
  déjà en fonctionnement (il ne les voit même pas : elles vivent dans un
  volume, pas dans le dépôt).
- `ansible-role-grav-site` peut créer les répertoires persistants et
  injecter des secrets au déploiement — il ne modifie jamais les pages
  persistantes lors d'un redéploiement (cahier §4.2, "ne pas modifier les
  pages persistantes lors d'un redéploiement").
- `grav-sites-ops` peut changer *quelle* référence d'image et *quelles*
  variables publiques sont déclarées pour une instance — il ne touche jamais
  directement le contenu d'une instance (c'est le rôle qui exécute la
  mutation, pas l'orchestrateur).
- Aucune des composantes automatisées de cette chaîne ne lit ni n'écrit le
  contenu d'un message de formulaire de contact : le plugin `contact`
  transmet directement par e-mail, sans journalisation du contenu (voir
  `docs/contact-form.md` à la racine de ce dépôt).

---

```yaml
Sources documentées : grav-runtime (v1.0.4) — docker/entrypoint.sh, docker/seed-init.sh ;
                       ansible-role-grav-site (v2.0.0), grav-sites-ops (v1.0.0) — voir docs/documentation-sources.yml
Dernière vérification : 2026-09-11
```
