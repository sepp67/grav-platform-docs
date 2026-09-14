---
title: "Sections de code"
template: docs
taxonomy:
    category: [docs]
---

Chaque section suit le même patron : but, place dans le flux,
implémentation, entrées, traitement, sorties, invariant protégé, cas
d'échec, preuve, pourquoi ce choix. Renvoie au [Flux
chronologique](../04.flux-chronologique) pour la vue d'ensemble.

#### 1. Validation des variables (`assert.yml`)

**But.** Échouer avant toute mutation si la configuration demandée est
incohérente ou dangereuse.

**Place dans le flux.** Étape 1, la toute première de `tasks/main.yml`.

**Implémentation.** `tasks/assert.yml`, 16 blocs `ansible.builtin.assert`
indépendants.

**Entrées.** L'ensemble des variables publiques `grav_*` (voir
[Configuration et interfaces](../06.configuration-et-interfaces)).

**Traitement.** Notamment : `grav_image`/`grav_version` non vides ;
`grav_version != "latest"` ; `grav_image` sans tag ni digest incorporé
(algorithme : un `@` est toujours refusé, un `:` n'est refusé qu'après le
premier `/`, pour autoriser un port de registre) ; `grav_digest` vide ou
`sha256:` + 64 hex ; `grav_container_name` restreint
(`^[A-Za-z0-9][A-Za-z0-9._-]*$`, ni `..`, `/`, `:`) ; `grav_state` dans la
liste fermée ; `grav_http_port` dans 1-65535 ; **`grav_bind_address` non
vide et IPv4 stricte** (voir section 6 de cette page) ; fenêtre d'attente
`grav_deploy_wait_retries × _delay >= 120` ; tri-state admin ; clés de
`grav_extra_environment` (`^GRAV_[A-Z0-9_]+$`, jamais une clé déjà gérée) ;
aucun retour à la ligne dans une valeur destinée à `grav.env`.

**Sorties.** Configuration jugée admissible, ou échec avec message
explicite nommant la variable et la valeur en cause.

**Invariant protégé.** Aucune tâche de mutation (Docker, répertoires,
secrets, Compose) ne s'exécute si une seule de ces assertions échoue.

**Cas d'échec.** Chaque assertion porte son propre `fail_msg`, actionnable
et nommé (ex. `grav_bind_address="..." invalide : v2.0.0 supporte
uniquement une adresse IPv4 littérale...`).

**Preuve.** `tests/test_assertions.yml` rejoue **uniquement** ce fichier
(aucun Docker, aucune mutation) sur 46 scénarios valides/invalides (comptage exact : 46 entrées `label:` dans le fichier — le README annonce "~35", TEST-RESULTS.md et le code concordent sur 46) — non
ré-exécuté pendant ce Lot (voir [Tests et CI](../08.tests-et-ci)).

**Pourquoi ce choix ?** Échouer côté Ansible avec un message clair plutôt
que de laisser le conteneur refuser de démarrer avec un message moins
lisible — même politique de validation précoce que `grav-runtime` applique
à son propre bootstrap admin.

**Pour aller plus loin.** [Configuration et interfaces](../06.configuration-et-interfaces).

---

#### 2. Validation IPv4 stricte de `grav_bind_address`

**But.** Garantir que l'adresse d'écoute déclarée est une IPv4 littérale
exploitable, jamais un nom d'hôte ni une IPv6 mal supportée.

**Place dans le flux.** Fait partie de l'étape 1 (`assert.yml`), isolée ici
car c'est un point obligatoire explicite de cette rubrique.

**Implémentation.** `tasks/assert.yml`, expression régulière
`^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$`,
ou `"0.0.0.0"` littéral.

**Entrées.** `grav_bind_address` (chaîne).

**Traitement.** Chaque octet doit être 0-255, sans zéro initial, exactement
4 octets séparés par des points ; `0.0.0.0` accepté explicitement en plus.
Une chaîne contenant `:` (IPv6, y compris `::`) échoue systématiquement.

**Sorties.** Adresse validée, ou échec explicite.

