---
title: "Adopter et étendre"
template: docs
taxonomy:
    category: [docs]
---

## Ajouter un site déjà servi par `ansible-role-grav-site` seul

Ce n'est **pas** une migration : c'est l'ajout d'un site neuf au parc.
Procédure directe : ajouter l'hôte à l'inventaire, sa définition à
`grav_sites`, ses secrets au vault, puis `make validate` → `make
preflight` → `make deploy`.

## Migrer un ancien profil `ansible-role-grav-site` vers `grav-sites-ops`

Résumé fidèle de `docs/MIGRATION.md` (358 lignes, lu en intégralité).
**Aucun script de migration n'existe dans ce dépôt** — c'est une
procédure documentée à exécuter manuellement, avec des gates humains
explicites.

### Préconditions bloquantes (§1)

`make test-reproducible` vert, `make lint` sans faute, `make
lint-lifecycle` vert, `make test-functional` réussi au moins une fois,
et `inventories/production/` qui n'existe pas encore.

### 0. Ce qui est transféré — et ce qui ne l'est pas

Le contenu persistant (`pages`, `accounts`, `data`, `images` sous
`base_directory`) **n'est jamais recopié, déplacé ni réinitialisé** — il
reste en place sur la VM (`GSO-REQ-133`/`160`). Seul le **point de
contrôle Ansible** change.

### 1-3. Diagnostic et sauvegarde du vault (bloquant)

Le diagnostic de l'existant ne doit jamais reproduire une valeur secrète.
La sauvegarde du vault historique est **bloquante** avant toute
migration : copie chiffrée vers un chemin **hors des deux dépôts**,
permissions `600`, somme de contrôle SHA-256 avant/après (preuve
d'identité des octets, pas de validité du mot de passe), vérification de
déchiffrabilité via `ansible-vault view … >/dev/null` (sans jamais
afficher le contenu), exclusion Git confirmée (`git check-ignore`). Arrêt
immédiat si une vérification échoue.

### 4. Cartographie ancien → nouveau (table complète, GSO-REQ-133/164)

Aucune conversion implicite. Chaque champ a une destination documentée ou
est explicitement classé obsolète — un champ sans correspondance
normative impose un **arrêt et une décision humaine documentée**, jamais
une déduction automatique. Points notables :

- la clé de jointure est **l'hôte d'inventaire**, jamais un identifiant secondaire ;
- `digest` n'existait pas dans l'ancien profil — sa valeur au nouveau
  format est une **décision humaine** (référence par tag, ou digest
  vérifié épinglé) ;
- les indirections vault de l'ancien profil (`{{ vault_grav_admin_user }}`,
  etc.) sont **résolues** : la valeur réelle migre vers
  `vault_grav_sites[<hôte>]`, jamais reproduite en clair ailleurs ;
- les secrets migrent strictement en forme `name`+`content`, jamais `src` ;
- les volumes existants sont conservés en place, jamais recopiés.

### 5. Chemins structurants (GSO-REQ-176)

Six éléments ne doivent **jamais** être modifiés silencieusement par une
migration « à l'identique » — identité d'hôte, `container_name`,
`base_directory`, adresse/port d'exposition, organisation des données
persistantes, emplacement/structure du vault. En modifier un seul est une
**migration structurante distincte**, à traiter et documenter séparément.

### 6. Un site à la fois (GSO-REQ-167)

Interdiction explicite de toute forme de migration globale (boucle sur
`grav_servers`, `--limit all`, script « migrate-all »). L'acceptation
d'un site précède le début du suivant. Onze étapes par site : ajout
hôte → définition → secrets → revue du diff → `validate`+`preflight` →
`check` (la référence déployée doit déjà coïncider avec le registre —
migration ≠ mise à jour) → revue humaine → autorisation du premier
déploiement (gate humain) → déploiement de validation → vérification
post-déploiement → verdict daté consigné avant le site suivant.

### 7-9. Nouveau vault, déploiement de validation, vérification

Le nouveau vault est créé **directement chiffré** (jamais de fichier
temporaire en clair suivi ou persistant, `GSO-REQ-165`). Sa seule
existence n'est **pas** une preuve de migration réussie (`GSO-REQ-166`).
Le premier déploiement utilise **exactement** la référence déjà présente
sur la VM — ne jamais combiner migration et montée de version sans
décision explicite séparée. La vérification post-déploiement exige un
`check` en `IN_SYNC` et les quatre chemins persistants inchangés.

### 10-11. Fin de migration et autonomie (GSO-REQ-170)

La migration est terminée quand `grav-sites-ops` fonctionne **sans aucun
chemin, lien ou lecture** vers l'ancien dépôt du rôle — garantie par
`tests/l9-migration-doc-guard.sh` et `GSO-T23`. L'ancien vault est
conservé pendant une période de sécurité ; son nettoyage est une
**décision humaine distincte**, jamais intégrée à un playbook ou un
commit de migration.

### 12. Retour arrière de migration — distinct du rollback L7

Le rollback L7 change une référence d'image dans le registre puis
redéploie. Le retour arrière de **migration** est **organisationnel** :
les images et volumes de la VM restent inchangés, seul le point de
contrôle Ansible utilisé par l'opérateur change (retour à l'ancien
profil). Possible tant que l'ancien profil et sa sauvegarde sont
conservés ; aucune destruction de VM, volume ou contenu ; aucun script ne
l'applique automatiquement.

## Retirer un site du parc (procédure manuelle, voir chronologie E)

Voir [Flux chronologique, chronologie E](../04.flux-chronologique) pour la
séquence complète. Rappel essentiel : le retrait n'est **jamais**
automatisé par ce dépôt — c'est une édition manuelle du registre suivie
d'un commit Git, validée a posteriori par `gso_lifecycle.py`.

## Réactiver un site retiré

Symétrique du retrait : ajout d'un événement à
`registry/reactivated-sites.yml` référençant le retrait via
`previous_retirement`, puis réintégration manuelle de l'entrée dans
`grav_sites` et le vault. Jamais une modification de la fiche de retrait
existante.

---

```yaml
Source documentée : https://github.com/sepp67/grav-sites-ops
Référence : v1.0.0
Commit : 48b9a59b956f73f10e5602b72a222dd71b4a3f3a
Fichiers principaux : docs/MIGRATION.md (lu en intégralité), docs/LIFECYCLE-SCHEMA.md
Dernière vérification : 2026-09-14
```
