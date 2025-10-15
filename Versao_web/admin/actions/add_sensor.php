<?php
require_once '../../includes/auth.php';
requireAdmin();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $dados = [
        'tipo_sensor' => sanitize($_POST['tipo_sensor']),
        'unidade_medida' => sanitize($_POST['unidade_medida']),
        'descricao' => sanitize($_POST['descricao'])
    ];
    
    // Validações
    if (empty($dados['tipo_sensor']) || empty($dados['unidade_medida'])) {
        header('Location: ../dashboard.php?error=campos_obrigatorios');
        exit;
    }
    
    // Inserir sensor
    $success = insertData('sensores', $dados);
    
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