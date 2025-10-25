# 📡 API do TELEGRAMPO

APIs PHP para comunicação entre ESP32 e banco de dados MySQL.

## 📁 Estrutura de Arquivos

```
api/
├── config.php                          # Configurações do banco
├── salvar_leituras.php                 # Salvar dados dos sensores
├── obter_dados.php                     # Obter última leitura
├── obter_notificacoes.php              # Obter notificações pendentes
├── marcar_notificacao_enviada.php      # Marcar notificação como enviada
└── README_API.md                       # Esta documentação
```

## ⚙️ Configuração Inicial

1. **Edite o arquivo `config.php`:**
```php
define('DB_HOST', 'localhost');     // Host do MySQL
define('DB_USER', 'root');          // Usuário do MySQL
define('DB_PASS', '');              // Senha do MySQL
define('DB_NAME', 'telegrampo_db'); // Nome do banco
```

2. **Carregue os arquivos para seu servidor web:**
   - Use XAMPP, WAMP ou servidor Apache/Nginx
   - Coloque na pasta `htdocs/telegrampo/api/`

3. **Teste a conexão:**
   - Acesse: `http://localhost/telegrampo/api/obter_dados.php?device_id=ESP32_001`

---

## 🔌 Endpoints Disponíveis

### 1️⃣ Salvar Leituras dos Sensores

**Endpoint:** `POST /api/salvar_leituras.php`

**Parâmetros:**
```
device_id          (string, obrigatório) - ID do dispositivo
temperatura        (float, opcional)     - Temperatura em °C
umidade_ar         (float, opcional)     - Umidade do ar em %
valor_bruto        (int, opcional)       - Valor bruto do sensor de umidade
umidade_percentual (int, opcional)       - Umidade da roupa em %
```

**Exemplo de requisição (ESP32):**
```cpp
String url = "http://SEU_SERVIDOR/api/salvar_leituras.php";
String postData = "device_id=ESP32_001";
postData += "&temperatura=" + String(temp);
postData += "&umidade_ar=" + String(humidity);
postData += "&valor_bruto=" + String(valorSensor);
postData += "&umidade_percentual=" + String(umidadePerc);

HTTPClient http;
http.begin(url);
http.addHeader("Content-Type", "application/x-www-form-urlencoded");
int httpCode = http.POST(postData);
```

**Resposta de sucesso:**
```json
{
  "success": true,
  "message": "Leituras salvas com sucesso",
  "data": {
    "dht22": {
      "id": 123,
      "temperatura": 25.5,
      "umidade_ar": 60.2
    },
    "umidade_roupa": {
      "id": 456,
      "valor_bruto": 2500,
      "umidade_percentual": 45,
      "status_roupa": "Úmida"
    }
  },
  "timestamp": 1698765432
}
```

---

### 2️⃣ Obter Dados Atuais

**Endpoint:** `GET /api/obter_dados.php`

**Parâmetros:**
```
device_id (string, obrigatório) - ID do dispositivo
```

**Exemplo de requisição:**
```
GET http://SEU_SERVIDOR/api/obter_dados.php?device_id=ESP32_001
```

**Resposta:**
```json
{
  "success": true,
  "message": "Dados obtidos com sucesso",
  "data": {
    "dispositivo": {
      "id": 1,
      "nome": "Grampo Quintal",
      "localizacao": "Área Externa - Varal Principal",
      "device_id": "ESP32_001",
      "status": "ativo"
    },
    "usuario": {
      "nome": "Usuário Teste",
      "chat_id": "-1003035825266"
    },
    "configuracoes": {
      "limiar_umidade_seca": 30,
      "intervalo_leitura": 5000
    },
    "leituras": {
      "temperatura": 25.5,
      "umidade_ar": 60.2,
      "umidade_roupa": 45,
      "status_roupa": "Úmida",
      "valor_bruto": 2500,
      "ultima_leitura_ambiente": "2025-09-29 14:30:00",
      "ultima_leitura_roupa": "2025-09-29 14:30:00"
    },
    "chuva": false
  },
  "timestamp": 1698765432
}
```

---

### 3️⃣ Obter Notificações Pendentes

**Endpoint:** `GET /api/obter_notificacoes.php`

**Parâmetros:**
```
device_id (string, obrigatório) - ID do dispositivo
```

