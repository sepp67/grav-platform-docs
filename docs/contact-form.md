# Formulaire de contact

Reprend le mécanisme fonctionnel du formulaire de `projet-lavallee-website`
(cahier §10), audité au commit `c4341ca77270565969e1e801e11a8fda72e5b402`
(voir `docs/documentation-sources.yml`), adapté visuellement à Learn2.

## Audit de compatibilité avant réutilisation

`grav/user/plugins/contact/contact.php` de `projet-lavallee-website` :

- utilise l'API de plugin standard de Grav (`Plugin`, `getSubscribedEvents`,
  événements `onPluginsInitialized`, `onTwigInitialized`,
  `onFormValidationProcessed`) — compatible avec Grav 2.0.11 fourni par
  `grav-runtime:1.0.4`, sans dépendance à une fonctionnalité propre au site
  lavallee.tech (thème, langue, routes) ;
- ne dépend d'aucun plugin tiers autre que le système de formulaires natif
  de Grav ;
- aucune syntaxe PHP incompatible avec PHP 8.3 constatée (typage des
  méthodes, promotion de propriétés non utilisée mais non requise).

**Conclusion : réutilisable tel quel.** La logique métier est reprise à
l'identique ; seuls les gabarits Twig et le CSS sont propres à
`grav-platform-docs` (cahier §10 : « Réutiliser la logique métier ; créer
les templates Twig et le CSS propres au site »).

## Contrat fonctionnel repris

- page Grav portant `form.name: contact-form` (`grav/user/pages/08.contact/default.md`) ;
- champs `nom`, `email`, `telephone` (facultatif), `message`, `honeypot` ;
- validation des champs obligatoires (`nom`, `email`, `message`) côté Grav ;
- honeypot rejeté silencieusement par `onFormValidationProcessed` (`contact.php`) ;
- `reply_to` dérivé de l'adresse saisie dans le champ `email` ;
- corps du message rendu par `templates/forms/contact-email.html.twig`,
  propre à `grav-platform-docs` ;
- redirection vers `/contact/confirmation` après envoi ;
- destinataire résolu par `proprietaire_email()` à partir du compte Grav
  désigné par la clé `proprietaire` du frontmatter de la page (`admin` par
  défaut), avec repli sur `plugins.email.to` si le compte n'existe pas ou
  n'a pas d'adresse — jamais d'adresse en clair dans une page versionnée.

## Secrets

Les paramètres SMTP sensibles (hôte, port, identifiants) sont lus depuis
`user/config/email-private.php`, chargé par `contact.php` s'il existe
(`loadEmailPrivateConfig()`). Ce fichier n'est jamais commité
(`.gitignore`) et n'est jamais construit dans l'image (`.dockerignore`) : il
sera injecté au déploiement, comme pour `projet-lavallee-website` et
`projet-gites`.

## Adresses non secrètes provisoires

`grav/user/config/plugins/email.yaml` contient des adresses non secrètes
(`from`, `from_name`, `to` de repli) — pas des secrets, mais une décision
opérationnelle. Contrairement à `projet-lavallee-website`
(`contact@lavallee.tech`), ce dépôt utilise provisoirement
`contact@example.invalid` (domaine réservé RFC 2606, non fonctionnel).
L'adresse opérationnelle définitive de `grav-platform-docs` est une décision
humaine ultérieure, non prise à ce stade.

## Anti-spam

Protection minimale par honeypot uniquement (champ `honeypot`, rejeté s'il
est rempli). Identique au mécanisme de `projet-lavallee-website` ; aucune
protection supplémentaire (CAPTCHA, limitation de débit) n'a été ajoutée,
conformément à la portée du cahier (§10 : « protection minimale anti-spam
par honeypot »).

## Journalisation

Aucun code de ce plugin n'écrit le contenu du message ou les secrets SMTP
dans un journal (aucun appel à une fonction de log dans `contact.php`). Les
journaux Nginx/PHP-FPM génériques de `grav-runtime` ne sont pas modifiés par
ce dépôt.

## Ce qui reste à tester (voir `docs/testing.md`)

Affichage du formulaire, validation des champs requis et du honeypot,
redirection vers la confirmation, absence d'envoi réel via un SMTP factice.
