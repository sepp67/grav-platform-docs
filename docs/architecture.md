# Architecture de ce dépôt

Ce document décrit comment **ce dépôt** (`grav-platform-docs`) est construit —
pas le contenu éditorial du site, qui vit dans `grav/user/pages/` et sera
rédigé lot par lot (voir le cahier de construction, `doc/`).

## Position dans la plateforme

```text
grav-runtime (ghcr.io/sepp67/grav-runtime:1.0.4)
    │  socle technique générique — PHP-FPM, Nginx, Grav Core + Admin,
    │  entrypoint, healthcheck, bootstrap admin, mécanisme de seed
    │
    └── grav-platform-docs (ce dépôt)
            │  thème enfant platform-docs-theme (hérite de Learn2), plugin
            │  contact, pages de documentation, configuration versionnée
            │
            └── ansible-role-grav-site (non branché à ce stade)
                    déploiera l'image publiée, exactement comme pour
                    projet-lavallee-website et projet-gites
```

`grav-platform-docs` est une sixième image applicative, indépendante des
cinq dépôts qu'elle documente. Elle ne les modifie jamais et n'a aucune
dépendance logicielle vers eux : elle en documente le comportement à un
commit figé (voir `docs/documentation-sources.yml`), pas leur code source.

## Intégration de Learn2

### Pourquoi pas un submodule Git ni une installation GPM

Un submodule Git introduirait une seconde source de vérité pour la version
du thème (le pointeur de commit du submodule, distinct du tag Git réel) et
compliquerait le build reproductible en image Docker. Une installation via
l'interface Admin de Grav (GPM) n'est pas reproductible en build automatisé
et est explicitement exclue par le cahier (§4.3).

### Mécanisme retenu : téléchargement épinglé et vérifié

Le `Dockerfile` télécharge l'archive GitHub correspondant exactement au
commit du tag `1.8.3` de `grav-theme-learn2` (pas la branche `develop`, pas
un tag `latest`), vérifie son intégrité par SHA-256 avant extraction, et
échoue le build sur toute divergence :

| Élément | Valeur |
|---|---|
| Dépôt | `https://github.com/getgrav/grav-theme-learn2` |
| Tag | `1.8.3` |
| Commit | `22b7f1e2d4a024b105399f912124fc901f807d7a` |
| Archive | `https://github.com/getgrav/grav-theme-learn2/archive/22b7f1e2d4a024b105399f912124fc901f807d7a.tar.gz` |
| SHA-256 | `e3cb9bf571ed5504675bb26dc1b3308542bd9c8e77fb2e6432c04373afb21449` |
| Installé sous | `/var/www/html/user/themes/learn2/` |

Cette étape s'exécute avant la copie du code applicatif de ce dépôt, donc
avant toute couche susceptible de changer plus souvent — elle profite du
cache de build Docker tant que `LEARN2_COMMIT` ne change pas.

### Thème enfant, sans copie ni modification du thème parent

`grav/user/themes/platform-docs-theme/` ne contient **aucune copie** du
thème Learn2. Le chaînage est déclaré dans
`platform-docs-theme.yaml` :

```yaml
streams:
  schemes:
    theme:
      type: ReadOnlyStream
      paths:
        - user://themes/platform-docs-theme
        - user://themes/learn2
```

Ce mécanisme fait que le flux `theme://` (utilisé par Grav pour résoudre
les templates, CSS, JS et images du thème actif) cherche d'abord dans
`platform-docs-theme`, puis retombe sur `learn2` pour tout fichier absent du
thème enfant. Aucun fichier de Learn2 n'est dupliqué ni modifié : seuls les
fichiers listés ci-dessous existent dans le thème enfant.

Ce mécanisme est celui documenté par Grav lui-même (guide officiel « Theme
Customization », clé `streams.schemes.theme`) et il est déjà utilisé et
vérifié fonctionnel dans cette même plateforme : `projet-gites/grav/user/
themes/gites-theme` chaîne vers `quark2` de façon identique, après l'échec
constaté d'une première tentative avec la clé `extends@` (voir le
commentaire de `gites-theme.yaml`). `grav-platform-docs` reprend ce
mécanisme déjà éprouvé plutôt que de le redécouvrir.

### Fichiers surchargés et raison de chaque surcharge

| Fichier du thème enfant | Statut | Raison |
|---|---|---|
| `platform-docs-theme.yaml` | nouveau | déclare le chaînage de flux vers Learn2 et la métadonnée du thème |
| `templates/partials/base.html.twig` | **copie modifiée** de Learn2 | seul moyen d'altérer le bloc `topbar` du gabarit commun (Twig ne permet pas d'étendre par bloc un template chargé via `{% embed %}` à travers deux thèmes empilés) ; tout le reste du fichier est identique à l'original — voir le commentaire en tête de fichier |
| `templates/partials/header-links.html.twig` | nouveau | porte les deux liens globaux du header (§9 du cahier), sans détourner `github_link.html.twig` de Learn2 (conçu pour éditer la page courante sur GitHub, pas pour un lien global) |
| `templates/contact.html.twig` | nouveau | gabarit du formulaire de contact, absent de Learn2 |
| `templates/forms/contact-email.html.twig` | nouveau | gabarit de l'e-mail envoyé, absent de Learn2 |
| `css/custom.css` | nouveau, **point d'extension natif** | Learn2 référence déjà `theme://css/custom.css` dans son propre `base.html.twig` sans livrer ce fichier — c'est le point d'extension CSS prévu par le thème lui-même, pas une surcharge |

