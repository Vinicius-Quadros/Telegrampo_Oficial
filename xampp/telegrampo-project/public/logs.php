<?php
require_once '../includes/db_connect.php';
require_once '../includes/auth.php';

requireLogin();

$pageTitle = 'Logs do Sistema - TeleGrampo';

// Parâmetros de filtro e paginação
$dispositivo_id = $_GET['dispositivo_id'] ?? '';
$tipo = $_GET['tipo'] ?? '';
$data_inicio = $_GET['data_inicio'] ?? '';
$data_fim = $_GET['data_fim'] ?? '';
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = 20;
$offset = ($page - 1) * $limit;

// Construir query com filtros
$where = [];
$params = [];

if ($dispositivo_id) {
    $where[] = "l.dispositivo_id = ?";
    $params[] = $dispositivo_id;
}

if ($tipo) {
    $where[] = "l.tipo = ?";
    $params[] = $tipo;
}

if ($data_inicio) {
    $where[] = "l.criado_em >= ?";
    $params[] = $data_inicio . ' 00:00:00';
}

if ($data_fim) {
    $where[] = "l.criado_em <= ?";
    $params[] = $data_fim . ' 23:59:59';
}

$whereClause = $where ? 'WHERE ' . implode(' AND ', $where) : '';

// Contar total de registros
$countQuery = "SELECT COUNT(*) as total FROM logs_sistema l $whereClause";
$stmt = $pdo->prepare($countQuery);
$stmt->execute($params);
$totalLogs = $stmt->fetch()['total'];
$totalPages = ceil($totalLogs / $limit);

// Buscar logs com paginação
$query = "
    SELECT 
        l.*,
        d.nome as dispositivo_nome
    FROM logs_sistema l
    LEFT JOIN dispositivos d ON l.dispositivo_id = d.id
    $whereClause
    ORDER BY l.criado_em DESC
    LIMIT $limit OFFSET $offset
";

$stmt = $pdo->prepare($query);
$stmt->execute($params);
$logs = $stmt->fetchAll();

// Buscar dispositivos para filtro
$dispositivos = $pdo->query("SELECT id, nome FROM dispositivos ORDER BY nome")->fetchAll();

// Buscar tipos de log
$tipos = $pdo->query("SELECT DISTINCT tipo FROM logs_sistema ORDER BY tipo")->fetchAll();

include '../includes/header.php';
?>

<div class="row">
    <div class="col-12">
        <h2 class="mb-4">
            <i class="fas fa-list"></i> Logs do Sistema
        </h2>
    </div>
</div>

<!-- Filtros -->
<div class="card mb-4">
    <div class="card-header">
        <h5 class="mb-0"><i class="fas fa-filter"></i> Filtros</h5>
    </div>
    <div class="card-body">
        <form method="GET" action="logs.php" class="row g-3">
            <div class="col-md-3">
                <label for="dispositivo_id" class="form-label">Dispositivo</label>
                <select class="form-select" id="dispositivo_id" name="dispositivo_id">
                    <option value="">Todos</option>
                    <?php foreach ($dispositivos as $disp): ?>
                    <option value="<?php echo $disp['id']; ?>" 
                        <?php echo $dispositivo_id == $disp['id'] ? 'selected' : ''; ?>>
                        <?php echo htmlspecialchars($disp['nome']); ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            
            <div class="col-md-3">
                <label for="tipo" class="form-label">Tipo</label>
                <select class="form-select" id="tipo" name="tipo">
                    <option value="">Todos</option>
                    <?php foreach ($tipos as $t): ?>
                    <option value="<?php echo $t['tipo']; ?>" 
                        <?php echo $tipo == $t['tipo'] ? 'selected' : ''; ?>>
                        <?php echo htmlspecialchars($t['tipo']); ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            
            <div class="col-md-2">
                <label for="data_inicio" class="form-label">Data Início</label>
                <input type="date" class="form-control" id="data_inicio" name="data_inicio" 
                    value="<?php echo htmlspecialchars($data_inicio); ?>">
            </div>
            
            <div class="col-md-2">
                <label for="data_fim" class="form-label">Data Fim</label>
                <input type="date" class="form-control" id="data_fim" name="data_fim" 
                    value="<?php echo htmlspecialchars($data_fim); ?>">
            </div>
            
            <div class="col-md-2">
                <label class="form-label">&nbsp;</label>
                <div class="d-grid gap-2">
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-search"></i> Filtrar
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<!-- Tabela de Logs -->
<div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">Registros (Total: <?php echo $totalLogs; ?>)</h5>
        <a href="logs.php" class="btn btn-sm btn-secondary">
            <i class="fas fa-sync"></i> Limpar Filtros
        </a>
    </div>
    <div class="card-body">
        <?php if (empty($logs)): ?>
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i> Nenhum log encontrado com os filtros aplicados.
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Data/Hora</th>
                        <th>Dispositivo</th>
                        <th>Tipo</th>
                        <th>Mensagem</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($logs as $log): ?>
                    <tr>
                        <td><?php echo $log['id']; ?></td>
                        <td>
                            <small><?php echo date('d/m/Y H:i:s', strtotime($log['criado_em'])); ?></small>
                        </td>
                        <td>
                            <?php 
                            echo $log['dispositivo_nome'] ? 
                                htmlspecialchars($log['dispositivo_nome']) : 
                                '<span class="text-muted">Sistema</span>'; 
                            ?>
                        </td>
                        <td>
                            <span class="badge bg-secondary">
                                <?php echo htmlspecialchars($log['tipo']); ?>
                            </span>
                        </td>
                        <td><?php echo htmlspecialchars($log['mensagem']); ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        
        <!-- Paginação -->
        <?php if ($totalPages > 1): ?>
        <nav aria-label="Navegação de logs">
            <ul class="pagination justify-content-center">
                <li class="page-item <?php echo $page <= 1 ? 'disabled' : ''; ?>">
                    <a class="page-link" href="?page=<?php echo $page-1; ?>&dispositivo_id=<?php echo $dispositivo_id; ?>&tipo=<?php echo $tipo; ?>&data_inicio=<?php echo $data_inicio; ?>&data_fim=<?php echo $data_fim; ?>">
                        Anterior
                    </a>
                </li>
                
                <?php for ($i = max(1, $page-2); $i <= min($totalPages, $page+2); $i++): ?>
                <li class="page-item <?php echo $i == $page ? 'active' : ''; ?>">
                    <a class="page-link" href="?page=<?php echo $i; ?>&dispositivo_id=<?php echo $dispositivo_id; ?>&tipo=<?php echo $tipo; ?>&data_inicio=<?php echo $data_inicio; ?>&data_fim=<?php echo $data_fim; ?>">
                        <?php echo $i; ?>
                    </a>
                </li>
                <?php endfor; ?>
                
                <li class="page-item <?php echo $page >= $totalPages ? 'disabled' : ''; ?>">
                    <a class="page-link" href="?page=<?php echo $page+1; ?>&dispositivo_id=<?php echo $dispositivo_id; ?>&tipo=<?php echo $tipo; ?>&data_inicio=<?php echo $data_inicio; ?>&data_fim=<?php echo $data_fim; ?>">
                        Próxima
                    </a>
                </li>
            </ul>
        </nav>
        <?php endif; ?>
        <?php endif; ?>
    </div>
</div>

<?php include '../includes/footer.php'; ?>