**Invariant protégé.** **L'IPv6 est refusée en v2.0.0**, sans exception —
la validation ne tente jamais de la reconnaître partiellement.

**Cas d'échec.** Nom d'hôte, IPv6, adresse malformée → message citant la
valeur reçue et recommandant une IPv4 explicite ou `0.0.0.0`.

**Preuve.** `tests/test_assertions.yml` couvre explicitement "présence et
forme de `grav_bind_address`" (README "Tests") — non ré-exécuté dans ce
Lot.

**Pourquoi ce choix ?** Une validation IPv6 fiable exigerait
`ansible.utils` + `netaddr`, des dépendances jugées disproportionnées pour
ce rôle (commentaire du fichier, `docs/MIGRATION.md`). Le compromis assumé :
lier l'instance en IPv4 et laisser un reverse proxy gérer l'IPv6 côté
public.

**Pour aller plus loin.** [Référence](../11.reference) (limites connues).

---

#### 3. Garde administrateur avant mutation (`admin_guard.yml`)

**But.** Empêcher qu'une instance démarre avec la création du premier
compte administrateur ouverte sur `/admin`.

**Place dans le flux.** Étapes 2a-2e, juste après la validation — avant
Docker, les répertoires et le rendu de `grav.env`. `admin_guard.yml`
lui-même est importé **sans condition** par `tasks/main.yml` ; seule sa
dernière tâche (l'assertion) porte une condition.

**Implémentation.** `tasks/admin_guard.yml`.

**Entrées.** Contenu (métadonnées seules) de `grav_accounts_directory` ;
`grav_admin_user`/`_password`/`_email` ; `grav_state`.

**Traitement — cinq tâches, pas deux.** (1) `stat` sur
`grav_accounts_directory` : **toujours exécutée**, quel que soit
`grav_state`. (2) `find` des fichiers `*.yaml`/`*.yml` (métadonnées
seules, jamais le contenu) : exécutée **seulement si** le `stat`
précédent constate que le répertoire existe **et** qu'il s'agit bien
d'un répertoire (`_grav_accounts_dir.stat.exists` et `.isdir`) — pas
conditionnée par `grav_state`. (3) Calcul de
`_grav_admin_account_present` : toujours exécuté, avec `default(0)` sur
le résultat du `find` pour couvrir le cas où celui-ci a été sauté. (4)
Calcul de `_grav_admin_bootstrap_count` (nombre de variables admin
renseignées) : toujours exécuté. (5) L'assertion finale ("ce fichier
**ou** les 3 variables admin complètes") : **seule** cette tâche porte
`when: grav_state != 'stopped'` — voir le tableau détaillé dans [Flux
chronologique](../04.flux-chronologique). La validation tri-state
elle-même (les 3 variables ou aucune) vit séparément dans `assert.yml`,
sans aucune condition : elle s'applique **même** quand
`grav_state == stopped`.

**Sorties.** Déploiement autorisé à continuer, ou échec.

**Invariant protégé.** Aucune mutation (Docker, répertoires, secrets,
Compose) n'a lieu avant que cette garde n'ait statué.

**Cas d'échec.** Aucun fichier de compte et bootstrap incomplet → échec
avec message actionnable, **avant toute mutation**.

**Preuve.** `tests/test_admin_guard.yml` (T09/T10/T11, matrice complète) et
`tests/test_persistence_untouched.yml` (persistance intacte après la
garde) — tous deux sans Docker, non ré-exécutés dans ce Lot.

**Pourquoi ce choix ?** `grav-runtime` ne fournit lui-même aucun compte par
défaut ; sans cette garde côté rôle, un opérateur pourrait déployer une
instance non initialisée sans s'en apercevoir avant qu'un tiers n'atteigne
`/admin` le premier.

**Pour aller plus loin.** [Données, secrets et
persistance](../07.donnees-secrets-persistance) (matrice du contrat
administrateur).

---

#### 4. Installation ou vérification de Docker (`docker.yml` / `verify_docker.yml`)

**But.** Garantir que Docker Engine et le plugin Compose v2 sont
opérationnels avant tout rendu de configuration, sans supposer
silencieusement leur présence.

**Place dans le flux.** Étape 3a ou 3b, mutuellement exclusives selon
`grav_manage_docker`.

**Implémentation.** `tasks/docker.yml` (installation) ou
`tasks/verify_docker.yml` (vérification).

**Entrées.** `grav_manage_docker` ; faits Ansible (`os_family`,
`architecture`, `distribution`).

**Traitement.** Installation : vérifie Debian/Ubuntu et x86_64/aarch64,
ajoute le dépôt APT officiel Docker (clé GPG dédiée), installe
`docker-ce`/`docker-ce-cli`/`containerd.io`/`docker-compose-plugin`,
démarre et active le service. Vérification : `docker version` et
`docker compose version`, échec si l'un des deux retourne un code non nul.

**Sorties.** Docker Engine + Compose v2 opérationnels, dans les deux cas.

**Invariant protégé.** Un OS ou une architecture non supportés échouent
**avant** toute tentative d'installation — jamais une installation
partielle.

**Cas d'échec.** `docker.yml` : OS/architecture non supportés → échec
explicite. `verify_docker.yml` : Docker absent ou non fonctionnel → échec
ici, avec un message plus lisible que l'échec qui se produirait plus tard
dans `deploy.yml`.

**Preuve.** `molecule test -s install` (T02/T03 : installation +
idempotence sur Debian 12, Ubuntu 22.04, Ubuntu 24.04) — observé comme
`success` sur le run CI du tag `v2.0.0` (`gh run view`), **non
ré-exécuté** dans ce Lot (Molecule nécessite des conteneurs privilégiés,
hors périmètre de cet audit documentaire).

**Pourquoi ce choix ?** Limiter l'installation automatique à Debian/Ubuntu
plutôt que de tenter un support générique fragile ; sur un autre OS,
l'opérateur installe Docker lui-même et désactive `grav_manage_docker`.

**Pour aller plus loin.** [Référence](../11.reference) (systèmes
supportés).

---

#### 5. Fichiers secrets (`secrets.yml`)

**But.** Déposer sur l'hôte cible des fichiers secrets fournis par
l'appelant, sans jamais en générer le contenu.

**Place dans le flux.** Étape 5, après les répertoires persistants.

**Implémentation.** `tasks/secrets.yml`.

**Entrées.** `grav_secrets` (liste de `{name, src|content}`) ;
`grav_container_gid`.

**Traitement.** Valide que chaque entrée fournit `name` et exactement l'un
de `src`/`content` (jamais les deux, jamais aucun) ; valide le nom
(`^[A-Za-z0-9][A-Za-z0-9._-]*$`, ni `..`, `/`, `:` — il sert à construire à
la fois un chemin de fichier et un point de montage Docker) ; crée
`grav_secret_directory` (`0750`, `root:grav_container_gid`) ; dépose
chaque secret, par `src` (copie) ou `content` (contenu inline), en `0640
root:grav_container_gid`.

**Sorties.** Fichiers secrets présents sur l'hôte, lisibles par le GID du
conteneur, jamais par "other".

**Invariant protégé.** Le rôle ne génère jamais le contenu d'un secret —
il ne fait que le positionner. Un nom de secret ne peut jamais provoquer
de traversée de répertoire ni casser la syntaxe du bind mount.

**Cas d'échec.** Entrée sans `src` ni `content` (ou les deux) → échec avant
tout dépôt. Nom invalide → échec avant tout dépôt.

**Preuve.** `tests/test_no_secret_leak.yml` (audit de non-fuite, sans
Docker) — non ré-exécuté dans ce Lot.

**Pourquoi ce choix ?** `grav_container_gid` (82 par défaut) doit
correspondre au GID de `www-data` dans l'image `grav-runtime` utilisée :
c'est le seul moyen pour PHP-FPM de lire ces fichiers sans recourir à un
bit "other", puisque ce montage ne passe jamais par le mécanisme de
permissions du runtime (lecture seule, jamais chowné par le conteneur).

**Pour aller plus loin.** [Données, secrets et
persistance](../07.donnees-secrets-persistance).

---

#### 6. Rendu Compose et référence d'image effective (`deploy.yml`, `vars/main.yml`)

**But.** Générer un `docker-compose.yml` générique et démarrer/arrêter le
conteneur avec la référence d'image exacte demandée.

**Place dans le flux.** Étapes 6-7, après les secrets.

**Implémentation.** `tasks/deploy.yml`, `templates/docker-compose.yml.j2`,
`templates/grav.env.j2`, `vars/main.yml` (`_grav_effective_reference`).

**Entrées.** `grav_image`, `grav_version`, `grav_digest`, `grav_state`,
`grav_force_pull`.

**Traitement.** `_grav_effective_reference` (calculée une fois, au
chargement du rôle) vaut `grav_image@grav_digest` si `grav_digest` est
renseigné, sinon `grav_image:grav_version` — **jamais** de forme hybride
`image:version@digest`. Le Compose généré référence cette seule valeur.
`community.docker.docker_compose_v2` reçoit `state: present` (si
`grav_state == started`) ou l'état demandé tel quel, `pull: always` si
`grav_force_pull` sinon `missing`, `recreate: auto`. Si `grav_state ==
stopped`, une tâche distincte arrête le service sans toucher aux volumes.

**Sorties.** `docker-compose.yml` (`0644`) et `grav.env` (`0600`, format
`raw`) sur l'hôte ; conteneur dans l'état demandé.

**Invariant protégé.** Jamais de pseudo-référence hybride. `pull: missing`
par défaut : un redémarrage ne dépend jamais de la disponibilité du
registre.

**Cas d'échec.** Échec de pull (image absente et registre injoignable),
échec de démarrage Docker.

**Preuve.** `tests/test.yml` (T04-T08 : premier déploiement, redéploiement
idempotent, mise à jour puis rollback entre deux versions publiques réelles
de `grav-runtime`) — observé `success` sur le run CI du tag `v2.0.0`, non
ré-exécuté dans ce Lot. `molecule test -s pull` (T17/T18 : `pull: missing`
sans consultation du registre, `grav_force_pull` → `pull: always`) — idem.

**Pourquoi ce choix ?** Séparer version (label humain, toujours obligatoire)
et digest (identité exacte, optionnelle) permet de garder un changelog
lisible même quand l'exploitation exige un épinglage immuable.

**Pour aller plus loin.** [Configuration et
interfaces](../06.configuration-et-interfaces) (tableau version/digest/référence
effective).

---

#### 7. Attente de santé, contrôle applicatif et diagnostic (`healthcheck.yml`)

**But.** Ne jamais considérer un déploiement réussi tant que le conteneur
n'est pas réellement sain **et** qu'une page réelle du site ne répond pas.

**Place dans le flux.** Étapes 8-11, dans un bloc `when: grav_state !=
'stopped'` de `tasks/main.yml`.

**Implémentation.** `tasks/healthcheck.yml` (bloc `block`/`rescue`),
`tasks/clear_failure_diagnostic.yml`.

**Entrées.** `grav_deploy_wait_retries`/`_delay` ; `grav_site_check_host`
(ou sa dérivation, `_grav_site_check_host`) ; `grav_site_check_path`/`_status`/`_retries`/`_delay`/`_timeout`.

**Traitement.** Boucle jusqu'à un verdict Docker définitif
(`healthy`/`unhealthy` — jamais bloquée sur `starting`, qui fait
retenter) ; `assert` que le verdict est exactement `healthy` ; requête HTTP
sur l'adresse dérivée jusqu'au code attendu. En cas de succès des trois :
supprime un éventuel `.last_failure.log` périmé. En cas d'échec de l'une
des trois : capture les 200 dernières lignes de logs du conteneur
(`no_log: true`, jamais affichées), les écrit dans
`{{ grav_base_directory }}/.last_failure.log` (`0600`, `root:root`), puis
échoue avec un message qui renvoie vers ce fichier sans en divulguer le
contenu.

**Sorties.** Confirmation de santé technique + applicative, ou échec
diagnostiqué sur l'hôte cible.

**Invariant protégé.** **Différence entre santé technique et santé
applicative** : le verdict Docker (`/healthz`, jamais Grav) est nécessaire
mais pas suffisant — le contrôle HTTP applicatif sur une page réelle est
une étape distincte, exigée en plus. Un `unhealthy` sort **immédiatement**
en échec, sans épuiser la fenêtre d'attente (qui ne borne que la phase
"starting").

