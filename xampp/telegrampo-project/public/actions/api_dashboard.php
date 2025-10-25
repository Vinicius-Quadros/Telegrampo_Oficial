<?php
require_once '../../includes/db_connect.php';
require_once '../../includes/auth.php';

requireLogin();

header('Content-Type: application/json');

try {
    // Buscar dados da última 1 hora
    // TODO SEGURANÇA: Use prepared statements
    
    // Temperatura
    $stmt = $pdo->query("
        SELECT 
            DATE_FORMAT(lido_em, '%H:%i') as horario,
            temperatura
        FROM leituras_dht22
        WHERE lido_em >= NOW() - INTERVAL 1 HOUR
        ORDER BY lido_em ASC
    ");
    $temperaturas = $stmt->fetchAll();
    
    // Umidade do ar
    $stmt = $pdo->query("
        SELECT 
            DATE_FORMAT(lido_em, '%H:%i') as horario,
            umidade_ar
        FROM leituras_dht22
        WHERE lido_em >= NOW() - INTERVAL 1 HOUR
        ORDER BY lido_em ASC
    ");
    $umidadesAr = $stmt->fetchAll();
    
    // Umidade da roupa
    $stmt = $pdo->query("
        SELECT 
            DATE_FORMAT(lido_em, '%H:%i') as horario,
            umidade_percentual,
            status_roupa
        FROM leituras_umidade_roupa
        WHERE lido_em >= NOW() - INTERVAL 1 HOUR
        ORDER BY lido_em ASC
    ");
    $umidadesRoupa = $stmt->fetchAll();
    
    // Estatísticas
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM dispositivos");
    $totalDispositivos = $stmt->fetch()['total'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM dispositivos WHERE status = 'ativo'");
    $dispositivosAtivos = $stmt->fetch()['total'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM logs_sistema WHERE criado_em >= NOW() - INTERVAL 1 HOUR");
    $logsRecentes = $stmt->fetch()['total'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM notificacoes WHERE enviado = 0");
    $notificacoesPendentes = $stmt->fetch()['total'];
    
    echo json_encode([
        'success' => true,
        'temperatura' => $temperaturas,
        'umidade_ar' => $umidadesAr,
        'umidade_roupa' => $umidadesRoupa,
        'stats' => [
            'total_dispositivos' => $totalDispositivos,
            'dispositivos_ativos' => $dispositivosAtivos,
            'logs_recentes' => $logsRecentes,
            'notificacoes_pendentes' => $notificacoesPendentes
        ],
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Erro ao buscar dados'
    ]);
}
?>
