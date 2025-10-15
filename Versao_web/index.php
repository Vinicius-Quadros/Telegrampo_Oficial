<?php
require_once 'includes/auth.php';

// Se já estiver logado, redirecionar para o dashboard apropriado
if (isLoggedIn()) {
    redirectByUserType();
} else {
    // Caso contrário, redirecionar para login
    header('Location: login.php');
    exit;
}
?>
<!DOCTYPE html>