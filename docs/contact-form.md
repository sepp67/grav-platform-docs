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

## Rejet applicatif CRLF (Lot 10.1)

`contact.php` rejette explicitement, avant tout traitement, toute valeur de
`nom` ou `email` contenant un retour chariot (CR) ou un saut de ligne (LF)
— jamais `message`, où un saut de ligne est un usage légitime. Câblé sur
l'événement `onFormPrepareValidation` (`Form::process()`), qui s'exécute
avant `$this->data->validate()`/`filter()` : intervenir plus tôt que
`onFormValidationProcessed` (utilisé pour le honeypot, voir plus haut)
est nécessaire pour deux raisons vérifiées empiriquement au Lot 10.1 —
un rejet plus tardif laisserait Grav réafficher la valeur fautive dans le
formulaire (comportement standard après un échec de validation), et le
champ `email` ne serait sinon pas protégé du tout (voir plus bas). En cas
de rejet : message d'erreur générique (`Votre demande n'a pas pu être
traitée.`, identique à celui du honeypot) ; valeur fautive jamais
journalisée ; aucun envoi d'e-mail (l'exception interrompt le traitement
du formulaire avant l'étape `email` de `process`) ; champ vidé dans les
données du formulaire avant de lever l'exception, pour que le template de
réaffichage ne la reproduise pas.

**Répartition précise des responsabilités**, vérifiée au Lot 10.1 :

- **rejet CRLF explicite = ce plugin** (`rejectCrlf()`, seul point du
  système à intervenir *spécifiquement* contre l'injection d'en-tête SMTP
  via CR/LF, avant tout traitement) ;
- **validation générique du formulaire = Grav Form**, toujours active en
  aval pour tout le reste (requis, type, longueur…) — et qui, sans le
  rejet ci-dessus, aurait un comportement inégal selon le champ : le type
  `text` non multiligne (`nom`) rejette déjà nativement toute séquence
  `\R` (`Validation::typeText`, avant même que ce plugin s'exécute s'il
  n'intervenait pas plus tôt), mais le type `email`
  (`Validation::typeEmail`) commence par retirer tous les espaces
  (dont `\r`/`\n`) avant validation — il **laisserait donc passer
  silencieusement** une valeur CRLF nettoyée plutôt que de la rejeter. Le
  rejet explicite de ce plugin comble cet écart et uniformise le
  comportement entre les deux champs ;
- **échappement du corps du message = Twig**, dans
  `templates/forms/contact-email.html.twig` (auto-échappement des
  variables interpolées) — protège contre l'injection dans le corps HTML
  du message, un problème distinct de l'injection d'en-tête ;
- **protection PHPMailer = complémentaire, en aval**, dans la bibliothèque
  utilisée par le plugin Email de Grav pour l'envoi effectif — une
  protection de dernier recours, jamais celle sur laquelle ce dépôt
  s'appuie en premier lieu.

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

## Testé (voir `docs/testing.md`)

Affichage du formulaire, validation des champs requis et du honeypot,
redirection vers la confirmation, absence d'envoi réel via un SMTP factice.
**Depuis le Lot 10.1** : rejet CRLF, six cas séparés (CR, LF, CRLF × nom,
email) — voir `tests/test-contact-form.sh`.
