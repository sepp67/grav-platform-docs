---
title: "Référence"
template: docs
taxonomy:
    category: [docs]
---

## Constat de sécurité SEC-GITES-001 — routage du formulaire de contact

Cette rubrique documente un constat de sécurité réel, confirmé
empiriquement pendant l'audit. **La procédure de reproduction complète,
les charges de test, les comptes utilisés et le détail technique du
mécanisme ne sont volontairement pas publiés sur ce site** : ils sont
conservés dans un rapport de sécurité séparé, hors de ce dépôt
documentaire public et hors de tous les dépôts documentés, à disposition
pour la correction.

| Champ | Valeur |
|---|---|
| Identifiant | SEC-GITES-001 |
| Composant | Routage du formulaire de contact de `projet-gites` |
| Version concernée | commit `b27d7af` (aucun tag applicatif) |
| Nature | Donnée de routage contrôlée côté client |
| Impact | Une demande de contact peut être dirigée vers un autre propriétaire valide que celui affiché au visiteur |
| Portée | Limitée aux destinataires existants reconnus par l'application |
| Adresse arbitraire | Non démontrée — le mécanisme reste borné aux comptes déjà existants sur l'instance |
| Preuve | Test local, en environnement jetable, avec deux comptes Grav synthétiques |
| Statut | Confirmé, non corrigé dans le snapshot documenté par ce lot |
| Correctif | À réaliser dans `projet-gites` — hors périmètre de ce dépôt documentaire |
| Retest | Obligatoire après correction, avant toute nouvelle certification de ce constat comme résolu |
| **Effet sur la publication** | **Bloque toute release publique et tout déploiement documentés comme prêts pour production, tant que la stratégie de correction et de divulgation n'a pas été explicitement arbitrée** — n'empêche pas la construction ni la consultation locale de ce site documentaire |

**Ce que cette page ne fournit pas, par choix éditorial** : la requête
exacte, une commande de reproduction, les identifiants de compte utilisés
pour la démonstration, ou tout autre détail permettant une exploitation
directe sans travail d'analyse supplémentaire.

## Autres constats sur la sécurité du formulaire

Ces points sont des propriétés générales du mécanisme, indépendantes de
SEC-GITES-001 et ne permettant pas, seuls, sa reproduction :

- **Honeypot** : mécanisme partagé avec `projet-lavallee-website`, même
  code, même limite — un filtre partiel, jamais une protection anti-spam
  complète.
- **CSRF** : sur le formulaire de contact, fourni par le Form plugin de
  Grav Core (nonce standard, non ré-audité au niveau code — voir
  [Lot 6](../../05.projet-lavallee-website/11.reference) pour la même
  observation). Sur le formulaire de gestion des disponibilités
  (`/gerer`), un nonce **dédié** est vérifié explicitement dans le code
  de ce dépôt, **avant** toute autre logique — mécanisme identifié avec
  certitude, pas déduit.
- **Échappement** : le gabarit d'e-mail échappe explicitement chaque
  valeur affichée.
- **Injection d'en-tête** : non retestée spécifiquement pour ce dépôt
  (mécanisme partagé avec `projet-lavallee-website`, déjà caractérisé
  précisément au Lot 6 — un comportement de rejet ou de neutralisation
  selon le champ, attribué **par déduction** à Grav Core/PHPMailer, jamais
  confirmé par lecture de leur code).
- **Chargement des secrets SMTP** : identique à `projet-lavallee-website`
  — voir [Données, secrets et persistance](../07.donnees-secrets-persistance)
  pour le risque de `ParseError` documenté et confirmé en direct (HTTP 500).
- **Langue** : sans objet pour la localisation — dépôt monolingue.

## Audit des données personnelles présentes dans le snapshot

Vérifié uniquement sur le contenu du commit audité — aucune consultation
de l'historique Git au-delà de ce qui était nécessaire.

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
| Contact (`/contact`) | `contact` | non (`visible: false`) | dynamique (`gite` du visiteur) | complet, fonctionnel — voir audit du routage ci-dessus |
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
| `docs/architecture.md`, `docs/compatibility-policy.md` | `grav-runtime` certifié : `1.0.2`, seule combinaison recommandée | `Dockerfile` : `FROM ghcr.io/sepp67/grav-runtime:1.0.4` | **écart réel et significatif, toujours présent au commit audité** — la propre politique du dépôt (« chaque nouvelle version de runtime nécessite une nouvelle certification explicite avant adoption ») n'a pas été suivie pour ce passage de version, au moins dans la documentation — voir chronologie précise ci-dessous |
| `docs/architecture.md`, `.gitignore`, `compose.dev.yml`, `docs/release-and-rollback.md` | `ansible-role-grav-site:1.0.1` (référencé de façon cohérente dans 4 fichiers distincts, tous écrits **au moment de la création du dépôt**) | tag `v1.0.1` **existe réellement** (`bbd825ebe6f676dfd91017405cdaa963bbdcdee5`) et a été vérifié spécifiquement pour ce lot — voir la comparaison complète ci-dessous | **écart de version documentaire, non corrigé depuis l'origine du dépôt** — le contrat `v1.0.1` a maintenant été vérifié directement (pas seulement déduit) ; l'exemple de `projet-gites` s'avère daté par rapport à `v2.0.0`, avec au moins un point de migration obligatoire identifié |
| README | « The test suite covers the application build, startup, application presence and persistence behaviour » | la suite couvre en réalité **6** aspects, dont les secrets et la mise à jour/rollback, non mentionnés dans cette phrase du README | écart mineur de complétude — le README sous-décrit la couverture réelle (`docs/testing.md` est, lui, complet et exact) |
| `docs/secrets-and-config.md` | `site.yaml` « contient encore des valeurs par défaut Grav non pertinentes… nettoyage éditorial possible » | confirmé : `title: Grav`, `author.name: Joe Bloggs` | **aucun écart** — auto-déclaré et confirmé identique |
| `docs/secrets-and-config.md` (cas 4/4) | une erreur de syntaxe dans `email-private.php` doit produire un HTTP 500 | **vérifié en direct** : HTTP 500 confirmé | **aucun écart** — comportement documenté et reproduit fidèlement |
| Aucune source | présence ou absence de tag applicatif | **absence confirmée** — `git tag --points-at b27d7af` ne retourne rien dans le worktree audité | conforme aux instructions de ce lot |
| `docs/testing.md` | `test-secrets.sh` corrige un « faux positif » antérieur (grep sur `docker save` compressé, motifs génériques) | confirmé par la lecture du script lui-même, qui documente précisément cet historique en commentaire | **aucun écart** — cohérence confirmée entre la documentation et le code |

