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
| `templates/partials/base.html.twig` | **copie modifiée** de Learn2 | seul moyen d'altérer le bloc `topbar` du gabarit commun (Twig ne permet pas d'étendre par bloc un template chargé via `{% embed %}` à travers deux thèmes empilés) ; trois déviations documentées dans le commentaire en tête de fichier — le bloc `topbar`, et depuis le Lot 10 la balise `<meta name="viewport">` (retrait de `maximum-scale=1, user-scalable=no`, qui désactivait le zoom navigateur) et `aria-label="Accueil"` sur le lien `#logo` (aucun nom accessible dans l'original) — deux violations WCAG constatées par axe-core (`meta-viewport`, `link-name`) ; tout le reste du fichier est identique à l'original |
| `templates/partials/header-links.html.twig` | nouveau | porte les deux liens globaux du header (§9 du cahier), sans détourner `github_link.html.twig` de Learn2 (conçu pour éditer la page courante sur GitHub, pas pour un lien global) |
| `templates/contact.html.twig` | nouveau | gabarit du formulaire de contact, absent de Learn2 |
| `templates/forms/contact-email.html.twig` | nouveau | gabarit de l'e-mail envoyé, absent de Learn2 |
| `templates/docs.html.twig` | **copie modifiée** de Learn2 (Lot 10.1) | même limite d'héritage Twig par bloc que `base.html.twig` ci-dessus ; une seule déviation, dans le bloc `navigation` — `aria-label` ajouté aux liens précédent/suivant, nommant explicitement la page ciblée (l'original ne leur donne aucun nom accessible, icône seule — violation WCAG 2.4.4/4.1.2 constatée par axe-core, `link-name`) ; présentation visuelle inchangée ; tout le reste du fichier est identique à l'original |
| `css/custom.css` | nouveau, **point d'extension natif** | Learn2 référence déjà `theme://css/custom.css` dans son propre `base.html.twig` sans livrer ce fichier — c'est le point d'extension CSS prévu par le thème lui-même, pas une surcharge ; porte aussi, depuis le Lot 10.1, les correctifs de contraste (voir la section dédiée) |

Aucun autre fichier de Learn2 (JS, polices, images, gabarits `chapter.html.twig`
/ `default.html.twig` / `error.html.twig`, partials de recherche,
breadcrumbs, etc.) n'est copié ni modifié : ils sont utilisés tels quels via
le chaînage de flux.

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
existant. Les trois conditions initialement posées avant d'envisager cette
migration sont désormais réunies : (1) construction du site documentaire
lui-même — **faite** (Lot 8) ; (2) correction du constat identifié dans
`projet-gites` (référence : rapport de sécurité privé associé, hors de ce
dépôt) — **faite**, publiée dans le tag `v1.1.0` (voir la rubrique
`projet-gites`, page « Référence ») ; (3) un nouvel audit du dépôt une
fois corrigé — **fait**, favorable (audit final au tag publié, Lot 9). La
migration elle-même **n'a pas commencé** : cette section reste une
intention et des contraintes à respecter le jour où elle sera engagée,
pas un mécanisme construit par ce lot ni par aucun lot antérieur —
conformément à la consigne de ne jamais créer ici de page authentifiée ou
prétendument privée avant que ce mécanisme soit explicitement conçu.

## Dettes d'accessibilité connues (Lot 8, mesurées au Lot 10, fermées ou complétées aux Lots 10.1/10.2, décisions humaines enregistrées au Lot 10.3)

VISUAL-001 a couvert le rendu visuel (absence de débordement horizontal,
lisibilité desktop/mobile, formulaire, confirmation) et corrigé un bug
réel (titre H1 de l'accueil débordant sur mobile étroit,
`overflow-wrap: break-word` ajouté à `custom.css`). Le Lot 10 a mesuré
réellement (Playwright + axe-core 4.10, contraste calculé depuis les
styles réellement appliqués) les trois vérifications laissées ouvertes au
Lot 8, corrigé ce qui pouvait l'être **minimalement** dans ce dépôt, et
identifié deux dettes supplémentaires (A11Y-004, A11Y-005). Le Lot 10.1 a
fermé ce qui bloquait encore une release publique v1.0.0 et identifié
trois nouvelles dettes (A11Y-006/007/008). Le Lot 10.2 a fermé ces trois
dettes, complété la recette clavier, corrigé le vocabulaire employé pour
le zoom, et identifié deux nouvelles dettes plus structurelles
(A11Y-009, A11Y-010) ainsi qu'un constat clavier (A11Y-011). Le Lot 10.3
n'a modifié aucun code : il enregistre la décision humaine issue d'un
contrôle manuel réel au zoom navigateur (100 %/200 %), qui requalifie
A11Y-009/010 et confirme/accepte explicitement A11Y-011 comme dette non
bloquante pour v1.0.0 :

