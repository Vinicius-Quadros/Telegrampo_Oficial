/*
 * ========================================
 * PROJETO TELEGRAMPO - ESP32
 * Sistema de Monitoramento de Secagem de Roupas
 * ========================================
 * 
 * Hardware:
 * - ESP32-WROOM-32
 * - Sensor DHT22 (Temperatura e Umidade do Ar) - Pino 33
 * - Sensor de Umidade do Solo (adaptado para roupa) - Pino 34
 * - LED Azul (Roupa Ãšmida) - Pino 32
 * - LED Vermelho (Roupa Seca) - Pino 25
 * 
 * ========================================
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <WebServer.h>
#include <LittleFS.h>
#include <DHT.h>
#include <ESPmDNS.h>
// ========================================
// CONFIGURAÃ‡Ã•ES - ALTERE AQUI!
// ========================================

// WiFi
const char* WIFI_SSID = "LUCAS";
const char* WIFI_PASSWORD = "lucasar25";

// IP Estático (ajuste conforme sua rede)
IPAddress local_IP(10,11,111,140);  // Mudou para sua rede
IPAddress gateway(10,11,111,192);     // Gateway da sua rede
IPAddress subnet(255, 255, 255, 0);
IPAddress primaryDNS(8, 8, 8, 8);

// Dispositivo
const char* DEVICE_ID = "ESP32_001";
const char* MDNS_NAME = "telegrampo"; 

// Servidor API PHP (seu IP Ethernet: 10.11.111.137)
String API_URL = "http://10.11.111.137/telegrampo/api/salvar_leituras.php";
String API_NOTIFICACOES = "http://10.11.111.137/telegrampo/api/obter_notificacoes.php";
String API_MARCAR_ENVIADA = "http://10.11.111.137/telegrampo/api/marcar_notificacao_enviada.php";

// Token do Bot Telegram
const char* TELEGRAM_BOT_TOKEN = "8238331019:AAG1gn4RQq9t7rK9LwWkFleuRXZyzTbw4hI";
// Estrutura para armazenar configurações
struct Config {
  char wifi_ssid[32] = "LUCAS";
  char wifi_password[64] = "lucasar25";
  uint8_t ip[4] = {10,11,111,140};
  uint8_t gateway[4] = {10,11,111,192};
  char api_url[128] = "http://10.11.111.137/telegrampo/api/salvar_leituras.php";
  char api_notificacoes[128] = "http://10.11.111.137/telegrampo/api/obter_notificacoes.php";
  char api_marcar_enviada[128] = "http://10.11.111.137/telegrampo/api/marcar_notificacao_enviada.php";
};

Config config;
// Pinos
#define DHT_PIN 33           // DHT22
#define UMIDADE_PIN 34       // Sensor de umidade (ADC)
#define LED_AZUL 32          // LED Ãšmida
#define LED_VERMELHO 25      // LED Seca

// DHT22
#define DHT_TYPE DHT22
DHT dht22(DHT_PIN, DHT_TYPE);

// Servidor Web
WebServer server(80);

// ========================================
// VARIÃVEIS GLOBAIS
// ========================================

// Leituras dos sensores
float temperatura = 0;
float umidade_ar = 0;
int valor_bruto_umidade = 0;
int umidade_roupa = 0;
String status_roupa = "Desconhecido";

// Controle de tempo (sem delay)
unsigned long previousMillisLeitura = 0;
unsigned long previousMillisNotificacao = 0;
const long intervaloLeitura = 5000;       // 5 segundos
const long intervaloNotificacao = 10000;  // 10 segundos

// ========================================
// FUNÇÕES DE CONFIGURAÇÃO
// ========================================

void salvarConfig() {
  File file = LittleFS.open("/config.bin", "w");
  if (file) {
    file.write((byte*)&config, sizeof(config));
    file.close();
    Serial.println("✓ Configuração salva");
  } else {
    Serial.println("✗ Erro ao salvar configuração");
  }
}

void carregarConfig() {
  if (LittleFS.exists("/config.bin")) {
    File file = LittleFS.open("/config.bin", "r");
    if (file) {
      file.read((byte*)&config, sizeof(config));
      file.close();
      Serial.println("✓ Configuração carregada");
      
      // Atualizar variáveis globais
      API_URL = String(config.api_url);
      API_NOTIFICACOES = String(config.api_notificacoes);
      API_MARCAR_ENVIADA = String(config.api_marcar_enviada);
    }
  } else {
    Serial.println("⚠ Usando configuração padrão");
  }
}
// ========================================
// SETUP
// ========================================

void setup() {
  WiFi.disconnect(true, true);
  delay(1000);
  Serial.begin(115200);
  Serial.println("\n\n========================================");
  Serial.println("TELEGRAMPO - Iniciando...");
  Serial.println("========================================\n");
  
  // Configurar pinos
  pinMode(LED_AZUL, OUTPUT);
  pinMode(LED_VERMELHO, OUTPUT);
  pinMode(UMIDADE_PIN, INPUT);
  
  // LEDs iniciais (teste)
  digitalWrite(LED_AZUL, HIGH);
  digitalWrite(LED_VERMELHO, HIGH);
  delay(1000);
  digitalWrite(LED_AZUL, LOW);
  digitalWrite(LED_VERMELHO, LOW);
  
  // Iniciar DHT22
  dht22.begin();
  Serial.println("âœ“ DHT22 inicializado");
  
  // Iniciar LittleFS
  if (!LittleFS.begin(true)) {
    Serial.println("âœ— Erro ao montar LittleFS");
  } else {
    Serial.println("âœ“ LittleFS montado com sucesso");
  }
  
// Carregar configurações salvas PRIMEIRO
  carregarConfig();
  
  // Conectar WiFi com as configurações carregadas
  conectarWiFi();
  
  // Inicializar mDNS
  if (MDNS.begin(MDNS_NAME)) {
    Serial.println("✓ mDNS iniciado");
    Serial.print("Acesse via: http://");
    Serial.print(MDNS_NAME);
    Serial.println(".local");
    MDNS.addService("http", "tcp", 80);
  } else {
    Serial.println("✗ Erro ao iniciar mDNS");
  }
  
  // Configurar servidor web
  configurarServidorWeb();
  Serial.println("\n========================================");
  Serial.println("TELEGRAMPO - Pronto!");
  Serial.println("Acesse: http://" + WiFi.localIP().toString());
  Serial.println("ou http://" + String(MDNS_NAME) + ".local");  // ADICIONAR ESTA LINHA
  Serial.println("========================================\n");
  Serial.println("Testando servidor web...");
Serial.println("GET http://" + WiFi.localIP().toString() + "/sensor_data");
}

// ========================================
// LOOP PRINCIPAL
// ========================================

void loop() {
  // Processar requisiÃ§Ãµes web
  server.handleClient();
  // REMOVER A LINHA MDNS.update() - nÃ£o Ã© necessÃ¡ria no ESP32
  
  unsigned long currentMillis = millis();
  
  // Ler sensores e enviar dados a cada 5 segundos
  if (currentMillis - previousMillisLeitura >= intervaloLeitura) {
    previousMillisLeitura = currentMillis;
    
    lerSensores();
    atualizarLEDs();
    enviarDadosParaAPI();
  }
  
  // Verificar notificaÃ§Ãµes a cada 10 segundos
  if (currentMillis - previousMillisNotificacao >= intervaloNotificacao) {
    previousMillisNotificacao = currentMillis;
    
    verificarNotificacoes();
  }
}
// ========================================
// FUNÃ‡Ã•ES DE WIFI
// ========================================

void conectarWiFi() {
  Serial.println("Configurando IP estático...");
  
  IPAddress localIP(config.ip[0], config.ip[1], config.ip[2], config.ip[3]);
  IPAddress gw(config.gateway[0], config.gateway[1], config.gateway[2], config.gateway[3]);
  IPAddress subnet(255, 255, 255, 0);
  IPAddress primaryDNS(8, 8, 8, 8);
  
  if (!WiFi.config(localIP, gw, subnet, primaryDNS)) {
    Serial.println("✗ Falha ao configurar IP estático");
  }
    
  WiFi.mode(WIFI_STA);
  WiFi.begin(config.wifi_ssid, config.wifi_password);
  
  Serial.print("Conectando ao WiFi ");
  Serial.println(config.wifi_ssid);
  
  int tentativas = 0;
  while (WiFi.status() != WL_CONNECTED && tentativas < 30) {
    delay(500);
    Serial.print(".");
    tentativas++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n--------------------------------------------------");
    Serial.print("✓ Conectado a: ");
    Serial.println(config.wifi_ssid);
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    Serial.println("--------------------------------------------------");
  } else {
    Serial.println("\n✗ Falha ao conectar WiFi");
  }
}

// ========================================
// FUNÃ‡Ã•ES DE LEITURA DE SENSORES
// ========================================

void lerSensores() {
  Serial.println("\n--- Lendo Sensores ---");
  
  // Ler DHT22 (Temperatura e Umidade do Ar)
  temperatura = dht22.readTemperature();
  umidade_ar = dht22.readHumidity();
  
  if (isnan(temperatura) || isnan(umidade_ar)) {
    Serial.println("âœ— Erro ao ler DHT22");
    temperatura = 0;
    umidade_ar = 0;
  } else {
    Serial.print("Temperatura: ");
    Serial.print(temperatura);
    Serial.println(" Â°C");
    
    Serial.print("Umidade Ar: ");
    Serial.print(umidade_ar);
    Serial.println(" %");
  }
  
  // Ler Sensor de Umidade da Roupa
  valor_bruto_umidade = analogRead(UMIDADE_PIN);
  
  // MAPEAMENTO CORRETO: quanto menor o valor, mais Ãºmido
  // 4095 = seco (ar), 0 = molhado (Ã¡gua)
  umidade_roupa = map(valor_bruto_umidade, 4095, 0, 0, 100);
  umidade_roupa = constrain(umidade_roupa, 0, 100);
  
  Serial.print("Umidade Roupa: ");
  Serial.print(umidade_roupa);
  Serial.print(" % (Bruto: ");
  Serial.print(valor_bruto_umidade);
  Serial.println(")");
  
  // Determinar status da roupa (limiar ajustÃ¡vel)
  if (umidade_roupa < 5) {  // Menos de 40% = Seca
    status_roupa = "Seca";
  } else {
    status_roupa = "Umida";
  }
  
  Serial.print("Status: ");
  Serial.println(status_roupa);
  Serial.println("----------------------");
}

void atualizarLEDs() {
  // LÃ³gica corrigida: < 40% = Seca (LED Vermelho)
  if (umidade_roupa < 40) {
    digitalWrite(LED_AZUL, LOW);
    digitalWrite(LED_VERMELHO, HIGH);
  } else {
    digitalWrite(LED_AZUL, HIGH);
    digitalWrite(LED_VERMELHO, LOW);
  }
}

// ========================================
// FUNÃ‡Ã•ES DE COMUNICAÃ‡ÃƒO COM API
// ========================================

void enviarDadosParaAPI() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("âœ— WiFi desconectado");
    return;
  }
  
  // Montar dados POST
  String postData = "device_id=" + String(DEVICE_ID);
  postData += "&temperatura=" + String(temperatura);
  postData += "&umidade_ar=" + String(umidade_ar);
  postData += "&valor_bruto=" + String(valor_bruto_umidade);
  postData += "&umidade_percentual=" + String(umidade_roupa);
  
  Serial.println("\n--- Enviando para API ---");
  Serial.print("URL: ");
  Serial.println(API_URL);
  Serial.print("Dados: ");
  Serial.println(postData);
  
  HTTPClient http;
  http.begin(API_URL);
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  
  int httpCode = http.POST(postData);
  
  if (httpCode > 0) {
    Serial.print("âœ“ HTTP Code: ");
    Serial.println(httpCode);
    
    if (httpCode == 200) {
      String payload = http.getString();
      Serial.print("Resposta: ");
      Serial.println(payload);
    }
  } else {
    Serial.print("âœ— Erro: ");
    Serial.println(http.errorToString(httpCode));
  }
  
  http.end();
  Serial.println("-------------------------");
}

void verificarNotificacoes() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  HTTPClient http;
  String url = API_NOTIFICACOES + "?device_id=" + String(DEVICE_ID);
  
  http.begin(url);
  int httpCode = http.GET();
  
  if (httpCode == 200) {
    String response = http.getString();
    
    // Verificar se hÃ¡ notificaÃ§Ãµes pendentes
    if (response.indexOf("\"total\":0") == -1 && response.indexOf("notificacoes") != -1) {
      Serial.println("\n--- NotificaÃ§Ãµes Pendentes ---");
      processarNotificacoes(response);
    }
  }
  
  http.end();
}

void processarNotificacoes(String jsonResponse) {
  // Parser manual simplificado
  int posId = jsonResponse.indexOf("\"id\":");
  int posMensagem = jsonResponse.indexOf("\"mensagem\":\"");
  int posChatId = jsonResponse.indexOf("\"chat_id\":\"");
  
  if (posId == -1 || posMensagem == -1 || posChatId == -1) {
    return;
  }
  
  // Extrair ID da notificaÃ§Ã£o
  int idStart = posId + 5;
  int idEnd = jsonResponse.indexOf(",", idStart);
  String notificacao_id = jsonResponse.substring(idStart, idEnd);
  
  // Extrair mensagem
  int msgStart = posMensagem + 12;
  int msgEnd = jsonResponse.indexOf("\"", msgStart);
  String mensagem = jsonResponse.substring(msgStart, msgEnd);
  
  // Extrair chat_id
  int chatStart = posChatId + 11;
  int chatEnd = jsonResponse.indexOf("\"", chatStart);
  String chat_id = jsonResponse.substring(chatStart, chatEnd);
  
  Serial.print("ID: ");
  Serial.println(notificacao_id);
  Serial.print("Mensagem: ");
  Serial.println(mensagem);
  Serial.print("Chat ID: ");
  Serial.println(chat_id);
  
  // Enviar via Telegram
  if (enviarTelegram(chat_id, mensagem)) {
    marcarNotificacaoEnviada(notificacao_id);
  }
  
  Serial.println("-------------------------------");
}

bool enviarTelegram(String chat_id, String mensagem) {
  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }
  
  WiFiClientSecure client;
  client.setInsecure();
  
  if (!client.connect("api.telegram.org", 443)) {
    Serial.println("âœ— Falha ao conectar Telegram");
    return false;
  }
  
  String url = "/bot" + String(TELEGRAM_BOT_TOKEN) + "/sendMessage?chat_id=" + chat_id + "&text=" + urlEncode(mensagem);
  
  client.println("GET " + url + " HTTP/1.1");
  client.println("Host: api.telegram.org");
  client.println("Connection: close");
  client.println();
  
  unsigned long timeout = millis();
  while (client.available() == 0) {
    if (millis() - timeout > 5000) {
      Serial.println("âœ— Timeout Telegram");
      client.stop();
      return false;
    }
  }
  
  while (client.available()) {
    String line = client.readStringUntil('\n');
    if (line.indexOf("\"ok\":true") != -1) {
      Serial.println("âœ“ Telegram enviado!");
      client.stop();
      return true;
    }
  }
  
  client.stop();
  return false;
}

void marcarNotificacaoEnviada(String notificacao_id) {
  HTTPClient http;
  String postData = "device_id=" + String(DEVICE_ID) + "&notificacao_id=" + notificacao_id;
  
  http.begin(API_MARCAR_ENVIADA);
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  
  int httpCode = http.POST(postData);
  
  if (httpCode == 200) {
    Serial.println("âœ“ NotificaÃ§Ã£o marcada como enviada");
  }
  
  http.end();
}

// ========================================
// CONFIGURAR SERVIDOR WEB
// ========================================

void configurarServidorWeb() {
  // Página principal
  server.on("/", []() {
    String html = R"rawliteral(
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TELEGRAMPO - Monitor IoT</title>
    <link rel="stylesheet" href="/styles.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌡️ TELEGRAMPO</h1>
            <div class="last-update" id="lastUpdate">Carregando dados...</div>
            <a href="/config" style="color: white; text-decoration: underline; font-size: 0.9rem; margin-top: 10px; display: inline-block;">⚙️ Configurações</a>
        </div>

        <div class="connection-status" id="connectionStatus">Conectando...</div>

        <div class="dashboard" id="dashboard">
            <div class="card">
                <div class="card-icon" id="statusIcon">👕</div>
                <div class="card-title">Status da Roupa</div>
                <div class="card-value" id="statusValue">---</div>
                <div class="card-unit">Estado atual</div>
            </div>

            <div class="card">
                <div class="card-icon">🌡️</div>
                <div class="card-title">Temperatura</div>
                <div class="card-value temperature" id="tempValue">--</div>
                <div class="card-unit">°C</div>
            </div>

            <div class="card">
                <div class="card-icon">💧</div>
                <div class="card-title">Umidade do Ar</div>
                <div class="card-value humidity" id="humidityValue">--</div>
                <div class="card-unit">%</div>
            </div>

            <div class="card">
                <div class="card-icon">👔</div>
                <div class="card-title">Umidade da Roupa</div>
                <div class="card-value" id="roupaValue">--</div>
                <div class="card-unit">%</div>
            </div>
        </div>
    </div>
    <script src="/script.js"></script>
</body>
</html>
)rawliteral";
    
    server.send(200, "text/html", html);
  });
  
  // Rota CSS
  server.on("/styles.css", []() {
    String css = R"rawliteral(
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    padding: 20px;
    color: #333;
}

.container {
    max-width: 800px;
    margin: 0 auto;
}

.header {
    text-align: center;
    margin-bottom: 30px;
    color: white;
}

.header h1 {
    font-size: 2.2rem;
    margin-bottom: 10px;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

.last-update {
    font-size: 0.9rem;
    opacity: 0.9;
}

.dashboard {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-bottom: 30px;
}

.card {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(10px);
    border-radius: 15px;
    padding: 25px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.card:hover {
    transform: translateY(-5px);
    box-shadow: 0 15px 40px rgba(0, 0, 0, 0.15);
}

.card-icon {
    font-size: 2.5rem;
    margin-bottom: 15px;
    display: block;
    text-align: center;
}

.card-title {
    font-size: 1.1rem;
    font-weight: 600;
    margin-bottom: 10px;
    text-align: center;
    color: #555;
}

.card-value {
    font-size: 2rem;
    font-weight: bold;
    text-align: center;
    margin-bottom: 5px;
}

.card-unit {
    font-size: 0.9rem;
    text-align: center;
    opacity: 0.7;
}

.temperature {
    color: #e74c3c;
}

.humidity {
    color: #3498db;
}

.status-umida {
    color: #3498db;
}

.status-seca {
    color: #27ae60;
}

.connection-status {
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 10px 15px;
    border-radius: 25px;
    font-size: 0.8rem;
    font-weight: bold;
    z-index: 1000;
}

.connected {
    background: rgba(39, 174, 96, 0.9);
    color: white;
}

.disconnected {
    background: rgba(231, 76, 60, 0.9);
    color: white;
}

@media (max-width: 768px) {
    .dashboard {
        gap: 15px;
    }
}

@media (max-width: 480px) {
    .dashboard {
        grid-template-columns: 1fr;
    }
}
)rawliteral";
    
    server.send(200, "text/css", css);
  });
  
  // Rota JS
  server.on("/script.js", []() {
    String js = R"rawliteral(
const CONFIG = {
    LOCAL_API: '/sensor_data',
    UPDATE_INTERVAL: 2000
};

let updateTimer = null;

document.addEventListener('DOMContentLoaded', function() {
    console.log('TELEGRAMPO Access Point - Iniciado!');
    carregarDados();
    startAutoUpdate();
});

function carregarDados() {
    fetch(CONFIG.LOCAL_API)
        .then(response => response.json())
        .then(data => {
            atualizarInterface(data);
            updateConnectionStatus(true);
        })
        .catch(error => {
            console.error('Erro:', error);
            updateConnectionStatus(false);
        });
}

function atualizarInterface(dados) {
    document.getElementById('tempValue').textContent = 
        dados.temperatura !== undefined ? parseFloat(dados.temperatura).toFixed(1) : '--';
    
    document.getElementById('humidityValue').textContent = 
        dados.umidade_ar !== undefined ? parseFloat(dados.umidade_ar).toFixed(1) : '--';
    
    document.getElementById('roupaValue').textContent = 
        dados.umidade_roupa !== undefined ? dados.umidade_roupa : '--';
    
    const statusValue = document.getElementById('statusValue');
    const statusIcon = document.getElementById('statusIcon');
    const status = dados.status_roupa || 'Desconhecido';
    
    statusValue.textContent = status;
    
    if (status === 'Seca') {
        statusValue.className = 'card-value status-seca';
        statusIcon.textContent = '☀️';
    } else if (status === 'Úmida') {
        statusValue.className = 'card-value status-umida';
        statusIcon.textContent = '💧';
    }
    
    document.getElementById('lastUpdate').textContent = 
        'Última atualização: ' + new Date().toLocaleString('pt-BR');
}

function startAutoUpdate() {
    if (updateTimer) clearInterval(updateTimer);
    updateTimer = setInterval(carregarDados, CONFIG.UPDATE_INTERVAL);
}

function updateConnectionStatus(connected) {
    const statusElement = document.getElementById('connectionStatus');
    statusElement.className = connected ? 'connection-status connected' : 'connection-status disconnected';
    statusElement.textContent = connected ? '🟢 Conectado' : '🔴 Desconectado';
}
)rawliteral";
    
    server.send(200, "application/javascript", js);
  });
  
  // API local - dados dos sensores (JSON)
  server.on("/sensor_data", []() {
    String json = "{";
    json += "\"temperatura\":" + String(temperatura) + ",";
    json += "\"umidade_ar\":" + String(umidade_ar) + ",";
    json += "\"umidade_roupa\":" + String(umidade_roupa) + ",";
    json += "\"status_roupa\":\"" + status_roupa + "\",";
    json += "\"valor_bruto\":" + String(valor_bruto_umidade);
    json += "}";
    
    server.send(200, "application/json", json);
  });
  
  // Página de configuração
  server.on("/config", []() {
    String html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configurações - TELEGRAMPO</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        h1 { color: #667eea; margin-bottom: 30px; text-align: center; }
        h2 { color: #333; margin: 25px 0 15px; font-size: 1.2rem; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; color: #555; }
        input { width: 100%; padding: 10px; border: 2px solid #ddd; border-radius: 8px; font-size: 1rem; }
        input:focus { outline: none; border-color: #667eea; }
        .ip-group { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
        .ip-group input { text-align: center; }
        button { 
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 1.1rem;
            font-weight: bold;
            cursor: pointer;
            margin-top: 20px;
        }
        button:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102,126,234,0.4); }
        .btn-secondary {
            background: #6c757d;
            margin-top: 10px;
        }
        .success { background: #27ae60; padding: 15px; border-radius: 8px; color: white; text-align: center; margin-bottom: 20px; display: none; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚙️ Configurações do TELEGRAMPO</h1>
        <div class="success" id="success">Configurações salvas! Reiniciando...</div>
        
        <form id="configForm">
            <h2>📡 Configurações Wi-Fi</h2>
            <div class="form-group">
                <label>Nome da Rede (SSID)</label>
                <input type="text" name="wifi_ssid" value=")rawliteral" + String(config.wifi_ssid) + R"rawliteral(" required>
            </div>
            <div class="form-group">
                <label>Senha do Wi-Fi</label>
                <input type="password" name="wifi_password" value=")rawliteral" + String(config.wifi_password) + R"rawliteral(" required>
            </div>
            
            <h2>🌐 Configurações de IP</h2>
            <div class="form-group">
                <label>IP do ESP32</label>
                <div class="ip-group">
                    <input type="number" name="ip1" value=")rawliteral" + String(config.ip[0]) + R"rawliteral(" min="0" max="255" required>
                    <input type="number" name="ip2" value=")rawliteral" + String(config.ip[1]) + R"rawliteral(" min="0" max="255" required>
                    <input type="number" name="ip3" value=")rawliteral" + String(config.ip[2]) + R"rawliteral(" min="0" max="255" required>
                    <input type="number" name="ip4" value=")rawliteral" + String(config.ip[3]) + R"rawliteral(" min="0" max="255" required>
                </div>
            </div>
            <div class="form-group">
                <label>Gateway</label>
                <div class="ip-group">
                    <input type="number" name="gw1" value=")rawliteral" + String(config.gateway[0]) + R"rawliteral(" min="0" max="255" required>
                    <input type="number" name="gw2" value=")rawliteral" + String(config.gateway[1]) + R"rawliteral(" min="0" max="255" required>
                    <input type="number" name="gw3" value=")rawliteral" + String(config.gateway[2]) + R"rawliteral(" min="0" max="255" required>
                    <input type="number" name="gw4" value=")rawliteral" + String(config.gateway[3]) + R"rawliteral(" min="0" max="255" required>
                </div>
            </div>
            
            <h2>🔗 URLs da API</h2>
            <div class="form-group">
                <label>API Salvar Leituras</label>
                <input type="text" name="api_url" value=")rawliteral" + String(config.api_url) + R"rawliteral(" required>
            </div>
            <div class="form-group">
                <label>API Obter Notificações</label>
                <input type="text" name="api_notificacoes" value=")rawliteral" + String(config.api_notificacoes) + R"rawliteral(" required>
            </div>
            <div class="form-group">
                <label>API Marcar Enviada</label>
                <input type="text" name="api_marcar_enviada" value=")rawliteral" + String(config.api_marcar_enviada) + R"rawliteral(" required>
            </div>
            
            <button type="submit">💾 Salvar e Reiniciar</button>
            <button type="button" class="btn-secondary" onclick="window.location.href='/'">❌ Cancelar</button>
        </form>
    </div>
    
    <script>
        document.getElementById('configForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const params = new URLSearchParams(formData).toString();
            
            fetch('/save_config', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params
            })
            .then(response => response.text())
            .then(data => {
                document.getElementById('success').style.display = 'block';
                setTimeout(() => window.location.href = '/', 3000);
            });
        });
    </script>
</body>
</html>
)rawliteral";
    server.send(200, "text/html", html);
  });
  
  // Salvar configuração
  server.on("/save_config", HTTP_POST, []() {
    // WiFi
    if (server.hasArg("wifi_ssid")) {
      server.arg("wifi_ssid").toCharArray(config.wifi_ssid, 32);
    }
    if (server.hasArg("wifi_password")) {
      server.arg("wifi_password").toCharArray(config.wifi_password, 64);
    }
    
    // IP
    config.ip[0] = server.arg("ip1").toInt();
    config.ip[1] = server.arg("ip2").toInt();
    config.ip[2] = server.arg("ip3").toInt();
    config.ip[3] = server.arg("ip4").toInt();
    
    // Gateway
    config.gateway[0] = server.arg("gw1").toInt();
    config.gateway[1] = server.arg("gw2").toInt();
    config.gateway[2] = server.arg("gw3").toInt();
    config.gateway[3] = server.arg("gw4").toInt();
    
    // URLs
    if (server.hasArg("api_url")) {
      server.arg("api_url").toCharArray(config.api_url, 128);
      API_URL = String(config.api_url);
    }
    if (server.hasArg("api_notificacoes")) {
      server.arg("api_notificacoes").toCharArray(config.api_notificacoes, 128);
      API_NOTIFICACOES = String(config.api_notificacoes);
    }
    if (server.hasArg("api_marcar_enviada")) {
      server.arg("api_marcar_enviada").toCharArray(config.api_marcar_enviada, 128);
      API_MARCAR_ENVIADA = String(config.api_marcar_enviada);
    }
    
    salvarConfig();
    
    server.send(200, "text/plain", "OK");
    
    delay(1000);
    ESP.restart();
  });
  
  server.begin();
  Serial.println("✓ Servidor Web iniciado");
}

// ========================================
// FUNÃ‡Ã•ES AUXILIARES
// ========================================

String urlEncode(String str) {
  String encoded = "";
  char c;
  char code0;
  char code1;
  
  for (int i = 0; i < str.length(); i++) {
    c = str.charAt(i);
    if (c == ' ') {
      encoded += '+';
    } else if (isalnum(c)) {
      encoded += c;
    } else {
      code1 = (c & 0xf) + '0';
      if ((c & 0xf) > 9) {
        code1 = (c & 0xf) - 10 + 'A';
      }
      c = (c >> 4) & 0xf;
      code0 = c + '0';
      if (c > 9) {
        code0 = c - 10 + 'A';
      }
      encoded += '%';
      encoded += code0;
      encoded += code1;
    }
  }
  return encoded;
}