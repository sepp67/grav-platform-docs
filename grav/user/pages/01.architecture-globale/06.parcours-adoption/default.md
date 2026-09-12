---
title: "Parcours d'adoption"
template: docs
taxonomy:
    category: [docs]
---

## Adopter un sixième site : `grav-platform-docs`

Ce site documentaire est lui-même le sixième site de la plateforme, et sert
ici d'exemple réel — pas hypothétique — de ce que signifie "adopter un
nouveau site". Le parcours ci-dessous distingue ce qui a été fait pour ce
dépôt de ce qui reste à faire pour qu'il soit réellement en ligne.

### 1. Prérequis

- Une version de `grav-runtime` déjà publiée et épinglée
  (`ghcr.io/sepp67/grav-runtime:1.0.4`, choisie pour `grav-platform-docs`).
- Un thème (ici Learn2, en thème parent chaîné, jamais copié — voir
  `docs/architecture.md` de ce dépôt) et, le cas échéant, un plugin métier
  (ici `contact`, réutilisé depuis `projet-lavallee-website`).
- Une décision de nom de dépôt et d'image (`grav-platform-docs`).

### 2. Exemple minimal

Un `Dockerfile` qui épingle `grav-runtime`, copie le thème, le plugin et la
configuration non secrète dans l'image, et place le contenu initial sous
`/opt/grav-seed/pages/` — rien de plus. Réalisé au Lot 1 de ce dépôt.

### 3. Validation locale

`compose.dev.yml` (jamais utilisé en production) et une suite de tests de
fumée (`tests/`) : build, démarrage, healthcheck, présence du thème et de la
navigation, formulaire de contact avec SMTP factice, absence de secrets
dans l'image. Réalisé au Lot 1 ; renforcé au Lot 1.1 (validations
syntaxiques, vérification stricte des liens de header).

### 4. Personnalisation autorisée

Un thème enfant propre au site (`platform-docs-theme`), chaîné vers le
thème parent par flux (`streams.schemes.theme`) plutôt que copié — seuls les
fichiers réellement modifiés existent dans le thème enfant (voir
`docs/architecture.md`). C'est la limite entre "personnalisation autorisée"
et "détail interne à ne pas modifier" : le thème parent (Learn2) et le
runtime (`grav-runtime`) ne sont jamais copiés ni édités directement.

### 5. Intégration à la plateforme — **pas encore faite**

Pour que `grav-platform-docs` devienne une instance réelle du parc, il
faudrait :

1. publier l'image sur GHCR (`ghcr.io/sepp67/grav-platform-docs`, taguée
   explicitement) ;
2. déclarer une nouvelle entrée dans le registre de `grav-sites-ops`
   (`image`, `version`, `bind_address`, `http_port`, `base_directory`,
   `container_name` — voir `docs/REGISTRY-SCHEMA.md` de `grav-sites-ops`) ;
3. injecter les secrets réels de déploiement (SMTP) hors dépôt, via le
   mécanisme de `grav-sites-ops` — jamais les adresses provisoires
   `contact@example.invalid` utilisées en local ;
4. invoquer le déploiement pour cette seule instance.

**Aucune de ces quatre étapes n'a été réalisée** (cahier §15 : "pas de
déploiement réel", "pas de push, tag ou release sans autorisation humaine
explicite"). Cette page documente le chemin, elle ne l'emprunte pas.

### 6. Exploitation

Une fois déployé, ce site suivrait exactement le même cycle que
`projet-lavallee-website` ou `projet-gites` : healthcheck Docker, contrôle
HTTP applicatif, journal append-only de `grav-sites-ops` — rien de
spécifique à un site de documentation.

### 7. Mise à jour

Un changement de contenu (par exemple la rédaction d'un lot suivant de
cette documentation) suivrait le [flux construction →
déploiement](../03.flux-construction-deploiement) : nouveau commit, nouvelle
image, nouveau tag déclaré dans le registre, redéploiement.

### 8. Rollback

Identique à celui décrit sur la page [Versionnement et
rollback](../05.versionnement-et-rollback) : redéclarer l'ancienne version
et redéployer. Comme pour tout site de la plateforme, un rollback ne
restaure pas le contenu persistant (pages éditées, comptes) — seul le code
exécuté change.

### 9. Limites

- Ce parcours suppose un `control-repository` déjà configuré pour le
  domaine choisi — hors périmètre de ce dépôt et de `grav-sites-ops`.
- La rédaction éditoriale complète (Lots 3 à 8) est indépendante de
  l'intégration à la plateforme : un site peut être "intégré" au sens des
  étapes 1 à 4 avec un contenu encore partiellement en placeholder.

## Ce que ce parcours ne doit jamais faire pour un site futur

Reproduire une partie du contrat de `grav-runtime` (PHP, Nginx, entrypoint,
healthcheck) dans le nouveau dépôt ; committer un secret réel pour "tester
plus vite" ; faire dépendre `grav-sites-ops` de l'arborescence interne du
nouveau site plutôt que de son image publiée ; contourner le registre
déclaratif par une modification manuelle directe sur la VM.

---

```yaml
Sources documentées : ce dépôt (grav-platform-docs, Lots 0-1.1) ;
                       grav-sites-ops (v1.0.0) — docs/REGISTRY-SCHEMA.md
Dernière vérification : 2026-09-11
```
