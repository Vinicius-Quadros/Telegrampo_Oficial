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
#include <ESPmDNS.h>

// ========================================
// CONFIGURAÇÕES - ALTERE AQUI!
// ========================================

// WiFi
const char* WIFI_SSID = "LUCAS";
const char* WIFI_PASSWORD = "lucasar25";

// IP Estático (ajuste conforme sua rede)
IPAddress local_IP(10,11,111,140);
IPAddress gateway(10,11,111,192);
IPAddress subnet(255, 255, 255, 0);
IPAddress primaryDNS(8, 8, 8, 8);

// Dispositivo
const char* DEVICE_ID = "ESP32_001";
const char* MDNS_NAME = "telegrampo"; 

// Servidor API PHP
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
#define DHT_PIN 33
#define UMIDADE_PIN 34
#define LED_AZUL 32
#define LED_VERMELHO 25

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
const long intervaloLeitura = 5000;
const long intervaloNotificacao = 10000;

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
  
  pinMode(LED_AZUL, OUTPUT);
  pinMode(LED_VERMELHO, OUTPUT);
  pinMode(UMIDADE_PIN, INPUT);
  
  digitalWrite(LED_AZUL, HIGH);
  digitalWrite(LED_VERMELHO, HIGH);
  delay(1000);
  digitalWrite(LED_AZUL, LOW);
  digitalWrite(LED_VERMELHO, LOW);
  
  dht22.begin();
  Serial.println("✓ DHT22 inicializado");
  
  if (!LittleFS.begin(true)) {
    Serial.println("✗ Erro ao montar LittleFS");
  } else {
    Serial.println("✓ LittleFS montado com sucesso");
  }
  
  carregarConfig();
  conectarWiFi();
  
  if (MDNS.begin(MDNS_NAME)) {
    Serial.println("✓ mDNS iniciado");
    Serial.print("Acesse via: http://");
    Serial.print(MDNS_NAME);
    Serial.println(".local");
    MDNS.addService("http", "tcp", 80);
  } else {
    Serial.println("✗ Erro ao iniciar mDNS");
  }
  
  configurarServidorWeb();
  Serial.println("\n========================================");
  Serial.println("TELEGRAMPO - Pronto!");
  Serial.println("Acesse: http://" + WiFi.localIP().toString());
  Serial.println("ou http://" + String(MDNS_NAME) + ".local");
  Serial.println("========================================\n");
}

// ========================================
// LOOP PRINCIPAL
// ========================================

void loop() {
  server.handleClient();
  
  unsigned long currentMillis = millis();
  
  if (currentMillis - previousMillisLeitura >= intervaloLeitura) {
    previousMillisLeitura = currentMillis;
    
    lerSensores();
    atualizarLEDs();
    enviarDadosParaAPI();
  }
  
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
// FUNÇÕES DE LEITURA DE SENSORES
// ========================================

void lerSensores() {
  temperatura = dht22.readTemperature();
  umidade_ar = dht22.readHumidity();
  
  if (isnan(temperatura) || isnan(umidade_ar)) {
    Serial.println("✗ Erro ao ler DHT22");
    temperatura = 0;
    umidade_ar = 0;
  }
  
  valor_bruto_umidade = analogRead(UMIDADE_PIN);
  umidade_roupa = map(valor_bruto_umidade, 4095, 0, 0, 100);
  umidade_roupa = constrain(umidade_roupa, 0, 100);
  
  if (umidade_roupa < 5) {
    status_roupa = "Seca";
  } else {
    status_roupa = "Umida";
  }
}

void atualizarLEDs() {
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
  
  String postData = "device_id=" + String(DEVICE_ID);
  postData += "&temperatura=" + String(temperatura);
  postData += "&umidade_ar=" + String(umidade_ar);
  postData += "&valor_bruto=" + String(valor_bruto_umidade);
  postData += "&umidade_percentual=" + String(umidade_roupa);
  
  HTTPClient http;
  http.begin(API_URL);
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  
  int httpCode = http.POST(postData);
  
  // SOMENTE mostrar erros
  if (httpCode <= 0) {
    Serial.print("✗ Erro API: ");
    Serial.println(http.errorToString(httpCode));
  }
  // Não mostrar mais "Dados recebidos" do servidor
  
  http.end();
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
    
    if (response.indexOf("\"total\":0") == -1 && response.indexOf("notificacoes") != -1) {
      processarNotificacoes(response);
    }
  } else if (httpCode <= 0) {
    Serial.print("✗ Erro ao verificar notificações: ");
    Serial.println(http.errorToString(httpCode));
  }
  
  http.end();
}

