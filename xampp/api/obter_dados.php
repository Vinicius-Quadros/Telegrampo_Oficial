<?php
// ========================================
// API PARA OBTER DADOS DOS SENSORES
// api/obter_dados.php
// ========================================

require_once 'config.php';

// Permitir apenas GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    $db = new Database();
    $db->sendError("Método não permitido. Use GET.", 405);
    exit;
}

$db = new Database();

// Obter device_id
$device_id = getDeviceId();

if (!$device_id || !validarDeviceId($device_id)) {
    $db->sendError("device_id inválido ou não fornecido");
    exit;
}

// Buscar dados do dispositivo e última leitura
$sql = "SELECT 
            d.id,
            d.nome,
            d.localizacao,
            d.device_id,
            d.status AS dispositivo_status,
            u.nome AS usuario_nome,
            u.chat_id,
            c.limiar_umidade_seca,
            c.intervalo_leitura
        FROM dispositivos d
        LEFT JOIN usuarios u ON d.usuario_id = u.id
        LEFT JOIN configuracoes c ON d.id = c.dispositivo_id
        WHERE d.device_id = ? AND d.status = 'ativo'
        LIMIT 1";

$result = $db->query($sql, [$device_id], 's');

if (!$result || mysqli_num_rows($result) === 0) {
    $db->sendError("Dispositivo não encontrado");
    exit;
}

$dispositivo = mysqli_fetch_assoc($result);
$dispositivo_id = $dispositivo['id'];

// Buscar última leitura do DHT22
$sql = "SELECT temperatura, umidade_ar, lido_em 
        FROM leituras_dht22 
        WHERE dispositivo_id = ? 
        ORDER BY id DESC 
        LIMIT 1";

$result = $db->query($sql, [$dispositivo_id], 'i');
$dht22 = ($result && mysqli_num_rows($result) > 0) 
    ? mysqli_fetch_assoc($result) 
    : ['temperatura' => null, 'umidade_ar' => null, 'lido_em' => null];

// Buscar última leitura de umidade da roupa
$sql = "SELECT valor_bruto, umidade_percentual, status_roupa, lido_em 
        FROM leituras_umidade_roupa 
        WHERE dispositivo_id = ? 
        ORDER BY id DESC 
        LIMIT 1";

$result = $db->query($sql, [$dispositivo_id], 'i');
$umidade_roupa = ($result && mysqli_num_rows($result) > 0) 
    ? mysqli_fetch_assoc($result) 
    : ['valor_bruto' => null, 'umidade_percentual' => null, 'status_roupa' => 'Desconhecido', 'lido_em' => null];

// Montar resposta
$response = [
    'dispositivo' => [
        'id' => $dispositivo['id'],
        'nome' => $dispositivo['nome'],
        'localizacao' => $dispositivo['localizacao'],
        'device_id' => $dispositivo['device_id'],
        'status' => $dispositivo['dispositivo_status']
    ],
    'usuario' => [
        'nome' => $dispositivo['usuario_nome'],
        'chat_id' => $dispositivo['chat_id']
    ],
    'configuracoes' => [
        'limiar_umidade_seca' => intval($dispositivo['limiar_umidade_seca']),
        'intervalo_leitura' => intval($dispositivo['intervalo_leitura'])
    ],
    'leituras' => [
        'temperatura' => $dht22['temperatura'] !== null ? floatval($dht22['temperatura']) : null,
        'umidade_ar' => $dht22['umidade_ar'] !== null ? floatval($dht22['umidade_ar']) : null,
        'umidade_roupa' => $umidade_roupa['umidade_percentual'] !== null ? intval($umidade_roupa['umidade_percentual']) : null,
        'status_roupa' => $umidade_roupa['status_roupa'],
        'valor_bruto' => $umidade_roupa['valor_bruto'],
        'ultima_leitura_ambiente' => $dht22['lido_em'],
        'ultima_leitura_roupa' => $umidade_roupa['lido_em']
    ],
    'chuva' => false // Será implementado quando adicionar sensor de chuva
];

$db->sendSuccess($response, "Dados obtidos com sucesso");
?>