<?php

namespace Grav\Plugin;

use Grav\Common\Data\ValidationException;
use Grav\Common\Plugin;
use RocketTheme\Toolbox\Event\Event;

class ContactPlugin extends Plugin
{
    public static function getSubscribedEvents(): array
    {
        return [
            'onPluginsInitialized' => ['onPluginsInitialized', 0],
        ];
    }

    public function onPluginsInitialized(): void
    {
        $this->loadEmailPrivateConfig();

        $this->enable([
            'onTwigInitialized' => ['onTwigInitialized', 0],
            'onFormPrepareValidation' => ['onFormPrepareValidation', 0],
            'onFormValidationProcessed' => ['onFormValidationProcessed', 0],
        ]);
    }

    /**
     * Rejet CRLF explicite du plugin contact (Lot 10.1, section E).
     *
     * Volontairement câblé sur onFormPrepareValidation — le seul événement
     * de Form qui s'exécute avant $this->data->validate()/filter() (voir
     * classes/Form.php) — et non sur onFormValidationProcessed : le champ
     * "nom" (type: text, non multiline) fait déjà l'objet d'une règle
     * intégrée à Grav (Validation::typeText, `\R` sur texte non multiligne)
     * qui rejetterait un CR/LF de toute façon, mais seulement une fois
     * validate() déjà passé — trop tard pour empêcher le réaffichage de la
     * valeur fautive dans le formulaire (comportement standard de Form
     * après un échec de validation). En interceptant plus tôt, ce rejet
     * s'applique identiquement aux deux champs, y compris "email" — que
     * Grav ne rejette pas de lui-même : typeEmail retire les espaces
     * (dont \r\n) avant validation, donc laisse passer silencieusement une
     * valeur CRLF nettoyée plutôt que de la rejeter.
     */
    public function onFormPrepareValidation(Event $event): void
    {
        $form = $event['form'];
        if ($form->getName() !== 'contact-form') {
            return;
        }

        $this->rejectCrlf($form, 'nom');
        $this->rejectCrlf($form, 'email');
    }

    public function onFormValidationProcessed(Event $event): void
    {
        $form = $event['form'];
        if ($form->getName() !== 'contact-form') {
            return;
        }

        if ($form->value('honeypot')) {
            throw new ValidationException('Votre demande n\'a pas pu être traitée.');
        }
    }

    /**
     * Rejette explicitement, avant tout traitement, une valeur de champ
     * contenant un retour chariot (CR) ou un saut de ligne (LF).
     * Volontairement limité à nom/email — jamais message, où un saut de
     * ligne est un usage légitime : ce sont nom et email qui peuvent se
     * retrouver recopiés dans des en-têtes SMTP (From, Reply-To, sujet),
     * là où une injection CR/LF permettrait d'ajouter des en-têtes
     * arbitraires (Bcc, Cc, etc.). Complémentaire, jamais redondant, avec :
     * la validation générique du formulaire (Grav Form, sur required/type,
     * toujours active en aval pour tout ce que ce contrôle ne couvre pas) ;
     * l'échappement du corps du message par Twig
     * (forms/contact-email.html.twig) ; la protection propre à PHPMailer en
     * aval. Message volontairement générique : la valeur fautive n'est ni
     * journalisée, ni transmise à un envoi d'e-mail (l'exception interrompt
     * le traitement du formulaire avant l'étape email), ni réaffichée — le
     * champ est vidé dans les données du formulaire avant de lever
     * l'exception, pour que le template de réaffichage ne la reproduise
     * pas.
     */
    private function rejectCrlf(mixed $form, string $field): void
    {
        $value = $form->value($field);
        if (is_string($value) && preg_match('/[\r\n]/', $value) === 1) {
            $form->setData($field, '');
            throw new ValidationException('Votre demande n\'a pas pu être traitée.');
        }
    }

    public function onTwigInitialized(): void
    {
        $this->grav['twig']->twig()->addFunction(
            new \Twig\TwigFunction('proprietaire_email', [$this, 'resolveProprietaireEmail'])
        );
    }

    /**
     * Résout l'adresse e-mail réelle du destinataire à partir du compte Grav
     * désigné par la clé "proprietaire" du frontmatter de la page portant le
     * formulaire (par défaut "/contact") — jamais une adresse en clair dans
     * un fichier versionné. Mécanisme repris à l'identique de
     * projet-lavallee-website (lui-même une simplification du mécanisme de
     * projet-gites) — voir docs/contact-form.md.
     */
    public function resolveProprietaireEmail(?string $route = null): ?string
    {
        $fallback = $this->grav['config']->get('plugins.email.to');

        $page = $this->grav['pages']->find($route ?? '/contact');
        if (!$page) {
            return $fallback;
        }

        $header = (array) $page->header();
        $username = $header['proprietaire'] ?? null;
        if (!$username) {
            return $fallback;
        }

        $user = $this->grav['accounts']->load($username);
        if (!$user->exists()) {
            return $fallback;
        }

        return $user['email'] ?? $fallback;
    }

    private function loadEmailPrivateConfig(): void
    {
        $path = $this->grav['locator']->findResource('user://config/email-private.php');
        if (!$path || !file_exists($path)) {
            return;
        }

        $credentials = require $path;
        if (!is_array($credentials)) {
            return;
        }

        $config = $this->grav['config'];
        foreach ($credentials as $key => $value) {
            $config->set("plugins.email.mailer.smtp.{$key}", $value);
        }
    }
}