- **A11Y-001 — contraste : les quatre éléments identifiés au Lot 10 sont
  conformes, mesurés après correction (Lot 10.1).** Voir `custom.css`
  pour le détail des ratios. `axe-core` ne rapporte plus aucune violation
  `color-contrast` ni `link-in-text-block` sur ces quatre éléments.
- **A11Y-002 — clavier : recette complétée au Lot 10.2, toujours non
  garantie exhaustive à 100 %.** Parcours réellement exécuté (Playwright,
  vraies pressions de touche `Tab`/`Shift+Tab`/`Enter`/`Escape`, jamais de
  simulation de focus par script) : lien logo → champ de recherche →
  sommaire (8 rubriques) → « Clear History » → crédit « Grav » → liens du
  bandeau (`lavallee.tech`, GitHub) → bouton de sidebar mobile (là où il
  est réellement rendu dans le DOM, voir A11Y-011) → liens
  précédent/suivant (page docs) → formulaire complet
  (nom → e-mail → téléphone → message → envoi). Sur les 19 arrêts de la
  page d'accueil et les 19 de la page de contact : indicateur de focus
  visible sur chacun, aucun piège clavier constaté (le focus atteint
  normalement la fin de la séquence après le bouton d'envoi, sans boucler).
  Bouton de sidebar mobile testé isolément (375 px) : `Enter` ouvre le
  menu (classe `sidebar-hidden` ajoutée, `#sidebar` passe de `left:-230px`
  à `left:0`), le focus reste sur le bouton ; un second `Enter` sur ce
  même bouton referme le menu et le focus y reste — un aller-retour
  ouverture/fermeture par la même touche sur le même contrôle fonctionne
  correctement et restitue le focus au bon endroit. Voir A11Y-011 pour un
  constat lié mais distinct (ordre de tabulation, pas activation).
  **Non exhaustif** : sous-menus du sommaire dépliables/repliables au
  clavier non testés un à un.
- **A11Y-003 — zoom à 200 % : vocabulaire corrigé au Lot 10.2 ; vérifié
  sur un périmètre de largeurs élargi.** Le Lot 10.1 avait qualifié à tort
  `document.documentElement.style.zoom` de « zoom navigateur réel » — ce
  n'est pas le cas : c'est un contrôle CSS complémentaire, qui déclenche
  un vrai reflow de mise en page (contrairement à un `transform: scale`
  ou à un simple viewport réduit) mais n'est pas le zoom natif du
  navigateur (`Ctrl` + `+`, implémenté au niveau du chrome du navigateur,
  pas de la page). Le Lot 10.2 a tenté d'automatiser un vrai zoom
  navigateur dans cet environnement : ni l'envoi de l'accélérateur clavier
  réel (`xdotool`, fenêtre Chromium non-headless authentiquement focalisée
  sur un display X11 réel) ni `Emulation.setPageScaleFactor` (CDP — ne
  produit qu'un zoom visuel de type pincement mobile, sans reflow, et sans
  effet constaté ici) n'ont réussi à déclencher un vrai zoom navigateur
  avec reflow, malgré plusieurs méthodes essayées.

  **Décision humaine enregistrée (Lot 10.3) : contrôle manuel réel
  effectué par l'utilisateur, zoom navigateur réel (`Ctrl` + `+`, pas le
  contrôle CSS ci-dessus) à 100 % et à 200 %, hors de cette session
  automatisée. Constat : aucun défaut bloquant observé pendant ce
  contrôle réel.** Ce contrôle n'a pas été détaillé page par page dans ce
  dépôt (pas de liste des pages couvertes, pas de capture) — il fait
  foi comme vérification humaine du zoom navigateur réel demandé par
  WCAG 1.4.4/1.4.10, mais avec un niveau de granularité moindre que le
  reste de cette recette. Conséquence directe sur A11Y-009 et A11Y-010
  (débordements trouvés uniquement via le contrôle CSS complémentaire,
  à 320 px et 768 px) : **non reproduits lors de ce contrôle réel** —
  requalifiés ci-dessous en observations issues du seul contrôle CSS
  renforcé, pas en défauts confirmés au zoom navigateur réel.

  Le contrôle CSS complémentaire (six pages : accueil, page profonde,
  tableau large, bloc de code, glossaire, formulaire ; quatre largeurs :
  320, 375, 768, 1440 px) reste documenté ci-dessous et dans
  `docs/testing.md`, explicitement requalifié comme un **complément**,
  jamais une preuve de zoom navigateur réel à lui seul : accueil,
  glossaire, formulaire conformes (aucun débordement horizontal global) à
  1440 px ; page profonde/tableau large et bloc de code, non conformes à
  1440 px avant correction (voir A11Y-008, fermé), à nouveau conformes
  après ; à 320 et 768 px, des débordements distincts subsistent au
  contrôle CSS — voir A11Y-009 et A11Y-010, requalifiés.

  **Aucune certification WCAG globale n'est revendiquée** pour le zoom :
  ni le contrôle CSS complémentaire ni le contrôle manuel réel
  (non détaillé page par page) ne couvrent l'ensemble des pages et
  composants du site ; seuls les éléments et pages effectivement
  contrôlés, listés ici, le sont.
