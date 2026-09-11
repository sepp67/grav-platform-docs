---
title: Accueil
template: default
---

# Documentation de la plateforme Grav

Ce site documente l'architecture et le fonctionnement de la plateforme de
déploiement de sites Grav de Sébastien Lavallée, composée de cinq dépôts
indépendants :

- **grav-runtime** — image Docker générique d'exécution de Grav (PHP-FPM,
  Nginx, bootstrap administrateur, healthcheck).
- **ansible-role-grav-site** — rôle Ansible atomique qui déploie une
  instance Grav à partir d'une image applicative.
- **grav-sites-ops** — orchestration Ansible d'un parc de sites Grav sur des
  VM existantes.
- **projet-lavallee-website** — image applicative du site lavallee.tech.
- **projet-gites** — image applicative du site des gîtes.

## Comment lire cette documentation

La rubrique **Architecture globale** explique comment ces composants
s'articulent : qui construit quoi, qui déploie quoi, où vivent la
configuration, les secrets et les données persistantes.

Chaque dépôt dispose ensuite de sa propre rubrique, organisée de façon
identique : vue d'ensemble, place dans l'architecture, structure, flux
chronologique, sections de code, configuration, données et secrets, tests,
exploitation et diagnostic, adoption et référence.

Les affirmations techniques de ce site sont tracées à un commit précis de
chaque dépôt source — voir `docs/documentation-sources.yml` dans le dépôt
`grav-platform-docs`.
