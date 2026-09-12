---
title: "Architecture globale"
template: chapter
taxonomy:
    category: [docs]
---

Cette rubrique explique comment les cinq dépôts de la plateforme
s'articulent, avant d'entrer dans le détail de chacun (rubriques
suivantes). Elle répond progressivement aux huit questions du cahier de
construction de ce site :

1. [Vue d'ensemble](01.vue-ensemble) — quel problème la plateforme
   résout-elle, et pourquoi séparer runtime, image applicative, rôle
   atomique et orchestration ?
2. [Responsabilités et frontières](02.responsabilites-et-frontieres) —
   qui construit quoi, qui déploie quoi, RACI, contrats d'interface,
   frontière avec le reverse proxy.
3. [Flux construction → déploiement](03.flux-construction-deploiement) —
   comment une modification traverse le système, du commit au site en
   fonctionnement.
4. [Données, persistance et secrets](04.donnees-persistance-secrets) —
   où vivent la configuration, les secrets et les données persistantes.
5. [Versionnement et rollback](05.versionnement-et-rollback) — comment une
   mise à jour et un rollback sont déclarés et observés.
6. [Parcours d'adoption](06.parcours-adoption) — comment un sixième site
   (ce site documentaire lui-même) s'intègre à la plateforme.

Les affirmations de cette rubrique sont tracées aux sources listées dans
`docs/documentation-sources.yml`, à la racine de ce dépôt — chaque sous-page
ci-dessus cite en pied de page les dépôts, références et commits qui la
concernent spécifiquement.

---

```yaml
Sources documentées : cinq dépôts + Learn2 — voir docs/documentation-sources.yml
Dernière vérification : 2026-09-11
```
