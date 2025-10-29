// ========================================
// CONFIGURAÇÕES
// ========================================
const CONFIG = {
    LOCAL_API: '/sensor_data',
    UPDATE_INTERVAL: 2000,
    MAX_DATA_POINTS: 20,
    MAX_LOGS: 50
};

// ========================================
// VARIÁVEIS GLOBAIS
// ========================================
let updateTimer = null;
let isConnected = false;

// Arrays para armazenar dados dos gráficos
let dataTemperatura = [];
let dataUmidadeAr = [];
let dataUmidadeRoupa = [];
let dataLabels = [];

// Objetos dos gráficos
let chartTemperatura = null;
let chartUmidadeAr = null;
let chartUmidadeRoupa = null;

// Array de logs
let logs = [];

// ========================================
// INICIALIZAÇÃO
// ========================================
document.addEventListener('DOMContentLoaded', function() {
    console.log('TELEGRAMPO - Iniciado!');
    
    inicializarGraficos();
    carregarDados();
    startAutoUpdate();
    
    addLog('Sistema iniciado', 'success');
});

// ========================================
// FUNÇÕES DE GRÁFICOS
// ========================================
function inicializarGraficos() {
    const configGrafico = {
        type: 'line',
        options: {
            responsive: true,
            maintainAspectRatio: true,
            animation: {
                duration: 750
            },
            scales: {
                y: {
                    beginAtZero: false,
                    grid: {
                        color: 'rgba(0, 0, 0, 0.05)'
                    }
                },
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        maxTicksLimit: 10
                    }
                }
            },
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    };

    // Gráfico Temperatura
    chartTemperatura = new Chart(
        document.getElementById('chartTemperatura'),
        {
            ...configGrafico,
            data: {
                labels: dataLabels,
                datasets: [{
                    label: 'Temperatura (°C)',
                    data: dataTemperatura,
                    borderColor: '#e74c3c',
                    backgroundColor: 'rgba(231, 76, 60, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            }
        }
    );

    // Gráfico Umidade do Ar
    chartUmidadeAr = new Chart(
        document.getElementById('chartUmidadeAr'),
        {
            ...configGrafico,
            data: {
                labels: dataLabels,
                datasets: [{
                    label: 'Umidade do Ar (%)',
                    data: dataUmidadeAr,
                    borderColor: '#3498db',
                    backgroundColor: 'rgba(52, 152, 219, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            }
        }
    );

    // Gráfico Umidade da Roupa
    chartUmidadeRoupa = new Chart(
        document.getElementById('chartUmidadeRoupa'),
        {
            ...configGrafico,
            data: {
                labels: dataLabels,
                datasets: [{
                    label: 'Umidade da Roupa (%)',
                    data: dataUmidadeRoupa,
                    borderColor: '#9b59b6',
                    backgroundColor: 'rgba(155, 89, 182, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            }
        }
    );

    addLog('Gráficos inicializados', 'success');
}

function atualizarGraficos(dados) {
    const horaAtual = new Date().toLocaleTimeString('pt-BR', { 
        hour: '2-digit', 
        minute: '2-digit', 
        second: '2-digit' 
    });

    // Adicionar novos dados
    dataLabels.push(horaAtual);
    dataTemperatura.push(parseFloat(dados.temperatura) || 0);
    dataUmidadeAr.push(parseFloat(dados.umidade_ar) || 0);
    dataUmidadeRoupa.push(parseInt(dados.umidade_roupa) || 0);

    // Limitar quantidade de pontos
    if (dataLabels.length > CONFIG.MAX_DATA_POINTS) {
        dataLabels.shift();
        dataTemperatura.shift();
        dataUmidadeAr.shift();
        dataUmidadeRoupa.shift();
    }

    // Atualizar gráficos
    chartTemperatura.update('none');
    chartUmidadeAr.update('none');
    chartUmidadeRoupa.update('none');
}

// ========================================
// FUNÇÕES DE LOGS
// ========================================
function addLog(mensagem, tipo = 'info') {
    const timestamp = new Date().toLocaleTimeString('pt-BR');
    
    logs.unshift({
        time: timestamp,
        message: mensagem,
        type: tipo
    });

    // Limitar quantidade de logs
    if (logs.length > CONFIG.MAX_LOGS) {
        logs.pop();
    }

    atualizarLogsUI();
}

function atualizarLogsUI() {
    const container = document.getElementById('logsContainer');
    
    container.innerHTML = logs.map(log => `
        <div class="log-entry log-${log.type}">
            <span class="log-time">${log.time}</span>
            <span class="log-message">${log.message}</span>
        </div>
    `).join('');
}

// ========================================
// FUNÇÕES DE ATUALIZAÇÃO DE DADOS
// ========================================
function carregarDados() {
    fetch(CONFIG.LOCAL_API)
        .then(response => {
            if (!response.ok) {
                throw new Error('Erro HTTP: ' + response.status);
            }
            return response.json();
        })
        .then(data => {
            atualizarInterface(data);
            atualizarGraficos(data);
            updateConnectionStatus(true);
            
            addLog(`Dados recebidos: Temp=${data.temperatura}°C, UmidAr=${data.umidade_ar}%, UmidRoupa=${data.umidade_roupa}%`, 'success');
        })
        .catch(error => {
            console.error('Erro:', error);
            updateConnectionStatus(false);
            addLog('Erro ao carregar dados: ' + error.message, 'error');
        });
}

function atualizarInterface(dados) {
    // Temperatura
    const tempElement = document.getElementById('tempValue');
    if (tempElement) {
        tempElement.textContent = dados.temperatura !== undefined && dados.temperatura !== null 
            ? parseFloat(dados.temperatura).toFixed(1) 
            : '--';
    }
    
    // Umidade do ar
    const humidityElement = document.getElementById('humidityValue');
    if (humidityElement) {
        humidityElement.textContent = dados.umidade_ar !== undefined && dados.umidade_ar !== null 
            ? parseFloat(dados.umidade_ar).toFixed(1) 
            : '--';
    }
    
    // Umidade da roupa
    const roupaElement = document.getElementById('roupaValue');
    if (roupaElement) {
        roupaElement.textContent = dados.umidade_roupa !== undefined && dados.umidade_roupa !== null 
            ? dados.umidade_roupa 
            : '--';
    }
    
    // Status da roupa
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
    
    // Última atualização
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
    
    addLog('Atualização automática iniciada', 'info');
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
// FUNÇÕES DOS MODAIS
// ========================================
function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    
    sidebar.classList.toggle('active');
    overlay.classList.toggle('active');
}

function closeSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    
    sidebar.classList.remove('active');
    overlay.classList.remove('active');
}

function openConfigModal() {
    document.getElementById('configModal').classList.add('active');
    closeSidebar();
}

function openHistoricoModal() {
    document.getElementById('historicoModal').classList.add('active');
    closeSidebar();
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
    }
}

function salvarConfig(event) {
    event.preventDefault();
    addLog('Configuração salva com sucesso', 'success');
    closeModal('configModal');
}

// ========================================
// LIMPEZA
// ========================================
window.addEventListener('beforeunload', function() {
    if (updateTimer) {
        clearInterval(updateTimer);
    }
});