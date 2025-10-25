<?php
require_once '../includes/db_connect.php';
require_once '../includes/auth.php';

requireLogin();

$pageTitle = 'Dashboard - TeleGrampo';

// Buscar estatísticas gerais
$stmt = $pdo->query("SELECT COUNT(*) as total FROM dispositivos");
$totalDispositivos = $stmt->fetch()['total'];

$stmt = $pdo->query("SELECT COUNT(*) as total FROM dispositivos WHERE status = 'ativo'");
$dispositivosAtivos = $stmt->fetch()['total'];

$stmt = $pdo->query("SELECT COUNT(*) as total FROM logs_sistema WHERE criado_em >= NOW() - INTERVAL 1 HOUR");
$logsRecentes = $stmt->fetch()['total'];

$stmt = $pdo->query("SELECT COUNT(*) as total FROM notificacoes WHERE enviado = 0");
$notificacoesPendentes = $stmt->fetch()['total'];

// Última leitura
$stmt = $pdo->query("SELECT * FROM vw_ultima_leitura LIMIT 1");
$ultimaLeitura = $stmt->fetch();

include '../includes/header.php';
?>

<div class="row">
    <div class="col-12">
        <h2 class="mb-4">
            <i class="fas fa-chart-line"></i> Dashboard
            <small class="text-muted">Monitoramento em Tempo Real</small>
        </h2>
    </div>
</div>

<!-- Cards de Estatísticas -->
<div class="row mb-4">
    <div class="col-md-3 mb-3">
        <div class="card border-primary">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="card-subtitle mb-2 text-muted">Total Dispositivos</h6>
                        <h2 class="card-title mb-0"><?php echo $totalDispositivos; ?></h2>
                    </div>
                    <div class="text-primary">
                        <i class="fas fa-microchip fa-3x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3 mb-3">
        <div class="card border-success">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="card-subtitle mb-2 text-muted">Dispositivos Ativos</h6>
                        <h2 class="card-title mb-0 text-success"><?php echo $dispositivosAtivos; ?></h2>
                    </div>
                    <div class="text-success">
                        <i class="fas fa-check-circle fa-3x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3 mb-3">
        <div class="card border-warning">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="card-subtitle mb-2 text-muted">Logs (1h)</h6>
                        <h2 class="card-title mb-0 text-warning"><?php echo $logsRecentes; ?></h2>
                    </div>
                    <div class="text-warning">
                        <i class="fas fa-list fa-3x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3 mb-3">
        <div class="card border-danger">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="card-subtitle mb-2 text-muted">Notificações</h6>
                        <h2 class="card-title mb-0 text-danger"><?php echo $notificacoesPendentes; ?></h2>
                    </div>
                    <div class="text-danger">
                        <i class="fas fa-bell fa-3x"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Última Leitura -->
<?php if ($ultimaLeitura): ?>
<div class="row mb-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header bg-info text-white">
                <h5 class="mb-0"><i class="fas fa-info-circle"></i> Última Leitura</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3">
                        <strong>Dispositivo:</strong><br>
                        <?php echo htmlspecialchars($ultimaLeitura['dispositivo_nome']); ?>
                    </div>
                    <div class="col-md-3">
                        <strong>Temperatura:</strong><br>
                        <span class="badge bg-danger"><?php echo number_format($ultimaLeitura['temperatura'], 1); ?>°C</span>
                    </div>
                    <div class="col-md-3">
                        <strong>Umidade do Ar:</strong><br>
                        <span class="badge bg-primary"><?php echo number_format($ultimaLeitura['umidade_ar'], 1); ?>%</span>
                    </div>
                    <div class="col-md-3">
                        <strong>Status da Roupa:</strong><br>
                        <?php
                        $statusClass = $ultimaLeitura['status_roupa'] === 'Seca' ? 'success' : 'warning';
                        ?>
                        <span class="badge bg-<?php echo $statusClass; ?>">
                            <?php echo htmlspecialchars($ultimaLeitura['status_roupa']); ?> 
                            (<?php echo $ultimaLeitura['umidade_percentual']; ?>%)
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>

<!-- Gráficos -->
<div class="row mb-4">
    <div class="col-md-6 mb-3">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="fas fa-thermometer-half"></i> Temperatura (Última Hora)</h5>
            </div>
            <div class="card-body">
                <canvas id="chartTemperatura"></canvas>
            </div>
        </div>
    </div>
    
    <div class="col-md-6 mb-3">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="fas fa-tint"></i> Umidade do Ar (Última Hora)</h5>
            </div>
            <div class="card-body">
                <canvas id="chartUmidadeAr"></canvas>
            </div>
        </div>
    </div>
</div>

<div class="row mb-4">
    <div class="col-md-12 mb-3">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="fas fa-tshirt"></i> Umidade da Roupa (Última Hora)</h5>
            </div>
            <div class="card-body">
                <canvas id="chartUmidadeRoupa"></canvas>
            </div>
        </div>
    </div>
</div>

<!-- Info de Auto-refresh -->
<div class="row">
    <div class="col-12">
        <div class="alert alert-info d-flex justify-content-between align-items-center">
            <div>
                <i class="fas fa-sync-alt"></i> Os gráficos são atualizados automaticamente a cada 5 minutos.
                <span id="lastUpdate" class="ms-3">Última atualização: carregando...</span>
            </div>
            <button id="btnRefresh" class="btn btn-sm btn-primary" onclick="manualRefresh()">
                <i class="fas fa-sync-alt"></i> Atualizar Agora
            </button>
        </div>
    </div>
</div>

<script src="assets/js/dashboard.js"></script>

<?php include '../includes/footer.php'; ?>
