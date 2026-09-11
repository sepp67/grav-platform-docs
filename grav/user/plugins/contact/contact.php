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
            'onFormValidationProcessed' => ['onFormValidationProcessed', 0],
        ]);
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
