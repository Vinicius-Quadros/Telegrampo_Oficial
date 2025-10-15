<?php
/**
 * Configuração do Banco de Dados
 */

class Database {
    private $host = 'localhost';
    private $db_name = 'grampo_iot';
    private $username = 'root';
    private $password = '';
    public $conn;

    /**
     * Conectar ao banco de dados
     */
    public function connect() {
        $this->conn = null;

        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8",
                $this->username,
                $this->password,
                array(
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
                )
            );
        } catch(PDOException $e) {
            echo "Erro na conexão: " . $e->getMessage();
        }

        return $this->conn;
    }

    /**
     * Verificar se a conexão está ativa
     */
    public function isConnected() {
        return $this->conn !== null;
    }

    /**
     * Fechar conexão
     */
    public function disconnect() {
        $this->conn = null;
    }
}

/**
 * Função global para obter conexão
 */
function getConnection() {
    $database = new Database();
    return $database->connect();
}

/**
 * Função para executar consultas preparadas
 */
function executeQuery($sql, $params = []) {
    try {
        $conn = getConnection();
        $stmt = $conn->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    } catch(PDOException $e) {
        error_log("Erro na consulta: " . $e->getMessage());
        return false;
    }
}

/**
 * Função para buscar um registro
 */
function fetchOne($sql, $params = []) {
    $stmt = executeQuery($sql, $params);
    return $stmt ? $stmt->fetch() : false;
}

/**
 * Função para buscar múltiplos registros
 */
function fetchAll($sql, $params = []) {
    $stmt = executeQuery($sql, $params);
    return $stmt ? $stmt->fetchAll() : [];
}

/**
 * Função para inserir dados
 */
function insertData($table, $data) {
    $fields = array_keys($data);
    $placeholders = ':' . implode(', :', $fields);
    $sql = "INSERT INTO {$table} (" . implode(', ', $fields) . ") VALUES ({$placeholders})";
    
    $stmt = executeQuery($sql, $data);
    return $stmt ? true : false;
}

/**
 * Função para atualizar dados
 */
function updateData($table, $data, $where, $whereParams = []) {
    $fields = array_keys($data);
    $setClause = implode(' = ?, ', $fields) . ' = ?';
    $sql = "UPDATE {$table} SET {$setClause} WHERE {$where}";
    
    $params = array_merge(array_values($data), $whereParams);
    $stmt = executeQuery($sql, $params);
    return $stmt ? true : false;
}

/**
 * Função para deletar dados
 */
function deleteData($table, $where, $params = []) {
    $sql = "DELETE FROM {$table} WHERE {$where}";
    $stmt = executeQuery($sql, $params);
    return $stmt ? true : false;
}

/**
 * Função para contar registros
 */
function countRecords($table, $where = '', $params = []) {
    $sql = "SELECT COUNT(*) as total FROM {$table}";
    if ($where) {
        $sql .= " WHERE {$where}";
    }
    
    $result = fetchOne($sql, $params);
    return $result ? $result['total'] : 0;
}
?>