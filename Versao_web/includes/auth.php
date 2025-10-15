<?php
/**
 * Funções de Autenticação e Sessão
 */

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';

/**
 * Fazer login do usuário
 */
function login($email, $senha) {
    $sql = "SELECT * FROM usuarios WHERE email = ? AND tipo_usuario IN ('A', 'C')";
    $user = fetchOne($sql, [$email]);
    
    if ($user && password_verify($senha, $user['senha'])) {
        $_SESSION['user_id'] = $user['id_usuario'];
        $_SESSION['user_name'] = $user['nome'];
        $_SESSION['user_email'] = $user['email'];
        $_SESSION['user_type'] = $user['tipo_usuario'];
        $_SESSION['logged_in'] = true;
        
        return true;
    }
    
    return false;
}

/**
 * Fazer logout do usuário
 */
function logout() {
    session_unset();
    session_destroy();
    
    // Determinar o caminho correto baseado na localização atual
    $base_path = '';
    if (strpos($_SERVER['REQUEST_URI'], '/admin/') !== false) {
        $base_path = '../';
    } elseif (strpos($_SERVER['REQUEST_URI'], '/user/') !== false) {
        $base_path = '../';
    } elseif (strpos($_SERVER['REQUEST_URI'], '/includes/') !== false) {
        $base_path = '../';
    }
    
    header('Location: ' . $base_path . 'login.php?success=logout');
    exit;
}

/**
 * Verificar se o usuário está logado
 */
function isLoggedIn() {
    return isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true;
}

/**
 * Verificar se o usuário é administrador
 */
function isAdmin() {
    return isLoggedIn() && $_SESSION['user_type'] === 'A';
}

/**
 * Verificar se o usuário é comum
 */
function isUser() {
    return isLoggedIn() && $_SESSION['user_type'] === 'C';
}

/**
 * Obter dados do usuário logado
 */
function getCurrentUser() {
    if (!isLoggedIn()) {
        return false;
    }
    
    $sql = "SELECT * FROM usuarios WHERE id_usuario = ?";
    return fetchOne($sql, [$_SESSION['user_id']]);
}

/**
 * Registrar novo usuário
 */
function registerUser($dados) {
    // Verificar se email já existe
    $emailExists = fetchOne("SELECT id_usuario FROM usuarios WHERE email = ?", [$dados['email']]);
    if ($emailExists) {
        return ['success' => false, 'message' => 'Email já cadastrado!'];
    }
    
    // Verificar se CPF já existe
    $cpfExists = fetchOne("SELECT id_usuario FROM usuarios WHERE cpf = ?", [$dados['cpf']]);
    if ($cpfExists) {
        return ['success' => false, 'message' => 'CPF já cadastrado!'];
    }
    
    // Criptografar senha
    $dados['senha'] = password_hash($dados['senha'], PASSWORD_DEFAULT);
    
    // Inserir usuário
    $success = insertData('usuarios', $dados);
    
    if ($success) {
        return ['success' => true, 'message' => 'Usuário cadastrado com sucesso!'];
    } else {
        return ['success' => false, 'message' => 'Erro ao cadastrar usuário!'];
    }
}

/**
 * Atualizar dados do usuário
 */
function updateUser($id_usuario, $dados) {
    // Se há nova senha, criptografar
    if (isset($dados['senha']) && !empty($dados['senha'])) {
        $dados['senha'] = password_hash($dados['senha'], PASSWORD_DEFAULT);
    } else {
        unset($dados['senha']); // Remove se estiver vazia
    }
    
    $success = updateData('usuarios', $dados, 'id_usuario = ?', [$id_usuario]);
    
    if ($success) {
        // Atualizar sessão se for o próprio usuário
        if (isset($_SESSION['user_id']) && $_SESSION['user_id'] == $id_usuario) {
            if (isset($dados['nome'])) $_SESSION['user_name'] = $dados['nome'];
            if (isset($dados['email'])) $_SESSION['user_email'] = $dados['email'];
        }
        return ['success' => true, 'message' => 'Dados atualizados com sucesso!'];
    } else {
        return ['success' => false, 'message' => 'Erro ao atualizar dados!'];
    }
}

/**
 * Gerar token para recuperação de senha
 */
