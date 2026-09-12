---
title: "Sections de code"
template: docs
taxonomy:
    category: [docs]
---

Chaque section suit le même patron : but, place dans le flux, implémentation,
entrées, traitement, sorties, invariant protégé, cas d'échec, preuve,
pourquoi ce choix. Renvoie au [Flux chronologique](../04.flux-chronologique)
pour la vue d'ensemble.

#### 1. Téléchargement, vérification et installation de Grav

**But.** Vendoriser Grav Core + Admin dans l'image, sans jamais utiliser un
contenu téléchargé non vérifié.

**Place dans le flux.** Étape A4. Après l'installation des dépendances
système (A2-A3) ; avant la surcharge de `quark2` (A5), qui a besoin que
`user/themes/quark2` existe déjà.

**Implémentation.** `Dockerfile` lignes 58-69, un seul bloc `RUN`.

**Entrées.** `GRAV_ZIP_URL`, `GRAV_ZIP_SHA256` (ARGs, valeurs par défaut
pointant vers la release GitHub `2.0.11`).

**Traitement.** `curl -fsSL` télécharge l'archive ; `sha256sum -c -` vérifie
son empreinte ; extraction dans un répertoire temporaire ; le nom du
répertoire racine de l'archive est détecté dynamiquement (`find ...
-name 'grav*'`), pas codé en dur ; son contenu est copié dans
`/var/www/html` ; **le contenu de démo livré par l'archive officielle
(`user/pages`, `user/accounts`, `user/data`, `user/config`) est
supprimé**, puis ces quatre répertoires sont recréés vides.

**Sorties.** Grav Core + Admin installés ; `user/themes` et `user/plugins`
peuplés (socle technique) ; `user/pages`, `user/accounts`, `user/data`,
`user/config` vides et prêts à être traités comme seedables/persistants par
une image fille.

**Invariant protégé.** Aucun contenu Grav non vérifié n'entre dans l'image :
tout échec de téléchargement ou de correspondance de somme de contrôle
arrête le build (`set -eu` + `sha256sum -c -` sans tolérance).

**Cas d'échec.** Échec réseau `curl` → build interrompu (`set -eu`).
Somme de contrôle incorrecte → `sha256sum -c -` retourne un statut non nul,
build interrompu. Structure d'archive inattendue (répertoire racine
introuvable) → message explicite `"Grav archive layout not recognized"` et
`exit 1`.

**Preuve.** Vérifié empiriquement dans ce Lot : un build avec
`GRAV_ZIP_SHA256` volontairement erroné échoue avec `sha256sum: WARNING: 1
of 1 computed checksums did NOT match` (méthode identique à celle utilisée
pour vérifier l'intégrité de Learn2 dans `grav-platform-docs`, Lot 1.1).
Build réel de ce tag exécuté dans ce Lot :
`docker exec ... php -v` → `PHP 8.3.33`, version **observée** lors de ce
build local du 2026-09-12, pas une version fixée par le `Dockerfile` (voir
[Configuration et interfaces](../06.configuration-et-interfaces),
"Reproductibilité") ;
`grep GRAV_VERSION /var/www/html/system/defines.php` → `"2.0.11"`, cette
valeur-là bien épinglée par le `Dockerfile`.

**Pourquoi ce choix ?** `getgrav.org` ne publie aucune somme de contrôle
pour ses liens "latest" ; la release GitHub versionnée en publie une,
authentique, via l'API GitHub Releases — c'est la seule source vérifiable
utilisée ici (README "Limitations connues").

**Pour aller plus loin.** [Configuration et interfaces](../06.configuration-et-interfaces)
pour la liste complète des ARGs de build.

---

#### 2. Surcharge ciblée du thème vendorisé `quark2`

**But.** Ajouter une ligne de crédit au footer de `quark2` sans modifier le
reste du thème vendorisé, ni forcer chaque image fille à le revendoriser.

**Place dans le flux.** Étape A5, après l'installation de Grav (A4).

**Implémentation.** `Dockerfile` ligne 75 ;
`docker/theme-overrides/quark2/templates/partials/footer.html.twig`.

**Entrées.** Le fichier source du thème enfant local
(`docker/theme-overrides/`), pas de variable.

**Traitement.** `COPY --chown=www-data:www-data` écrase un seul fichier de
`user/themes/quark2/` après que le thème complet a été vendorisé par
l'étape précédente.

**Sorties.** `user/themes/quark2/templates/partials/footer.html.twig`
modifié ; tout le reste de `quark2` reste tel que livré par l'archive
officielle Grav Admin.

**Invariant protégé.** Aucun autre fichier de `quark2` n'est touché — la
surcharge est un remplacement de fichier unique, pas une reconstruction du
thème.

**Cas d'échec.** Fichier source absent du contexte de build → le `COPY`
échoue, build interrompu.

**Preuve.** Contenu du fichier lu directement dans le tag (`git show
v1.0.4:docker/theme-overrides/quark2/templates/partials/footer.html.twig`) :
ajoute un crédit `lavallee.tech` au footer par défaut de `quark2`.

**Pourquoi ce choix ?** `quark2` reste le thème par défaut du bundle Grav
Admin officiel — un thème applicatif peut en hériter par chaînage de flux
(`theme://`, voir `gites-theme.yaml`) sans jamais le dupliquer. Le retirer
casserait ce mécanisme pour toute image fille qui l'utilise (README
"Pourquoi `quark2` reste dans le runtime").