Aucun autre fichier de Learn2 (JS, polices, images, gabarits `docs.html.twig`
/ `chapter.html.twig` / `default.html.twig` / `error.html.twig`, partials de
recherche, breadcrumbs, etc.) n'est copié ni modifié : ils sont utilisés
tels quels via le chaînage de flux.

### Header et identité visuelle (cahier §9)

Le mécanisme natif `github_link` de Learn2 (position `top` par défaut) est
désactivé (`github: {position: off}` dans
`grav/user/config/themes/platform-docs-theme.yaml`) : il est conçu pour
pointer vers le dépôt de la page courante affichée, pas pour porter un lien
global fixe. Le bandeau supérieur du contenu (`#top-bar`, bloc `topbar` de
`base.html.twig`) affiche à la place `header-links.html.twig`, avec les deux
liens requis, `target="_blank" rel="noopener noreferrer"` sur les deux :

| Libellé | Cible |
|---|---|
| `lavallee.tech` | `https://lavallee.tech/en` |
| `GitHub` | `https://github.com/sepp67` |

Le logo/lien de retour à l'accueil (`#logo` dans la colonne de navigation,
`templates/partials/base.html.twig`, hérité tel quel de Learn2) pointe déjà
vers `theme_config.home_url ?: base_url_absolute` — c'est-à-dire l'accueil
du site documentaire par défaut, sans modification nécessaire.

## Répartition immuable / persistante

Respecte le contrat de `grav-runtime` (cahier §4.2), identique à
`projet-lavallee-website` et `projet-gites` :

| Élément | Statut | Où |
|---|---|---|
| Thème (`platform-docs-theme` + Learn2 téléchargé), plugin `contact`, configuration non secrète | immuable, dans l'image | `grav/user/themes/`, `grav/user/plugins/`, `grav/user/config/` → copiés dans l'image |
| Pages initiales | seed non destructif | `grav/user/pages/` → `/opt/grav-seed/pages/` dans l'image, copié vers le volume persistant uniquement s'il est vide au premier démarrage (`docker/seed-init.sh` de `grav-runtime`) |
| Pages, comptes, données, images en fonctionnement | persistant | volumes Docker nommés (`compose.dev.yml` en local ; volumes de production gérés par `ansible-role-grav-site`, non branché à ce stade) |
| Secrets SMTP | jamais dans l'image | `user/config/email-private.php`, injecté au déploiement — voir `docs/contact-form.md` |

Aucune réimplémentation de PHP, Nginx, Grav Core, de l'entrypoint, du
healthcheck ou du bootstrap administrateur : tout cela appartient
exclusivement à `grav-runtime`.

## Ce que ce dépôt ne fait jamais

Construire ou modifier `grav-runtime` ; contenir le code des cinq dépôts
qu'il documente ; générer ou committer un Compose de production, ou
dupliquer une tâche de déploiement (appartient à `ansible-role-grav-site`) ;
déclarer sa propre instance de déploiement (appartient à `grav-sites-ops`) ;
committer un secret réel, un compte utilisateur réel ou une adresse de
production.

## Décision différée : future page authentifiée pour contenu sensible

Constat du Lot 7 (audit de `projet-gites`) : certains constats d'audit
(détail technique de vulnérabilités confirmées, procédures de
reproduction) ne doivent jamais être publiés sur ce site tel qu'il est
construit aujourd'hui — un site entièrement public, sans authentification.
Une page réservée à un public restreint (mainteneurs des dépôts
documentés) est envisagée pour une itération future, **pas construite
maintenant**. Décision d'architecture posée à l'avance, pour cadrer ce
travail futur :

- `visible: false` ne constitue **pas** un contrôle d'accès — seulement
  une absence du menu ; une page ainsi marquée reste atteignable par son
  URL directe, sans restriction.
- La future page exigera une **authentification Grav réelle** (compte,
  identifiants), pas seulement une URL non référencée.
- L'autorisation devra être **vérifiée côté serveur**, à chaque requête —
  jamais seulement par un gabarit qui masque un lien ou un formulaire.
- Le contenu sensible ne devra **jamais** être stocké dans ce dépôt public,
  ni committé, ni versionné ici.
- Il ne devra **jamais** être intégré à l'image Docker publique construite
  depuis ce dépôt.
- Il devra être **injecté depuis une source privée** directement dans un
  volume persistant, hors du cycle de build/publication de l'image — le
  mécanisme d'injection lui-même **reste entièrement à concevoir**,
  aucune solution n'est retenue à ce stade.
- Un accès direct à l'URL sans authentification valide devra retourner un
  refus explicite (403) ou une redirection vers l'authentification —
  jamais un contenu partiel ou une page silencieusement absente.
- Les mécanismes de cache, flux RSS, recherche interne, sitemap et
  indexation par des moteurs externes devront **exclure** cette page
  explicitement.
- Toute sauvegarde du volume contenant cette page devra recevoir la même
  protection que le contenu lui-même (chiffrement, accès restreint).
- Les comptes autorisés à consulter cette page devront recevoir un droit
  **dédié et minimal**, distinct des droits d'administration générale du
  site.

**Aucune migration de contenu sensible n'a encore été effectuée** — cette
section documente une intention et des contraintes, pas un mécanisme
existant. Cette migration n'est pas planifiée avant, dans l'ordre : (1) la
fin de la construction du site documentaire lui-même ; (2) la correction
du constat identifié dans `projet-gites` (référence : rapport de sécurité
privé associé, hors de ce dépôt) ; (3) un nouvel audit du dépôt une fois
corrigé.
