<?php
// ========================================
// ARQUIVO DE CONFIGURAÇÃO DO BANCO DE DADOS
// api/config.php
// ========================================

// Configurações do banco de dados
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'telegrampo_db');

// Configurações da API
define('API_VERSION', '1.0');
define('TIMEZONE', 'America/Sao_Paulo');

// Configurar timezone
date_default_timezone_set(TIMEZONE);

// Habilitar CORS para ESP32
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// Classe de conexão com o banco de dados
class Database {
    private $conn;
    
    public function __construct() {
        $this->connect();
    }
    
    // Conectar ao banco de dados
    private function connect() {
        $this->conn = mysqli_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME);
        
        if (!$this->conn) {
            $this->sendError("Falha na conexão com o banco de dados: " . mysqli_connect_error(), 500);
            exit;
        }
        
        // Configurar charset UTF-8
        mysqli_set_charset($this->conn, "utf8mb4");

        echo "✅ Conexão com o banco de dados estabelecida com sucesso!<br>";
    }
    
    // Obter conexão
    public function getConnection() {
        return $this->conn;
    }
    
    // Executar query com prepared statement
    public function query($sql, $params = [], $types = '') {
        $stmt = mysqli_prepare($this->conn, $sql);
        
        if (!$stmt) {
            $this->sendError("Erro ao preparar query: " . mysqli_error($this->conn), 500);
            return false;
        }
        
        // Bind parameters se existirem
        if (!empty($params) && !empty($types)) {
            mysqli_stmt_bind_param($stmt, $types, ...$params);
        }
        
        // Executar
        if (!mysqli_stmt_execute($stmt)) {
            $this->sendError("Erro ao executar query: " . mysqli_stmt_error($stmt), 500);
            return false;
        }
        
        // Obter resultado
        $result = mysqli_stmt_get_result($stmt);
        mysqli_stmt_close($stmt);
        
        return $result;
    }
    
    // Inserir dados e retornar ID
    public function insert($sql, $params = [], $types = '') {
        $stmt = mysqli_prepare($this->conn, $sql);
        
        if (!$stmt) {
            return false;
        }
        
        if (!empty($params) && !empty($types)) {
            mysqli_stmt_bind_param($stmt, $types, ...$params);
        }
        
        if (mysqli_stmt_execute($stmt)) {
            $insertId = mysqli_insert_id($this->conn);
            mysqli_stmt_close($stmt);
            return $insertId;
        }
        
        mysqli_stmt_close($stmt);
        return false;
    }
    
    // Enviar resposta JSON de sucesso
    public function sendSuccess($data, $message = "Operação realizada com sucesso") {
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data,
            'timestamp' => time()
        ], JSON_UNESCAPED_UNICODE);
    }
    
    // Enviar resposta JSON de erro
    public function sendError($message, $code = 400) {
        http_response_code($code);
        echo json_encode([
            'success' => false,
            'error' => $message,
            'timestamp' => time()
        ], JSON_UNESCAPED_UNICODE);
    }
    
    // Fechar conexão
    public function close() {
        if ($this->conn) {
            mysqli_close($this->conn);
        }
    }
    
    public function __destruct() {
        $this->close();
    }
}

// Função auxiliar para sanitizar entrada
function sanitize($data) {
    return htmlspecialchars(strip_tags(trim($data)));
}

// Função para validar device_id
function validarDeviceId($device_id) {
    return preg_match('/^[A-Za-z0-9_]+$/', $device_id);
}

// Função para obter device_id da requisição
function getDeviceId() {
    // Tentar obter de POST
    if (isset($_POST['device_id'])) {
        return sanitize($_POST['device_id']);
    }
    
    // Tentar obter de GET
    if (isset($_GET['device_id'])) {
        return sanitize($_GET['device_id']);
    }
    
    // Tentar obter do JSON body
    $json = file_get_contents('php://input');
    if ($json) {
        $data = json_decode($json, true);
        if (isset($data['device_id'])) {
            return sanitize($data['device_id']);
        }
    }
    
    return null;
}
?>