**Écart constaté.** Le commentaire du `Dockerfile` (ligne 72) renvoie à
`docker/theme-overrides/README.md` — ce fichier **n'existe pas** dans le
tag `v1.0.4` (confirmé par `git ls-tree -r v1.0.4`). Commentaire non à jour,
sans conséquence fonctionnelle.

**Pour aller plus loin.** [Adopter et étendre](../10.adopter-et-etendre)
pour le mécanisme de chaînage de thème repris par les images filles.

---

#### 3. Correction des permissions au démarrage (`fix_permissions`)

**But.** Garantir que les chemins que Grav/PHP-FPM écrivent réellement sont
accessibles à `www-data`, sans `chown -R` inconditionnel à chaque
redémarrage.

**Place dans le flux.** Étape B2, en tout premier dans `entrypoint.sh`
— avant toute initialisation du seed (B3).

**Implémentation.** `docker/entrypoint.sh`, fonction `fix_permissions()`.

**Entrées.** L'état d'appartenance actuel de 8 chemins fixes (`cache`,
`logs`, `images`, `assets`, `user/accounts`, `user/data`, `user/pages`,
`user/images`).

**Traitement.** Pour chaque chemin : `mkdir -p`, puis compare le
propriétaire courant à `82:82` (uid:gid de `www-data`) ; ne `chown`/`chmod`
que si différent.

**Sorties.** Chemins accessibles en écriture à `www-data` ; opération
tracée dans les logs uniquement quand une correction a réellement eu lieu.

**Invariant protégé.** Idempotence : un volume déjà correctement possédé
n'est jamais retraité inutilement à chaque redémarrage.

**Cas d'échec.** Aucun cas d'échec bloquant identifié dans le script
(`chown`/`chmod` sur un chemin local, sans dépendance réseau).

**Preuve.** Vérifié empiriquement : `id www-data` dans le conteneur
construit retourne `uid=82(www-data) gid=82(www-data)`, confirmant la
comparaison `82:82` du script contre l'utilisateur réel de l'image.

**Pourquoi ce choix ?** Éviter un `chown -R` de l'arbre entier à chaque
démarrage (coûteux sur de gros volumes, et inutile une fois la propriété
correcte) — voir README "Utilisateurs, permissions et opérations root".

**Pour aller plus loin.** [Données, secrets et persistance](../07.donnees-secrets-persistance).

---

#### 4. Initialisation non destructive depuis le seed (`seed-init.sh`)

**But.** Peupler un répertoire persistant vide à partir du contenu initial
d'une image fille, sans jamais écraser un contenu déjà présent.

**Place dans le flux.** Étape B3, appelée 4 fois indépendamment (`pages`,
`accounts`, `data`, `images`), après B2.

