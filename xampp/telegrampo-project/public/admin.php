<?php
require_once '../includes/db_connect.php';
require_once '../includes/auth.php';

requireAdmin();

$pageTitle = 'Painel Administrativo - TeleGrampo';

// Determinar qual tabela exibir
$table = $_GET['table'] ?? 'usuarios';

// Lista de tabelas disponíveis
$availableTables = [
    'usuarios' => 'Usuários',
    'dispositivos' => 'Dispositivos',
    'configuracoes' => 'Configurações',
    'leituras_dht22' => 'Leituras DHT22',
    'leituras_umidade_roupa' => 'Leituras Umidade Roupa',
    'notificacoes' => 'Notificações',
    'logs_sistema' => 'Logs do Sistema'
];

// Buscar dados da tabela selecionada
$stmt = $pdo->query("SELECT * FROM $table ORDER BY id DESC LIMIT 100");
$records = $stmt->fetchAll();

// Obter colunas da tabela
$stmt = $pdo->query("DESCRIBE $table");
$columns = $stmt->fetchAll();

include '../includes/header.php';
?>

<div class="row">
    <div class="col-12">
        <h2 class="mb-4">
            <i class="fas fa-cog"></i> Painel Administrativo
            <small class="text-muted">Gerenciamento Completo</small>
        </h2>
    </div>
</div>

<div class="row">
    <!-- Menu Lateral -->
    <div class="col-md-3 mb-4">
        <div class="card">
            <div class="card-header bg-primary text-white">
                <h5 class="mb-0"><i class="fas fa-database"></i> Tabelas</h5>
            </div>
            <div class="list-group list-group-flush">
                <?php foreach ($availableTables as $key => $name): ?>
                <a href="?table=<?php echo $key; ?>" 
                   class="list-group-item list-group-item-action <?php echo $table === $key ? 'active' : ''; ?>">
                    <i class="fas fa-table"></i> <?php echo $name; ?>
                </a>
                <?php endforeach; ?>
            </div>
        </div>
        
        <div class="card mt-3">
            <div class="card-body">
                <h6 class="card-title"><i class="fas fa-info-circle"></i> Informações</h6>
                <p class="card-text small">
                    Total de registros: <strong><?php echo count($records); ?></strong>
                </p>
            </div>
        </div>
    </div>
    
    <!-- Conteúdo Principal -->
    <div class="col-md-9">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">
                    <i class="fas fa-table"></i> <?php echo $availableTables[$table]; ?>
                </h5>
                <button class="btn btn-sm btn-success" onclick="showAddModal()">
                    <i class="fas fa-plus"></i> Adicionar Novo
                </button>
            </div>
            <div class="card-body">
                <?php if (empty($records)): ?>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle"></i> Nenhum registro encontrado nesta tabela.
                </div>
                <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-striped table-hover table-sm">
                        <thead class="table-dark">
                            <tr>
                                <?php foreach ($columns as $column): ?>
                                <th><?php echo htmlspecialchars($column['Field']); ?></th>
                                <?php endforeach; ?>
                                <th width="150">Ações</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($records as $record): ?>
                            <tr>
                                <?php foreach ($columns as $column): ?>
                                <td>
                                    <?php 
                                    $value = $record[$column['Field']];
                                    // Truncar valores longos
                                    if (strlen($value) > 50) {
                                        echo htmlspecialchars(substr($value, 0, 50)) . '...';
                                    } else {
                                        echo htmlspecialchars($value ?? '');
                                    }
                                    ?>
                                </td>
                                <?php endforeach; ?>
                                <td>
                                    <div class="btn-group btn-group-sm">
                                        <button class="btn btn-primary" 
                                                onclick='editRecord(<?php echo json_encode($record); ?>)' 
                                                title="Editar">
                                            <i class="fas fa-edit"></i>
                                        </button>
                                        <button class="btn btn-danger" 
                                                onclick="deleteRecord(<?php echo $record['id']; ?>)" 
                                                title="Excluir">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<!-- Modal de Edição -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-edit"></i> Editar Registro</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form id="editForm" action="actions/update_record.php" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="table" value="<?php echo $table; ?>">
                    <input type="hidden" name="id" id="edit_id">
                    
                    <div id="editFields"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Salvar Alterações
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
const columns = <?php echo json_encode($columns); ?>;
const currentTable = '<?php echo $table; ?>';

function editRecord(record) {
    document.getElementById('edit_id').value = record.id;
    const fieldsDiv = document.getElementById('editFields');
    fieldsDiv.innerHTML = '';
    
    columns.forEach(column => {
        if (column.Field === 'id') return;
        
        const div = document.createElement('div');
        div.className = 'mb-3';
        
        const label = document.createElement('label');
        label.className = 'form-label';
        label.textContent = column.Field;
        
        let input;
        if (column.Type.includes('text')) {
            input = document.createElement('textarea');
            input.className = 'form-control';
            input.rows = 3;
        } else {
            input = document.createElement('input');
            input.className = 'form-control';
            input.type = 'text';
        }
        
        input.name = column.Field;
        input.value = record[column.Field] || '';
        
        div.appendChild(label);
        div.appendChild(input);
        fieldsDiv.appendChild(div);
    });
    
    const modal = new bootstrap.Modal(document.getElementById('editModal'));
    modal.show();
}

function deleteRecord(id) {
    if (confirm('Tem certeza que deseja excluir este registro? Esta ação não pode ser desfeita.')) {
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = 'actions/delete_record.php';
        
        const inputTable = document.createElement('input');
        inputTable.type = 'hidden';
        inputTable.name = 'table';
        inputTable.value = currentTable;
        
        const inputId = document.createElement('input');
        inputId.type = 'hidden';
        inputId.name = 'id';
        inputId.value = id;
        
        form.appendChild(inputTable);
        form.appendChild(inputId);
        document.body.appendChild(form);
        form.submit();
    }
}

function showAddModal() {
    alert('Funcionalidade de adicionar novo registro será implementada em breve!');
    // TODO: Implementar modal de adição similar ao de edição
}
</script>

<script src="assets/js/admin.js"></script>

<?php include '../includes/footer.php'; ?>