**Cas d'échec.** Fenêtre épuisée sans verdict définitif ; verdict
`unhealthy` ; code HTTP inattendu après épuisement des tentatives — les
trois mènent au `rescue`.

**Preuve.** `molecule test -s deploy` (T09-T16 : bootstrap réel, garde
avant mutation, `grav_bind_address` sous ses trois formes, verdict
`starting`→`healthy`/`unhealthy`, `.last_failure.log`) et
`tests/test_failure_log_lifecycle.yml` (cycle de vie du fichier, sans
Docker) — tous deux `success` sur le run CI du tag, non ré-exécutés dans ce
Lot.

**Pourquoi ce choix ?** Le README de `grav-runtime` documente lui-même la
limite du `HEALTHCHECK` natif (technique, pas applicatif) et attend
explicitement qu'un rôle de déploiement la complète — c'est précisément le
rôle de cette section.

**Pour aller plus loin.** [Exploitation et
diagnostic](../09.exploitation-et-diagnostic) (`.last_failure.log`).

---

#### 8. Traçabilité (`version.yml`)

**But.** Enregistrer l'état de déploiement effectif, uniquement une fois
la santé confirmée.

**Place dans le flux.** Étape 13, dernière du bloc conditionnel — après la
vérification post-démarrage du compte admin.