**Implémentation.** `docker/seed-init.sh` (appelé avec trois paramètres
positionnels : `seed-dir`, `dest-dir`, `label`).

**Entrées.** Chemin du seed (`/opt/grav-seed/<sous-dossier>`, fourni par
l'image fille — vide dans `grav-runtime` lui-même) et chemin de la
destination persistante.

**Traitement.** Quatre cas, dans cet ordre : seed absent → rien à faire ;
destination déjà peuplée (`ls -A` non vide) → rien à faire ; seed vide →
rien à faire ; sinon `cp -a` puis `chown -R www-data:www-data` et
`chmod -R u+rwX,g+rwX` sur la destination.

**Sorties.** Destination peuplée au premier démarrage utile ; état
inchangé dans tous les autres cas.

**Invariant protégé.** **La condition exacte qui empêche un nouveau seed
est `[ -n "$(ls -A "$DEST_DIR" 2>/dev/null)" ]`** — dès qu'un seul fichier
existe dans la destination, plus aucune copie n'a lieu, quel que soit le
contenu du seed. Aucun fichier `.initialized` séparé : l'état est lu
directement sur le contenu réel du répertoire. `rsync --delete` n'est
jamais utilisé — rien n'est jamais supprimé automatiquement.

**Cas d'échec.** Échec de `cp -a` → message d'erreur explicite et `exit 1`,
qui remonte et interrompt le démarrage du conteneur (`entrypoint.sh` teste
le code de sortie de chaque appel).

**Preuve.** Vérifié empiriquement dans ce Lot, avec le seed de test du
dépôt (`test/seed/pages/01.home/`) : premier démarrage → log `"destination
... is empty — copying initial content"`, contenu du seed present.
Modification manuelle du fichier puis redémarrage → log `"already populated
— leaving untouched"`, modification toujours présente après redémarrage.

**Pourquoi ce choix ?** Traiter chaque sous-répertoire indépendamment
permet à une image applicative de monter `user/pages` sans monter
`user/images`, sans qu'un état "déjà initialisé" global n'interfère entre
les deux (voir docstring de `seed-init.sh`).

**Pour aller plus loin.** [Tests et CI](../08.tests-et-ci), Test 4 du
README (harnais `test/compose.yml`, non versionné — voir [Structure du
dépôt](../03.structure-du-depot)).

---

#### 5. Bootstrap administrateur tri-state (`bootstrap-admin.sh`)

**But.** Créer optionnellement un compte administrateur Grav au démarrage,
sans jamais écraser un compte existant ni démarrer silencieusement dans un
état de configuration incohérent.

**Place dans le flux.** Étape B5, après l'initialisation du seed (B3) —
un compte bootstrap peut ainsi s'appuyer sur un `user/accounts` déjà dans
son état définitif.

**Implémentation.** `docker/bootstrap-admin.sh`, exécuté via `su-exec
www-data:www-data` depuis `entrypoint.sh`.

**Entrées.** `GRAV_ADMIN_USER`, `GRAV_ADMIN_PASSWORD`, `GRAV_ADMIN_EMAIL`
(le triplet), `GRAV_ADMIN_TYPE` (optionnel, défaut `both`),
`GRAV_ADMIN_FULLNAME`/`_LANGUAGE`/`_TITLE` (optionnels) ; présence ou non
de `user/accounts/<user>.yaml`.

**Traitement — la politique tri-state exacte :**

```text
aucune des 3 variables définie   → bootstrap désactivé, exit 0 (démarrage normal)
les 3 variables définies         → bootstrap exécuté
variables partiellement définies → exit 1 (le conteneur ne démarre pas)
```

Si `GRAV_ADMIN_TYPE` n'est ni `admin`, ni `api`, ni `both` : `exit 1` avant
toute tentative de création de compte. Si le compte existe déjà
(`user/accounts/<user>.yaml` présent) : bootstrap ignoré, `exit 0`, aucune
modification. Sinon, le mot de passe est transmis à
`bin/plugin login new-user` **exclusivement via stdin** (jamais en
argument CLI), dans l'ordre de prompts confirmé empiriquement par le
mainteneur (commentaire du script, lignes 94-106). Si la CLI officielle ou
le plugin `login` sont absents, ou si la création échoue pour toute autre
raison : `exit 1`.

**Sorties.** `user/accounts/<user>.yaml` créé avec les arborescences de
droits `access.admin.*` et/ou `access.api.*` selon `GRAV_ADMIN_TYPE` ; ou
aucun changement ; ou conteneur arrêté avant d'avoir démarré Nginx/PHP-FPM.

**Invariant protégé.** Un compte existant n'est **jamais** recréé ni
modifié, quelles que soient les variables fournies au redémarrage suivant.
Le mot de passe n'apparaît jamais dans un log, y compris dans la sortie de
la CLI en cas d'échec (filtré explicitement par `grep -v -F
"$GRAV_ADMIN_PASSWORD"`).

**Cas d'échec.** Variables partielles → `exit 1`, message explicite.
`GRAV_ADMIN_TYPE` invalide → `exit 1`, message explicite. Plugin `login`
absent → `exit 1`. Échec de la CLI pour toute autre raison → `exit 1`,
sortie de la CLI loguée avec le mot de passe redacté.

**Preuve.** Les trois cas de la politique tri-state ont été exécutés
réellement dans ce Lot sur l'image construite localement à partir du tag :
aucune variable → log `"not set — admin bootstrap disabled"` ; les trois
variables → log `"Admin account 'admin' created successfully"` ; deux
variables sur trois → log `"partial admin bootstrap configuration —
refusing to start"`, conteneur sorti avec le code **1** (vérifié via
`docker run` sans pipe, pas seulement déduit du script).

