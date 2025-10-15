<?php
/**
 * Arquivo de logout universal
 * Coloque este arquivo na pasta raiz do projeto
 */

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Limpar todas as variáveis de sessão
session_unset();

// Destruir a sessão
session_destroy();

// Redirecionar para a página de login com mensagem de sucesso
header('Location: login.php?success=logout');
exit;
?>