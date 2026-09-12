---
title: "Tests et CI"
template: docs
taxonomy:
    category: [docs]
---

## Niveaux de preuve — à ne pas confondre

Cette page distingue explicitement quatre niveaux, pour ce Lot :

1. **Tests présents comme scripts versionnés dans le dépôt** — aucun.
   `git ls-tree -r v1.0.4` ne contient aucun répertoire `tests/` ni
   `test/*.sh`. Seuls des fixtures existent : `test/config/system.yaml`,
   `test/seed/pages/01.home/default.md`.
2. **Tests documentés en prose, avec commandes, dans le README** — huit
   tests numérotés (1 à 8, plus des variantes 3bis à 3octies), qui
   s'appuient sur `test/compose.yml`. Documentés, pas automatisés.
3. **Validations réellement exécutées par Claude pendant ce Lot** — un
   sous-ensemble des huit, listé ci-dessous avec leur résultat réel.
4. **Comportement CI** — distingué entre ce qui a été observé (métadonnées
   du run réel) et ce qui est déduit de la lecture du workflow.

## Écart : le harnais de test n'est pas versionné

Comme noté en [Structure du dépôt](../03.structure-du-depot),
`test/compose.yml` existe sur le disque local mais est exclu par
`.gitignore` (`**/compose.yml`). Les huit tests du README en dépendent
tous. Un clone frais du tag `v1.0.4` ne peut donc pas les exécuter tels
quels sans recréer ce fichier depuis sa description dans le README.

## Tests exécutés réellement pendant ce Lot

| Test README | Exécuté dans ce Lot | Méthode | Résultat observé |
|---|---|---|---|
| Test 1 — Build | oui | `docker build` sur un worktree Git détaché au tag `v1.0.4`, tag local `grav-runtime:v1.0.4-audit-local`, jamais publié | succès |
| Test 2 — Premier démarrage | oui (sans `compose.yml`, via `docker run` équivalent) | conteneur démarré, `/healthz` interrogé | `200`, `healthy` |
| Test 3 — Bootstrap (3 variables) | oui | `docker run` avec les 3 variables | compte créé, log `"created successfully"` |
| Test 3bis — Variables partielles | oui | `docker run` (sans pipe, pour observer le vrai code de sortie) avec 2 variables sur 3 | `exit 1` réel, log explicite |
| Test 3ter — Aucune variable | oui | `docker run` sans variable admin | log `"admin bootstrap disabled"`, aucun fichier créé |
| Test 3quater à 3septies — `GRAV_ADMIN_TYPE` | **non ré-exécuté** | — | non vérifié dans ce Lot (comportement lu dans le code, cohérent avec le README, non testé empiriquement ici) |
| Test 3octies — Non-écrasement d'un compte | **non ré-exécuté** | — | non vérifié dans ce Lot |
| Test 4 — Seed | oui | seed de test du dépôt monté, premier démarrage puis modification + redémarrage | copié au premier démarrage ; modification conservée après redémarrage |
| Test 5 — Protection des données | couvert par le Test 4 | — | conforme |
| Test 6 — Permissions | partiellement | `id www-data` dans le conteneur | `uid=82(www-data) gid=82(www-data)`, conforme au README |
| Test 7 — Arrêt propre | **non ré-exécuté** | — | non vérifié dans ce Lot |
| Test 8 — Arrêt inattendu de PHP-FPM | **non ré-exécuté** | — | non vérifié dans ce Lot |

Aucun de ces résultats n'est affirmé par simple lecture du README : chaque
ligne "exécuté" ci-dessus correspond à une commande réellement lancée
pendant ce Lot, dans un conteneur construit depuis le tag audité.

## Ce qui est statique (lint, syntaxe)

Aucun outil de lint n'a été trouvé versionné dans ce dépôt (pas de
configuration ESLint/hadolint/shellcheck). `sh -n` n'a pas été exécuté sur
les scripts de ce dépôt dans ce Lot (limite de ce Lot 3, périmètre listé
en fin de page) — à la différence de `grav-platform-docs`, qui applique ce
contrôle à ses propres scripts (`tests/test-syntax.sh`).

## CI : ce qui est observé vs ce qui est déduit

