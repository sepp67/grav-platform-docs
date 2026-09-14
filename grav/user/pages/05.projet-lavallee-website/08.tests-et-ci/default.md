---
title: "Tests et CI"
template: docs
taxonomy:
    category: [docs]
---

## Discipline de preuve

Sept statuts distincts, jamais confondus dans cette page : **test présent
dans le dépôt**, **test réellement exécuté pendant ce lot**, **build local
réellement exécuté**, **démarrage réellement exécuté**, **formulaire
réellement soumis**, **workflow CI lu** (le fichier YAML), **run CI
observé** (aucun ici — voir [Référence](11.reference)), et **comportement
seulement déduit** de la lecture du code.

## Commandes réellement exécutées pour cette rubrique

Dans le worktree détaché sur le commit `c4341ca7`, aucun paquet système
installé, aucune VM contactée, un port dynamique (`18095`-`18097`) pour ne
jamais perturber `projet-lavallee-dev` sur `8080` (vérifié pré-existant,
arrêté, non touché) :

```text
$ sh tests/run-all.sh
```

Résultat réel obtenu — **4/4 tests du dépôt réussis** :

```text
== test-build.sh        → [PASS] docker build réussi
== test-startup.sh      → conteneur healthy ; / → HTTP 302 (redirection /fr) ; /fr → HTTP 200
== test-app-presence.sh → thème/plugin/seed présents ; 12 routes fr/en/de → HTTP 200 ;
                           sélecteur de langue cohérent ; formulaire présent ; CSS et /admin accessibles
== test-persistence.sh  → 4 marqueurs (pages/accounts/data/images) survivent à un redémarrage
Tous les tests ont réussi.
```

**Soumission réelle du formulaire de contact**, non couverte par les tests
du dépôt lui-même (voir plus bas) — conteneur jetable + Mailpit sur un
réseau Docker dédié, image `email-private.php` factice montée depuis le
scratchpad de cette session (jamais copiée dans le dépôt source) :

```text
$ docker run … -v <scratchpad>/email-private.php:/var/www/html/user/config/email-private.php:ro …
```

Constats, dans l'ordre où ils ont été obtenus, **sept charges testées
individuellement** (session propre par test) plus une soumission de
contrôle pour l'échappement :

- formulaire `/fr/contact` : champs `nom`/`email`/`message`/`honeypot` présents, avec 3 champs cachés (`__form-name__`, `__unique_form_id__`, `form-nonce`) ;
- `message` vide → **rejetée avant tout traitement**, HTTP 200, pas de redirection, aucun e-mail produit ;
- `<script>alert(1)</script>` dans `nom` → **rejetée avant tout traitement**, « Erreurs XSS probablement détectées dans le champ 'Nom' », aucun e-mail produit ;
- `<script>alert(document.cookie)</script>` dans `message` → **rejetée avant tout traitement**, « …dans le champ 'Message' », aucun e-mail produit ;
- retour à la ligne dans `nom` (tentative d'injection d'en-tête via le champ utilisé par le sujet) → **rejetée avant tout traitement**, « Saisie non valide "Nom" », aucun e-mail produit ;
- retour à la ligne dans `email` (même tentative, sur le champ utilisé par `Reply-To`) → **acceptée** par le formulaire (HTTP 302) ; e-mail **produit**, mais **sans** en-tête `Reply-To` ni `Bcc` injecté — la valeur malformée a été silencieusement omise comme adresse de réponse, et n'apparaît que dans le corps HTML du message (sans effet d'en-tête) ;
- `pas-une-adresse` (e-mail syntaxiquement invalide) dans `email` → **rejetée avant tout traitement**, « Saisie non valide "E-mail" », aucun e-mail produit ;
- honeypot rempli → **rejetée**, « Votre demande n'a pas pu être traitée. » (mécanisme identifié avec certitude : `contact.php`, ce dépôt), aucun e-mail produit ;
- soumission nominale (« Jean Dupont », valeurs propres) → HTTP 302, `Location: /fr/contact/confirmation`, e-mail produit ;
- soumission de contrôle pour l'échappement (« Jean Dupont & Associés », message avec apostrophes/guillemets/balise `<b>`) → e-mail produit, `To: admin@example.com` (compte de test synthétique, voir [Référence](11.reference)), sujet et corps HTML correctement échappés (`&amp;`, `&lt;b&gt;`, `&#039;`, `&quot;`).

