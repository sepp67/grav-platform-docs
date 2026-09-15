---
title: "Référence"
template: docs
taxonomy:
    category: [docs]
---

## Constat de sécurité SEC-GITES-001 — routage du formulaire de contact

Cette rubrique documente un constat de sécurité réel, confirmé
empiriquement lors de l'audit initial (Lot 7, commit `b27d7af`), **depuis
corrigé et publié dans le tag `v1.1.0`**. **La procédure de reproduction
complète du constat d'origine, les charges de test, les comptes utilisés
et le détail technique du mécanisme ne sont volontairement pas publiés
sur ce site, y compris après correction** : ils restent conservés dans un
rapport de sécurité séparé, hors de ce dépôt documentaire public et hors
de tous les dépôts documentés.

| Champ | Valeur |
|---|---|
| Identifiant | SEC-GITES-001 |
| Composant | Routage du formulaire de contact de `projet-gites` |
| Version concernée (constat d'origine) | commit `b27d7af` (aucun tag applicatif à l'époque) |
| Version corrigée | **tag `v1.1.0`, commit `7309bd1968c1f9a4ede93098d624cea46243aa0b`** |
| Nature | Donnée de routage contrôlée côté client, non revalidée à la soumission |
| Impact (constaté à l'origine) | Une demande de contact pouvait être dirigée vers un autre propriétaire valide que celui affiché au visiteur |
| Portée | Limitée aux destinataires existants reconnus par l'application |
| Adresse arbitraire | Non démontrée — le mécanisme restait borné aux comptes déjà existants sur l'instance |
| Preuve (constat d'origine) | Test local, en environnement jetable, avec deux comptes Grav synthétiques |
| **Statut** | **Corrigé et publié.** Sélection visible et obligatoire, résolue exclusivement depuis une table serveur fermée — voir « Stratégie de correction » ci-dessous |
| Correctif | Réalisé dans `projet-gites`, tag `v1.1.0` — voir la chronologie complète ci-dessous |
| Retest | Suite de tests étendue (60 assertions dédiées) exécutée avec succès contre la source reconstruite **et** contre l'image réellement publiée sur GHCR |
| **Effet sur la publication** | **Levé** — ce constat ne bloque plus de release ni de déploiement ; l'audit final au tag publié (2026-09-15) a été favorable |

**Ce que cette page ne fournit pas, par choix éditorial, y compris après
correction** : la requête exacte, une commande de reproduction du constat
d'origine, les identifiants de compte utilisés pour la démonstration
initiale, ou tout autre détail permettant une exploitation directe sans
travail d'analyse supplémentaire.

### Stratégie de correction retenue — sélection visible et validation serveur fermée

Le champ `gite`, historiquement un champ `hidden` prérempli côté serveur
mais jamais revalidé à la soumission, devient un **sélecteur visible et
obligatoire**. Trois principes vérifiés directement dans le code publié :

- **Identifiant public fondé sur le slug** de la page (pas la route
  complète) — présélectionné de façon ergonomique sur la fiche d'un gîte
  (`setData('gite', page.slug)`), mais **aucune présélection** sur
  `/contact` consulté seul ; cette présélection reste une valeur cliente,
  jamais une preuve de sécurité.
- **Option explicite `general`** — identifiant réservé pour une demande ne
  visant aucun gîte précis, disponible uniquement si l'adresse générale du
  site est elle-même valide.
- **Aucune confiance accordée à la valeur reçue** — la valeur soumise sert
  uniquement de clé de lookup dans une table serveur recalculée à
  l'instant de la validation ; l'affichage des options, la validation de
  la soumission et la résolution du destinataire lisent tous les trois
  cette même table, jamais trois logiques distinctes.

### Chronologie complète, de la détection à la publication

| Étape | Date | Détail |
|---|---|---|
| Détection | 2026-09-14 (Lot 7) | Confirmée empiriquement au commit `b27d7af`, avec deux comptes Grav synthétiques |
| Stratégie A étudiée puis invalidée | 2026-09-15 | Dérivation du contexte depuis l'URI/la page serveur — invalidée **expérimentalement** : le formulaire rendu sur une fiche de gîte poste toujours vers `/contact`, quelle que soit la fiche d'origine ; ce contexte n'est donc pas discriminant |
| Stratégie C étudiée puis écartée | 2026-09-15 | Jeton de contexte signé côté serveur — jugée disproportionnée par l'opérateur du dépôt (complexité cryptographique et cycle de vie du secret non justifiés par l'impact observé) |
| Stratégie D retenue et implémentée | 2026-09-15 | Sélection visible et obligatoire, table serveur unique — voir ci-dessus |
| Correction testée | 2026-09-15 | Suite de tests étendue à 60 assertions nommées, vérifiée capable de détecter la régression sur le code pré-correctif |
| Durcissements complémentaires | 2026-09-15 | Réservation de l'identifiant `general` et protection contre les collisions ; éligibilité stricte des pages (routabilité, template, format de slug) ; validation syntaxique des adresses ; rejet applicatif explicite des `\r`/`\n` dans `nom`/`email`, avant même la neutralisation déjà assurée par la bibliothèque d'envoi |
| Audit FIX-GITES-R1 | 2026-09-15 | Lecture de code indépendante, avant fusion, dans un worktree détaché dédié — modèle de confiance retracé bout en bout, verdict favorable sous réserve d'une correction mineure |
| Correction du nettoyage temporaire | 2026-09-15 | Défaut mineur découvert par cet audit (fichiers temporaires de test jamais nettoyés) — corrigé et couvert par un test dédié |
| Rebase d'identité Git, sans changement de contenu | 2026-09-15 | Les trois commits de la branche de correction ont été réécrits (métadonnées auteur/committeur uniquement) avant fusion — contenu vérifié rigoureusement identique par comparaison d'arbre Git |
| Fusion | 2026-09-15 | Pull request fusionnée dans `main` (commit `c052f21`), CI distante verte |
| Publication `v1.1.0` | 2026-09-15 | Tag créé, image `ghcr.io/sepp67/projet-gites:1.1.0` construite et publiée sur GHCR, CI de publication verte |
| Audit final favorable | 2026-09-15 (Lot 9) | Commit du tag vérifié ancêtre de `main` ; image publiée vérifiée par digest et par étiquette de révision ; suite complète et contrôles ciblés rejoués avec succès contre l'image réellement tirée de GHCR ; aucune fuite trouvée |

## Autres constats sur la sécurité du formulaire

Ces points sont des propriétés générales du mécanisme, indépendantes de
SEC-GITES-001 et ne permettant pas, seuls, sa reproduction :

- **Honeypot** — **attribution précise, vérifiée dans le code (`v1.1.0`)** :
  le *type* de champ `honeypot` et son rendu (normalement invisible) sont
  fournis par le plugin Form de Grav ; la *lecture* de sa valeur et le
  *rejet* de la soumission sont un contrôle applicatif de ce plugin
  contact — Form ne rejette rien de lui-même sur ce champ. Un filtre
  partiel, jamais une protection anti-spam complète.
- **CSRF** : sur le formulaire de contact, fourni par le Form plugin de
  Grav Core (nonce standard, non ré-audité au niveau code — voir
  [Lot 6](../../05.projet-lavallee-website/11.reference) pour la même
  observation). Sur le formulaire de gestion des disponibilités
  (`/gerer`), un nonce **dédié** est vérifié explicitement dans le code
  de ce dépôt, **avant** toute autre logique — mécanisme identifié avec
  certitude, pas déduit.
- **Échappement** : le gabarit d'e-mail échappe explicitement chaque
  valeur affichée (`|e`) ; le sujet est échappé par l'auto-échappement
  Twig par défaut — confirmé directement, pas déduit.
- **Injection d'en-tête (CR/LF)** — **retestée directement pour ce dépôt
  dans `v1.1.0`, avec attribution précise par cas** : `\r`/`\n` dans
  `nom` ou `email` sont désormais **rejetés par ce plugin contact
  lui-même**, avant tout traitement — pas seulement neutralisés en aval.
  Constat historique conservé : avant ce durcissement, un tel caractère
  dans `email` franchissait déjà la validation de champ de Grav Form,
  mais était neutralisé par la bibliothèque d'envoi (Reply-To supprimé
  plutôt qu'injecté) — cette bibliothèque reste une protection
  complémentaire observée, plus la seule barrière. Une balise `<script>`
  reste rejetée par la validation de champ de Grav Form ; une balise HTML
  non-script est acceptée puis échappée à l'affichage — ces deux
  comportements ne doivent jamais être confondus l'un avec l'autre.
- **Chargement des secrets SMTP** : identique à `projet-lavallee-website`
  — voir [Données, secrets et persistance](../07.donnees-secrets-persistance)
  pour le risque de `ParseError` documenté et confirmé en direct (HTTP 500).
- **Langue** : sans objet pour la localisation — dépôt monolingue.

## Audit des données personnelles présentes dans le snapshot

Vérifié initialement sur le contenu du commit `b27d7af` (Lot 7) — aucune
consultation de l'historique Git au-delà de ce qui était nécessaire.
**Inchangé au tag `v1.1.0`** : la correction SEC-GITES-001 ne touche pas
le contenu éditorial des fiches de gîtes, confirmé par comparaison directe
(les fichiers listés ci-dessous ne figurent dans aucun des commits de la
correction).

| Élément | Classification | Détail |
|---|---|---|
| `proprio-gite-1`, `proprio-gite-2` (noms de compte attendus) | donnée d'exemple / identifiant technique | pas de nom de famille, forme générique |
| Adresse postale + coordonnées GPS précises de « Chalet Wisches » | **donnée personnelle** | code postal et localité réels, latitude/longitude décimales précises au niveau de la parcelle — **non reproduits dans cette documentation** |
| Adresse postale + coordonnées GPS de « Maison Taintrux » | **donnée personnelle** | même nature — **non reproduits dans cette documentation** |
| Récit à la première personne sur « Chalet Wisches » (mentionnant que le logement est la résidence principale du propriétaire, et un détail physique personnel) | **donnée personnelle** | contenu éditorial rédigé à la première personne — **non cité verbatim dans cette documentation** |
| `admin@lavallee.tech` (`email.yaml`) | donnée publique assumée | adresse de contact du site, cohérente avec le domaine `lavallee.tech` déjà documenté aux Lots 5-6 |
| `joe@example.com` / « Joe Bloggs » (`site.yaml`) | donnée d'exemple | valeurs par défaut du squelette Grav, jamais personnalisées, domaine RFC 2606 |
| Nom d'hôte SMTP réel, référencé par `tests/test-secrets.sh` comme métadonnée d'infrastructure historique | **métadonnée d'infrastructure — information non secrète, mais indésirable dans un exemple générique** | un exemple de `docs/secrets-and-config.md` contenait encore une valeur liée à une infrastructure SMTP réelle ; aucun identifiant ni mot de passe associé n'a été constaté à proximité ; ce nom d'hôte a été, par le passé, réellement committé en clair avant d'être retiré — `tests/test-secrets.sh` garde activement contre son retour (test de non-régression). Nom exact non reproduit dans cette documentation — voir le fichier source cité pour le détail |
| Contenu de `tests/fixtures/email-private.valid.php` | donnée d'exemple / secret de test | valeurs `*.invalid`, sentinelle explicitement marquée `DO_NOT_SHIP`, jamais un secret réel |
| `salt` de `plugins/api.yaml` | donnée technique non secrète (selon la classification du dépôt lui-même) | générée automatiquement par Grav Admin |
| Comptes Grav réels (`user/accounts/`) | absent du snapshot | `.gitignore`, jamais committé |
| Numéros de téléphone | absents du snapshot | aucun trouvé dans le contenu versionné |

## Inventaire éditorial

| Route logique | Template | Visible | Propriétaire | État |
|---|---|---:|---|---|
| Accueil (`/`) | `homepage` | oui | — | complet |
| Typographie (`/typography`) | (défaut Grav) | non (`visible: false`) | — | **contenu de démonstration standard de Grav, jamais retiré** — auto-signalé comme « point ouvert » par `docs/seed-lifecycle.md` |
| Gîtes, index (`/gites`) | — | oui | — | `redirect: /gites/gite-un`, pas de page de listing propre à cette route |
| Chalet Wisches (`/gites/gite-un`) | `gite-item` | oui | `proprio-gite-1` | complet, contenu éditorial rédigé, 9 photos classées |
| Photos Chalet Wisches (`/gites/gite-un/photos`) | `gite-photos` | non (`visible: false`) | — | complet |
| Maison Taintrux (`/gites/gite-deux`) | `gite-item` | oui | `proprio-gite-2` | **auto-déclaré temporaire** dans son propre contenu (« à remplacer par les données réelles »), `capacite_max`/`nombre_chambres` à `0`, équipements non renseignés, **typo dans le titre H1** (« Appartemetn ») |
| Photos Maison Taintrux (`/gites/gite-deux/photos`) | `gite-photos` | non (`visible: false`) | — | complet |
| Gérer mes disponibilités (`/gerer`) | `gerer-disponibilites` | non (`visible: false`) | dynamique (utilisateur connecté) | complet, réservé aux propriétaires authentifiés |
| Contact (`/contact`) | `contact` | non (`visible: false`) | dynamique (sélection visible du visiteur, résolue côté serveur) | complet, fonctionnel — voir audit du routage ci-dessus |
| Confirmation (`/contact/confirmation`) | (défaut) | non (`visible: false`) | — | complet |

**Constats** : aucune traduction à vérifier (monolingue) ; aucun lien
cassé identifié dans les templates de ce dépôt (à la différence du
lien LinkedIn de `projet-lavallee-website`) ; un média absent n'a pas été
constaté (les 9 + 7 photos référencées existent toutes dans l'arborescence
du commit) ; une donnée de démonstration Grav standard (`02.typography`)
reste présente et non retirée, avec une décision éditoriale explicitement
différée par la documentation du dépôt elle-même.

## Écarts constatés

| Source | Affirmation | Code/comportement réel | Écart |
|---|---|---|---|
| `docs/architecture.md`, `docs/compatibility-policy.md` (au commit `b27d7af`) | `grav-runtime` certifié : `1.0.2`, seule combinaison recommandée | `Dockerfile` : `FROM ghcr.io/sepp67/grav-runtime:1.0.4` | **écart historique, résolu dans le tag `v1.1.0`** — `docs/compatibility-policy.md` y certifie désormais `1.0.4`, sur la base de la suite de tests de ce même chantier réellement exécutée contre cette version. Chronologie complète ci-dessous |
| `docs/architecture.md`, `.gitignore`, `compose.dev.yml`, `docs/release-and-rollback.md` (au commit `b27d7af`) | `ansible-role-grav-site:1.0.1` (référencé de façon cohérente dans 4 fichiers distincts, tous écrits **au moment de la création du dépôt**) | tag `v1.0.1` **existe réellement** (`bbd825ebe6f676dfd91017405cdaa963bbdcdee5`) et avait été vérifié spécifiquement au Lot 7 | **écart historique, résolu dans le tag `v1.1.0`** — les 4 fichiers référencent désormais `ansible-role-grav-site:2.0.0`, avec `grav_bind_address` ajouté à l'exemple (devenu obligatoire) ; alignement vérifié **statiquement seulement** (lecture du code et du guide de migration du rôle), aucun déploiement Ansible réel exécuté |
| `docs/compatibility-policy.md` (dans le tag `v1.1.0` lui-même) | la ligne `1.1.0` est qualifiée de « proposée — non encore taguée » | le tag `v1.1.0` **existe réellement et est publié** (image GHCR vérifiée par digest) | **écart documentaire réel, présent dans le tag publié** — formulation exacte au moment de sa rédaction (avant la création du tag), désormais dépassée ; non corrigée par ce lot ni par `grav-platform-docs` (qui ne modifie jamais `projet-gites`), et le tag `v1.1.0` ne doit jamais être déplacé pour la corriger rétroactivement — dette documentaire pour une version ultérieure |
| `docs/security-notes.md` (dans le tag `v1.1.0` lui-même) | SEC-GITES-001 est qualifié de « en attente de release », « numéro de version corrigée : à déterminer » | le correctif **est** publié dans ce tag même | **même nature d'écart, même cause, même non-correction** — voir la ligne précédente |
| README | « The test suite covers the application build, startup, application presence and persistence behaviour » | la suite couvre en réalité **8** aspects dans `v1.1.0`, dont les secrets, le routage du formulaire et la mise à jour/rollback, non mentionnés dans cette phrase du README | écart mineur de complétude, inchangé depuis le Lot 7 — le README sous-décrit la couverture réelle (`docs/testing.md` est, lui, complet et exact) |
| `docs/secrets-and-config.md` | `site.yaml` « contient encore des valeurs par défaut Grav non pertinentes… nettoyage éditorial possible » | confirmé : `title: Grav`, `author.name: Joe Bloggs` | **aucun écart** — auto-déclaré et confirmé identique, inchangé dans `v1.1.0` |
| `docs/secrets-and-config.md` (cas 4/4) | une erreur de syntaxe dans `email-private.php` doit produire un HTTP 500 | **vérifié en direct** : HTTP 500 confirmé, à nouveau au tag `v1.1.0` | **aucun écart** — comportement documenté et reproduit fidèlement |
| `docs/testing.md` | `test-secrets.sh` corrige un « faux positif » antérieur (grep sur `docker save` compressé, motifs génériques) | confirmé par la lecture du script lui-même, qui documente précisément cet historique en commentaire | **aucun écart** — cohérence confirmée entre la documentation et le code |

### Chronologie précise de l'écart `grav-runtime`/`ansible-role-grav-site` (établie depuis l'historique Git du dépôt, lecture seule)

| Date | Événement |
|---|---|
| 2026-07-25 | Création du dépôt ; `docs/compatibility-policy.md` rédigé, certifiant `grav-runtime 1.0.2` ; les quatre fichiers citant `ansible-role-grav-site:1.0.1` sont écrits |
| 2026-07-26 | `Dockerfile` passe à `grav-runtime:1.0.3` — `docs/compatibility-policy.md` **non mis à jour** |
| 2026-08-05 | `Dockerfile` passe à `grav-runtime:1.0.4` — `docs/compatibility-policy.md` **toujours non mis à jour** |
| 2026-08-23 | Commit audité au Lot 7 (`b27d7af`) — l'écart existe tel que décrit ci-dessus |
| 2026-09-14 | Audit complet Lot 7 — écart documenté, non corrigé, état au-delà de ce commit non revérifié à ce stade |
| **2026-09-15** | **Correction publiée dans le tag `v1.1.0`** : `docs/compatibility-policy.md` certifie `1.0.4` ; les 4 fichiers référencent `ansible-role-grav-site:2.0.0` avec `grav_bind_address` ajouté — voir « Écarts constatés » ci-dessus pour la dette documentaire résiduelle (formulations « non encore taguée » toujours présentes dans le tag lui-même) |

Cette chronologie établit que l'écart n'est pas un simple oubli ponctuel :
la documentation de certification n'a **jamais** été mise à jour après sa
rédaction initiale, malgré deux changements successifs de version du
runtime.

### Vérification ciblée du tag `ansible-role-grav-site:v1.0.1`

Worktree Git détaché créé temporairement sur
`bbd825ebe6f676dfd91017405cdaa963bbdcdee5` (tag `v1.0.1`, existe réellement
sur le dépôt distant), pour cette seule comparaison — pas un nouvel audit
complet du rôle. Fichiers lus : `defaults/main.yml`, `meta/main.yml`,
`tasks/main.yml`, `tasks/assert.yml`, `tasks/secrets.yml`,
`requirements.yml`, sections utilisation/variables du `README.md`. Worktree
supprimé après lecture ; dépôt source `ansible-role-grav-site` inchangé.

| Élément | Exemple `projet-gites` | Contrat `v1.0.1` | Contrat `v2.0.0` | Conclusion |
|---|---|---|---|---|
| Nom et résolution du rôle | `role: ansible-role-grav-site` (nom du dépôt) | identité Galaxy `sepp67.grav_site` ; le README `v1.0.1` utilise lui-même le nom du dépôt dans son exemple, pas l'identité Galaxy | identité Galaxy **inchangée** ; l'exemple propre de `v2.0.0` utilise `grav_site` (nom court) | **compatible avec v1.0.1 au moment du snapshot** — l'exemple reproduit fidèlement la convention (imprécise) du README `v1.0.1` ; l'identité Galaxy réelle n'a pas changé entre les deux versions |
| `grav_image` | présent, valeur explicite | présent, obligatoire | inchangé | compatible avec les deux versions |
| `grav_version` | présent, jamais `latest` | présent, obligatoire, `latest` refusé | inchangé | compatible avec les deux versions |
| `grav_digest` | **absent de l'exemple** | **n'existe pas** dans le rôle à cette version (confirmé : absent de `defaults/main.yml`) | existe, optionnel (défaut `""`) | **compatible avec v1.0.1 au moment du snapshot** (le champ n'existait pas encore) ; **encore compatible avec v2.0.0** (champ optionnel, son absence ne bloque rien) |
| `grav_container_name` | présent | présent, même règle de validation | inchangée | compatible avec les deux versions |
| `grav_base_directory` | **absent de l'exemple** | optionnel, dérivé de `grav_container_name` | inchangé | compatible avec les deux versions — absence = valeur dérivée, pas une erreur |
| `grav_bind_address` | **absent de l'exemple** | optionnel, **défaut implicite `127.0.0.1`** | **obligatoire depuis `v2.0.0`** (le rôle cite lui-même « contrat v1.0.1 §7.1 »), aucun défaut implicite, IPv4 stricte ou `0.0.0.0` uniquement | **migration obligatoire** — cet exemple, tel quel, ferait échouer une assertion bloquante du rôle en `v2.0.0`, alors qu'il fonctionnait silencieusement (écoute loopback) en `v1.0.1` |
| `grav_http_port` | présent | présent, même validation | inchangée | compatible avec les deux versions |
| `grav_manage_docker` | **absent de l'exemple** | optionnel, défaut `true` | inchangé | compatible avec les deux versions |
| Identifiants administrateur | tri-state (`_user`/`_email`/`_password`) | tri-state (0 ou 3 définies), identique | inchangé | compatible avec les deux versions |
| `grav_secrets` | forme `content` uniquement | accepte `src` **ou** `content` (exactement l'un des deux) ; nom validé par la même regex qu'au v2.0.0 | **inchangé** — le rôle accepte toujours `src` ou `content` aux deux versions (vérifié par comparaison directe des deux `tasks/secrets.yml`) | compatible avec les deux versions — la restriction « `src` interdit » documentée pour `grav-sites-ops` (Lot 5) est une politique de cet orchestrateur, **pas** une contrainte du rôle lui-même |
| Structure d'inventaire | non fournie dans l'exemple (playbook seul) | inventaire minimal à un groupe (`[grav_servers]`) | non revérifié en détail pour cette comparaison ciblée | **non vérifiable faute d'information** sur ce point précis pour `projet-gites` |
| Collection `community.docker` | citée séparément dans le README (hors de l'exemple Ansible) | `>=5.0.0,<6.0.0` | identique (vérifié par comparaison directe des deux `requirements.yml`) | compatible avec les deux versions |
| Méthode d'installation du rôle | non détaillée dans l'exemple lui-même | `ansible-galaxy collection install -r requirements.yml` pour la collection ; installation du rôle lui-même non approfondie dans les sections lues | identique pour la collection | compatible avec les deux versions pour la collection ; méthode d'installation du rôle non creusée davantage (hors périmètre de cette vérification ciblée) |

**Conclusion d'ensemble (historique, établie au Lot 7)** : l'exemple
documenté par `projet-gites` était **réellement compatible avec `v1.0.1`**
au moment où il a été écrit — ce n'est pas une simple hypothèse, la
vérification directe du tag le confirme. Il restait **majoritairement
compatible avec `v2.0.0`**, à l'exception d'un point précis et vérifié :
`grav_bind_address`, devenu obligatoire.

**Résolution (tag `v1.1.0`)** : cette migration a depuis été appliquée —
l'exemple de `docs/release-and-rollback.md` référence désormais
`ansible-role-grav-site:2.0.0` directement, avec `grav_bind_address`
ajouté explicitement. Vérifiée **statiquement** (lecture du code et du
guide de migration du rôle) ; **aucun déploiement Ansible réel** n'a été
exécuté pour produire cette mise à jour, ce que la documentation du tag
`v1.1.0` indique elle-même explicitement.

## Glossaire local

| Terme | Définition |
|---|---|
| Seed | contenu initial copié dans `/opt/grav-seed/pages/`, appliqué uniquement si le volume `user/pages` est vide au premier démarrage |
| Code applicatif immuable | thème, plugins, configuration — réécrits à chaque nouveau conteneur, jamais lus depuis un volume persistant |
| `proprietaire` | clé de frontmatter d'une page de gîte désignant le compte Grav dont l'adresse sert de destinataire du formulaire de contact — la clé de résolution reste ce nom de compte, jamais une valeur transmise par le visiteur (corrigé dans `v1.1.0`) |
| Honeypot | champ **rendu** par le plugin Form de Grav ; sa lecture et le rejet de la soumission qu'il déclenche sont un contrôle applicatif de ce plugin contact — **pas** une protection complète contre le spam à lui seul |
| Table serveur (`contactTable()`) | **nouveau dans `v1.1.0`** — source de vérité unique du routage du formulaire : identifiant public → libellé, page, compte, adresse déjà validée ; partagée par l'affichage des options, la validation de soumission et la résolution du destinataire |
| Garde administrateur (`Permissions::canManage`) | vérification serveur, avant toute mutation de disponibilités, qu'un utilisateur authentifié correspond bien au propriétaire du gîte concerné |
| SEC-GITES-001 | identifiant du constat de sécurité sur le routage du formulaire de contact — **corrigé et publié dans `v1.1.0`**, voir plus haut sur cette page |

## Limites de preuve de cette rubrique

- L'exemple de playbook Ansible (`docs/release-and-rollback.md`, version
  `v2.0.0` dans le tag `v1.1.0`) a été vérifié **statiquement** contre le
  code et le guide de migration du rôle — pas un audit complet du rôle,
  et **aucun déploiement Ansible réel** n'a été exécuté pour cette
  vérification (constat maintenu du Lot 7 à ce lot).
- L'injection d'en-tête (CR/LF) dans `nom`/`email` a été **retestée
  directement pour ce dépôt** dans `v1.1.0` (6 cas nommés, voir plus
  haut) ; l'échappement du champ `email` à l'affichage n'a pas été
  retesté spécifiquement au-delà de ce qui était déjà caractérisé au
  Lot 6 sur le mécanisme partagé.
- Le comportement exact d'un identifiant `gite` pointant vers une page
  **sans** template `gite-item` a été testé pour la correction (rejeté,
  voir `test-contact-routing.sh`) ; le cas historique d'une route brute
  pointant vers une telle page au commit `b27d7af` n'avait, lui, pas été
  testé spécifiquement.
- Deux runs CI distants ont été observés en direct pour ce lot
  (identifiants exacts en [Tests et CI](../08.tests-et-ci)) — au-delà de
  ces deux runs, l'historique CI complet du dépôt n'a pas été passé en
  revue.
- La bibliothèque `Symfony\Component\Yaml\Yaml`, utilisée par
  `Availability::readHeaderFromDisk()`, n'a pas été relue ligne à ligne —
  son comportement est supposé conforme à la bibliothèque standard, non
  vérifié par lecture de son code.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : tag v1.1.0 (commit 7309bd1968c1f9a4ede93098d624cea46243aa0b) ;
  constat d'origine SEC-GITES-001 établi au commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : grav/user/pages/03.gites/**/default.md (frontmatters), docs/*.md (les 7 fichiers),
  README.md, tests/{test-secrets,test-contact-routing}.sh, grav/user/plugins/contact/contact.php
Dernière vérification : 2026-09-15
```
