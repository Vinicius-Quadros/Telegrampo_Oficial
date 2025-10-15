<?php
require_once 'includes/auth.php';

if (isLoggedIn()) {
    redirectByUserType();
}

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['login'])) {
    $email = sanitize($_POST['email']);
    $senha = $_POST['senha'];
    
    if (empty($email) || empty($senha)) {
        $error = 'Por favor, preencha todos os campos!';
    } else {
        if (login($email, $senha)) {
            redirectByUserType();
        } else {
            $error = 'Email ou senha incorretos!';
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['register'])) {
    $dados = [
        'nome' => sanitize($_POST['nome']),
        'cpf' => preg_replace('/[^0-9]/', '', $_POST['cpf']),
        'celular' => sanitize($_POST['celular']),
        'email' => sanitize($_POST['email']),
        'senha' => $_POST['senha'],
        'data_nascimento' => $_POST['data_nascimento'],
        'tipo_usuario' => 'C'
    ];
    
    if (empty($dados['nome']) || empty($dados['cpf']) || empty($dados['celular']) || 
        empty($dados['email']) || empty($dados['senha']) || empty($dados['data_nascimento'])) {
        $error = 'Por favor, preencha todos os campos!';
    } elseif (!validateCPF($dados['cpf'])) {
        $error = 'CPF inválido!';
    } elseif (!validateEmail($dados['email'])) {
        $error = 'Email inválido!';
    } elseif (strlen($dados['senha']) < 6) {
        $error = 'A senha deve ter pelo menos 6 caracteres!';
    } else {
        $result = registerUser($dados);
        if ($result['success']) {
            $success = $result['message'];
        } else {
            $error = $result['message'];
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['reset_password'])) {
    $email = sanitize($_POST['reset_email']);
    
    if (empty($email)) {
        $error = 'Por favor, digite seu email!';
    } elseif (!validateEmail($email)) {
        $error = 'Email inválido!';
    } else {
        $result = generatePasswordResetToken($email);
        if ($result['success']) {
            $success = 'Link de recuperação enviado! Use o token: ' . $result['token'];
        } else {
            $error = $result['message'];
        }
    }
}

if (isset($_GET['error'])) {
    switch ($_GET['error']) {
        case 'unauthorized':
            $error = 'Você precisa fazer login para acessar esta página!';
            break;
        case 'forbidden':
            $error = 'Acesso negado!';
            break;
    }
}

if (isset($_GET['success'])) {
    switch ($_GET['success']) {
        case 'password_reset':
            $success = 'Senha alterada com sucesso! Faça login com a nova senha.';
            break;
        case 'logout':
            $success = 'Logout realizado com sucesso!';
            break;
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grampo IoT - Login</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --tg-bg: #17212b;
            --tg-bg-secondary: #242f3d;
            --tg-bg-card: #0e1621;
            --tg-text: #ffffff;
            --tg-text-secondary: #aaaaaa;
            --tg-blue: #2AABEE;
            --tg-blue-dark: #1e88cf;
            --tg-border: #2b5278;
            --tg-error: #e53935;
            --tg-success: #00c853;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: var(--tg-bg);
            color: var(--tg-text);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            width: 100%;
            max-width: 400px;
        }

        .logo {
            text-align: center;
            margin-bottom: 40px;
        }

        .logo-icon {
            width: 80px;
            height: 80px;
            background: var(--tg-blue);
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            margin-bottom: 16px;
        }

        .logo h1 {
            font-size: 26px;
            font-weight: 600;
            margin-bottom: 8px;
        }

        .logo p {
            color: var(--tg-text-secondary);
            font-size: 15px;
        }

        .card {
            background: var(--tg-bg-secondary);
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.3);
        }

        .tabs {
            display: flex;
            background: var(--tg-bg-card);
        }

        .tab-btn {
            flex: 1;
            padding: 16px;
            border: none;
            background: none;
            color: var(--tg-text-secondary);
            font-size: 15px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            border-bottom: 2px solid transparent;
        }

        .tab-btn.active {
            color: var(--tg-blue);
            border-bottom-color: var(--tg-blue);
        }

        .form-container {
            display: none;
            padding: 24px;
        }

        .form-container.active {
            display: block;
        }

        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            color: var(--tg-text-secondary);
            font-size: 14px;
            margin-bottom: 8px;
        }

        input {
            width: 100%;
            padding: 12px 16px;
            background: var(--tg-bg-card);
            border: 1px solid var(--tg-border);
            border-radius: 8px;
            color: var(--tg-text);
            font-size: 15px;
            transition: all 0.2s;
        }

        input:focus {
            outline: none;
            border-color: var(--tg-blue);
            background: var(--tg-bg);
        }

        input::placeholder {
            color: #666;
        }

        .btn {
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 8px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            margin-bottom: 12px;
        }

        .btn-primary {
            background: var(--tg-blue);
            color: white;
        }

        .btn-primary:hover {
            background: var(--tg-blue-dark);
        }

        .btn-primary:active {
            transform: scale(0.98);
        }

        .btn-secondary {
            background: var(--tg-bg-card);
            color: var(--tg-text);
            border: 1px solid var(--tg-border);
        }

        .btn-secondary:hover {
            background: var(--tg-bg);
        }

        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 3px solid;
        }

        .alert-error {
            background: rgba(229, 57, 53, 0.1);
            border-color: var(--tg-error);
            color: #ff6b6b;
        }

        .alert-success {
            background: rgba(0, 200, 83, 0.1);
            border-color: var(--tg-success);
            color: #4caf50;
        }

        .link {
            color: var(--tg-blue);
            text-decoration: none;
            font-size: 14px;
        }

        .link:hover {
            text-decoration: underline;
        }

        .text-center {
            text-align: center;
        }

        .token-form {
            display: none;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid var(--tg-border);
        }

        @media (max-width: 480px) {
            .logo-icon {
                width: 60px;
                height: 60px;
                font-size: 30px;
            }

            .logo h1 {
                font-size: 22px;
            }

            .tab-btn {
                font-size: 14px;
                padding: 14px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">
            <div class="logo-icon">🌡️</div>
            <h1>Grampo IoT</h1>
            <p>Monitoramento Inteligente</p>
        </div>

        <div class="card">
            <?php if ($error): ?>
                <div style="padding: 24px 24px 0;">
                    <div class="alert alert-error"><?php echo $error; ?></div>
                </div>
            <?php endif; ?>

            <?php if ($success): ?>
                <div style="padding: 24px 24px 0;">
                    <div class="alert alert-success"><?php echo $success; ?></div>
                </div>
            <?php endif; ?>

            <div class="tabs">
                <button class="tab-btn active" onclick="showTab('login')">Entrar</button>
                <button class="tab-btn" onclick="showTab('register')">Cadastrar</button>
                <button class="tab-btn" onclick="showTab('forgot')">Recuperar</button>
            </div>

            <!-- Login -->
            <div id="login" class="form-container active">
                <form method="POST">
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" name="email" placeholder="seu@email.com" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Senha</label>
                        <input type="password" name="senha" placeholder="••••••••" required>
                    </div>
                    
                    <button type="submit" name="login" class="btn btn-primary">Entrar</button>
                </form>
            </div>

            <!-- Cadastro -->
            <div id="register" class="form-container">
                <form method="POST">
                    <div class="form-group">
                        <label>Nome Completo</label>
                        <input type="text" name="nome" required>
                    </div>
                    
                    <div class="form-group">
                        <label>CPF</label>
                        <input type="text" id="reg_cpf" name="cpf" placeholder="000.000.000-00" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Celular</label>
                        <input type="text" id="reg_celular" name="celular" placeholder="(00) 00000-0000" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" name="email" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Senha</label>
                        <input type="password" name="senha" minlength="6" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Data de Nascimento</label>
                        <input type="date" name="data_nascimento" required>
                    </div>
                    
                    <button type="submit" name="register" class="btn btn-primary">Cadastrar</button>
                </form>
            </div>

            <!-- Recuperação -->
            <div id="forgot" class="form-container">
                <form method="POST">
                    <div class="form-group">
                        <label>Email para recuperação</label>
                        <input type="email" name="reset_email" placeholder="seu@email.com" required>
                    </div>
                    
                    <button type="submit" name="reset_password" class="btn btn-primary">Enviar Token</button>
                    <button type="button" class="btn btn-secondary" onclick="showResetForm()">Tenho o Token</button>
                </form>
                
                <div id="token-form" class="token-form">
                    <form method="POST" action="reset_password.php">
                        <div class="form-group">
                            <label>Token de Recuperação</label>
                            <input type="text" name="token" required>
                        </div>
                        
                        <div class="form-group">
                            <label>Nova Senha</label>
                            <input type="password" id="nova_senha" name="nova_senha" minlength="6" required>
                        </div>
                        
                        <div class="form-group">
                            <label>Confirmar Senha</label>
                            <input type="password" id="confirmar_senha" name="confirmar_senha" minlength="6" required>
                        </div>
                        
                        <button type="submit" class="btn btn-primary">Alterar Senha</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script>
        function showTab(tab) {
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.form-container').forEach(container => container.classList.remove('active'));
            
            event.target.classList.add('active');
            document.getElementById(tab).classList.add('active');
        }

        function showResetForm() {
            document.getElementById('token-form').style.display = 'block';
        }

        document.getElementById('reg_cpf').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            value = value.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
            e.target.value = value;
        });

        document.getElementById('reg_celular').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length === 11) {
                value = value.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
            } else if (value.length === 10) {
                value = value.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
            }
            e.target.value = value;
        });

        document.getElementById('confirmar_senha')?.addEventListener('blur', function() {
            const senha = document.getElementById('nova_senha').value;
            const confirmar = this.value;
            
            if (senha !== confirmar) {
                this.setCustomValidity('As senhas não coincidem');
            } else {
                this.setCustomValidity('');
            }
        });
    </script>
</body>
</html>