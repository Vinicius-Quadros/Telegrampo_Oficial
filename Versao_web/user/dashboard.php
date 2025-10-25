<?php
require_once '../includes/auth.php';
requireAuth();

$current_user = getCurrentUser();
$user_id = $_SESSION['user_id'];

// Buscar dispositivos do usuário
$dispositivos = fetchAll("SELECT * FROM dispositivos WHERE id_usuario = ? ORDER BY criado_em DESC", [$user_id]);

// Buscar últimas leituras
$leituras = fetchAll("SELECT l.*, d.nome as dispositivo_nome, s.tipo_sensor, s.unidade_medida 
                      FROM leituras l 
                      JOIN dispositivos d ON l.id_dispositivo = d.id_dispositivo 
                      JOIN sensores s ON l.id_sensor = s.id_sensor 
                      WHERE d.id_usuario = ? 
                      ORDER BY l.data_hora DESC 
                      LIMIT 20", [$user_id]);

// Buscar dados para gráficos (últimas 24h)
$dados_grafico = fetchAll("SELECT l.valor, l.data_hora, s.tipo_sensor, s.unidade_medida, d.nome as dispositivo_nome
                           FROM leituras l 
                           JOIN dispositivos d ON l.id_dispositivo = d.id_dispositivo 
                           JOIN sensores s ON l.id_sensor = s.id_sensor 
                           WHERE d.id_usuario = ? 
                           AND l.data_hora >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
                           ORDER BY l.data_hora ASC", [$user_id]);

// Buscar logs do sistema (ações do usuário)
$logs = fetchAll("SELECT 'leitura' as tipo, l.data_hora, CONCAT('Nova leitura: ', s.tipo_sensor, ' = ', l.valor, s.unidade_medida, ' (', d.nome, ')') as descricao
                  FROM leituras l
                  JOIN dispositivos d ON l.id_dispositivo = d.id_dispositivo
                  JOIN sensores s ON l.id_sensor = s.id_sensor
                  WHERE d.id_usuario = ?
                  UNION ALL
                  SELECT 'dispositivo' as tipo, criado_em as data_hora, CONCAT('Dispositivo cadastrado: ', nome) as descricao
                  FROM dispositivos
                  WHERE id_usuario = ?
                  UNION ALL
                  SELECT 'notificacao' as tipo, data_hora, mensagem as descricao
                  FROM notificacoes
                  WHERE id_usuario = ?
                  ORDER BY data_hora DESC
                  LIMIT 50", [$user_id, $user_id, $user_id]);

// Estatísticas
$stats = [
    'dispositivos' => count($dispositivos),
    'ativos' => countRecords('dispositivos', 'id_usuario = ? AND status = "ativo"', [$user_id]),
    'leituras' => countRecords('leituras l JOIN dispositivos d ON l.id_dispositivo = d.id_dispositivo', 'd.id_usuario = ?', [$user_id]),
    'notificacoes' => countRecords('notificacoes', 'id_usuario = ? AND lida = 0', [$user_id])
];
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Grampo IoT</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
     <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --tg-bg: #17212b;
            --tg-bg-secondary: #242f3d;
            --tg-bg-card: #0e1621;
            --tg-text: #ffffff;
            --tg-text-secondary: #aaaaaa;
            --tg-blue: #2AABEE;
            --tg-blue-dark: #1e88cf;
            --tg-border: #2b5278;
            --tg-success: #00c853;
            --tg-warning: #ffa726;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: var(--tg-bg);
            color: var(--tg-text);
        }

        .header {
            background: var(--tg-bg-secondary);
            border-bottom: 1px solid var(--tg-border);
            padding: 16px 24px;
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .header-content {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header-title {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .header-icon {
            width: 40px;
            height: 40px;
            background: var(--tg-blue);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .header h1 {
            font-size: 20px;
            font-weight: 600;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .user-name {
            color: var(--tg-text-secondary);
            font-size: 14px;
        }

        .btn-logout {
            background: var(--tg-bg-card);
            color: var(--tg-text);
            border: 1px solid var(--tg-border);
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.2s;
            text-decoration: none;
        }

        .btn-logout:hover {
            background: var(--tg-bg);
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 24px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }

        .stat-card {
            background: var(--tg-bg-secondary);
            border: 1px solid var(--tg-border);
            border-radius: 12px;
            padding: 20px;
            transition: all 0.2s;
        }

        .stat-card:hover {
            border-color: var(--tg-blue);
            transform: translateY(-2px);
        }

        .stat-label {
            color: var(--tg-text-secondary);
            font-size: 14px;
            margin-bottom: 8px;
        }

        .stat-number {
            font-size: 32px;
            font-weight: 600;
            color: var(--tg-blue);
        }

        .tabs {
            display: flex;
            background: var(--tg-bg-secondary);
            border-radius: 12px 12px 0 0;
            border: 1px solid var(--tg-border);
            border-bottom: none;
            overflow-x: auto;
        }

        .tab-btn {
            padding: 16px 24px;
            border: none;
            background: none;
            color: var(--tg-text-secondary);
            font-size: 15px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            border-bottom: 2px solid transparent;
            white-space: nowrap;
        }

        .tab-btn.active {
            color: var(--tg-blue);
            border-bottom-color: var(--tg-blue);
        }

        .card {
            background: var(--tg-bg-secondary);
            border: 1px solid var(--tg-border);
            border-radius: 0 0 12px 12px;
            overflow: hidden;
            margin-bottom: 24px;
        }

        .card-header {
            padding: 16px 20px;
            border-bottom: 1px solid var(--tg-border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .card-title {
            font-size: 18px;
            font-weight: 600;
        }

        .card-body {
            padding: 20px;
        }

        .tab-content {
            display: none;
        }

        .tab-content.active {
            display: block;
        }

        .device-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 16px;
        }

        .device-card {
            background: var(--tg-bg-card);
            border: 1px solid var(--tg-border);
            border-radius: 10px;
            padding: 16px;
            transition: all 0.2s;
            cursor: pointer;
        }

        .device-card:hover {
            border-color: var(--tg-blue);
        }

        .device-header {
            display: flex;
            justify-content: space-between;
            align-items: start;
            margin-bottom: 12px;
        }

        .device-name {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .device-location {
            color: var(--tg-text-secondary);
            font-size: 13px;
        }

        .badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }

        .badge-active {
            background: rgba(0, 200, 83, 0.2);
            color: var(--tg-success);
        }

        .badge-inactive {
            background: rgba(255, 167, 38, 0.2);
            color: var(--tg-warning);
        }

        .reading-item {
            padding: 16px;
            border-bottom: 1px solid var(--tg-border);
            transition: background 0.2s;
        }

        .reading-item:last-child {
            border-bottom: none;
        }

        .reading-item:hover {
            background: var(--tg-bg-card);
        }

        .reading-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
        }

        .reading-device {
            font-weight: 600;
            font-size: 15px;
        }

        .reading-time {
            color: var(--tg-text-secondary);
            font-size: 13px;
        }

        .reading-data {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .reading-value {
            font-size: 24px;
            font-weight: 600;
            color: var(--tg-blue);
        }

        .reading-unit {
            color: var(--tg-text-secondary);
            font-size: 14px;
        }

        .reading-sensor {
            color: var(--tg-text-secondary);
            font-size: 13px;
        }

        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.2s;
        }

        .btn-primary {
            background: var(--tg-blue);
            color: white;
        }

        .btn-primary:hover {
            background: var(--tg-blue-dark);
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--tg-text-secondary);
        }

        .empty-icon {
            font-size: 64px;
            margin-bottom: 16px;
            opacity: 0.3;
        }

        .chart-container {
            position: relative;
            height: 400px;
            margin-bottom: 20px;
        }

        .log-item {
            padding: 12px 16px;
            border-bottom: 1px solid var(--tg-border);
            display: flex;
            gap: 12px;
            align-items: start;
            transition: background 0.2s;
        }

        .log-item:last-child {
            border-bottom: none;
        }

        .log-item:hover {
            background: var(--tg-bg-card);
        }

        .log-icon {
            width: 32px;
            height: 32px;
            background: var(--tg-bg-card);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            font-size: 16px;
        }

        .log-content {
            flex: 1;
        }

        .log-description {
            font-size: 14px;
            margin-bottom: 4px;
        }

        .log-time {
            font-size: 12px;
            color: var(--tg-text-secondary);
        }

        @media (max-width: 768px) {
            .container {
                padding: 16px;
            }

            .header-content {
                flex-direction: column;
                gap: 12px;
            }

            .stats-grid {
                grid-template-columns: 1fr;
            }

            .device-grid {
                grid-template-columns: 1fr;
            }

            .chart-container {
                height: 300px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="header-title">
                <div class="header-icon">🌡️</div>
                <h1>Meus Dispositivos</h1>
            </div>
            <div class="user-info">
                <span class="user-name"><?php echo htmlspecialchars($current_user['nome']); ?></span>
                <a href="../logout.php" class="btn-logout">Sair</a>
            </div>
        </div>
    </div>

    <div class="container">
        <!-- Estatísticas -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Dispositivos</div>
                <div class="stat-number"><?php echo $stats['dispositivos']; ?></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Ativos</div>
                <div class="stat-number"><?php echo $stats['ativos']; ?></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Leituras</div>
                <div class="stat-number"><?php echo $stats['leituras']; ?></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Notificações</div>
                <div class="stat-number"><?php echo $stats['notificacoes']; ?></div>
            </div>
        </div>

        <!-- Abas -->
        <div class="tabs">
            <button class="tab-btn active" onclick="showTab('dispositivos')">📱 Dispositivos</button>
            <button class="tab-btn" onclick="showTab('leituras')">📊 Leituras</button>
            <button class="tab-btn" onclick="showTab('graficos')">📈 Gráficos</button>
            <button class="tab-btn" onclick="showTab('logs')">📋 Logs</button>
        </div>

        <div class="card">
            <!-- Tab Dispositivos -->
            <div id="dispositivos" class="tab-content active">
                <div class="card-header">
                    <h2 class="card-title">Meus Dispositivos</h2>
                    <button class="btn btn-primary" onclick="alert('Adicionar dispositivo em desenvolvimento')">+ Adicionar</button>
                </div>
                <div class="card-body">
                    <?php if (empty($dispositivos)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">📱</div>
                            <p>Você ainda não tem dispositivos cadastrados</p>
                        </div>
                    <?php else: ?>
                        <div class="device-grid">
                            <?php foreach ($dispositivos as $dispositivo): ?>
                            <div class="device-card">
                                <div class="device-header">
                                    <div>
                                        <div class="device-name"><?php echo htmlspecialchars($dispositivo['nome']); ?></div>
                                        <div class="device-location">📍 <?php echo htmlspecialchars($dispositivo['localizacao']); ?></div>
                                    </div>
                                    <span class="badge <?php echo $dispositivo['status'] === 'ativo' ? 'badge-active' : 'badge-inactive'; ?>">
                                        <?php echo ucfirst($dispositivo['status']); ?>
                                    </span>
                                </div>
                                <div style="color: var(--tg-text-secondary); font-size: 13px; margin-top: 8px;">
                                    Modelo: <?php echo htmlspecialchars($dispositivo['modelo']); ?>
                                </div>
                            </div>
                            <?php endforeach; ?>
                        </div>
                    <?php endif; ?>
                </div>
            </div>

            <!-- Tab Leituras -->
            <div id="leituras" class="tab-content">
                <div class="card-header">
                    <h2 class="card-title">Leituras Recentes</h2>
                </div>
                <?php if (empty($leituras)): ?>
                    <div class="empty-state">
                        <div class="empty-icon">📊</div>
                        <p>Nenhuma leitura registrada ainda</p>
                    </div>
                <?php else: ?>
                    <?php foreach ($leituras as $leitura): ?>
                    <div class="reading-item">
                        <div class="reading-header">
                            <span class="reading-device"><?php echo htmlspecialchars($leitura['dispositivo_nome']); ?></span>
                            <span class="reading-time"><?php echo date('d/m H:i', strtotime($leitura['data_hora'])); ?></span>
                        </div>
                        <div class="reading-data">
                            <span class="reading-value"><?php echo $leitura['valor']; ?></span>
                            <span class="reading-unit"><?php echo htmlspecialchars($leitura['unidade_medida']); ?></span>
                            <span class="reading-sensor">• <?php echo htmlspecialchars($leitura['tipo_sensor']); ?></span>
                        </div>
                    </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>

            <!-- Tab Gráficos -->
            <div id="graficos" class="tab-content">
                <div class="card-header">
                    <h2 class="card-title">Gráficos - Últimas 24 Horas</h2>
                </div>
                <div class="card-body">
                    <?php if (empty($dados_grafico)): ?>
                        <div class="empty-state">
                            <div class="empty-icon">📈</div>
                            <p>Sem dados para exibir gráficos</p>
                        </div>
                    <?php else: ?>
                        <div class="chart-container">
                            <canvas id="chartLeituras"></canvas>
                        </div>
                    <?php endif; ?>
                </div>
            </div>

            <!-- Tab Logs -->
            <div id="logs" class="tab-content">
                <div class="card-header">
                    <h2 class="card-title">Logs do Sistema</h2>
                </div>
                <?php if (empty($logs)): ?>
                    <div class="empty-state">
                        <div class="empty-icon">📋</div>
                        <p>Nenhum log registrado</p>
                    </div>
                <?php else: ?>
                    <?php foreach ($logs as $log): ?>
                    <div class="log-item">
                        <div class="log-icon">
                            <?php 
                            switch($log['tipo']) {
                                case 'leitura': echo '📊'; break;
                                case 'dispositivo': echo '📱'; break;
                                case 'notificacao': echo '🔔'; break;
                                default: echo '📝';
                            }
                            ?>
                        </div>
                        <div class="log-content">
                            <div class="log-description"><?php echo htmlspecialchars($log['descricao']); ?></div>
                            <div class="log-time"><?php echo date('d/m/Y H:i:s', strtotime($log['data_hora'])); ?></div>
                        </div>
                    </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <script>
        function showTab(tab) {
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
            
            event.target.classList.add('active');
            document.getElementById(tab).classList.add('active');
        }

        // Dados para o gráfico
        <?php if (!empty($dados_grafico)): ?>
        const dadosGrafico = <?php echo json_encode($dados_grafico); ?>;
        
        // Agrupar por tipo de sensor
        const dadosPorSensor = {};
        dadosGrafico.forEach(item => {
            if (!dadosPorSensor[item.tipo_sensor]) {
                dadosPorSensor[item.tipo_sensor] = {
                    labels: [],
                    data: [],
                    unidade: item.unidade_medida
                };
            }
            dadosPorSensor[item.tipo_sensor].labels.push(
                new Date(item.data_hora).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
            );
            dadosPorSensor[item.tipo_sensor].data.push(parseFloat(item.valor));
        });

        // Cores para os datasets
        const cores = [
            'rgba(42, 171, 238, 1)',  // Azul Telegram
            'rgba(0, 200, 83, 1)',    // Verde
            'rgba(255, 167, 38, 1)',  // Laranja
            'rgba(229, 57, 53, 1)'    // Vermelho
        ];

        // Criar datasets
        const datasets = [];
        let corIndex = 0;
        for (const [sensor, dados] of Object.entries(dadosPorSensor)) {
            datasets.push({
                label: sensor,
                data: dados.data,
                borderColor: cores[corIndex % cores.length],
                backgroundColor: cores[corIndex % cores.length].replace('1)', '0.1)'),
                tension: 0.4,
                fill: true
            });
            corIndex++;
        }

        // Pegar todos os labels únicos
        const allLabels = [...new Set(dadosGrafico.map(item => 
            new Date(item.data_hora).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
        ))];

        // Criar gráfico
        const ctx = document.getElementById('chartLeituras');
        if (ctx) {
            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: allLabels,
                    datasets: datasets
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            labels: {
                                color: '#ffffff'
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                color: '#aaaaaa'
                            },
                            grid: {
                                color: '#2b5278'
                            }
                        },
                        x: {
                            ticks: {
                                color: '#aaaaaa'
                            },
                            grid: {
                                color: '#2b5278'
                            }
                        }
                    }
                }
            });
        }
        <?php endif; ?>
    </script>
</body>
</html>
