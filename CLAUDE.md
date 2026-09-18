# Instructions locales — grav-platform-docs

Avant toute action, lire le fichier `../CLAUDE.md`.

Ce dépôt produit l'image applicative du site documentaire de la plateforme
Grav à partir de `grav-runtime`.

## Invariants locaux

- conserver le thème enfant `platform-docs-theme` fondé sur Learn2 ;
- maintenir les pages et diagrammes destinés au site documentaire ;
- conserver le manifeste des sources documentaires ;
- documenter les dépôts sources à partir de références immuables : tag et SHA ;
- distinguer explicitement un test présent, un test lu, un test exécuté et un
  résultat réellement observé ;
- ne jamais transformer une branche flottante en référence d'audit ;
- ne jamais intégrer de secret, vault, inventaire de production ou donnée
  personnelle au site ;
- ne pas remplacer la documentation normative détenue par les dépôts sources ;
- signaler toute divergence entre la documentation publiée et la source
  auditée.

## Sources et contenu

- une page décrivant un dépôt doit indiquer la version et le SHA audités ;
- toute mise à jour documentaire doit identifier les sources effectivement
  consultées ;
- les pages Grav publiées sont du contenu applicatif de ce dépôt ;
- les brouillons, prompts et rapports intermédiaires restent hors du dépôt,
  conformément au `CLAUDE.md` parent.

## Avant une modification

Consulter au minimum :

- `README.md` ;
- `Dockerfile` ;
- `docs/documentation-sources.yml` ;
- `grav/user/pages/` ;
- le thème enfant `platform-docs-theme` ;
- les tests et contrôles présents dans le dépôt.

## Contrôles spécifiques

- validation du manifeste des sources ;
- cohérence entre chaque page, le tag et le SHA annoncés ;
- validation des liens internes ;
- contrôle des versions française, allemande et anglaise lorsqu'elles existent ;
- construction de l'image ;
- vérification du rendu et de la navigation Learn2 ;
- vérification qu'aucune information non publiable n'est intégrée au site.