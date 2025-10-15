<?php
require_once 'auth.php';

// Fazer logout
if (isLoggedIn()) {
    // Limpar sessão
    session_unset();
    session_destroy();
    
    // Redirecionar para login com mensagem de sucesso
    header('Location: /login.php?success=logout');
    exit;
} else {
    // Se não estiver logado, redirecionar para login
    header('Location: /login.php');
    exit;
}
?>