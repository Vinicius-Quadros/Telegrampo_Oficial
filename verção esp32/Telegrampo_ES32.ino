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
 * - LED Azul (Roupa Úmida) - Pino 32
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

// ========================================
// CONFIGURAÇÕES - ALTERE AQUI!
// ========================================

// WiFi
const char* WIFI_SSID = "";
const char* WIFI_PASSWORD = "";

// IP Estático (ajuste conforme sua rede)
IPAddress local_IP(192, 168, 100, 200);  // IP fixo do ESP32
IPAddress gateway(192, 168, 100, 1);     // Gateway da sua rede
IPAddress subnet(255, 255, 255, 0);      // Máscara de sub-rede
IPAddress primaryDNS(8, 8, 8, 8);        // DNS do Google

// Dispositivo
const char* DEVICE_ID = "ESP32_001";

// Servidor API PHP
String API_URL = "http://192.168.100.182/telegrampo/api/salvar_leituras.php";
String API_NOTIFICACOES = "http://192.168.100.182/telegrampo/api/obter_notificacoes.php";
String API_MARCAR_ENVIADA = "http://192.168.100.182/telegrampo/api/marcar_notificacao_enviada.php";

// Token do Bot Telegram
const char* TELEGRAM_BOT_TOKEN = "8238331019:AAG1gn4RQq9t7rK9LwWkFleuRXZyzTbw4hI";

// Pinos
#define DHT_PIN 33           // DHT22
#define UMIDADE_PIN 34       // Sensor de umidade (ADC)
#define LED_AZUL 32          // LED Úmida
#define LED_VERMELHO 25      // LED Seca

// DHT22
#define DHT_TYPE DHT22
DHT dht22(DHT_PIN, DHT_TYPE);

// Servidor Web
WebServer server(80);

// ========================================
// VARIÁVEIS GLOBAIS
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
// SETUP
// ========================================

void setup() {
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
  Serial.println("✓ DHT22 inicializado");
  
  // Iniciar LittleFS
  if (!LittleFS.begin(true)) {
    Serial.println("✗ Erro ao montar LittleFS");
  } else {
    Serial.println("✓ LittleFS montado com sucesso");
  }
  
  // Conectar WiFi com IP estático
  conectarWiFi();
  
  // Configurar servidor web
  configurarServidorWeb();
  
  Serial.println("\n========================================");
  Serial.println("TELEGRAMPO - Pronto!");
  Serial.println("Acesse: http://" + WiFi.localIP().toString());
  Serial.println("========================================\n");
}

// ========================================
// LOOP PRINCIPAL
// ========================================

void loop() {
  // Processar requisições web
  server.handleClient();
  
  unsigned long currentMillis = millis();
  
  // Ler sensores e enviar dados a cada 5 segundos
  if (currentMillis - previousMillisLeitura >= intervaloLeitura) {
    previousMillisLeitura = currentMillis;
    
    lerSensores();
    atualizarLEDs();
    enviarDadosParaAPI();
  }
  
  // Verificar notificações a cada 10 segundos
  if (currentMillis - previousMillisNotificacao >= intervaloNotificacao) {
    previousMillisNotificacao = currentMillis;
    
    verificarNotificacoes();
  }
}

// ========================================
// FUNÇÕES DE WIFI
// ========================================

void conectarWiFi() {
  Serial.println("Configurando IP estático...");
  
  if (!WiFi.config(local_IP, gateway, subnet, primaryDNS)) {
    Serial.println("✗ Falha ao configurar IP estático");
  }
    
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  Serial.print("Conectando ao WiFi ");
  Serial.println(WIFI_SSID);
  
  int tentativas = 0;
  while (WiFi.status() != WL_CONNECTED && tentativas < 30) {
    delay(500);
    Serial.print(".");
    tentativas++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n--------------------------------------------------");
    Serial.print("✓ Conectado a: ");
    Serial.println(WIFI_SSID);
    Serial.print("IP Estático: ");
    Serial.println(WiFi.localIP());
    Serial.println("--------------------------------------------------");
  } else {
    Serial.println("\n✗ Falha ao conectar WiFi");
  }
}

// ========================================
// FUNÇÕES DE LEITURA DE SENSORES
// ========================================