void processarNotificacoes(String jsonResponse) {
  int posId = jsonResponse.indexOf("\"id\":");
  int posMensagem = jsonResponse.indexOf("\"mensagem\":\"");
  int posChatId = jsonResponse.indexOf("\"chat_id\":\"");
  
  if (posId == -1 || posMensagem == -1 || posChatId == -1) {
    return;
  }
  
  int idStart = posId + 5;
  int idEnd = jsonResponse.indexOf(",", idStart);
  String notificacao_id = jsonResponse.substring(idStart, idEnd);
  
  int msgStart = posMensagem + 12;
  int msgEnd = jsonResponse.indexOf("\"", msgStart);
  String mensagem = jsonResponse.substring(msgStart, msgEnd);
  
  int chatStart = posChatId + 11;
  int chatEnd = jsonResponse.indexOf("\"", chatStart);
  String chat_id = jsonResponse.substring(chatStart, chatEnd);
  
  if (enviarTelegram(chat_id, mensagem)) {
    marcarNotificacaoEnviada(notificacao_id);
  }
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
  } else if (httpCode <= 0) {
    Serial.print("✗ Erro ao marcar notificação: ");
    Serial.println(http.errorToString(httpCode));
  }
  
  http.end();
}

// ========================================
// CONFIGURAR SERVIDOR WEB
// ========================================

void configurarServidorWeb() {
  // Página principal
  server.on("/", []() {
    if (LittleFS.exists("/index.html")) {
      File file = LittleFS.open("/index.html", "r");
      server.streamFile(file, "text/html");
      file.close();
    } else {
      server.send(404, "text/plain", "index.html não encontrado no LittleFS");
      Serial.println("✗ index.html não encontrado");
    }
  });
  
  // CSS
  server.on("/styles.css", []() {
    if (LittleFS.exists("/styles.css")) {
      File file = LittleFS.open("/styles.css", "r");
      server.streamFile(file, "text/css");
      file.close();
    } else {
      server.send(404, "text/plain", "styles.css não encontrado");
      Serial.println("✗ styles.css não encontrado");
    }
  });
  
  // JS
  server.on("/script.js", []() {
    if (LittleFS.exists("/script.js")) {
      File file = LittleFS.open("/script.js", "r");
      server.streamFile(file, "application/javascript");
      file.close();
    } else {
      server.send(404, "text/plain", "script.js não encontrado");
      Serial.println("✗ script.js não encontrado");
    }
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
    String html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Config</title></head><body>";
    html += "<h1>Configurações TELEGRAMPO</h1>";
    html += "<form action='/save_config' method='POST'>";
    html += "SSID: <input name='wifi_ssid' value='" + String(config.wifi_ssid) + "'><br>";
    html += "Senha: <input name='wifi_password' type='password' value='" + String(config.wifi_password) + "'><br>";
    html += "IP: <input name='ip1' value='" + String(config.ip[0]) + "'>.<input name='ip2' value='" + String(config.ip[1]) + "'>.<input name='ip3' value='" + String(config.ip[2]) + "'>.<input name='ip4' value='" + String(config.ip[3]) + "'><br>";
    html += "Gateway: <input name='gw1' value='" + String(config.gateway[0]) + "'>.<input name='gw2' value='" + String(config.gateway[1]) + "'>.<input name='gw3' value='" + String(config.gateway[2]) + "'>.<input name='gw4' value='" + String(config.gateway[3]) + "'><br>";
    html += "API URL: <input name='api_url' value='" + String(config.api_url) + "'><br>";
    html += "API Notif: <input name='api_notificacoes' value='" + String(config.api_notificacoes) + "'><br>";
    html += "API Marcar: <input name='api_marcar_enviada' value='" + String(config.api_marcar_enviada) + "'><br>";
    html += "<button type='submit'>Salvar</button></form></body></html>";
    
    server.send(200, "text/html", html);
  });
  
  // Salvar configuração
  server.on("/save_config", HTTP_POST, []() {
    if (server.hasArg("wifi_ssid")) {
      server.arg("wifi_ssid").toCharArray(config.wifi_ssid, 32);
    }
    if (server.hasArg("wifi_password")) {
      server.arg("wifi_password").toCharArray(config.wifi_password, 64);
    }
    
    config.ip[0] = server.arg("ip1").toInt();
    config.ip[1] = server.arg("ip2").toInt();
    config.ip[2] = server.arg("ip3").toInt();
    config.ip[3] = server.arg("ip4").toInt();
    
    config.gateway[0] = server.arg("gw1").toInt();
    config.gateway[1] = server.arg("gw2").toInt();
    config.gateway[2] = server.arg("gw3").toInt();
    config.gateway[3] = server.arg("gw4").toInt();
    
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
