<?php
require_once '../../includes/db_connect.php';
require_once '../../includes/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nome = $_POST['nome'] ?? '';
    $email = $_POST['email'] ?? '';
    $senha = $_POST['senha'] ?? '';
    $telefone = $_POST['telefone'] ?? null;
    $tipo_usuario = $_POST['tipo_usuario'] ?? 'C';
    
    // TODO SEGURANÇA: Validar e sanitizar entrada
    // TODO SEGURANÇA: Verificar força da senha
    
    // Verifica se email já existe
    $stmt = $pdo->prepare("SELECT id FROM usuarios WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        header('Location: ../register.php?error=exists');
        exit;
    }
    
    try {
        if (registerUser($nome, $email, $senha, $telefone, $tipo_usuario, $pdo)) {
            header('Location: ../login.php?registered=1');
            exit;
        } else {
            header('Location: ../register.php?error=1');
            exit;
        }
    } catch (Exception $e) {
        header('Location: ../register.php?error=1');
        exit;
    }
} else {
    header('Location: ../register.php');
    exit;
}
?>