### Chronologie précise de l'écart `grav-runtime` (établie depuis l'historique Git du dépôt, lecture seule)

| Date | Événement |
|---|---|
| 2026-07-25 | Création du dépôt ; `docs/compatibility-policy.md` rédigé, certifiant `grav-runtime 1.0.2` ; les quatre fichiers citant `ansible-role-grav-site:1.0.1` sont écrits |
| 2026-07-26 | `Dockerfile` passe à `grav-runtime:1.0.3` — `docs/compatibility-policy.md` **non mis à jour** |
| 2026-08-05 | `Dockerfile` passe à `grav-runtime:1.0.4` — `docs/compatibility-policy.md` **toujours non mis à jour** |
| **2026-08-23** | **Commit audité par ce lot** (`b27d7af`) — l'écart existe déjà tel que décrit ci-dessus |
| 2026-09-14 | Date de cet audit — **l'état actuel du dépôt, au-delà du commit fixé, n'a pas été revérifié** ; un correctif a pu être appliqué depuis sans que cette documentation en soit informée |

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

**Conclusion d'ensemble** : l'exemple documenté par `projet-gites` était
**réellement compatible avec `v1.0.1`** au moment où il a été écrit — ce
n'est pas une simple hypothèse, la vérification directe du tag le
confirme. Il reste **majoritairement compatible avec `v2.0.0`**, à
l'exception d'un point précis et vérifié : `grav_bind_address`, devenu
obligatoire, ferait échouer un déploiement basé tel quel sur cet exemple
contre le rôle `v2.0.0` déjà audité au Lot 4.

## Glossaire local

| Terme | Définition |
|---|---|
| Seed | contenu initial copié dans `/opt/grav-seed/pages/`, appliqué uniquement si le volume `user/pages` est vide au premier démarrage |
| Code applicatif immuable | thème, plugins, configuration — réécrits à chaque nouveau conteneur, jamais lus depuis un volume persistant |
| `proprietaire` | clé de frontmatter d'une page de gîte désignant le compte Grav dont l'adresse sert de destinataire du formulaire de contact |
| Honeypot | champ caché destiné aux robots ; son remplissage rejette la soumission — **pas** une protection complète contre le spam |
| Garde administrateur (`Permissions::canManage`) | vérification serveur, avant toute mutation de disponibilités, qu'un utilisateur authentifié correspond bien au propriétaire du gîte concerné |
| SEC-GITES-001 | identifiant du constat de sécurité sur le routage du formulaire de contact — voir plus haut sur cette page |

## Limites de preuve de cette rubrique

- L'exemple de playbook Ansible (`docs/release-and-rollback.md`) a été
  vérifié directement contre le tag `v1.0.1` réel (voir la comparaison
  ci-dessus) — cette vérification reste **ciblée** sur les éléments cités
  dans l'exemple, pas un audit complet du rôle à cette version (structure
  d'inventaire et méthode exacte d'installation du rôle non approfondies).
- L'injection d'en-tête (CRLF) et l'échappement du champ `email` n'ont pas
  été retestés spécifiquement pour ce dépôt — le mécanisme partagé
  (`contact.php`) a déjà été caractérisé précisément au Lot 6, et ce lot
  s'est concentré sur ce qui **diffère** réellement (routage par `gite`,
  validation des dates, plugin de disponibilités).
- Le comportement exact d'une route `gite` pointant vers une page **sans**
  template `gite-item` (une page quelconque du site dotée d'un
  `proprietaire`) n'a pas été testé — seules des routes de gîte réelles ou
  inexistantes l'ont été.
- Aucun run CI distant n'a été observé.
- La bibliothèque `Symfony\Component\Yaml\Yaml`, utilisée par
  `Availability::readHeaderFromDisk()`, n'a pas été relue ligne à ligne —
  son comportement est supposé conforme à la bibliothèque standard, non
  vérifié par lecture de son code.

---

```yaml
Source documentée : https://github.com/sepp67/projet-gites
Référence : commit b27d7afa0c86461e94ab8c9ec53c557edb0afd0e
Fichiers principaux : grav/user/pages/03.gites/**/default.md (frontmatters), docs/*.md (les 6 fichiers),
  README.md, tests/test-secrets.sh
Dernière vérification : 2026-09-14
```
