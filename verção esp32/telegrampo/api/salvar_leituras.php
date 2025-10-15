<?php
// ========================================
// API PARA SALVAR LEITURAS DOS SENSORES
// api/salvar_leituras.php
// ========================================

require_once 'config.php';

// Verificar método HTTP
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $db = new Database();
    $db->sendError("Método não permitido. Use POST.", 405);
    exit;
}

$db = new Database();

// Obter dados da requisição
$device_id = getDeviceId();
$temperatura = isset($_POST['temperatura']) ? floatval($_POST['temperatura']) : null;
$umidade_ar = isset($_POST['umidade_ar']) ? floatval($_POST['umidade_ar']) : null;
$valor_bruto = isset($_POST['valor_bruto']) ? intval($_POST['valor_bruto']) : null;
$umidade_percentual = isset($_POST['umidade_percentual']) ? intval($_POST['umidade_percentual']) : null;

// Validar dados obrigatórios
if (!$device_id || !validarDeviceId($device_id)) {
    $db->sendError("device_id inválido ou não fornecido");
    exit;
}

// Buscar ID do dispositivo
$sql = "SELECT id, usuario_id FROM dispositivos WHERE device_id = ? AND status = 'ativo' LIMIT 1";
$result = $db->query($sql, [$device_id], 's');

if (!$result || mysqli_num_rows($result) === 0) {
    $db->sendError("Dispositivo não encontrado ou inativo");
    exit;
}

$dispositivo = mysqli_fetch_assoc($result);
$dispositivo_id = $dispositivo['id'];
$usuario_id = $dispositivo['usuario_id'];

// Obter limiar de umidade para considerar roupa seca
$sql = "SELECT limiar_umidade_seca FROM configuracoes WHERE dispositivo_id = ? LIMIT 1";
$result = $db->query($sql, [$dispositivo_id], 'i');
$limiar = 30; // Valor padrão

if ($result && mysqli_num_rows($result) > 0) {
    $config = mysqli_fetch_assoc($result);
    $limiar = $config['limiar_umidade_seca'];
}

$leituras_salvas = [];

// 1. Salvar leitura do DHT22 (Temperatura e Umidade do Ar)
if ($temperatura !== null && $umidade_ar !== null) {
    $sql = "INSERT INTO leituras_dht22 (dispositivo_id, temperatura, umidade_ar) 
            VALUES (?, ?, ?)";
    
    $id = $db->insert($sql, [$dispositivo_id, $temperatura, $umidade_ar], 'idd');
    
    if ($id) {
        $leituras_salvas['dht22'] = [
            'id' => $id,
            'temperatura' => $temperatura,
            'umidade_ar' => $umidade_ar
        ];
    }
}

// 2. Salvar leitura do Sensor de Umidade da Roupa
if ($valor_bruto !== null && $umidade_percentual !== null) {
    // Determinar status da roupa baseado no limiar
    $status_roupa = ($umidade_percentual <= $limiar) ? 'Seca' : 'Úmida';
    
    $sql = "INSERT INTO leituras_umidade_roupa 
            (dispositivo_id, valor_bruto, umidade_percentual, status_roupa) 
            VALUES (?, ?, ?, ?)";
    
    $id = $db->insert($sql, [$dispositivo_id, $valor_bruto, $umidade_percentual, $status_roupa], 'iiis');
    
    if ($id) {
        $leituras_salvas['umidade_roupa'] = [
            'id' => $id,
            'valor_bruto' => $valor_bruto,
            'umidade_percentual' => $umidade_percentual,
            'status_roupa' => $status_roupa
        ];
        
        // Se roupa está seca, verificar se precisa criar notificação
        if ($status_roupa === 'Seca') {
            // O trigger do banco já cria a notificação automaticamente
            // Aqui apenas registramos no log
            $sql = "INSERT INTO logs_sistema (dispositivo_id, tipo, mensagem) 
                    VALUES (?, 'roupa_seca', 'Roupa detectada como seca')";
            $db->query($sql, [$dispositivo_id], 'i');
        }
    }
}

// Verificar se salvou pelo menos uma leitura
if (empty($leituras_salvas)) {
    $db->sendError("Nenhum dado válido fornecido para salvar");
    exit;
}

// Registrar log de sucesso
$sql = "INSERT INTO logs_sistema (dispositivo_id, tipo, mensagem) 
        VALUES (?, 'leitura_salva', 'Leituras salvas com sucesso')";
$db->query($sql, [$dispositivo_id], 'i');

// Retornar sucesso
$db->sendSuccess($leituras_salvas, "Leituras salvas com sucesso");
?>