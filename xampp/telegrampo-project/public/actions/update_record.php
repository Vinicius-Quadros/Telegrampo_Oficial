<?php
require_once '../../includes/db_connect.php';
require_once '../../includes/auth.php';

requireAdmin();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $table = $_POST['table'] ?? '';
    $id = $_POST['id'] ?? '';
    
    // Lista de tabelas permitidas (segurança)
    $allowedTables = [
        'usuarios', 'dispositivos', 'configuracoes', 
        'leituras_dht22', 'leituras_umidade_roupa', 
        'notificacoes', 'logs_sistema'
    ];
    
    if (!in_array($table, $allowedTables)) {
        die('Tabela não permitida');
    }
    
    // TODO SEGURANÇA: Validar e sanitizar todos os campos
    
    // Remover campos não editáveis
    unset($_POST['table']);
    unset($_POST['id']);
    
    // Construir query de UPDATE
    $fields = [];
    $values = [];
    
    foreach ($_POST as $field => $value) {
        $fields[] = "$field = ?";
        $values[] = $value;
    }
    
    $values[] = $id;
    
    $query = "UPDATE $table SET " . implode(', ', $fields) . " WHERE id = ?";
    
    try {
        $stmt = $pdo->prepare($query);
        $stmt->execute($values);
        
        header("Location: ../admin.php?table=$table&success=updated");
        exit;
    } catch (Exception $e) {
        header("Location: ../admin.php?table=$table&error=update");
        exit;
    }
} else {
    header('Location: ../admin.php');
    exit;
}
?>