**Implémentation.** `tasks/version.yml`, `templates/deployed_state.yml.j2`.

**Entrées.** `_grav_effective_reference` ; état précédent lu depuis
`.deployed_state.yml` (s'il existe).

**Traitement.** Fige un horodatage UTC indépendant de `gather_facts`.
Compare l'état contractuel précédent (`declared_version`, `digest`,
`effective_reference`) au nouveau. Écrit systématiquement
`.deployed_version` (une ligne, référence effective) et
`.deployed_state.yml` (structuré) — mais n'ajoute une ligne à
`deployed_versions.log` **que si l'état contractuel a changé**.

**Sorties.** Fichiers de traçabilité à jour sur l'hôte cible.

**Invariant protégé.** Un redéploiement strictement identique, ou un
simple `grav_state: restarted`, **n'ajoute jamais de ligne** au journal —
seul un changement réel de version, digest ou référence effective en
ajoute une.

**Cas d'échec.** Aucun identifié dans le fichier lui-même — cette étape
n'est atteinte que si les étapes précédentes (healthcheck, vérification
admin) ont déjà réussi.

**Preuve.** `tests/test_traceability.yml` (rejoue uniquement ce fichier,
`gather_facts: false`, aucun Docker : idempotence, mise à jour, rollback
A→B→A, déploiement par digest) et `molecule test -s digest` (T19/T20/T23,
traçabilité sur un déploiement réel) — tous deux `success` sur le run CI du
tag, non ré-exécutés dans ce Lot.

**Pourquoi ce choix ?** Ce fichier est "purement documentaire : ne pilote
aucune logique du rôle" (commentaire du fichier) — une mise à jour ou un
rollback ne sont rien d'autre que rejouer le rôle avec une autre référence.

**Pour aller plus loin.** [Architecture globale — Versionnement et
rollback](../../01.architecture-globale/05.versionnement-et-rollback).

---

```yaml
Source documentée : https://github.com/sepp67/ansible-role-grav-site
Référence : v2.0.0
Commit : 1339e50bc20257fbb9f21953995c08262ae3043e
Fichiers principaux : tasks/*.yml, vars/main.yml, templates/*.j2
Dernière vérification : 2026-09-12
```
