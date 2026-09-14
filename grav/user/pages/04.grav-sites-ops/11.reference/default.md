---
title: "Référence"
template: docs
taxonomy:
    category: [docs]
---

## L'écart connu : un tag qui existe, décrit comme absent

**Constat vérifié directement** : `git tag --points-at
48b9a59b956f73f10e5602b72a222dd71b4a3f3a` retourne `v1.0.0`, et
`git rev-parse v1.0.0` retourne exactement ce commit. Le tag **existe**,
localement et sur le dépôt distant.

**Pourtant**, trois fichiers **suivis par ce même commit** affirment le
contraire : `README.md` (« Version du dépôt : `1.0.0`, tag prévu `v1.0.0`,
non créé »), `CHANGELOG.md` (entrée `[1.0.0] - 2026-09-11` : « Tag prévu
`v1.0.0` — non créé »), `docs/ACCEPTANCE.md` (release « BLOCKED,
préparation en cours »).

**L'écart est historiquement explicable : les documents ont été finalisés
avant la création du tag, ensuite posé sur le même commit. Il reste
néanmoins une incohérence documentaire dans `v1.0.0` : le lecteur
consultant le tag voit encore une affirmation désormais fausse.** Quatre
éléments à ne jamais fusionner :

- **Explication historique** (reconstituée depuis la chronologie
  ci-dessous, pas supposée) : le contenu de ces trois fichiers a été
  rédigé et committé sur `main` à un moment où la release (l'opération de
  tag elle-même) n'avait pas encore eu lieu — un commit de
  **préparation** de release, dont la prose décrivait fidèlement l'état
  des choses au moment où elle a été écrite. Le tag `v1.0.0` a ensuite été
  créé après coup, sur ce même commit, sans que sa prose soit mise à jour
  rétroactivement. C'est un artefact normal de tout flux où le tagging est
  un acte séparé et postérieur au commit qu'il désigne — pas un bug du
  dépôt.
- **État Git observé** (fait, pas interprétation) : `git tag --points-at
  48b9a59b…` retourne `v1.0.0` ; le tag existe, localement et sur le
  distant, et pointe exactement sur ce commit.
- **Effet pour le lecteur** : quiconque consulte le tag `v1.0.0` — code
  source, README, CHANGELOG — lit une affirmation **devenue fausse** au
  moment même où ce tag existe. L'explication historique n'efface pas cet
  effet : un lecteur qui n'a pas cette documentation sous les yeux est
  réellement induit en erreur par le contenu du tag qu'il consulte.
- **Absence de modification du dépôt source dans ce projet
  documentaire** : `grav-platform-docs` n'a et ne peut avoir aucune
  action sur ce texte — corriger `README.md`/`CHANGELOG.md` dans
  `grav-sites-ops` est hors périmètre (cahier §15, dépôt en lecture
  seule). Cette page se limite à **signaler** l'écart avec la précision
  requise, jamais à le corriger ni à le minimiser.

**Conséquence pour cette documentation** : chaque affirmation de ce
chapitre distingue explicitement « ce que dit le texte du commit » de
« ce que montre l'état Git » — jamais fusionnés silencieusement.

## Chronologie de la release, telle que documentée par le dépôt lui-même

Reconstituée depuis `docs/ACCEPTANCE.md` (151 lignes, lu en intégralité)
et les 80 premières lignes de `CHANGELOG.md` (sur 513) :

| Date | Événement | Réf. |
|---|---|---|
| — | `main` = `d69a05a`, poussé | run CI `34513250088` — un pas rouge (défaut de garde `GSO-REQ-192`) |
| — | correctif en 5 commits sur le défaut de garde | branche `correctif/ci-192-post-push` |
| 2026-09-10/11 | `main` = `b2e97f2`, poussé | run CI `34591427344` — **premier run global entièrement vert**, gate `conformance` inclus |
| 2026-09-11 | décision de licence + version | AGPL-3.0-or-later, `1.0.0` |
| 2026-09-11 | préparation de la release sur branche `release/1.0.0` | **non intégrée, non poussée** au moment de la rédaction de `ACCEPTANCE.md` |
| (postérieur, non documenté dans ces fichiers) | création effective du tag `v1.0.0` sur le commit `48b9a59b` | constat Git direct, pas une prose du dépôt |