**Pourquoi ce choix ?** Un démarrage silencieux "à moitié configuré"
masquerait une erreur d'opérateur (une seule variable oubliée) derrière un
site qui semble fonctionner mais sans le compte attendu — le README
documente ce choix comme une extension délibérée de la politique stricte.

**Pour aller plus loin.** [Exploitation et diagnostic](../09.exploitation-et-diagnostic)
pour l'arbre de diagnostic "compte administrateur absent".

---

#### 6. Supervision des processus et arrêt (`entrypoint.sh`, PID 1)

**But.** Démarrer Nginx et PHP-FPM dans un seul conteneur, détecter la
mort inattendue de l'un des deux, et transmettre un arrêt propre aux deux
sur signal.

**Place dans le flux.** Étapes B6-B7, après un bootstrap réussi (ou
désactivé).

**Implémentation.** `docker/entrypoint.sh`, section finale (`php-fpm -F &`,
`nginx -g "daemon off;" &`, boucle `while true`, `trap on_term TERM INT
QUIT`).

**Entrées.** Aucune nouvelle entrée — poursuite du même processus PID 1.

**Traitement.** Les deux processus sont lancés en arrière-plan, leurs PID
mémorisés. Une boucle vérifie `kill -0` sur chacun toutes les secondes. Sur
réception de `TERM`/`INT`/`QUIT` : envoie `TERM` aux deux, attend leur
sortie, sort avec le code 0. Si l'un des deux meurt seul : l'autre est
arrêté, le conteneur sort avec le code 1.

**Sorties.** Arrêt propre coordonné, ou détection immédiate d'une
défaillance partielle — jamais un conteneur qui continue de tourner avec un
seul des deux processus vivant.

**Invariant protégé.** Jamais de service "à moitié fonctionnel" observable
de l'extérieur au-delà d'une seconde (fréquence de la boucle de contrôle).

**Cas d'échec.** Mort inattendue de `nginx` ou `php-fpm` → l'autre est
arrêté, sortie en erreur (code 1), logué explicitement.

**Preuve.** Statut des processus vérifié empiriquement dans ce Lot :
`ps aux` dans le conteneur montre `php-fpm: master process` et `nginx:
master process` sous root (transitoire), leurs workers sous `www-data` —
conforme au tableau du README "Utilisateurs, permissions et opérations
root". Le README documente un Test 8 (arrêt forcé de PHP-FPM, `kill -9`)
non ré-exécuté dans ce Lot (voir [Tests et CI](../08.tests-et-ci)).

