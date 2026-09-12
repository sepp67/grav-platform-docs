---
title: "Responsabilités et frontières"
template: docs
taxonomy:
    category: [docs]
---

## Quelles frontières empêchent les dépôts de se coupler ?

Chaque dépôt de la plateforme a une responsabilité exclusive et des
non-responsabilités explicites. Trois règles structurelles, vérifiées par
les dépôts eux-mêmes (pas seulement affirmées ici), maintiennent ces
frontières :

- **`ansible-role-grav-site` ne construit ni ne modifie jamais d'image
  Docker** — il consomme une référence déjà publiée sur un registre (GHCR).
  Il « ne dépend jamais de l'arborescence interne » du dépôt appelant
  (`ansible-role-grav-site/README.md`).
- **`grav-sites-ops` ne dépend jamais directement de `grav-runtime` ni des
  images applicatives.** Sa seule dépendance de build/déploiement est
  `ansible-role-grav-site`, épinglée par tag Git dans `requirements.yml`
  (`git+https://github.com/sepp67/ansible-role-grav-site.git`, `version:
  "v2.0.0"`) — jamais une branche mouvante. `grav-runtime` et les images
  applicatives « fournissent les images référencées dans le registre », sans
  lien de dépendance direct (`grav-sites-ops/docs/ARCHITECTURE.md`).
- **`grav-sites-ops` ne mute jamais un autre dépôt.** Une tâche du parc ne
  modifie jamais `ansible-role-grav-site`, une image applicative,
  `grav-runtime` ou le `control-repository` (`docs/GOVERNANCE.md`, "Bornage
  des mutations") ; aucune opération Ansible du parc ne touche un dépôt
  distant ou un registre d'images autrement qu'en lecture.

## Ce que `grav-sites-ops` invoque réellement

`grav-sites-ops` n'appelle pas `ansible-role-grav-site` "en gros" : un
playbook ciblé (`playbooks/deploy-site.yml`) sélectionne un site, verrouille
la mutation, valide les assertions, **traduit** chaque champ du registre
déclaratif vers une variable publique du rôle, puis inclut la séquence
partagée qui invoque le rôle :

| Champ du registre (`grav-sites-ops`) | Variable publique (`ansible-role-grav-site`) |
|---|---|
| `image` | `grav_image` |
| `version` | `grav_version` |
| `digest` | `grav_digest` |
| `container_name` | `grav_container_name` |
| `base_directory` | `grav_base_directory` |
| `bind_address` | `grav_bind_address` |
| `http_port` | `grav_http_port` |
| `state` | `grav_state` |
| `force_pull` | `grav_force_pull` |
| `manage_docker` | `grav_manage_docker` |
| `site_check_path` | `grav_site_check_path` |
| `extra_environment` | `grav_extra_environment` |

Cette traduction est ce qui permet à `ansible-role-grav-site` de rester
générique (il ne connaît que ses variables publiques) tout en laissant
`grav-sites-ops` décrire le parc dans son propre vocabulaire (le registre).

## Tableau RACI simplifié

R = Réalise, A = Décide (Accountable), C = Consulté, I = Informé.

| Activité | Auteur d'une image applicative | Mainteneur `grav-runtime` | Mainteneur `ansible-role-grav-site` | Opérateur `grav-sites-ops` | Mainteneur `control-repository` |
|---|---|---|---|---|---|
| Construire l'image de base (PHP-FPM, Nginx, Grav Core) | I | R/A | I | I | — |
| Construire et publier une image applicative | R/A | C | — | I | — |
| Déclarer/modifier une instance dans le registre du parc | I | — | I | R/A | — |
| Injecter les secrets de déploiement (vault, hors dépôt) | — | — | C | R/A | — |
| Exécuter le déploiement (rôle : pull, Compose, démarrage) | I | — | R/A | R | — |
| Vérifier healthcheck et contrôle HTTP après déploiement | I | — | R | R/A | — |
| Décider d'une mise à jour ou d'un rollback (changement déclaratif) | C | I | I | R/A | — |
| Configurer le reverse proxy, TLS, DNS | — | — | — | I | R/A |

Le mainteneur `control-repository` n'apparaît qu'une fois : aucune des
étapes de construction ou de déploiement ne le concerne (voir ci-dessous).

## Tableau des contrats d'interface entre dépôts

| Interface | Producteur | Consommateur | Donnée échangée | Garantie | Hors contrat |
|---|---|---|---|---|---|
| Base d'image | `grav-runtime` | image applicative | image Docker taguée (`ghcr.io/sepp67/grav-runtime:X.Y.Z`) | contrat immuable/persistant respecté (cahier §4.2), healthcheck `/healthz` | contenu métier, comptes, secrets |
| Publication | image applicative | GHCR | image taguée, jamais `latest` | version explicite, reproductible | disponibilité du registre lui-même |
| Consommation d'image | GHCR | `ansible-role-grav-site` | image tirée par référence (`grav_image` + `grav_version` ou `grav_digest`) | référence jamais construite localement | contenu de l'image |
| Invocation du rôle | `grav-sites-ops` | `ansible-role-grav-site` | variables publiques traduites (table ci-dessus), tag Git épinglé (`v2.0.0`) | interface stable par version de tag ; pas de dépendance à l'arborescence interne du rôle | tâches internes, noms de fichiers de tâches, registres internes du rôle |
| Déploiement | `ansible-role-grav-site` | VM cible | conteneur démarré/mis à jour, volumes persistants, healthcheck | idempotence, non-écrasement des données persistantes | reverse proxy, TLS, DNS, pare-feu |
| Exposition | VM cible | `control-repository` | adresse/port bind local (`bind_address`, `http_port`) | aucune — relation manuelle, hors automatisation | tout déclenchement automatique depuis la chaîne de déploiement |

## La frontière avec le reverse proxy et le `control-repository`

Ni `ansible-role-grav-site` ni `grav-sites-ops` ne configurent de reverse
proxy, de TLS, de DNS ou de pare-feu. Le rôle l'énonce explicitement dans sa
section "Contrat réseau" (`ansible-role-grav-site/README.md`) : le domaine
public, TLS et le routage sont la responsabilité d'un `control-repository`
séparé, "indépendamment". Une instance déployée par cette chaîne n'est donc
joignable, à l'issue du déploiement, que sur son adresse et son port de
liaison locaux (`bind_address`, `http_port`) — pas encore sur un nom de
domaine public.

`grav-sites-ops` va plus loin qu'une simple convention documentaire : un
test (`tests/gso-t23-no-control-repository.sh`) vérifie l'absence de tout
lien programmatique (sous-module, référence dans `requirements.yml`, import
Ansible) vers un `control-repository`. Nommer la frontière en prose reste
autorisé — c'est précisément ce que fait cette page.

---

```yaml
Sources documentées : ansible-role-grav-site (v2.0.0, commit 1339e50bc20257fbb9f21953995c08262ae3043e) — README.md, tasks/main.yml ;
                       grav-sites-ops (v1.0.0, commit 48b9a59b956f73f10e5602b72a222dd71b4a3f3a) — docs/ARCHITECTURE.md, docs/CONTRAT-ARCHITECTURAL.md, docs/REGISTRY-SCHEMA.md, docs/GOVERNANCE.md, requirements.yml, playbooks/deploy-site.yml ;
                       grav-runtime (v1.0.4, commit e6e35c37bce2d214b4fb2ca77549f7bec7eed3d4) — Dockerfile (mention du contrat immuable/persistant dans le tableau des contrats d'interface)
Périmètre détaillé : voir docs/documentation-sources.yml
Dernière vérification : 2026-09-11
```