- **A11Y-004 — labels du formulaire de contact : fermé au Lot 10.1.**
  Un `id:` explicite par champ dans le frontmatter de la page contact,
  sans nouvelle surcharge de template. `axe-core` (`label`) : 0 violation.
- **A11Y-005 — liens icône seule « page précédente/suivante » : fermé au
  Lot 10.1.** Surcharge minimale `docs.html.twig`, `aria-label` explicite.
  `axe-core` (`link-name`) : 0 violation.
- **A11Y-006 — contraste du texte indicatif du champ de recherche : fermé
  au Lot 10.2.** Cause identifiée précisément (pas seulement la couleur
  déclarée) : `.searchbox input::-webkit-input-placeholder` est déclaré en
  blanc mais avec un **canal alpha** (`rgba(255,255,255,0.6)`) — la
  couleur réellement affichée est le mélange de ce blanc à 60 % avec le
  fond de `.searchbox` (`#1383b3`), soit ≈ `rgb(161,205,225)`, vérifié à
  la fois par calcul et par échantillonnage direct des pixels d'une
  capture d'écran. Contraste réel mesuré ≈ 2.56:1 — très en dessous de ce
  qu'`axe-core` avait rapporté (4.26:1, calculé sans tenir compte du canal
  alpha). Plus significatif encore : même un blanc totalement opaque ne
  suffit pas sur ce fond (plafond calculé de 4.26:1, quel que soit le
  texte choisi, le blanc étant la couleur la plus claire possible) — seul
  un assombrissement du fond de `.searchbox` pouvait suffire. Corrigé en
  assombrissant `.searchbox` vers `#0e6185` (couleur déjà en usage
  ailleurs dans ce fichier, pour la cohérence visuelle) et en rendant le
  texte indicatif totalement opaque : **6.85:1 mesuré**, dans les deux cas
  champ vide (texte indicatif) et rempli (texte saisi, qui plafonnait au
  même défaut), en desktop et mobile (le composant ne change pas de style
  selon le viewport), et à l'état focus (`:focus` ne modifie que la
  bordure/l'ombre, jamais le fond de `.searchbox`). `axe-core` : 0
  violation sur les trois pages testées.
