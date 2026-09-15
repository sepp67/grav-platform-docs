---
title: "Glossaire commun"
template: docs
taxonomy:
    category: [docs]
---

Cette page rassemble, pour le Lot 8 (cohérence transverse), les termes qui
recouvrent une **même signification technique** dans plusieurs des cinq
dépôts documentés. Elle ne remplace aucun glossaire local (page
« Référence » de chaque rubrique) : elle signale la cohérence — ou l'écart
délibéré — entre dépôts, et sert de point d'entrée unique pour un terme
rencontré n'importe où sur ce site.

## Termes partagés, définition identique dans tous les dépôts concernés

| Terme | Définition | Dépôts concernés |
|---|---|---|
| Seed | Contenu initial fourni par une image applicative (`/opt/grav-seed/<dir>`), copié **une seule fois** dans un répertoire persistant, uniquement s'il est vide au premier démarrage — jamais resynchronisé ensuite | [`grav-runtime`](../02.grav-runtime) (mécanisme), [`projet-lavallee-website`](../05.projet-lavallee-website), [`projet-gites`](../06.projet-gites) (contenu applicatif) |
| Code applicatif immuable | Thème, plugins, configuration versionnée — copiés dans l'image à chaque build, réécrits à chaque nouveau conteneur, jamais lus depuis un volume persistant | les deux images applicatives et `grav-platform-docs` lui-même |
| Healthcheck technique vs. contrôle applicatif | `/healthz` (fourni par `grav-runtime`) prouve seulement que Nginx et PHP-FPM répondent ensemble ; il ne prouve jamais qu'une page réelle du site rend correctement — un second contrôle HTTP sur une page réelle est systématiquement ajouté en aval | `grav-runtime`, `ansible-role-grav-site` |
| État désiré / appliqué / réel | Trois couches distinctes d'un même système de contrôle de dérive : ce qu'un registre déclare (désiré), ce qu'un mécanisme de déploiement a écrit lors de son dernier passage (appliqué), ce qu'une sonde observe au moment du contrôle (réel) | `grav-sites-ops` (le seul dépôt à implémenter cette classification à trois niveaux) |
| Rollback ≠ restauration de données | Un rollback ne fait jamais que redéclarer une version d'image antérieure et redéployer — il ne touche **jamais** au contenu des volumes persistants ; restaurer un contenu est une opération distincte, toujours manuelle | `ansible-role-grav-site`, `grav-sites-ops`, `projet-gites` (`test-update-rollback.sh`) |
| `latest` toujours refusé en production | Chaque dépôt qui publie ou consomme une image applicative interdit explicitement le tag `latest` comme version de déploiement — vérifié soit par une assertion Ansible (`ansible-role-grav-site`), soit par une validation de registre (`grav-sites-ops`), soit par une déclaration documentaire constante (les deux images applicatives) | tous les dépôts qui publient ou déploient une image |
| Tri-state du bootstrap administrateur | Les trois variables d'identité admin (utilisateur/mot de passe/e-mail) doivent être **toutes** définies ou **toutes** absentes — jamais un sous-ensemble | `grav-runtime` (politique d'origine), `ansible-role-grav-site` (assertion reprise), `grav-sites-ops` (validation reprise) |

## Termes qui désignent des mécanismes différents malgré un nom proche

| Terme | Sens dans un dépôt | Sens différent ailleurs |
|---|---|---|
| « Digest » | `ansible-role-grav-site` v2.0.0 : `grav_digest`, un champ optionnel qui épingle une image par somme de contrôle SHA-256, en plus du tag | **n'existe pas** dans `ansible-role-grav-site` v1.0.1 (vérifié directement, Lot 7) — un exemple écrit contre cette version antérieure ne le mentionne jamais, sans que ce soit une erreur |
| « Contrat » | `ansible-role-grav-site` cite un « contrat v1.0.1 » comme texte normatif à plusieurs endroits de son propre code (commentaires `assert.yml`) | ce texte normatif lui-même n'a pas été lu par `grav-platform-docs` — seules ses conséquences observables dans le code ont été vérifiées |
| « Rôle » (formulaire de contact) | `projet-lavallee-website` : route fixe par défaut (`/contact`), un seul propriétaire possible | `projet-gites` : sélection visible et obligatoire parmi une liste fermée construite côté serveur, plusieurs propriétaires possibles selon le gîte choisi — mécanisme corrigé dans le tag `v1.1.0` (historiquement un champ qualifié de « caché », non revalidé à la soumission : constat de sécurité SEC-GITES-001, voir la rubrique `projet-gites`) |
| « Glossaire » | Chaque rubrique de dépôt porte son propre « Glossaire local » (page Référence), spécifique à son vocabulaire de code | cette page-ci, seule à porter le nom « Glossaire commun », ne documente que les recoupements entre dépôts |

## Comment lire ce glossaire

Un terme absent d'ici et présent dans un glossaire local n'est pas
nécessairement propre à ce dépôt : il peut simplement ne pas avoir de
recoupement direct avec un autre dépôt de la plateforme. Consultez le
glossaire local de la rubrique concernée pour tout terme spécifique à son
code.

---

```yaml
Sources documentées : les onze pages « Référence » des cinq dépôts déjà audités — voir docs/documentation-sources.yml
Dernière vérification : 2026-09-15 (Lot 9 — ligne SEC-GITES-001 actualisée : corrigé, tag v1.1.0)
```
