---
title: "Vue d'ensemble"
template: docs
taxonomy:
    category: [docs]
---

## Quel problème ce dépôt résout-il ?

`ansible-role-grav-site` déploie **une** instance par invocation, mais ne
sait rien d'un parc : qui sont les sites, sur quelles VM, avec quelles
versions. Sans orchestrateur, un opérateur devrait mémoriser ces
informations et invoquer le rôle à la main pour chaque site, avec le risque
d'une cible mal tapée, d'un secret égaré ou d'une mutation lancée deux fois
en parallèle. `grav-sites-ops` répond à cela : il **décrit l'état désiré**
du parc dans un registre versionné, et **invoque** le rôle pour la machine
explicitement sélectionnée — jamais plus.

## Qui l'utilise ?

Un opérateur humain, via `make <cible> SITE=<hôte>` ou les scripts
équivalents. Aucun autre dépôt ne consomme `grav-sites-ops` : c'est le
sommet de la chaîne de dépendance (voir [Place dans
l'architecture](../02.place-dans-architecture)).

## Que reçoit-il et que produit-il ?

| | |
|---|---|
| Entrée | un registre déclaratif (`grav_sites.yml`), un inventaire, un vault, et une commande opérateur (`SITE=<hôte>`) |
| Sortie | une instance déployée/redémarrée/arrêtée sur la VM sélectionnée (via le rôle), ou un verdict de conformité en lecture seule (`check`/`check-all`) |

## Quelle est sa responsabilité exclusive ?

Décrire l'état désiré d'un parc et invoquer atomiquement le rôle pour
**exactement une** machine à la fois, jamais plus. Rien de la logique de
déploiement elle-même : elle appartient à `sepp67.grav_site`.

## Que refuse-t-il de faire ?

- construire, tester ou publier des images (`grav-runtime`, `projet-*`) ;
- provisionner une VM — les VM sont des ressources préexistantes ;
- reproduire la logique interne du rôle (aucune tâche Docker/Grav propre) ;
- orchestrer un service autre que Grav ;
- dépendre du `control-repository`, sous quelque forme que ce soit ;
- déclencher une mutation sur une cible globale, absente ou multiple ;
- automatiser le retrait ou la réactivation d'un site (opérations Git
  manuelles, voir [Adopter et étendre](../10.adopter-et-etendre)) ;
- déclencher une mutation de VM à partir d'un événement Git de release.

## Fiche synthétique

| Champ | Contenu |
|---|---|
| Type de composant | orchestrateur Ansible (registre déclaratif + invocation d'un rôle) |
| Entrée principale | registre `grav_sites`, inventaire, vault, sélection `SITE` |
| Sortie principale | instance déployée/mutée sur la VM sélectionnée ; verdict de dérive en lecture seule |
| Dépendance directe | **uniquement** `sepp67.grav_site`, épinglé par tag dans `requirements.yml` |
| Données persistantes | non, dans ce dépôt lui-même — il ne fait que déclarer ce que le rôle doit appliquer |
| Secrets | jamais suivis par Git ; vault opérationnel fourni hors dépôt, jamais ouvert par la CI |
| Déclencheur | `make <cible> SITE=<hôte>` (ou script équivalent), exécuté par un opérateur |

## Quand utiliser ce dépôt ?

Pour décrire et exploiter un parc de sites Grav déployés par
`ansible-role-grav-site` sur des VM déjà existantes du réseau local.

## Quand ne pas l'utiliser ?

Pour déployer un site isolé sans parc (la couche autonome du rôle lui-même
suffit, voir [ansible-role-grav-site — Adopter et
étendre](../../03.ansible-role-grav-site/10.adopter-et-etendre)) ; pour
gérer l'exposition Internet d'un site (relève du `control-repository`,
hors périmètre absolu de ce dépôt) ; pour migrer un site réel sans avoir
d'abord lu [`docs/MIGRATION.md`](../10.adopter-et-etendre) de ce dépôt.

## État de ce dépôt au tag audité

Le tag `v1.0.0` documente une **construction locale acceptée** (lots
L0-L11), **publiée** avec un run CI distant globalement vert, mais dont la
**release** (tag + publication GitHub) et la **migration réelle** restent
explicitement **bloquées**, chacune en attente d'une autorisation humaine
ou d'une condition externe distincte. Voir
[Référence](../11.reference) pour la chronologie complète de cette
release, et l'écart connu sur l'existence du tag lui-même.

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : README.md, docs/ARCHITECTURE.md, docs/ACCEPTANCE.md
Dernière vérification : 2026-09-14
```
