<?php
// Fixture de test UNIQUEMENT — SMTP factice (Mailpit) sur le réseau Docker
// de test. Aucun identifiant, hôte ou destinataire réel. Jamais commité
// dans une image (voir .dockerignore, .gitignore).
return [
    'server' => 'mailpit',
    'port' => 1025,
    'encryption' => 'none',
    'user' => '',
    'password' => '',
];
