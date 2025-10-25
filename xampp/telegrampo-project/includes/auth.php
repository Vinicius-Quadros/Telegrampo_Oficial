<?php
/**
 * Funções de autenticação e controle de sessão
 */

// Inicia sessão se ainda não estiver iniciada
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/**
 * Verifica se usuário está logado
 */
function isLoggedIn() {
    return isset($_SESSION['user_id']) && isset($_SESSION['user_type']);
}

/**
 * Verifica se usuário é administrador
 */
function isAdmin() {
    return isLoggedIn() && $_SESSION['user_type'] === 'A';
}

/**
 * Redireciona para login se não estiver autenticado
 */
function requireLogin() {
    if (!isLoggedIn()) {
        header('Location: login.php');
        exit;
    }
}

/**
 * Redireciona para dashboard se não for admin
 */
function requireAdmin() {
    requireLogin();
    if (!isAdmin()) {
        header('Location: dashboard.php');
        exit;
    }
}

/**
 * Faz login do usuário
 * SEGURANÇA: Sem hash de senha (conforme solicitado) - EM PRODUÇÃO USE password_hash()
 */
function loginUser($email, $senha, $pdo) {
    // TODO SEGURANÇA: Use prepared statements para evitar SQL Injection
    $stmt = $pdo->prepare("SELECT id, nome, email, tipo_usuario FROM usuarios WHERE email = ? AND senha = ?");
    $stmt->execute([$email, $senha]);
    $user = $stmt->fetch();
    
    if ($user) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['user_name'] = $user['nome'];
        $_SESSION['user_email'] = $user['email'];
        $_SESSION['user_type'] = $user['tipo_usuario'];
        return true;
    }
    return false;
}

/**
 * Faz logout do usuário
 */
function logoutUser() {
    session_unset();
    session_destroy();
    header('Location: login.php');
    exit;
}

/**
 * Registra novo usuário
 * SEGURANÇA: Sem validação rigorosa (conforme solicitado)
 */
function registerUser($nome, $email, $senha, $telefone, $tipo_usuario, $pdo) {
    // TODO SEGURANÇA: Validar dados de entrada
    // TODO SEGURANÇA: Use password_hash() para senha
    $stmt = $pdo->prepare("INSERT INTO usuarios (nome, email, senha, telefone, tipo_usuario) VALUES (?, ?, ?, ?, ?)");
    return $stmt->execute([$nome, $email, $senha, $telefone, $tipo_usuario]);
}
?>