**Exemplo de requisição:**
```
GET http://SEU_SERVIDOR/api/obter_notificacoes.php?device_id=ESP32_001
```

**Resposta:**
```json
{
  "success": true,
  "message": "Notificações obtidas com sucesso",
  "data": {
    "notificacoes": [
      {
        "id": 1,
        "tipo": "roupa_seca",
        "mensagem": "🎉 Sua roupa já está seca! Umidade: 25%",
        "chat_id": "-1003035825266",
        "usuario_nome": "Usuário Teste",
        "criado_em": "2025-09-29 14:35:00"
      }
    ],
    "total": 1,
    "bot_token": "8238331019:AAG1gn4RQq9t7rK9LwWkFleuRXZyzTbw4hI"
  },
  "timestamp": 1698765432
}
```

---

### 4️⃣ Marcar Notificação como Enviada

**Endpoint:** `POST /api/marcar_notificacao_enviada.php`

**Parâmetros:**
```
device_id       (string, obrigatório) - ID do dispositivo
notificacao_id  (int, obrigatório)    - ID da notificação
```

**Exemplo de requisição:**
```cpp
String url = "http://SEU_SERVIDOR/api/marcar_notificacao_enviada.php";
String postData = "device_id=ESP32_001&notificacao_id=1";

HTTPClient http;
http.begin(url);
http.addHeader("Content-Type", "application/x-www-form-urlencoded");
int httpCode = http.POST(postData);
```

**Resposta:**
```json
{
  "success": true,
  "message": "Notificação marcada como enviada",
  "data": {
    "notificacao_id": 1
  },
  "timestamp": 1698765432
}
```

---

## 🔐 Segurança

### Recomendações:
- ✅ Use HTTPS em produção
- ✅ Implemente autenticação por token
- ✅ Valide todos os dados de entrada
- ✅ Use prepared statements (já implementado)
- ✅ Limite taxa de requisições (rate limiting)
- ✅ Configure backup automático do banco de dados

---

## 🧪 Testando as APIs

### Com cURL:

**Salvar Leitura:**
```bash
curl -X POST http://localhost/telegrampo/api/salvar_leituras.php \
  -d "device_id=ESP32_001" \
  -d "temperatura=25.5" \
  -d "umidade_ar=60.2" \
  -d "valor_bruto=2500" \
  -d "umidade_percentual=45"
```

**Obter Dados:**
```bash
curl http://localhost/telegrampo/api/obter_dados.php?device_id=ESP32_001
```

**Obter Notificações:**
```bash
curl http://localhost/telegrampo/api/obter_notificacoes.php?device_id=ESP32_001
```

---

## ⚠️ Tratamento de Erros

Todas as APIs retornam erros no formato:

```json
{
  "success": false,
  "error": "Descrição do erro",
  "timestamp": 1698765432
}
```

**Códigos HTTP:**
- `200` - Sucesso
- `400` - Erro de validação
- `405` - Método não permitido
- `500` - Erro interno do servidor

---

## 📊 Fluxo Completo no ESP32

```cpp
// 1. Ler sensores
float temp = dht.readTemperature();
float humidity = dht.readHumidity();
int valorSensor = analogRead(pinSensor);
int umidadePerc = map(valorSensor, 4095, 0, 0, 100);

// 2. Salvar no banco
salvarLeituras(temp, humidity, valorSensor, umidadePerc);

// 3. Verificar notificações pendentes
verificarNotificacoes();

// 4. Enviar notificações via Telegram
enviarNotificacoesTelegram();
```

---

## 🔄 Atualizações Futuras

- [ ] Autenticação JWT
- [ ] Webhook do Telegram
- [ ] API para histórico de leituras
- [ ] Exportação de dados em CSV
- [ ] Dashboard de estatísticas

---

## 📞 Suporte

Problemas comuns e soluções:

**Erro: "Dispositivo não encontrado"**
- Verifique se o device_id está cadastrado no banco
- Confirme que o status está como 'ativo'

**Erro: "Connection failed"**
- Verifique as credenciais em config.php
- Confirme que o MySQL está rodando
- Teste a conexão manualmente

**Notificações não são criadas**
- Verifique se o trigger está ativo no banco
- Confirme que o limiar de umidade está configurado
- Veja os logs na tabela logs_sistema