- **A11Y-007 — contraste des numéros du sommaire latéral : fermé au
  Lot 10.2.** Cause identifiée précisément : Learn2 applique
  `opacity: 0.5` **directement sur l'élément** `<b>` du numéro (pas une
  opacité héritée d'un ancêtre) — `#sidebar ul.topics > li > a b`. C'est
  ce canal alpha qui produit un rendu très inférieur à la couleur
  déclarée seule : contraste réel mesuré ≈ 2.36:1 (échantillonnage de
  pixels), contre les 1.35:1/2.32:1 rapportés par `axe-core` (qui mélange
  correctement l'opacité mais avec un fond supposé blanc au lieu du fond
  réellement affiché à cet endroit — sous-estimant la sévérité sans se
  tromper sur l'existence du défaut). Quatre rendus distincts selon l'état
  du `<li>` parent (jamais du `<b>` lui-même, qui n'a pas de couleur
  propre) : normal (texte hérité `#bbbbbb`, fond sombre `#38424D`),
  survol (`#d5d5d5`, même fond), rubrique dépliée/`li.parent`
  (`#bbbbbb` sur `#2d353e`), page active/`li.active` (fond blanc, texte
  `#555`). Corrigé par `opacity: 1` : le numéro reçoit exactement le même
  rendu que le texte adjacent (non signalé par `axe-core`) dans chacun de
  ces quatre états. Ratios mesurés après correction (Playwright,
  `getComputedStyle` + calcul de luminance) : normal 5.32:1, survol
  6.96:1, focus clavier 6.96:1 (Learn2 n'a pas de règle `:focus` propre
  ici — le focus reprend la couleur de survol), rubrique dépliée 6.47:1,
  page active 7.46:1. `axe-core` : 0 violation sur les trois pages
  testées.
- **A11Y-008 — débordement horizontal global à 200 % sur `<code>` inline
  non sécable : fermé au Lot 10.2, pour son périmètre exact.** Cause :
  `#body-inner code` n'avait par défaut aucune règle de coupure (seuls
  `<pre>` et les tableaux sont bornés depuis le Lot 8) ; un hash de commit
  ou un nom de méthode qualifié sans espace (ex.
  `Blueprint::addAllowedDynamicCallable()`) forçait la largeur de tout le
  document. Corrigé par `#body-inner code { overflow-wrap: anywhere }`,
  **explicitement exclu pour le code à l'intérieur d'un `<pre>`**
  (`#body-inner pre code { overflow-wrap: normal }`, règle plus
  spécifique) — un bloc de code déjà scrollable horizontalement
  (`#body-inner pre { overflow-x: auto }`, Lot 8) n'a pas besoin d'être
  cassé au milieu d'un mot, ce qui en détruirait la mise en forme (voir
  l'en-tête de `custom.css` pour le raisonnement complet). Vérifié à
  1440 px et 375 px, aux deux niveaux de zoom (100 % et 200 %, contrôle
  CSS voir A11Y-003) sur la page profonde/tableau large et le bloc de
  code : plus aucun débordement horizontal global (0 px, contre 19 px et
  125 px avant correction), `#body-inner pre` et `#body-inner table`
  continuent de défiler normalement en interne. **Non conforme à 320 px
  et 768 px** — mais pour une cause différente et non liée au code inline
  (voir A11Y-009, A11Y-010) : ce point precis (code inline) est fermé,
  la conformité globale au zoom 200 % sur toutes les largeurs ne l'est
  pas.
- **A11Y-009 — lien « GitHub » du bandeau, débordement horizontal à
  320 px + 200 % : requalifiée au Lot 10.3, non bloquante.** Trouvée
  uniquement via le contrôle CSS complémentaire (`document.documentElement.
  style.zoom`, voir A11Y-003) : le lien "GitHub" du bandeau ne dispose
  d'aucun point de coupure (nom propre) et le point de rupture responsive
  de `#header-links` (`max-width: 767px`, réel) ne réduit pas sa taille de
  police ni ne le fait passer sur plusieurs lignes — à 320 px de largeur
  réelle combinés à un contenu visuellement doublé par le contrôle CSS, le
  lien déborde du bandeau. **Décision humaine (Lot 10.3) : non reproduite
  lors du contrôle manuel réel au zoom navigateur (100 %/200 %,
  A11Y-003)** — requalifiée en observation issue du seul contrôle CSS
  renforcé, pas en défaut confirmé au zoom navigateur réel. Reste ouverte
  par prudence (le contrôle réel n'a pas couvert cette combinaison
  largeur/page en détail), mais n'est plus traitée comme un défaut
  bloquant. Root cause distincte de A11Y-008 (aucun `<code>` impliqué),
  hors du périmètre « code inline » du Lot 10.2. Non corrigée.
- **A11Y-010 — texte de paragraphe compressé par la largeur fixe du
  sommaire à 768 px + 200 % : requalifiée au Lot 10.3, non bloquante.**
  Trouvée uniquement via le contrôle CSS complémentaire : `#sidebar` a une
  largeur fixe (230 px sous 767 px réels, 300 px au-dessus) ; combinée au
  doublement visuel du contrôle CSS à 768 px, la colonne de contenu
  (`#body-inner`) se retrouve mesurée à 116 px de large — trop étroite
  pour qu'un mot de taille normale s'y case, y compris dans du texte
  `<strong>` ordinaire en dehors de tout `<code>` ou tableau. **Décision
  humaine (Lot 10.3) : non reproduite lors du contrôle manuel réel au
  zoom navigateur (100 %/200 %, A11Y-003)** — requalifiée en observation
  issue du seul contrôle CSS renforcé, pas en défaut confirmé au zoom
  navigateur réel. Reste ouverte par prudence, mais n'est plus traitée
  comme un défaut bloquant. Root cause structurelle (largeur fixe du
  sommaire combinée à un contenu visuellement doublé), pas un défaut de
  coupure de mot — hors du périmètre « code inline » du Lot 10.2. Non
  corrigée.
