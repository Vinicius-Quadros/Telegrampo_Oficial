<?php
// ========================================
// API PARA OBTER NOTIFICAÇÕES PENDENTES
// api/obter_notificacoes.php
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

// Buscar ID do dispositivo
$sql = "SELECT id, usuario_id FROM dispositivos WHERE device_id = ? AND status = 'ativo' LIMIT 1";
$result = $db->query($sql, [$device_id], 's');

if (!$result || mysqli_num_rows($result) === 0) {
    $db->sendError("Dispositivo não encontrado");
    exit;
}

$dispositivo = mysqli_fetch_assoc($result);
$dispositivo_id = $dispositivo['id'];
$usuario_id = $dispositivo['usuario_id'];

// Buscar notificações pendentes
$sql = "SELECT 
            n.id,
            n.tipo,
            n.mensagem,
            n.criado_em,
            u.chat_id,
            u.nome AS usuario_nome
        FROM notificacoes n
        JOIN usuarios u ON n.usuario_id = u.id
        WHERE n.dispositivo_id = ? 
            AND n.enviado = FALSE
            AND u.chat_id IS NOT NULL
        ORDER BY n.criado_em ASC";

$result = $db->query($sql, [$dispositivo_id], 'i');

$notificacoes = [];
if ($result && mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        $notificacoes[] = [
            'id' => $row['id'],
            'tipo' => $row['tipo'],
            'mensagem' => $row['mensagem'],
            'chat_id' => $row['chat_id'],
            'usuario_nome' => $row['usuario_nome'],
            'criado_em' => $row['criado_em']
        ];
    }
}

// Obter configuração do bot
$sql = "SELECT telegram_bot_token FROM configuracoes WHERE dispositivo_id = ? LIMIT 1";
$result = $db->query($sql, [$dispositivo_id], 'i');
$bot_token = null;

if ($result && mysqli_num_rows($result) > 0) {
    $config = mysqli_fetch_assoc($result);
    $bot_token = $config['telegram_bot_token'];
}

$db->sendSuccess([
    'notificacoes' => $notificacoes,
    'total' => count($notificacoes),
    'bot_token' => $bot_token
], "Notificações obtidas com sucesso");
?>