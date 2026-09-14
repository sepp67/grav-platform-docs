---
title: "Vue d'ensemble"
template: docs
taxonomy:
    category: [docs]
---

## Quel problème ce dépôt résout-il ?

Déployer une image Grav sur une VM implique une séquence précise et
répétitive : valider la configuration, protéger l'accès administrateur,
préparer Docker, créer des répertoires persistants, déposer des secrets,
générer un Compose, démarrer le conteneur, attendre qu'il soit
réellement sain, et tracer ce qui a été déployé. Sans un rôle dédié,
chaque site réimplémenterait cette séquence à sa façon — avec le risque
qu'un opérateur pressé saute la garde administrateur ou le contrôle de
santé applicatif.

## Qui l'utilise ?

Deux publics distincts (voir [Place dans l'architecture](../02.place-dans-architecture)) :
un opérateur humain, via la couche d'exploitation autonome fournie par ce
dépôt (`playbooks/`, `Makefile`) ; ou un autre dépôt Ansible (le futur
`grav-sites-ops`), qui consomme le rôle par tag Git épinglé via
`requirements.yml`.

## Que reçoit-il et que produit-il ?

| | |
|---|---|
| Entrée | des variables Ansible (`grav_image`, `grav_version`, `grav_bind_address`, ...) et un inventaire ciblant une VM |
| Sortie | un conteneur Grav démarré/arrêté/redémarré sur cette VM, un état de déploiement tracé (`.deployed_state.yml`, `.deployed_version`, `deployed_versions.log`) |

## Quelle est sa responsabilité exclusive ?

Déployer **atomiquement** une instance : une invocation du rôle = une
instance, sur une VM cible, à partir d'une référence d'image déjà publiée.
Rien de plus — le rôle ne connaît ni le parc de sites, ni la construction
d'image, ni le reverse proxy.

## Que refuse-t-il de faire ?

- construire ou modifier une image Docker (README "Ce que le rôle ne fait
  jamais") ;
- gérer le parc de sites, l'affectation site → VM, ou les versions de
  plusieurs sites à la fois (c'est `grav-sites-ops`, à venir) ;
- choisir la version de `grav-runtime` — figée dans le `Dockerfile` de
  l'image applicative, hors de portée du rôle ;
- gérer un reverse proxy, TLS, le DNS ou un pare-feu ;
- appeler `grav-sites-ops` ou le `control-repository`, ni générer leur
  configuration ;
- sauvegarder ou restaurer des données, ou effectuer un rollback
  automatique (voir [Données, secrets et
  persistance](../07.donnees-secrets-persistance)).

## Fiche synthétique

| Champ | Contenu |
|---|---|
| Type de composant | rôle Ansible atomique |
| Entrée principale | variables du rôle (interface publique `grav_*`) + inventaire |
| Sortie principale | conteneur déployé/arrêté/redémarré ; traçabilité écrite sur l'hôte cible |
| Dépendance directe | `community.docker` (≥5.0.0,<6.0.0), Ansible-core (≥2.17,<2.18) ; aucune dépendance vers `grav-sites-ops`, `grav-runtime` ou une image applicative |
| Données persistantes | non, dans le rôle lui-même — il gère le cycle de vie des répertoires persistants de l'instance qu'il déploie |
| Secrets | jamais générés ; déposés sur l'hôte cible depuis `grav_secrets` (src/content), toujours à vaultiser côté appelant |
| Déclencheur | `ansible-playbook` (couche autonome, ou dépôt appelant en mode cible) |

## Deux modes, une seule logique

Détaillé en [Place dans l'architecture](../02.place-dans-architecture) : le
rôle est utilisable seul (couche d'exploitation autonome fournie par ce
dépôt) ou comme dépendance réutilisable (consommé via `requirements.yml`
par un autre dépôt). Les deux modes appellent exactement le même rôle, sans
duplication de logique.

## Quand utiliser ce dépôt ?

Pour déployer, mettre à jour, arrêter ou faire un rollback d'une instance
Grav basée sur `grav-runtime`, sur une VM Debian/Ubuntu (ou tout OS si
Docker est déjà installé, `grav_manage_docker: false`).

## Quand ne pas l'utiliser ?

Pour orchestrer plusieurs sites à la fois (attendre `grav-sites-ops`) ;
pour un site nécessitant IPv6 en écoute (refusé en v2.0.0, voir [Données,
secrets et persistance](../07.donnees-secrets-persistance) et
[Référence](../11.reference)) ; pour construire une image (hors périmètre,
toujours).

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : README.md, meta/main.yml
Dernière vérification : 2026-09-12
```