- **A11Y-011 — ordre de tabulation du menu mobile : confirmée et
  explicitement acceptée comme dette non bloquante pour v1.0.0 (décision
  humaine, Lot 10.3).** Au clavier, à largeur mobile (≤ 767 px réels), les
  huit liens du sommaire (hors écran, `#sidebar` à `left:-230px` par
  défaut) restent **atteignables par `Tab`** avant même le bouton
  `#sidebar-toggle` qui les révèle visuellement — un utilisateur clavier
  voit son focus disparaître pendant 10 pressions de touche (aucun
  indicateur visible à l'écran) avant d'atteindre un élément visible.
  Symétriquement, une fois le menu ouvert au clavier, `Tab` (en avant)
  depuis le bouton ne mène pas dans le sommaire nouvellement visible (ces
  liens sont plus tôt dans l'ordre du DOM) mais directement aux liens du
  bandeau — `Shift+Tab` est nécessaire pour rejoindre le sommaire ouvert.
  Par ailleurs, `Escape` ne referme pas le menu (seule une nouvelle
  activation du bouton `#sidebar-toggle` le fait). Aucun piège clavier au
  sens strict (tout reste atteignable, dans les deux sens), mais un ordre
  de tabulation qui ne reflète pas l'ordre visuel pendant que le menu est
  fermé — WCAG 2.4.3. **Constat confirmé, non réévalué au Lot 10.3 (pas
  un artefact du contrôle CSS : reproduit par de vraies pressions de
  touche, indépendant de tout zoom).** Correction explicitement différée à
  une version ultérieure à v1.0.0 (déplacer le bouton plus tôt dans le DOM
  ou retirer les liens du sommaire de l'ordre de tabulation tant qu'il est
  fermé — `tabindex="-1"` géré en JavaScript — un changement de
  comportement plus large qu'une correction ponctuelle) : **non corrigée
  dans ce lot, sur décision explicite.**

**Corrigé au Lot 10** (mesuré, vérifié après correction, hors numérotation
A11Y puisque fermé dans le même lot que sa découverte) : langue du document
(`<html lang>` rendait `en` alors que tout le contenu est en français —
ajout de `default_lang: fr` à `grav/user/config/site.yaml`, WCAG 3.1.1) ;
lien `#logo` sans nom accessible (`axe-core` `link-name` — ajout de
`aria-label="Accueil"`, WCAG 2.4.4/4.1.2).

A11Y-001, A11Y-004, A11Y-005, A11Y-006, A11Y-007 et A11Y-008 (pour son
périmètre exact : code inline) sont désormais fermées. A11Y-002 et A11Y-003
sont complétées mais ne couvrent pas 100 % de leur périmètre respectif.

**Décision humaine enregistrée le jour du Lot 10.3** (contrôle manuel réel
au zoom navigateur, 100 % et 200 %, hors de cette session automatisée :
aucun défaut bloquant constaté) : A11Y-009 et A11Y-010, trouvées
uniquement via le contrôle CSS complémentaire et non reproduites lors de
ce contrôle réel, sont **requalifiées en observations issues du seul
contrôle CSS renforcé** — elles restent ouvertes par prudence mais ne
sont plus traitées comme des défauts confirmés au zoom navigateur réel.
A11Y-011 (ordre de tabulation du menu mobile), constat indépendant du
zoom et reproduit par de vraies pressions de touche, est **confirmée et
explicitement acceptée comme dette non bloquante pour v1.0.0** ; sa
correction est différée à une version ultérieure. Aucune de ces trois
dettes n'est une condition de ce lot ni du suivant, et aucune ne bloque
la construction ni la consultation locale de ce site documentaire.

**Aucune certification WCAG globale n'est revendiquée** : ni le contrôle
automatisé (axe-core, mesures de contraste, recette clavier scriptée) ni
le contrôle manuel réel (zoom navigateur, non détaillé page par page)
ne couvrent l'ensemble des pages et composants du site — seuls les
éléments et pages effectivement contrôlés, listés ci-dessus, le sont.