`docs/TEST-RESULTS.md` porte un placeholder explicitement non rempli :
« Run final du HEAD définitif — *(à compléter — run sur le HEAD portant
ce commit ; aucun commit après ce run.)* » — confirmation supplémentaire
que ces documents ont été figés **avant** la finalisation de la release.

### Les quatre verdicts séparés (`docs/ACCEPTANCE.md`, §1 et §4)

| Domaine | Verdict au texte du commit |
|---|---|
| Acceptation de la construction locale | ACCEPTED (`main` = `b2e97f2`) |
| Publication (push de `main`) | effectuée, CI distante globale verte |
| Release (tag + publication GitHub) | BLOCKED (préparation en cours) — **et pourtant le tag existe désormais**, voir ci-dessus |
| Migration réelle depuis l'ancien profil | BLOCKED |

Ces quatre verdicts ne sont **jamais fusionnés** entre eux dans cette
documentation : une construction acceptée ne signifie pas une migration
réalisée, une CI verte ne signifie pas un déploiement réel.

## Glossaire local

| Terme | Définition |
|---|---|
| Registre | `grav_sites`, état désiré non secret d'un parc |
| Vault | `vault_grav_sites`/`vault_retired_grav_sites`, données secrètes |
| Sélecteur fermé | algorithme à 8 règles qui résout `SITE` à exactement un hôte |
| État désiré | ce que déclare le registre |
| État appliqué | ce que le rôle a écrit lors de son dernier passage (`.deployed_state.yml`) |
| État réel | ce qu'observe une sonde directe (Docker, HTTP) au moment du contrôle |
| Dérive | écart classé entre ces trois états, en 8 catégories |
| Retrait | opération documentaire manuelle, jamais une automatisation |
| Gate | point d'autorisation humaine explicite et séparé (construction/publication/release/migration) |

## Limites connues de cette rubrique

- `GSO-T15` (déploiement fonctionnel réel) n'a **pas** été exécuté pour ce
  lot ; la seule preuve disponible est celle de `docs/TEST-RESULTS.md`,
  elle-même antérieure au commit du tag audité (run `34513250088`/commit
  `105e085`, branche `refonte/lot-9-release-preparation` — pas le HEAD
  `48b9a59b` lui-même pour tous les tests CI cités).
- `docs/CONTRAT-ARCHITECTURAL.md` (le contrat lui-même) n'a **pas** été lu
  intégralement — seuls ses intitulés d'exigences (extraits via la même
  expression régulière que `gso_compliance.py::_titles()`) et des
  citations ponctuelles reprises par `docs/GOVERNANCE.md`/`ACCEPTANCE.md`
  ont été consultés.
- Aucun contact réseau réel, aucune VM, aucun paquet système installé
  pour produire cette rubrique — conformément à la contrainte du lot.

**Résolu au Lot 5.1** (n'est plus une limite) : `scripts/lib/gso_lifecycle.py`
(473 lignes) et `scripts/lib/gso_compliance.py` (301 lignes) ont été lus
intégralement, et `docs/COMPLIANCE-MATRIX.md` a été lu et vérifié en
intégralité (257 lignes, 204 exigences comptées directement) — voir
[Sections de code](../05.sections-de-code) et [Tests et CI](../08.tests-et-ci).

## Index des pages de cette rubrique

1. [Vue d'ensemble](../01.vue-ensemble)
2. [Place dans l'architecture](../02.place-dans-architecture)
3. [Structure du dépôt](../03.structure-du-depot)
4. [Flux chronologique](../04.flux-chronologique)
5. [Sections de code](../05.sections-de-code)
6. [Configuration et interfaces](../06.configuration-et-interfaces)
7. [Données, secrets et persistance](../07.donnees-secrets-persistance)
8. [Tests et CI](../08.tests-et-ci)
9. [Exploitation et diagnostic](../09.exploitation-et-diagnostic)
10. [Adopter et étendre](../10.adopter-et-etendre)

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : docs/ACCEPTANCE.md, docs/VERSIONING.md, CHANGELOG.md, docs/TEST-RESULTS.md,
  scripts/lib/gso_lifecycle.py, scripts/lib/gso_compliance.py, docs/COMPLIANCE-MATRIX.md (les trois lus
  intégralement au Lot 5.1)
Dernière vérification : 2026-09-14 (Lot 5.1)
```
