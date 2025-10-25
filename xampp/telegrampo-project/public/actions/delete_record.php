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
    
    // TODO SEGURANÇA: Validar ID
    // TODO: Verificar se o registro pode ser excluído (integridade referencial)
    
    try {
        $stmt = $pdo->prepare("DELETE FROM $table WHERE id = ?");
        $stmt->execute([$id]);
        
        header("Location: ../admin.php?table=$table&success=deleted");
        exit;
    } catch (Exception $e) {
        // Provavelmente erro de integridade referencial
        header("Location: ../admin.php?table=$table&error=foreign_key");
        exit;
    }
} else {
    header('Location: ../admin.php');
    exit;
}
?>