**Observé réellement** (via `gh run list`/`gh run view`, accès direct à
l'historique GitHub Actions du dépôt) :

- Le run déclenché par le push du tag `v1.0.4` existe, statut
  `completed`/`success`, durée `3m21s`, daté du 5 août 2026 — cohérent avec
  la date du commit `e6e35c37b...` (`2026-08-05`).
- Le registre GHCR expose bien, **aujourd'hui**, les tags `1.0.4`, `1.0`,
  `1` et `latest` pour `ghcr.io/sepp67/grav-runtime`, tous les quatre
  pointant vers le même digest de manifeste
  (`sha256:995d59773839309706ce559e79c7206d1196ce12619a399051e79d4095fce5a6`)
  — vérifié par `docker manifest inspect` en direct sur le registre.
- Ce manifeste est un index multi-plateforme contenant **une seule image
  réelle** (`linux/amd64`) et une seconde entrée `unknown/unknown` — une
  attestation de provenance/SBOM ajoutée automatiquement par
  `docker/build-push-action@v6`, pas une seconde architecture construite.

**Non observé** (logs indisponibles) : le détail étape par étape du run
lui-même (`gh run view --log`) ne retourne aucune ligne pour ce run —
logs probablement expirés. Impossible de confirmer *depuis les logs* que
ce run précis a bien poussé exactement ces quatre tags ; c'est une
**déduction cohérente** entre la configuration du workflow (voir
ci-dessous) et l'état actuel, observé, du registre.

**Déduit de la lecture du workflow** (`.github/workflows/docker.yml`) :

- Déclenché sur push de tag `refs/tags/v[0-9]+.[0-9]+.[0-9]+`, ou
  manuellement (`workflow_dispatch`).
- `docker/metadata-action@v5` calcule, pour un tag `vX.Y.Z`, quatre tags
  OCI : `{{version}}` (`X.Y.Z`), `{{major}}.{{minor}}` (`X.Y`), `{{major}}`
  (`X`), et `latest` — ce dernier via
  `type=raw,value=latest,enable=${{ startsWith(github.ref, 'refs/tags/v') }}`,
  qui vaut vrai pour tout push de tag `vX.Y.Z`. **Le workflow publie donc
  bien un tag `latest` à chaque nouvelle release**, même si aucun
  consommateur ne doit l'utiliser.
- `platforms: linux/amd64` — une seule architecture construite, jamais de
  multi-arch (`linux/arm64` absent de la configuration).
- Aucune étape de test n'existe dans ce workflow : `checkout` → `buildx` →
  `login` → `metadata` → `build-push`. La publication sur GHCR n'est
  précédée d'aucune vérification automatisée, ni des huit tests du README,
  ni d'un lint.

## Le tag `latest` : quatre affirmations à ne pas mélanger

| Affirmation | Statut | Détail |
|---|---|---|
| `latest` existe sur GHCR | **observé**, le 2026-09-12 | `docker manifest inspect ghcr.io/sepp67/grav-runtime:latest` répond, même digest que `1.0.4` |
| Le workflow publie `latest` à chaque tag `vX.Y.Z` | **déduit** de la lecture de `.github/workflows/docker.yml` | `type=raw,value=latest,enable=${{ startsWith(github.ref, 'refs/tags/v') }}` — vrai pour tout push de tag, pas seulement pour cette release-ci |
| `latest` ne doit jamais être utilisé en production | **contrat déclaré**, pas un fait technique observable | README "Versionnement" ; repris par le cahier de construction de `grav-platform-docs` (§15) |
| `grav-platform-docs` épingle `1.0.4`, jamais `latest` | **observé** dans ce dépôt | `FROM ghcr.io/sepp67/grav-runtime:1.0.4` — `Dockerfile` de `grav-platform-docs` |

Ces quatre affirmations coexistent sans contradiction : le workflow publie
techniquement un tag que le contrat interdit d'utiliser, et l'usage réel
observé dans cette plateforme respecte le contrat, pas la facilité offerte
par le tag.

## Ce qui est documenté mais non observé

Le README affirme "Tous les tests ci-dessous ont été exécutés avec succès
pendant l'implémentation" — une affirmation du mainteneur, à un moment non
daté précisément, sur son propre poste. Cette page ne reprend jamais cette
affirmation comme preuve pour ce Lot : seule la colonne "Exécuté dans ce
Lot" ci-dessus fait foi pour les tests effectivement relancés ici.

---

```yaml
Source documentée : https://github.com/sepp67/grav-runtime
Référence : v1.0.4
Commit : e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4
Fichiers principaux : README.md ("Tests"), .github/workflows/docker.yml
Dernière vérification : 2026-09-12
```
