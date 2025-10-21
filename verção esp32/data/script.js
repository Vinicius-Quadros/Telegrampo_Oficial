// ========================================
// SCRIPT PRINCIPAL DO TELEGRAMPO
// script.js
// ========================================

// Configurações
const CONFIG = {
    API_URL: 'http://192.168.100.182/telegrampo/api', // ALTERE AQUI!
    UPDATE_INTERVAL: 5000, // 5 segundos
    DEVICE_ID: 'ESP32_001' // ID do seu dispositivo
};

// Variáveis globais
let updateTimer = null;
let isConnected = false;

// ========================================
// INICIALIZAÇÃO
// ========================================
document.addEventListener('DOMContentLoaded', function() {
    console.log('TELEGRAMPO iniciado!');
    
    // Carregar dados iniciais
    carregarDados();
    
    // Iniciar atualização automática
    startAutoUpdate();
    
    // Carregar chat ID salvo
    carregarChatIdSalvo();
});

// ========================================
// FUNÇÕES DE ATUALIZAÇÃO DE DADOS
// ========================================

function carregarDados() {
    fetch(`${CONFIG.API_URL}/obter_dados.php?device_id=${CONFIG.DEVICE_ID}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                atualizarInterface(data.data);
                updateConnectionStatus(true);
            } else {
                showError(data.error);
                updateConnectionStatus(false);
            }
        })
        .catch(error => {
            console.error('Erro ao carregar dados:', error);
            showError('Erro de conexão com o servidor');
            updateConnectionStatus(false);
        });
}

function atualizarInterface(dados) {
    // Atualizar temperatura
    document.getElementById('tempValue').textContent = 
        dados.leituras.temperatura !== null ? dados.leituras.temperatura.toFixed(1) : '--';
    
    // Atualizar umidade do ar
    document.getElementById('humidityValue').textContent = 
        dados.leituras.umidade_ar !== null ? dados.leituras.umidade_ar.toFixed(1) : '--';
    
    // Atualizar umidade da roupa
    document.getElementById('roupaValue').textContent = 
        dados.leituras.umidade_roupa !== null ? dados.leituras.umidade_roupa : '--';
    
    // Atualizar status da roupa
    const statusValue = document.getElementById('statusValue');
    const statusIcon = document.getElementById('statusIcon');
    
    statusValue.textContent = dados.leituras.status_roupa;
    
    if (dados.leituras.status_roupa === 'Seca') {
        statusValue.className = 'card-value status-seca';
        statusIcon.textContent = '☀️';
    } else if (dados.leituras.status_roupa === 'Úmida') {
        statusValue.className = 'card-value status-umida';
        statusIcon.textContent = '💧';
    } else {
        statusValue.className = 'card-value';
        statusIcon.textContent = '👕';
    }
    
    // Atualizar última atualização
    document.getElementById('lastUpdate').textContent = 
        'Última atualização: ' + new Date().toLocaleString('pt-BR');
}

function startAutoUpdate() {
    if (updateTimer) {
        clearInterval(updateTimer);
    }
    
    updateTimer = setInterval(() => {
        carregarDados();
    }, CONFIG.UPDATE_INTERVAL);
}

function updateConnectionStatus(connected) {
    isConnected = connected;
    const statusElement = document.getElementById('connectionStatus');
    
    if (connected) {
        statusElement.className = 'connection-status connected';
        statusElement.textContent = '🟢 Conectado';
    } else {
        statusElement.className = 'connection-status disconnected';
        statusElement.textContent = '🔴 Desconectado';
    }
}

// ========================================
// FUNÇÕES DA SIDEBAR
// ========================================

function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('active');
    document.getElementById('sidebarOverlay').classList.toggle('active');
}

function closeSidebar() {
    document.getElementById('sidebar').classList.remove('active');
    document.getElementById('sidebarOverlay').classList.remove('active');
}

// ========================================
// FUNÇÕES DOS MODAIS
// ========================================

function openConfigModal() {
    closeSidebar();
    document.getElementById('configModal').classList.add('active');
}

function openHistoricoModal() {
    closeSidebar();
    document.getElementById('historicoModal').classList.add('active');
    carregarHistorico();
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

// ========================================
// CONFIGURAÇÃO DE CHAT ID
// ========================================

function carregarChatIdSalvo() {
    const chatId = localStorage.getItem('chatId');
    const nome = localStorage.getItem('nomeUsuario');
    
    if (chatId) {
        document.getElementById('chatId').value = chatId;
    }
    if (nome) {
        document.getElementById('nomeUsuario').value = nome;
    }
}

function salvarConfig(event) {
    event.preventDefault();
    
    const chatId = document.getElementById('chatId').value.trim();
    const nome = document.getElementById('nomeUsuario').value.trim();
    
    if (!chatId || !nome) {
        showError('Preencha todos os campos');
        return;
    }
    
    // Salvar localmente
    localStorage.setItem('chatId', chatId);
    localStorage.setItem('nomeUsuario', nome);
    
    // Aqui você precisará criar um endpoint PHP para atualizar o chat_id no banco
    // Por enquanto, apenas salvamos localmente
    
    showSuccess('Configurações salvas com sucesso!');
    closeModal('configModal');
}

// ========================================
// HISTÓRICO
// ========================================

function carregarHistorico() {
    const content = document.getElementById('historicoContent');
    content.innerHTML = '<p style="text-align: center; padding: 20px;">Carregando histórico...</p>';
    
    // Aqui você pode criar um endpoint PHP para buscar histórico
    // Por enquanto, vamos simular
    setTimeout(() => {
        content.innerHTML = `
            <div style="padding: 20px;">
                <p style="text-align: center; color: #999;">
                    Funcionalidade em desenvolvimento.<br>
                    Em breve você poderá visualizar o histórico completo das leituras.
                </p>
            </div>
        `;
    }, 1000);
}

// ========================================
// FUNÇÕES AUXILIARES
// ========================================

function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    errorDiv.textContent = message;
    errorDiv.style.display = 'block';
    
    setTimeout(() => {
        errorDiv.style.display = 'none';
    }, 5000);
}

function showSuccess(message) {
    // Criar elemento de sucesso temporário
    const successDiv = document.createElement('div');
    successDiv.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        background: rgba(39, 174, 96, 0.9);
        color: white;
        padding: 15px 20px;
        border-radius: 10px;
        z-index: 9999;
        animation: slideIn 0.3s ease-out;
    `;
    successDiv.textContent = message;
    document.body.appendChild(successDiv);
    
    setTimeout(() => {
        successDiv.remove();
    }, 3000);
}

// ========================================
// FECHAR MODAIS COM ESC
// ========================================

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeModal('configModal');
        closeModal('historicoModal');
        closeSidebar();
    }
});

// ========================================
// LIMPAR INTERVALO AO SAIR
// ========================================

window.addEventListener('beforeunload', function() {
    if (updateTimer) {
        clearInterval(updateTimer);
    }
});