// ========================================
// SCRIPT PARA MODO ACCESS POINT
// script.js
// ========================================

// Configurações
const CONFIG = {
    LOCAL_API: '/sensor_data',  // API local do ESP32
    UPDATE_INTERVAL: 2000       // 2 segundos
};

// Variáveis globais
let updateTimer = null;
let isConnected = false;

// ========================================
// INICIALIZAÇÃO
// ========================================
document.addEventListener('DOMContentLoaded', function() {
    console.log('TELEGRAMPO Access Point - Iniciado!');
    
    // Esconder elementos que não funcionam no modo AP
    esconderElementosInativos();
    
    // Carregar dados iniciais
    carregarDados();
    
    // Iniciar atualização automática
    startAutoUpdate();
});

// ========================================
// ESCONDER ELEMENTOS INATIVOS
// ========================================
function esconderElementosInativos() {
    // Esconder botão de menu (não tem configurações no modo AP)
    const menuBtn = document.querySelector('.menu-btn');
    if (menuBtn) menuBtn.style.display = 'none';
    
    // Esconder sidebar
    const sidebar = document.getElementById('sidebar');
    if (sidebar) sidebar.style.display = 'none';
    
    const sidebarOverlay = document.getElementById('sidebarOverlay');
    if (sidebarOverlay) sidebarOverlay.style.display = 'none';
}

// ========================================
// FUNÇÕES DE ATUALIZAÇÃO DE DADOS
// ========================================

function carregarDados() {
    console.log('Buscando dados em: ' + CONFIG.LOCAL_API);
    
    fetch(CONFIG.LOCAL_API)
        .then(response => {
            console.log('Resposta recebida:', response.status);
            return response.json();
        })
        .then(data => {
            console.log('Dados recebidos:', data);
            atualizarInterface(data);
            updateConnectionStatus(true);
        })
        .catch(error => {
            console.error('Erro ao carregar dados:', error);
            updateConnectionStatus(false);
        });
}

function atualizarInterface(dados) {
    console.log('Atualizando interface com:', dados);
    
    // Atualizar temperatura
    const tempElement = document.getElementById('tempValue');
    if (tempElement) {
        tempElement.textContent = dados.temperatura !== undefined && dados.temperatura !== null 
            ? parseFloat(dados.temperatura).toFixed(1) 
            : '--';
    }
    
    // Atualizar umidade do ar
    const humidityElement = document.getElementById('humidityValue');
    if (humidityElement) {
        humidityElement.textContent = dados.umidade_ar !== undefined && dados.umidade_ar !== null 
            ? parseFloat(dados.umidade_ar).toFixed(1) 
            : '--';
    }
    
    // Atualizar umidade da roupa
    const roupaElement = document.getElementById('roupaValue');
    if (roupaElement) {
        roupaElement.textContent = dados.umidade_roupa !== undefined && dados.umidade_roupa !== null 
            ? dados.umidade_roupa 
            : '--';
    }
    
    // Atualizar status da roupa
    const statusValue = document.getElementById('statusValue');
    const statusIcon = document.getElementById('statusIcon');
    
    if (statusValue && statusIcon) {
        const status = dados.status_roupa || 'Desconhecido';
        statusValue.textContent = status;
        
        if (status === 'Seca') {
            statusValue.className = 'card-value status-seca';
            statusIcon.textContent = '☀️';
        } else if (status === 'Úmida') {
            statusValue.className = 'card-value status-umida';
            statusIcon.textContent = '💧';
        } else {
            statusValue.className = 'card-value';
            statusIcon.textContent = '👕';
        }
    }
    
    // Atualizar última atualização
    const lastUpdate = document.getElementById('lastUpdate');
    if (lastUpdate) {
        lastUpdate.textContent = 'Última atualização: ' + new Date().toLocaleString('pt-BR');
    }
}

function startAutoUpdate() {
    if (updateTimer) {
        clearInterval(updateTimer);
    }
    
    updateTimer = setInterval(() => {
        carregarDados();
    }, CONFIG.UPDATE_INTERVAL);
    
    console.log('Atualização automática iniciada a cada ' + (CONFIG.UPDATE_INTERVAL/1000) + ' segundos');
}

function updateConnectionStatus(connected) {
    isConnected = connected;
    const statusElement = document.getElementById('connectionStatus');
    
    if (statusElement) {
        if (connected) {
            statusElement.className = 'connection-status connected';
            statusElement.textContent = '🟢 Conectado';
        } else {
            statusElement.className = 'connection-status disconnected';
            statusElement.textContent = '🔴 Desconectado';
        }
    }
}

// ========================================
// FUNÇÕES DOS MODAIS (DESABILITADAS)
// ========================================

function toggleSidebar() {
    // Desabilitado no modo AP
    console.log('Sidebar desabilitada no modo Access Point');
}

function closeSidebar() {
    // Desabilitado no modo AP
}

function openConfigModal() {
    // Desabilitado no modo AP
    alert('Configurações não disponíveis no modo Access Point');
}

function openHistoricoModal() {
    // Desabilitado no modo AP
    alert('Histórico não disponível no modo Access Point');
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
    }
}

// ========================================
// LIMPAR INTERVALO AO SAIR
// ========================================

window.addEventListener('beforeunload', function() {
    if (updateTimer) {
        clearInterval(updateTimer);
        console.log('Timer de atualização parado');
    }
});

// ========================================
// DEBUG NO CONSOLE
// ========================================

console.log('Script carregado!');
console.log('Configuração:', CONFIG);