<?php
require_once '../../includes/db_connect.php';
require_once '../../includes/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = $_POST['email'] ?? '';
    $senha = $_POST['senha'] ?? '';
    
    // TODO SEGURANÇA: Validar e sanitizar entrada
    
    if (loginUser($email, $senha, $pdo)) {
        header('Location: ../dashboard.php');
        exit;
    } else {
        header('Location: ../login.php?error=1');
        exit;
    }
} else {
    header('Location: ../login.php');
    exit;
}
?>
