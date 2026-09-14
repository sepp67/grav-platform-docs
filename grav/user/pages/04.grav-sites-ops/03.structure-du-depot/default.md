---
title: "Structure du dépôt"
template: docs
taxonomy:
    category: [docs]
---

## Arborescence au tag `v1.0.0`

```text
.
├── ansible.cfg              aucun inventaire par défaut ; -i explicite obligatoire
├── requirements.yml         unique source de vérité de la version du rôle (v2.0.0)
├── Makefile                 21 cibles documentées, chacune couverte par un test
├── inventories/
│   ├── example/               inventaire + registre + vault.yml.example — entièrement fictif
│   └── production/            fourni hors dépôt, jamais suivi par Git (absent à ce stade)
├── playbooks/
│   ├── deploy-site.yml, restart-site.yml, stop-site.yml   intentions de mutation
│   ├── check-site.yml, check-all.yml                       contrôle de dérive (lecture seule)
│   └── _shared/
│       ├── mutate.yml          séquence commune aux 3 mutations
│       ├── translate.yml       traduction registre+vault → grav_*
│       └── observe.yml         collecte + classification (check/check-all)
├── registry/
│   ├── retired-sites.yml       ensemble EXACT des projets actuellement retirés
│   └── reactivated-sites.yml   historique append-only des réactivations
├── scripts/
│   ├── validate-target.sh, preflight.sh          sélecteur + préflight (L3, lecture seule)
│   ├── deploy.sh, restart-site.sh, stop-site.sh  intentions (L4-L5)
│   ├── check-site.sh, check-all.sh               contrôle de dérive (L6)
│   ├── lifecycle-history-check.sh                preuve append-only inter-version (L8)
│   └── lib/
│       ├── gso_validate.py      validateur partagé (registre, vault, sélecteur, préflight)
│       ├── gso_classify.py      classification pure de la dérive (8 catégories)
│       ├── gso_lifecycle.py     validateur du cycle de vie documentaire (lecture seule)
│       ├── gso_compliance.py    génère/vérifie docs/COMPLIANCE-MATRIX.md
│       ├── site-mutation.sh     chemin commun deploy/restart/stop (sélecteur→verrou→playbook)
│       └── site-check.sh        chemin commun check/check-all (sélecteur→playbook, sans verrou)
├── tests/
│   ├── gso-t01…t24-*.sh        24 tests numérotés de la matrice du contrat
│   ├── l4…l11-*.sh              12 preuves de mécanisme sans numéro GSO-T dédié
│   ├── lib/
│   │   ├── common.sh, selector_harness.py, vault_values.py
│   │   └── spy-role/sepp67.grav_site/   doublure du rôle (observe grav_* sans déployer)
│   ├── fixtures/                 jeux de données synthétiques par test
│   └── run-all.sh                lanceur (batterie reproductible, + GSO-T15 si --functional)
├── docs/                        architecture, contrat, schémas, exploitation, migration, tests, acceptation
└── .github/workflows/ci.yml     6 jobs : static, role, translate, drift, functional-contract, conformance
```

## Aucun contenu métier

Vérifié par lecture directe : aucun thème, plugin ou page. Les seules
données applicatives visibles sont explicitement fictives
(`inventories/example/`, adresses RFC 5737/TEST-NET, `registry/*.yml`
vides au tag audité).

## `inventories/production/` : absent par construction

Ce répertoire n'existe **pas** dans le tag — il est fourni hors dépôt et
`.gitignore`-exclu. Toute commande qui en dépend (`make deploy`, `make
check`, etc.) échoue tant qu'il n'est pas fourni par l'opérateur. C'est un
fait vérifiable directement (`git ls-tree -r v1.0.0` ne le liste pas), pas
seulement une affirmation du README.

## `registry/retired-sites.yml` et `reactivated-sites.yml` au tag audité

Les deux fichiers existent et sont suivis, mais **vides** au tag `v1.0.0`
(`retired_grav_sites: {}`, aucun événement) — cohérent avec un dépôt sans
site réel migré à ce stade.

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : git ls-tree -r v1.0.0, README.md ("Structure")
Dernière vérification : 2026-09-14
```
