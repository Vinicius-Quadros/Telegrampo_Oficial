<?php
require_once '../../includes/auth.php';
requireAdmin();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $dados = [
        'nome' => sanitize($_POST['nome']),
        'cpf' => preg_replace('/[^0-9]/', '', $_POST['cpf']),
        'celular' => sanitize($_POST['celular']),
        'email' => sanitize($_POST['email']),
        'senha' => $_POST['senha'],
        'data_nascimento' => $_POST['data_nascimento'],
        'tipo_usuario' => $_POST['tipo_usuario']
    ];
    
    // Validações
    if (empty($dados['nome']) || empty($dados['cpf']) || empty($dados['celular']) || 
        empty($dados['email']) || empty($dados['senha']) || empty($dados['data_nascimento'])) {
        header('Location: ../dashboard.php?error=campos_obrigatorios');
        exit;
    }
    
    if (!validateCPF($dados['cpf'])) {
        header('Location: ../dashboard.php?error=cpf_invalido');
        exit;
    }
    
    if (!validateEmail($dados['email'])) {
        header('Location: ../dashboard.php?error=email_invalido');
        exit;
    }
    
    if (strlen($dados['senha']) < 6) {
        header('Location: ../dashboard.php?error=senha_fraca');
        exit;
    }
    
    if (!in_array($dados['tipo_usuario'], ['A', 'C'])) {
        header('Location: ../dashboard.php?error=tipo_invalido');
        exit;
    }
    
    // Registrar usuário
    $result = registerUser($dados);
    
    if ($result['success']) {
        header('Location: ../dashboard.php?success=added');
    } else {
        header('Location: ../dashboard.php?error=' . urlencode($result['message']));
    }
    exit;
} else {
    header('Location: ../dashboard.php');
    exit;
}
?>