void lerSensores() {
  Serial.println("\n--- Lendo Sensores ---");
  
  // Ler DHT22 (Temperatura e Umidade do Ar)
  temperatura = dht22.readTemperature();
  umidade_ar = dht22.readHumidity();
  
  if (isnan(temperatura) || isnan(umidade_ar)) {
    Serial.println("✗ Erro ao ler DHT22");
    temperatura = 0;
    umidade_ar = 0;
  } else {
    Serial.print("Temperatura: ");
    Serial.print(temperatura);
    Serial.println(" °C");
    
    Serial.print("Umidade Ar: ");
    Serial.print(umidade_ar);
    Serial.println(" %");
  }
  
  // Ler Sensor de Umidade da Roupa
  valor_bruto_umidade = analogRead(UMIDADE_PIN);
  
  // MAPEAMENTO CORRETO: quanto menor o valor, mais úmido
  // 4095 = seco (ar), 0 = molhado (água)
  umidade_roupa = map(valor_bruto_umidade, 4095, 0, 0, 100);
  umidade_roupa = constrain(umidade_roupa, 0, 100);
  
  Serial.print("Umidade Roupa: ");
  Serial.print(umidade_roupa);
  Serial.print(" % (Bruto: ");
  Serial.print(valor_bruto_umidade);
  Serial.println(")");
  
  // Determinar status da roupa (limiar ajustável)
  if (umidade_roupa < 5) {  // Menos de 40% = Seca
    status_roupa = "Seca";
  } else {
    status_roupa = "Úmida";
  }
  
  Serial.print("Status: ");
  Serial.println(status_roupa);
  Serial.println("----------------------");
}

void atualizarLEDs() {
  // Lógica corrigida: < 40% = Seca (LED Vermelho)
  if (umidade_roupa < 40) {
    digitalWrite(LED_AZUL, LOW);
    digitalWrite(LED_VERMELHO, HIGH);
  } else {
    digitalWrite(LED_AZUL, HIGH);
    digitalWrite(LED_VERMELHO, LOW);
  }
}

// ========================================
// FUNÇÕES DE COMUNICAÇÃO COM API
// ========================================

void enviarDadosParaAPI() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("✗ WiFi desconectado");
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
    Serial.print("✓ HTTP Code: ");
    Serial.println(httpCode);
    
    if (httpCode == 200) {
      String payload = http.getString();
      Serial.print("Resposta: ");
      Serial.println(payload);
    }
  } else {
    Serial.print("✗ Erro: ");
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
    
    // Verificar se há notificações pendentes
    if (response.indexOf("\"total\":0") == -1 && response.indexOf("notificacoes") != -1) {
      Serial.println("\n--- Notificações Pendentes ---");
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
  
  // Extrair ID da notificação
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
    Serial.println("✗ Falha ao conectar Telegram");
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
      Serial.println("✗ Timeout Telegram");
      client.stop();
      return false;
    }
  }
  
  while (client.available()) {
    String line = client.readStringUntil('\n');
    if (line.indexOf("\"ok\":true") != -1) {
      Serial.println("✓ Telegram enviado!");
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
    Serial.println("✓ Notificação marcada como enviada");
  }
  
  http.end();
}

// ========================================
// SERVIDOR WEB
// ========================================

void configurarServidorWeb() {
  // Rota raiz
  server.on("/", []() {
    File file = LittleFS.open("/index.html", "r");
    if (!file) {
      server.send(404, "text/plain", "Arquivo não encontrado");
      return;
    }
    server.streamFile(file, "text/html");
    file.close();
  });
  
  // Rota CSS
  server.on("/styles.css", []() {
    File file = LittleFS.open("/styles.css", "r");
    if (!file) {
      server.send(404, "text/plain", "Arquivo não encontrado");
      return;
    }
    server.streamFile(file, "text/css");
    file.close();
  });
  
  // Rota JS
  server.on("/script.js", []() {
    File file = LittleFS.open("/script.js", "r");
    if (!file) {
      server.send(404, "text/plain", "Arquivo não encontrado");
      return;
    }
    server.streamFile(file, "application/javascript");
    file.close();
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
  
  server.begin();
  Serial.println("✓ Servidor Web iniciado");
}

// ========================================
// FUNÇÕES AUXILIARES
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