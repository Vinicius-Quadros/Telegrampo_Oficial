<?php
require_once '../../includes/auth.php';
requireAdmin();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $dados = [
        'id_usuario' => (int)$_POST['id_usuario'],
        'nome' => sanitize($_POST['nome']),
        'localizacao' => sanitize($_POST['localizacao']),
        'modelo' => sanitize($_POST['modelo']),
        'status' => $_POST['status']
    ];
    
    // Validações
    if (empty($dados['id_usuario']) || empty($dados['nome'])) {
        header('Location: ../dashboard.php?error=campos_obrigatorios');
        exit;
    }
    
    if (!in_array($dados['status'], ['ativo', 'inativo'])) {
        header('Location: ../dashboard.php?error=status_invalido');
        exit;
    }
    
    // Verificar se o usuário existe
    $user = fetchOne("SELECT id_usuario FROM usuarios WHERE id_usuario = ?", [$dados['id_usuario']]);
    if (!$user) {
        header('Location: ../dashboard.php?error=usuario_nao_existe');
        exit;
    }
    
    // Inserir dispositivo
    $success = insertData('dispositivos', $dados);
    
    if ($success) {
        header('Location: ../dashboard.php?success=added');
    } else {
        header('Location: ../dashboard.php?error=erro_inserir');
    }
    exit;
} else {
    header('Location: ../dashboard.php');
    exit;
}
?>