// Variáveis globais para os gráficos
let chartTemperatura, chartUmidadeAr, chartUmidadeRoupa;

// Configuração padrão dos gráficos
const chartConfig = {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
        legend: {
            display: true,
            position: 'top'
        }
    },
    scales: {
        y: {
            beginAtZero: false
        }
    }
};

/**
 * Inicializa os gráficos
 */
function initCharts() {
    // Gráfico de Temperatura
    const ctxTemp = document.getElementById('chartTemperatura').getContext('2d');
    chartTemperatura = new Chart(ctxTemp, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Temperatura (°C)',
                data: [],
                borderColor: 'rgb(255, 99, 132)',
                backgroundColor: 'rgba(255, 99, 132, 0.2)',
                tension: 0.3
            }]
        },
        options: chartConfig
    });
    
    // Gráfico de Umidade do Ar
    const ctxUmAr = document.getElementById('chartUmidadeAr').getContext('2d');
    chartUmidadeAr = new Chart(ctxUmAr, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Umidade do Ar (%)',
                data: [],
                borderColor: 'rgb(54, 162, 235)',
                backgroundColor: 'rgba(54, 162, 235, 0.2)',
                tension: 0.3
            }]
        },
        options: chartConfig
    });
    
    // Gráfico de Umidade da Roupa
    const ctxUmRoupa = document.getElementById('chartUmidadeRoupa').getContext('2d');
    chartUmidadeRoupa = new Chart(ctxUmRoupa, {
        type: 'bar',
        data: {
            labels: [],
            datasets: [{
                label: 'Umidade da Roupa (%)',
                data: [],
                backgroundColor: 'rgba(75, 192, 192, 0.6)',
                borderColor: 'rgb(75, 192, 192)',
                borderWidth: 1
            }]
        },
        options: {
            ...chartConfig,
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100
                }
            }
        }
    });
}

/**
 * Atualiza os dados dos gráficos
 */
async function updateDashboard() {
    try {
        const response = await fetch('actions/api_dashboard.php');
        const data = await response.json();
        
        if (data.success) {
            // Atualizar gráfico de temperatura
            chartTemperatura.data.labels = data.temperatura.map(item => item.horario);
            chartTemperatura.data.datasets[0].data = data.temperatura.map(item => item.temperatura);
            chartTemperatura.update();
            
            // Atualizar gráfico de umidade do ar
            chartUmidadeAr.data.labels = data.umidade_ar.map(item => item.horario);
            chartUmidadeAr.data.datasets[0].data = data.umidade_ar.map(item => item.umidade_ar);
            chartUmidadeAr.update();
            
            // Atualizar gráfico de umidade da roupa
            chartUmidadeRoupa.data.labels = data.umidade_roupa.map(item => item.horario);
            chartUmidadeRoupa.data.datasets[0].data = data.umidade_roupa.map(item => item.umidade_percentual);
            
            // Colorir barras baseado no status
            chartUmidadeRoupa.data.datasets[0].backgroundColor = data.umidade_roupa.map(item => {
                return item.status_roupa === 'Seca' ? 'rgba(75, 192, 192, 0.6)' : 'rgba(255, 206, 86, 0.6)';
            });
            chartUmidadeRoupa.update();
            
            // Atualizar timestamp
            document.getElementById('lastUpdate').textContent = 
                `Última atualização: ${data.timestamp}`;
            
            console.log('Dashboard atualizado com sucesso');
            return true;
        } else {
            console.error('Erro ao atualizar dashboard:', data.error);
            return false;
        }
    } catch (error) {
        console.error('Erro na requisição:', error);
        return false;
    }
}

/**
 * Atualização manual via botão
 */
async function manualRefresh() {
    const btn = document.getElementById('btnRefresh');
    const icon = btn.querySelector('i');
    
    // Desabilitar botão e mostrar loading
    btn.disabled = true;
    icon.classList.add('fa-spin');
    btn.innerHTML = '<i class="fas fa-sync-alt fa-spin"></i> Atualizando...';
    
    // Atualizar dashboard
    const success = await updateDashboard();
    
    // Restaurar botão
    setTimeout(() => {
        btn.disabled = false;
        icon.classList.remove('fa-spin');
        btn.innerHTML = '<i class="fas fa-sync-alt"></i> Atualizar Agora';
        
        // Mostrar feedback
        if (success) {
            showToast('Gráficos atualizados com sucesso!', 'success');
        } else {
            showToast('Erro ao atualizar. Tente novamente.', 'danger');
        }
    }, 500);
}

/**
 * Mostra notificação toast
 */
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `alert alert-${type} position-fixed top-0 end-0 m-3`;
    toast.style.zIndex = '9999';
    toast.style.minWidth = '300px';
    toast.innerHTML = `
        <strong>${type === 'success' ? '✓' : '✗'}</strong> ${message}
    `;
    
    document.body.appendChild(toast);
    
    // Remover após 3 segundos
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transition = 'opacity 0.5s';
        setTimeout(() => toast.remove(), 500);
    }, 3000);
}

/**
 * Inicializa quando a página carregar
 */
document.addEventListener('DOMContentLoaded', function() {
    // Inicializar gráficos
    initCharts();
    
    // Carregar dados iniciais
    updateDashboard();
    
    // Atualizar a cada 5 minutos (300000 ms)
    setInterval(updateDashboard, 300000);
    
    console.log('Dashboard inicializado - Auto-refresh ativado (5 minutos)');
});
