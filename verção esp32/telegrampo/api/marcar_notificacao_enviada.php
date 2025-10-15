<?php
// ========================================
// API PARA MARCAR NOTIFICAÇÃO COMO ENVIADA
// api/marcar_notificacao_enviada.php
// ========================================

require_once 'config.php';

// Permitir apenas POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $db = new Database();
    $db->sendError("Método não permitido. Use POST.", 405);
    exit;
}

$db = new Database();

// Obter dados
$notificacao_id = isset($_POST['notificacao_id']) ? intval($_POST['notificacao_id']) : null;
$device_id = getDeviceId();

if (!$notificacao_id) {
    $db->sendError("notificacao_id não fornecido");
    exit;
}

if (!$device_id || !validarDeviceId($device_id)) {
    $db->sendError("device_id inválido ou não fornecido");
    exit;
}

// Verificar se a notificação pertence ao dispositivo
$sql = "SELECT n.id 
        FROM notificacoes n
        JOIN dispositivos d ON n.dispositivo_id = d.id
        WHERE n.id = ? AND d.device_id = ?
        LIMIT 1";

$result = $db->query($sql, [$notificacao_id, $device_id], 'is');

if (!$result || mysqli_num_rows($result) === 0) {
    $db->sendError("Notificação não encontrada ou não pertence a este dispositivo");
    exit;
}

// Marcar como enviada
$sql = "UPDATE notificacoes 
        SET enviado = TRUE, enviado_em = NOW() 
        WHERE id = ?";

$stmt = mysqli_prepare($db->getConnection(), $sql);
mysqli_stmt_bind_param($stmt, 'i', $notificacao_id);

if (mysqli_stmt_execute($stmt)) {
    mysqli_stmt_close($stmt);
    $db->sendSuccess(['notificacao_id' => $notificacao_id], "Notificação marcada como enviada");
} else {
    mysqli_stmt_close($stmt);
    $db->sendError("Erro ao marcar notificação como enviada");
}
?>