**Pourquoi ce choix ?** L'image de base `php:8.3-fpm-alpine` déclare
`STOPSIGNAL SIGQUIT`, pertinent seulement quand PHP-FPM est lui-même PID 1
— ce qui n'est pas le cas ici. `grav-runtime` redéclare `STOPSIGNAL SIGTERM`
dans son propre `Dockerfile` pour que `docker stop` envoie le signal que
`entrypoint.sh` sait réellement traiter. Deux conteneurs séparés (Nginx /
PHP-FPM) ont été explicitement écartés : aucune nécessité technique ne le
justifie ici.

**Pour aller plus loin.** [Exploitation et diagnostic](../09.exploitation-et-diagnostic).

---

#### 7. Healthcheck technique (`/healthz`)

**But.** Prouver que Nginx et PHP-FPM sont vivants et correctement reliés,
indépendamment de tout contenu de site.

**Place dans le flux.** Chronologie C (voir [Flux
chronologique](../04.flux-chronologique)), **pas une étape de la séquence B**
de `entrypoint.sh` : Docker déclenche ce contrôle périodiquement, en
parallèle, dès que les processus sont démarrés (après B6) et jusqu'à
l'arrêt du conteneur — avec un délai de grâce de 10s
(`--start-period=10s`) avant la première tentative.

**Implémentation.** `docker/healthcheck.sh` (`CMD` du `HEALTHCHECK`),
`docker/healthz.php` (script exécuté), `docker/nginx.conf` (route
`location = /healthz`).

**Entrées.** Aucune — requête HTTP interne sans paramètre.

**Traitement.** `healthcheck.sh` exécute `curl -fsS --max-time 2
http://127.0.0.1/healthz`. Nginx route `/healthz` directement vers
`healthz.php` via FastCGI, **sans passer par `index.php`** (le front
controller de Grav). `healthz.php` répond `200`, `Content-Type:
text/plain`, corps `"ok"`.

**Sorties.** Code de sortie `0` (healthy) si la requête aboutit en moins de
2 secondes avec un statut HTTP 2xx/3xx implicite via `curl -f` ; `1`
sinon.

**Invariant protégé.** **Différence entre santé technique et santé
applicative** : `/healthz` prouve que Nginx et PHP-FPM fonctionnent
ensemble — il ne prouve jamais qu'une page Grav réelle (thème, plugins,
contenu) se rend correctement. Un conteneur `healthy` peut malgré tout
servir une erreur applicative sur `/`.

**Cas d'échec.** Timeout de 2s dépassé, PHP-FPM indisponible, ou tout code
HTTP non couvert par `curl -f` → `exit 1`, 3 tentatives (`--retries=3`)
avant que Docker ne marque le conteneur `unhealthy`.

**Preuve.** Vérifié empiriquement dans ce Lot : `curl http://.../healthz` →
`ok` (HTTP 200) ; `docker inspect --format='{{.State.Health.Status}}'` →
`healthy`.

**Pourquoi ce choix ?** Un healthcheck qui dépendrait du rendu d'une page
Grav réelle échouerait à distinguer une panne du runtime d'une erreur de
contenu propre à un site — le README documente explicitement cette limite
et recommande qu'un futur rôle Ansible la complète par un contrôle HTTP
applicatif séparé, configurable, **en plus** de celui-ci.

**Pour aller plus loin.** [Configuration et interfaces](../06.configuration-et-interfaces),
[Architecture globale — Versionnement et rollback](../../01.architecture-globale/05.versionnement-et-rollback)
(distinction healthcheck Docker / contrôle HTTP applicatif, `ansible-role-grav-site`).

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : Dockerfile, docker/entrypoint.sh, docker/seed-init.sh, docker/bootstrap-admin.sh, docker/healthcheck.sh, docker/healthz.php, docker/nginx.conf
Dernière vérification : 2026-09-12
```
