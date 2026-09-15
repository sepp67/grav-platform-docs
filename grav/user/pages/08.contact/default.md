---
title: Contact
template: contact
visible: false
proprietaire: admin
form:
  name: contact-form
  fields:
    nom:
      type: text
      label: Nom
      id: contact-nom
      validate:
        required: true
    email:
      type: email
      label: E-mail
      id: contact-email
      validate:
        required: true
    telephone:
      type: text
      label: Téléphone
      id: contact-telephone
    message:
      type: textarea
      label: Message
      id: contact-message
      validate:
        required: true
    honeypot:
      type: honeypot
  buttons:
    submit:
      type: submit
      value: Envoyer
  process:
    - email:
        to: "{{ proprietaire_email() }}"
        reply_to: "{{ form.value('email') }}"
        subject: "[Contact grav-platform-docs] Nouveau message de {{ form.value.nom }}"
        body: "{% include 'forms/contact-email.html.twig' %}"
    - redirect: /contact/confirmation
---

Une question sur la plateforme, un dépôt documenté ou une erreur relevée
dans cette documentation ? Utilisez le formulaire ci-dessous.

Le destinataire réel n'est jamais écrit ici : `proprietaire: admin` ci-dessus
désigne le compte Grav dont l'adresse e-mail (définie hors du dépôt) sert de
destinataire, avec repli sur `plugins.email.to` si le compte n'existe pas ou
n'a pas d'adresse. Voir `docs/contact-form.md`.
