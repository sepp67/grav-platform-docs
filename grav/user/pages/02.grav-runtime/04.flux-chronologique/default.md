---
title: "Flux chronologique"
template: docs
taxonomy:
    category: [docs]
---

Sommaire opérationnel de ce dépôt : trois chronologies distinctes,
reconstruites ligne à ligne depuis le `Dockerfile` et `docker/entrypoint.sh`
du tag `v1.0.4`. Chaque étape renvoie à son détail complet dans [Sections de
code](../05.sections-de-code).

**B et C ne sont pas séquentielles l'une par rapport à l'autre.** B est le
cycle de vie de `entrypoint.sh`, de son démarrage à son arrêt. C est un
contrôle **périodique, piloté par Docker**, qui s'exécute en parallèle
pendant toute la durée où le conteneur tourne (après B6, jusqu'à l'arrêt
amorcé en B7) — ce n'est ni une étape de `entrypoint.sh`, ni une commande
qu'il invoque lui-même, et il ne s'exécute jamais après l'arrêt du
conteneur.

## A. Construction de l'image (`docker build`)

| # | Étape | Déclencheur / condition | Action | État produit | Échec possible |
|---:|---|---|---|---|---|
| A1 | Image PHP de base | `ARG PHP_VERSION=8.3` | `FROM php:8.3-fpm-alpine` | couche de base | tag `8.3-fpm-alpine` introuvable (rare) |
| A2 | Dépendances système et PHP | toujours | `apk add` (nginx, curl, unzip, su-exec, libs image) puis `docker-php-ext-install gd zip intl mbstring opcache` | binaires et extensions PHP installés | échec réseau `apk`/build d'extension |
| A3 | Permissions Nginx | toujours, après A2 | `chown www-data:www-data /var/lib/nginx /var/lib/nginx/tmp` | répertoires Nginx traversables par `www-data` | — (opération locale, n'échoue pas en pratique) |
| A4 | Téléchargement, vérification et installation de Grav | toujours, après A3 (`WORKDIR /var/www/html`) | `curl` l'archive officielle, vérifie son SHA-256, l'extrait, copie son contenu, **supprime** le contenu de démo (`user/pages`, `user/accounts`, `user/data`, `user/config`), recrée ces répertoires vides, `chown -R www-data` | Grav Core + Admin installés, uniquement `user/themes`/`user/plugins` peuplés | téléchargement échoué, SHA-256 non conforme, ou archive de forme inattendue → `exit 1` explicite |
| A5 | Surcharge ciblée de `quark2` | après A4 | `COPY --chown=www-data:www-data docker/theme-overrides/quark2/ user/themes/quark2/` | un seul fichier du thème vendorisé remplacé (`templates/partials/footer.html.twig`) | fichier source absent du contexte de build |
| A6 | Répertoire seed | après A4 | `RUN mkdir -p /opt/grav-seed` | répertoire vide, prêt à être peuplé par une image fille | — |
| A7 | Configuration runtime | après A2 (indépendant de A4-A6) | `COPY` de `nginx.conf`, `php-fpm.conf`, `healthz.php` | configuration technique en place | fichier source absent |
| A8 | Scripts de démarrage | après A7 | `COPY` de `entrypoint.sh`, `bootstrap-admin.sh`, `seed-init.sh`, `healthcheck.sh` | scripts présents, pas encore exécutables | fichier source absent |
| A9 | Permissions finales | après A7-A8 | `chown` sur `healthz.php`, `chmod +x` sur les 4 scripts | scripts exécutables, `healthz.php` lisible par `www-data` | — |
| A10 | Déclaration du contrat d'exécution | après A9 | `EXPOSE 80`, `HEALTHCHECK ... CMD ["/healthcheck.sh"]`, `STOPSIGNAL SIGTERM`, `ENTRYPOINT ["/entrypoint.sh"]` | image terminée, prête à être taguée et publiée | — |

**Pourquoi cet ordre ?** A2-A3 avant A4 : les outils de téléchargement
(`curl`, `unzip`) doivent exister avant de les utiliser. A4 avant A5 : la
surcharge s'applique sur le thème vendorisé, qui doit déjà être en place.
A9 après A7-A8 : `chmod +x` porte sur des fichiers qui doivent déjà être
copiés.

## B. Démarrage et cycle de vie de l'entrypoint (`ENTRYPOINT`, PID 1)

| # | Étape | Déclencheur / condition | Action | État produit | Échec possible |
|---:|---|---|---|---|---|
| B1 | Point d'entrée réel | `docker run` / `docker start` | `entrypoint.sh` s'exécute comme PID 1 | processus superviseur démarré | — |
| B2 | Correction des permissions | toujours, en premier | pour chaque chemin critique (`cache`, `logs`, `images`, `assets`, `user/accounts`, `user/data`, `user/pages`, `user/images`) : `mkdir -p`, puis `chown`/`chmod` **seulement si** le propriétaire actuel n'est pas déjà `82:82` | chemins accessibles à `www-data`, opération idempotente | — |
| B3 | Initialisation non destructive depuis le seed | pour chacun des 4 sous-répertoires (`pages`, `accounts`, `data`, `images`), indépendamment | `seed-init.sh` (paramètres : seed, destination, étiquette) : copie si la destination est vide **et** le seed existe et n'est pas vide ; ne fait rien sinon | contenu initial présent au premier démarrage ; inchangé aux démarrages suivants | échec de la copie (`cp -a`) → `exit 1`, démarrage interrompu |
| B4 | Fuseau horaire (optionnel) | si `GRAV_TIMEZONE` défini | écrit `/usr/local/etc/php/conf.d/zz-timezone.ini` | `date.timezone` PHP réglé | — |
| B5 | Bootstrap administrateur | toujours tenté, exécuté en tant que `www-data` (`su-exec`) | voir la politique tri-state complète dans [Sections de code](../05.sections-de-code) | compte créé, absent, ou démarrage refusé selon le cas | variables partielles, ou bootstrap demandé mais impossible → `exit 1`, **le conteneur ne démarre pas** |
| B6 | Démarrage des processus | seulement si B5 n'a pas échoué | `php-fpm -F &` puis `nginx -g "daemon off;" &`, PID des deux mémorisés | les deux processus tournent, supervisés par le PID 1 | — |
| B7 | Supervision et arrêt | en continu, jusqu'à `SIGTERM`/`SIGINT`/`SIGQUIT` ou sortie inattendue de l'un des deux | boucle de contrôle (`kill -0` chaque seconde) ; sur signal : arrête les deux proprement ; si l'un meurt seul : arrête l'autre et sort en erreur | arrêt propre (code 0) sur signal, ou arrêt en erreur (code 1) si un processus meurt seul | `nginx` ou `php-fpm` meurt de façon inattendue |

**Pourquoi cet ordre ?** B2 avant B3 : le seed ne peut être copié que dans un
répertoire déjà accessible en écriture à `www-data`. B3 avant B5 : un compte
admin bootstrap sur un `user/accounts` fraîchement seedé doit s'appuyer sur
un répertoire déjà dans son état définitif. B5 avant B6 : le bootstrap
s'exécute avant que Nginx/PHP-FPM ne servent du trafic — un `exit 1` à cette
étape empêche le conteneur de répondre avec un site sans administrateur
alors qu'un opérateur en a explicitement demandé un.

## C. Contrôle de santé piloté par Docker (interaction périodique, en parallèle de B6-B7)

`HEALTHCHECK` n'est **pas une étape de la séquence B** : c'est Docker
lui-même (le démon, pas `entrypoint.sh`) qui déclenche cette interaction,
indépendamment et en parallèle, tant que le conteneur tourne.

| # | Étape | Déclencheur / condition | Action | État produit | Échec possible |
|---:|---|---|---|---|---|
| C1 | Déclenchement périodique | Docker, toutes les 30s (`--interval=30s`), après un délai de grâce de 10s (`--start-period=10s`), en continu depuis B6 jusqu'à l'arrêt du conteneur | Docker exécute `/healthcheck.sh` **dans** le conteneur | tentative de contrôle | — |
| C2 | Requête interne | à chaque déclenchement C1 | `healthcheck.sh` appelle `curl -fsS --max-time 2 http://127.0.0.1/healthz` | requête HTTP émise | timeout de 2s dépassé |
| C3 | Traversée technique | à chaque requête C2 | la requête traverse Nginx puis PHP-FPM (`healthz.php`) — **jamais** le front controller de Grav (`index.php`) | réponse `200`, corps `ok` | PHP-FPM indisponible, code HTTP non couvert par `curl -f` |
| C4 | Statut Docker | après chaque C3 | Docker marque le conteneur `healthy` (succès) ou compte un échec (3 échecs consécutifs, `--retries=3`, avant `unhealthy`) | statut visible par `docker inspect` | 3 échecs consécutifs → `unhealthy` |

**Ce que C prouve, ce qu'il ne prouve pas.** C prouve que Nginx et PHP-FPM
sont vivants et correctement reliés — la santé **technique** des deux
processus et de leur liaison. Il ne prouve **jamais** que les pages
métier d'un site fille répondent correctement (thème, plugins, contenu) —
la santé **applicative** est un sujet distinct, jamais couvert par ce
contrôle.

## Branches significatives

- **Premier démarrage vs relance** : B3 copie au premier démarrage
  (répertoire vide), ne fait rien ensuite — par sous-répertoire,
  indépendamment (monter `user/pages` sans `user/images` fonctionne).
- **Avec/sans bootstrap** : aucune variable admin → B5 désactivé,
  démarrage normal ; les trois variables → compte créé ou étape ignorée si
  déjà présent ; variables partielles ou bootstrap demandé mais impossible
  → conteneur arrêté avant B6.
- **Succès/échec** : toute défaillance de B3 ou B5 interrompt le démarrage
  avant que Nginx/PHP-FPM ne soient lancés — jamais de service partiellement
  fonctionnel.

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : Dockerfile, docker/entrypoint.sh, docker/seed-init.sh, docker/bootstrap-admin.sh, docker/healthcheck.sh, docker/healthz.php, docker/nginx.conf
Dernière vérification : 2026-09-12
```
