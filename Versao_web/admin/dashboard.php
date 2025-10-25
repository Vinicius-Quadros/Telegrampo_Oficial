<?php
require_once '../includes/auth.php';
requireAdmin();

// Contar registros das tabelas
$stats = [
    'usuarios' => countRecords('usuarios'),
    'dispositivos' => countRecords('dispositivos'),
    'leituras' => countRecords('leituras'),
    'notificacoes' => countRecords('notificacoes')
];

// Buscar dados para exibir
$usuarios = fetchAll("SELECT u.*, COUNT(d.id_dispositivo) as total_dispositivos 
                      FROM usuarios u 
                      LEFT JOIN dispositivos d ON u.id_usuario = d.id_usuario 
                      GROUP BY u.id_usuario 
                      ORDER BY u.criado_em DESC");

$dispositivos = fetchAll("SELECT d.*, u.nome as nome_usuario 
                          FROM dispositivos d 
                          JOIN usuarios u ON d.id_usuario = u.id_usuario 
                          ORDER BY d.criado_em DESC");

$leituras_recentes = fetchAll("SELECT l.*, d.nome as dispositivo_nome, s.tipo_sensor, s.unidade_medida 
                               FROM leituras l 
                               JOIN dispositivos d ON l.id_dispositivo = d.id_dispositivo 
                               JOIN sensores s ON l.id_sensor = s.id_sensor 
                               ORDER BY l.data_hora DESC 
                               LIMIT 50");

$sensores = fetchAll("SELECT * FROM sensores ORDER BY tipo_sensor");

$notificacoes = fetchAll("SELECT n.*, u.nome as usuario_nome 
                          FROM notificacoes n 
                          JOIN usuarios u ON n.id_usuario = u.id_usuario 
                          ORDER BY n.data_hora DESC 
                          LIMIT 50");

// Processar ações CRUD
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $action = $_POST['action'];
    $table = $_POST['table'];
    
    switch ($action) {
        case 'delete':
            $id = $_POST['id'];
            $result = false;
            
            switch ($table) {
                case 'usuarios':
                    $result = deleteData('usuarios', 'id_usuario = ?', [$id]);
                    break;
                case 'dispositivos':
                    $result = deleteData('dispositivos', 'id_dispositivo = ?', [$id]);
                    break;
                case 'leituras':
                    $result = deleteData('leituras', 'id_leitura = ?', [$id]);
                    break;
                case 'sensores':
                    $result = deleteData('sensores', 'id_sensor = ?', [$id]);
                    break;
                case 'notificacoes':
                    $result = deleteData('notificacoes', 'id_notificacao = ?', [$id]);
                    break;
            }
            
            if ($result) {
                header('Location: dashboard.php?success=deleted');
                exit;
            } else {
                $error = 'Erro ao excluir registro!';
            }
            break;
    }
}

$current_user = getCurrentUser();
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Admin - Grampo IoT</title>
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
            --tg-error: #e53935;
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
            max-width: 1400px;
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
            background: var(--tg-error);
            border-color: var(--tg-error);
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 24px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
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

        .card {
            background: var(--tg-bg-secondary);
            border: 1px solid var(--tg-border);
            border-radius: 12px;
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

        .tabs {
            display: flex;
            background: var(--tg-bg-card);
            border-bottom: 1px solid var(--tg-border);
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
        }

        .tab-btn.active {
            color: var(--tg-blue);
            border-bottom-color: var(--tg-blue);
        }

        .tab-content {
            display: none;
            padding: 20px;
        }

        .tab-content.active {
            display: block;
        }

        .table-container {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid var(--tg-border);
        }

        th {
            color: var(--tg-text-secondary);
            font-weight: 500;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        td {
            font-size: 14px;
        }

        tr:hover {
            background: var(--tg-bg-card);
        }

        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            transition: all 0.2s;
            margin-right: 8px;
        }

        .btn-primary {
            background: var(--tg-blue);
            color: white;
        }

        .btn-primary:hover {
            background: var(--tg-blue-dark);
        }

        .btn-danger {
            background: transparent;
            color: var(--tg-error);
            border: 1px solid var(--tg-error);
        }

        .btn-danger:hover {
            background: var(--tg-error);
            color: white;
        }

        .btn-secondary {
            background: transparent;
            color: var(--tg-text);
            border: 1px solid var(--tg-border);
        }

        .btn-secondary:hover {
            background: var(--tg-bg-card);
        }

        .badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }

        .badge-admin {
            background: rgba(42, 171, 238, 0.2);
            color: var(--tg-blue);
        }

        .badge-user {
            background: rgba(255, 167, 38, 0.2);
            color: var(--tg-warning);
        }

        .badge-active {
            background: rgba(0, 200, 83, 0.2);
            color: var(--tg-success);
        }

        .badge-inactive {
            background: rgba(229, 57, 53, 0.2);
            color: var(--tg-error);
        }

        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid;
        }

        .alert-success {
            background: rgba(0, 200, 83, 0.1);
            border-color: var(--tg-success);
            color: #4caf50;
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

            .tabs {
                overflow-x: auto;
            }

            .tab-btn {
                white-space: nowrap;
            }

            table {
                font-size: 13px;
            }

            th, td {
                padding: 8px;
            }
        }
    </style>
</head>
<body>
    <header class="header">
        <div class="header-content">
            <h1>🔧 Dashboard Administrativo</h1>
            <div class="user-info">
                <span>Olá, <?php echo htmlspecialchars($current_user['nome']); ?>!</span>
                <a href="../includes/logout.php" class="logout-btn">Sair</a>
            </div>
        </div>
    </header>

    <div class="container">
        <?php if (isset($_GET['success'])): ?>
            <div class="alert alert-success">
                <?php
                switch ($_GET['success']) {
                    case 'deleted':
                        echo 'Registro excluído com sucesso!';
                        break;
                    case 'added':
                        echo 'Registro adicionado com sucesso!';
                        break;
                    case 'updated':
                        echo 'Registro atualizado com sucesso!';
                        break;
                    default:
                        echo 'Operação realizada com sucesso!';
                }
                ?>
            </div>
        <?php endif; ?>

        <?php if (isset($error)): ?>
            <div class="alert alert-error"><?php echo $error; ?></div>
        <?php endif; ?>

        <!-- Estatísticas -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number"><?php echo $stats['usuarios']; ?></div>
                <div class="stat-label">Usuários</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><?php echo $stats['dispositivos']; ?></div>
                <div class="stat-label">Dispositivos</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><?php echo $stats['leituras']; ?></div>
                <div class="stat-label">Leituras</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><?php echo $stats['notificacoes']; ?></div>
                <div class="stat-label">Notificações</div>
            </div>
        </div>

        <!-- Abas -->
        <div class="tabs">
            <button class="tab-btn active" onclick="showTab('usuarios')">Usuários</button>
            <button class="tab-btn" onclick="showTab('dispositivos')">Dispositivos</button>
            <button class="tab-btn" onclick="showTab('leituras')">Leituras</button>
            <button class="tab-btn" onclick="showTab('sensores')">Sensores</button>
            <button class="tab-btn" onclick="showTab('notificacoes')">Notificações</button>
        </div>

        <!-- Conteúdo das Abas -->
        
        <!-- Usuários -->
        <div id="usuarios" class="tab-content active">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                <h3>Gerenciar Usuários</h3>
                <button class="btn btn-primary" onclick="openModal('addUserModal')">+ Adicionar Usuário</button>
            </div>
            
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nome</th>
                            <th>Email</th>
                            <th>CPF</th>
                            <th>Tipo</th>
                            <th>Dispositivos</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($usuarios as $usuario): ?>
                        <tr>
                            <td><?php echo $usuario['id_usuario']; ?></td>
                            <td><?php echo htmlspecialchars($usuario['nome']); ?></td>
                            <td><?php echo htmlspecialchars($usuario['email']); ?></td>
                            <td><?php echo formatCPF($usuario['cpf']); ?></td>
                            <td>
                                <span class="status-badge <?php echo $usuario['tipo_usuario'] === 'A' ? 'type-admin' : 'type-user'; ?>">
                                    <?php echo $usuario['tipo_usuario'] === 'A' ? 'Admin' : 'Usuário'; ?>
                                </span>
                            </td>
                            <td><?php echo $usuario['total_dispositivos']; ?></td>
                            <td>
                                <button class="btn btn-secondary" onclick="editUser(<?php echo $usuario['id_usuario']; ?>)">Editar</button>
                                <?php if ($usuario['id_usuario'] != $_SESSION['user_id']): ?>
                                <button class="btn btn-danger" onclick="deleteRecord('usuarios', <?php echo $usuario['id_usuario']; ?>)">Excluir</button>
                                <?php endif; ?>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Dispositivos -->
        <div id="dispositivos" class="tab-content">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                <h3>Gerenciar Dispositivos</h3>
                <button class="btn btn-primary" onclick="openModal('addDeviceModal')">+ Adicionar Dispositivo</button>
            </div>
            
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nome</th>
                            <th>Usuário</th>
                            <th>Localização</th>
                            <th>Modelo</th>
                            <th>Status</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($dispositivos as $dispositivo): ?>
                        <tr>
                            <td><?php echo $dispositivo['id_dispositivo']; ?></td>
                            <td><?php echo htmlspecialchars($dispositivo['nome']); ?></td>
                            <td><?php echo htmlspecialchars($dispositivo['nome_usuario']); ?></td>
                            <td><?php echo htmlspecialchars($dispositivo['localizacao']); ?></td>
                            <td><?php echo htmlspecialchars($dispositivo['modelo']); ?></td>
                            <td>
                                <span class="status-badge status-<?php echo $dispositivo['status']; ?>">
                                    <?php echo ucfirst($dispositivo['status']); ?>
                                </span>
                            </td>
                            <td>
                                <button class="btn btn-secondary" onclick="editDevice(<?php echo $dispositivo['id_dispositivo']; ?>)">Editar</button>
                                <button class="btn btn-danger" onclick="deleteRecord('dispositivos', <?php echo $dispositivo['id_dispositivo']; ?>)">Excluir</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Leituras -->
        <div id="leituras" class="tab-content">
            <h3>Leituras Recentes (Últimas 50)</h3>
            
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Dispositivo</th>
                            <th>Sensor</th>
                            <th>Valor</th>
                            <th>Unidade</th>
                            <th>Status Roupa</th>
                            <th>Data/Hora</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($leituras_recentes as $leitura): ?>
                        <tr>
                            <td><?php echo $leitura['id_leitura']; ?></td>
                            <td><?php echo htmlspecialchars($leitura['dispositivo_nome']); ?></td>
                            <td><?php echo htmlspecialchars($leitura['tipo_sensor']); ?></td>
                            <td><?php echo $leitura['valor']; ?></td>
                            <td><?php echo htmlspecialchars($leitura['unidade_medida']); ?></td>
                            <td><?php echo $leitura['status_roupa']; ?></td>
                            <td><?php echo date('d/m/Y H:i:s', strtotime($leitura['data_hora'])); ?></td>
                            <td>
                                <button class="btn btn-danger" onclick="deleteRecord('leituras', <?php echo $leitura['id_leitura']; ?>)">Excluir</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Sensores -->
        <div id="sensores" class="tab-content">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                <h3>Gerenciar Sensores</h3>
                <button class="btn btn-primary" onclick="openModal('addSensorModal')">+ Adicionar Sensor</button>
            </div>
            
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Tipo</th>
                            <th>Unidade</th>
                            <th>Descrição</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($sensores as $sensor): ?>
                        <tr>
                            <td><?php echo $sensor['id_sensor']; ?></td>
                            <td><?php echo htmlspecialchars($sensor['tipo_sensor']); ?></td>
                            <td><?php echo htmlspecialchars($sensor['unidade_medida']); ?></td>
                            <td><?php echo htmlspecialchars($sensor['descricao']); ?></td>
                            <td>
                                <button class="btn btn-secondary" onclick="editSensor(<?php echo $sensor['id_sensor']; ?>)">Editar</button>
                                <button class="btn btn-danger" onclick="deleteRecord('sensores', <?php echo $sensor['id_sensor']; ?>)">Excluir</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Notificações -->
        <div id="notificacoes" class="tab-content">
            <h3>Notificações Recentes (Últimas 50)</h3>
            
            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Usuário</th>
                            <th>Tipo</th>
                            <th>Mensagem</th>
                            <th>Data/Hora</th>
                            <th>Lida</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($notificacoes as $notificacao): ?>
                        <tr>
                            <td><?php echo $notificacao['id_notificacao']; ?></td>
                            <td><?php echo htmlspecialchars($notificacao['usuario_nome']); ?></td>
                            <td><?php echo htmlspecialchars($notificacao['tipo_notificacao']); ?></td>
                            <td><?php echo htmlspecialchars($notificacao['mensagem']); ?></td>
                            <td><?php echo date('d/m/Y H:i:s', strtotime($notificacao['data_hora'])); ?></td>
                            <td><?php echo $notificacao['lida'] ? 'Sim' : 'Não'; ?></td>
                            <td>
                                <button class="btn btn-danger" onclick="deleteRecord('notificacoes', <?php echo $notificacao['id_notificacao']; ?>)">Excluir</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Modais -->
    
    <!-- Modal Adicionar Usuário -->
    <div id="addUserModal" class="modal">
        <div class="modal-content">
            <h3>Adicionar Usuário</h3>
            <form action="actions/add_user.php" method="POST">
                <div class="form-group">
                    <label>Nome Completo:</label>
                    <input type="text" name="nome" required>
                </div>
                <div class="form-group">
                    <label>CPF:</label>
                    <input type="text" name="cpf" id="modal_cpf" required>
                </div>
                <div class="form-group">
                    <label>Celular:</label>
                    <input type="text" name="celular" id="modal_celular" required>
                </div>
                <div class="form-group">
                    <label>Email:</label>
                    <input type="email" name="email" required>
                </div>
                <div class="form-group">
                    <label>Senha:</label>
                    <input type="password" name="senha" required>
                </div>
                <div class="form-group">
                    <label>Data de Nascimento:</label>
                    <input type="date" name="data_nascimento" required>
                </div>
                <div class="form-group">
                    <label>Tipo de Usuário:</label>
                    <select name="tipo_usuario" required>
                        <option value="C">Usuário Comum</option>
                        <option value="A">Administrador</option>
                    </select>
                </div>
                <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('addUserModal')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Adicionar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal Adicionar Dispositivo -->
    <div id="addDeviceModal" class="modal">
        <div class="modal-content">
            <h3>Adicionar Dispositivo</h3>
            <form action="actions/add_device.php" method="POST">
                <div class="form-group">
                    <label>Usuário:</label>
                    <select name="id_usuario" required>
                        <option value="">Selecione um usuário</option>
                        <?php foreach ($usuarios as $user): ?>
                        <option value="<?php echo $user['id_usuario']; ?>">
                            <?php echo htmlspecialchars($user['nome']); ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label>Nome do Dispositivo:</label>
                    <input type="text" name="nome" required>
                </div>
                <div class="form-group">
                    <label>Localização:</label>
                    <input type="text" name="localizacao">
                </div>
                <div class="form-group">
                    <label>Modelo:</label>
                    <input type="text" name="modelo" value="ESP32">
                </div>
                <div class="form-group">
                    <label>Status:</label>
                    <select name="status" required>
                        <option value="ativo">Ativo</option>
                        <option value="inativo">Inativo</option>
                    </select>
                </div>
                <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('addDeviceModal')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Adicionar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal Adicionar Sensor -->
    <div id="addSensorModal" class="modal">
        <div class="modal-content">
            <h3>Adicionar Sensor</h3>
            <form action="actions/add_sensor.php" method="POST">
                <div class="form-group">
                    <label>Tipo do Sensor:</label>
                    <input type="text" name="tipo_sensor" required>
                </div>
                <div class="form-group">
                    <label>Unidade de Medida:</label>
                    <input type="text" name="unidade_medida" required>
                </div>
                <div class="form-group">
                    <label>Descrição:</label>
                    <textarea name="descricao" rows="3"></textarea>
                </div>
                <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('addSensorModal')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Adicionar</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal de Confirmação de Exclusão -->
    <div id="deleteModal" class="modal">
        <div class="modal-content">
            <h3>Confirmar Exclusão</h3>
            <p>Tem certeza que deseja excluir este registro? Esta ação não pode ser desfeita.</p>
            <form method="POST">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="table" id="delete_table">
                <input type="hidden" name="id" id="delete_id">
                <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 1rem;">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('deleteModal')">Cancelar</button>
                    <button type="submit" class="btn btn-danger">Excluir</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function showTab(tabName) {
            // Remover active de todas as abas
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
            
            // Ativar aba selecionada
            event.target.classList.add('active');
            document.getElementById(tabName).classList.add('active');
        }

        function openModal(modalId) {
            document.getElementById(modalId).classList.add('active');
        }

        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('active');
        }

        function deleteRecord(table, id) {
            document.getElementById('delete_table').value = table;
            document.getElementById('delete_id').value = id;
            openModal('deleteModal');
        }

        function editUser(id) {
            // Implementar edição de usuário
            alert('Função de editar usuário será implementada em breve');
        }

        function editDevice(id) {
            // Implementar edição de dispositivo
            alert('Função de editar dispositivo será implementada em breve');
        }

        function editSensor(id) {
            // Implementar edição de sensor
            alert('Função de editar sensor será implementada em breve');
        }

        // Fechar modal ao clicar fora
        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.classList.remove('active');
            }
        }

        // Máscara para CPF no modal
        document.getElementById('modal_cpf').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            value = value.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
            e.target.value = value;
        });

        // Máscara para celular no modal
        document.getElementById('modal_celular').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length === 11) {
                value = value.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
            } else if (value.length === 10) {
                value = value.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
            }
            e.target.value = value;
        });
    </script>
</body>
</html>
