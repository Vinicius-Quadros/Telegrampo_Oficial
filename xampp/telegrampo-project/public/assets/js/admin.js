// Admin Panel - Funções auxiliares

/**
 * Exibe alertas de feedback
 */
document.addEventListener('DOMContentLoaded', function() {
    // Verificar parâmetros de sucesso/erro na URL
    const urlParams = new URLSearchParams(window.location.search);
    
    if (urlParams.has('success')) {
        const successType = urlParams.get('success');
        let message = '';
        
        switch(successType) {
            case 'updated':
                message = 'Registro atualizado com sucesso!';
                break;
            case 'deleted':
                message = 'Registro excluído com sucesso!';
                break;
            case 'created':
                message = 'Registro criado com sucesso!';
                break;
        }
        
        if (message) {
            showAlert(message, 'success');
        }
    }
    
    if (urlParams.has('error')) {
        const errorType = urlParams.get('error');
        let message = '';
        
        switch(errorType) {
            case 'update':
                message = 'Erro ao atualizar registro.';
                break;
            case 'foreign_key':
                message = 'Não é possível excluir. Existem registros relacionados.';
                break;
            default:
                message = 'Ocorreu um erro. Tente novamente.';
        }
        
        showAlert(message, 'danger');
    }
});

/**
 * Exibe alerta temporário
 */
function showAlert(message, type = 'info') {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3`;
    alertDiv.style.zIndex = '9999';
    alertDiv.style.minWidth = '300px';
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(alertDiv);
    
    // Auto-remover após 5 segundos
    setTimeout(() => {
        alertDiv.remove();
    }, 5000);
}

/**
 * Confirma exclusão com mais detalhes
 */
function confirmDelete(id, name = '') {
    const nameText = name ? ` "${name}"` : '';
    return confirm(`Tem certeza que deseja excluir o registro${nameText}?\n\nEsta ação não pode ser desfeita.`);
}

/**
 * Valida formulário antes de enviar
 */
function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form.checkValidity()) {
        form.classList.add('was-validated');
        return false;
    }
    return true;
}

/**
 * Formata data para exibição
 */
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

/**
 * Exportar tabela para CSV
 */
function exportTableToCSV(filename = 'export.csv') {
    const table = document.querySelector('table');
    if (!table) return;
    
    let csv = [];
    const rows = table.querySelectorAll('tr');
    
    for (const row of rows) {
        const cols = row.querySelectorAll('td, th');
        const csvRow = [];
        
        for (const col of cols) {
            // Pular coluna de ações
            if (col.querySelector('.btn-group')) continue;
            csvRow.push('"' + col.textContent.trim().replace(/"/g, '""') + '"');
        }
        
        csv.push(csvRow.join(','));
    }
    
    // Criar download
    const csvContent = csv.join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    
    if (navigator.msSaveBlob) {
        navigator.msSaveBlob(blob, filename);
    } else {
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        link.click();
    }
}

/**
 * Pesquisa na tabela
 */
function searchTable(searchTerm) {
    const table = document.querySelector('tbody');
    const rows = table.querySelectorAll('tr');
    
    searchTerm = searchTerm.toLowerCase();
    
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

// Adicionar campo de busca se não existir
document.addEventListener('DOMContentLoaded', function() {
    const cardHeader = document.querySelector('.card-header');
    if (cardHeader && !document.getElementById('tableSearch')) {
        const searchDiv = document.createElement('div');
        searchDiv.className = 'input-group input-group-sm mt-2';
        searchDiv.innerHTML = `
            <input type="text" id="tableSearch" class="form-control" placeholder="Buscar na tabela...">
            <button class="btn btn-outline-secondary" type="button" onclick="document.getElementById('tableSearch').value=''; searchTable('');">
                <i class="fas fa-times"></i>
            </button>
        `;
        
        cardHeader.appendChild(searchDiv);
        
        document.getElementById('tableSearch').addEventListener('input', function(e) {
            searchTable(e.target.value);
        });
    }
});

console.log('Admin panel JavaScript carregado com sucesso');