Voir le tableau de preuve complet, charge par charge, en [Flux
chronologique, chronologie D](04.flux-chronologique).

## Matrice des tests et garanties

| Garantie | Test | Type | Exécuté réellement (par moi) | CI observée | Limite |
|---|---|---|---|---|---|
| Build reproductible de l'image | `test-build.sh` | dynamique, Docker | ✅ | job `test` de `ci.yml` (lu, non observé en exécution) | 3 tentatives avec délai — masque un échec transitoire isolé, pas un échec systématique |
| Démarrage, healthy, redirection multilingue | `test-startup.sh` | dynamique, Docker | ✅ | idem | conteneur jetable sans volume — ne teste pas un redémarrage |
| Présence applicative (thème, plugin, seed, 12 routes × 3 langues, sélecteur de langue, CSS, admin) | `test-app-presence.sh` | dynamique, Docker | ✅ | idem | vérifie la présence du champ `nom` dans le HTML, **pas** une soumission réelle |
| Persistance des 4 volumes après redémarrage | `test-persistence.sh` | dynamique, Docker Compose | ✅ | **non** — exclu explicitement de `ci.yml` (« non bloquant », scénario plus long) | — |
| Soumission réelle du formulaire — 7 charges distinctes (champ requis vide, XSS `nom`, XSS `message`, CRLF `nom`, CRLF `email`, e-mail invalide, honeypot) + 2 soumissions valides (nominale, échappement) | **aucun test dédié dans ce dépôt** | dynamique, Docker + Mailpit, construit pour ce lot | ✅ (audit Lot 6/6.1 uniquement, hors suite du dépôt) | absent | ce dépôt ne couvre pas du tout ce scénario par ses propres tests — écart signalé en [Référence](11.reference) ; les mécanismes de rejet observés (XSS, saisie multi-ligne, format e-mail) sont attribués **par déduction** à Grav Core, jamais confirmés par lecture de son code source |
| Absence de secret dans l'image | **aucun test dans ce dépôt** | — | non exécuté | absent | contrairement à `grav-platform-docs` (`test-secrets.sh`), ce dépôt n'a pas d'équivalent |

## CI : deux workflows, jamais le même déclencheur

`.github/workflows/ci.yml` (39 lignes, lu intégralement) — job unique
`test` : login GHCR en lecture seule (pour tirer `grav-runtime`), puis
`test-build.sh` → `test-startup.sh` → `test-app-presence.sh`. Se déclenche
sur tout push ou pull request. Le commentaire du fichier précise :
« inerte tant que ce dépôt n'a pas de remote Git » — cohérent avec
l'absence de tag/release observée.

`.github/workflows/release.yml` (64 lignes, lu intégralement) — job unique
`docker`, déclenché **seulement** par un tag `v[0-9]+.[0-9]+.[0-9]+` ou un
déclenchement manuel. Utilise `docker/metadata-action` pour générer les
tags sémantiques **et** `latest` (ce dernier conditionné à
`startswith(github.ref, 'refs/tags/v')` — jamais produit hors d'une
release taguée). Publication (`push:`) sous la même condition.

**Aucun run CI n'a été observé en direct** pour ce lot (aucun accès à
l'historique GitHub Actions de ce dépôt distant) — seule la lecture des
deux fichiers YAML permet d'affirmer ce qui précède.

---

```yaml
Source documentée : https://github.com/sepp67/projet-lavallee-website
Référence : commit c4341ca77270565969e1e801e11a8fda72e5b402
Fichiers principaux : tests/*.sh, .github/workflows/{ci,release}.yml
Dernière vérification : 2026-09-14
```