function generatePasswordResetToken($email) {
    $user = fetchOne("SELECT id_usuario FROM usuarios WHERE email = ?", [$email]);
    
    if (!$user) {
        return ['success' => false, 'message' => 'Email não encontrado!'];
    }
    
    $token = bin2hex(random_bytes(50));
    $expira = date('Y-m-d H:i:s', strtotime('+1 hour'));
    
    // Invalidar tokens anteriores
    executeQuery("UPDATE recuperacao_senha SET usado = 1 WHERE id_usuario = ?", [$user['id_usuario']]);
    
    // Inserir novo token
    $dados = [
        'id_usuario' => $user['id_usuario'],
        'token' => $token,
        'expira_em' => $expira
    ];
    
    $success = insertData('recuperacao_senha', $dados);
    
    if ($success) {
        return [
            'success' => true, 
            'message' => 'Token gerado com sucesso!',
            'token' => $token
        ];
    } else {
        return ['success' => false, 'message' => 'Erro ao gerar token!'];
    }
}

/**
 * Validar token de recuperação
 */
function validateResetToken($token) {
    $sql = "SELECT r.*, u.email FROM recuperacao_senha r 
            JOIN usuarios u ON r.id_usuario = u.id_usuario 
            WHERE r.token = ? AND r.usado = 0 AND r.expira_em > NOW()";
    
    return fetchOne($sql, [$token]);
}

/**
 * Resetar senha
 */
function resetPassword($token, $novaSenha) {
    $resetData = validateResetToken($token);
    
    if (!$resetData) {
        return ['success' => false, 'message' => 'Token inválido ou expirado!'];
    }
    
    $senhaHash = password_hash($novaSenha, PASSWORD_DEFAULT);
    
    // Atualizar senha
    $updated = updateData('usuarios', ['senha' => $senhaHash], 'id_usuario = ?', [$resetData['id_usuario']]);
    
    if ($updated) {
        // Marcar token como usado
        executeQuery("UPDATE recuperacao_senha SET usado = 1 WHERE token = ?", [$token]);
        return ['success' => true, 'message' => 'Senha alterada com sucesso!'];
    } else {
        return ['success' => false, 'message' => 'Erro ao alterar senha!'];
    }
}

/**
 * Redirecionar baseado no tipo de usuário
 */
function redirectByUserType() {
    if (isAdmin()) {
        header('Location: admin/dashboard.php');
    } else {
        header('Location: user/dashboard.php');
    }
    exit;
}

/**
 * Middleware para verificar autenticação
 */
function requireAuth() {
    if (!isLoggedIn()) {
        header('Location: login.php?error=unauthorized');
        exit;
    }
}

/**
 * Middleware para verificar se é admin
 */
function requireAdmin() {
    requireAuth();
    if (!isAdmin()) {
        header('Location: user/dashboard.php?error=forbidden');
        exit;
    }
}

/**
 * Sanitizar dados de entrada
 */
function sanitize($data) {
    return htmlspecialchars(strip_tags(trim($data)));
}

/**
 * Validar CPF
 */
function validateCPF($cpf) {
    $cpf = preg_replace('/[^0-9]/', '', $cpf);
    
    if (strlen($cpf) != 11) {
        return false;
    }
    
    // Verificar se todos os dígitos são iguais
    if (preg_match('/(\d)\1{10}/', $cpf)) {
        return false;
    }
    
    // Calcular os dígitos verificadores
    for ($t = 9; $t < 11; $t++) {
        for ($d = 0, $c = 0; $c < $t; $c++) {
            $d += $cpf[$c] * (($t + 1) - $c);
        }
        $d = ((10 * $d) % 11) % 10;
        if ($cpf[$c] != $d) {
            return false;
        }
    }
    
    return true;
}

/**
 * Validar email
 */
function validateEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Formatar CPF para exibição
 */
function formatCPF($cpf) {
    return preg_replace('/(\d{3})(\d{3})(\d{3})(\d{2})/', '$1.$2.$3-$4', $cpf);
}

/**
 * Formatar telefone para exibição
 */
function formatPhone($phone) {
    $phone = preg_replace('/[^0-9]/', '', $phone);
    if (strlen($phone) == 11) {
        return preg_replace('/(\d{2})(\d{5})(\d{4})/', '($1) $2-$3', $phone);
    } elseif (strlen($phone) == 10) {
        return preg_replace('/(\d{2})(\d{4})(\d{4})/', '($1) $2-$3', $phone);
    }
    return $phone;
}
?>