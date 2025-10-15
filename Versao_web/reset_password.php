<?php
require_once 'includes/auth.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $token = sanitize($_POST['token']);
    $nova_senha = $_POST['nova_senha'];
    $confirmar_senha = $_POST['confirmar_senha'];
    
    if (empty($token) || empty($nova_senha) || empty($confirmar_senha)) {
        $error = 'Por favor, preencha todos os campos!';
    } elseif ($nova_senha !== $confirmar_senha) {
        $error = 'As senhas não coincidem!';
    } elseif (strlen($nova_senha) < 6) {
        $error = 'A senha deve ter pelo menos 6 caracteres!';
    } else {
        $result = resetPassword($token, $nova_senha);
        if ($result['success']) {
            header('Location: login.php?success=password_reset');
            exit;
        } else {
            $error = $result['message'];
        }
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Redefinir Senha - Grampo IoT</title>
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
            font-size: 24px;
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
            padding: 24px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.3);
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

        .back-link {
            text-align: center;
            margin-top: 20px;
        }

        .link {
            color: var(--tg-blue);
            text-decoration: none;
            font-size: 14px;
        }

        .link:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">
            <div class="logo-icon">🔐</div>
            <h1>Redefinir Senha</h1>
            <p>Digite seu token e nova senha</p>
        </div>

        <div class="card">
            <?php if ($error): ?>
                <div class="alert alert-error"><?php echo $error; ?></div>
            <?php endif; ?>

            <form method="POST">
                <div class="form-group">
                    <label>Token de Recuperação</label>
                    <input type="text" name="token" required 
                           value="<?php echo isset($_POST['token']) ? htmlspecialchars($_POST['token']) : ''; ?>">
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

            <div class="back-link">
                <a href="login.php" class="link">← Voltar ao Login</a>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('confirmar_senha').addEventListener('blur', function() {
            const senha = document.getElementById('nova_senha').value;
            const confirmar = this.value;
            
            if (senha !== confirmar) {
                this.setCustomValidity('As senhas não coincidem');
            } else {
                this.setCustomValidity('');
            }
        });

        document.getElementById('nova_senha').addEventListener('input', function() {
            const confirmar = document.getElementById('confirmar_senha');
            if (confirmar.value && this.value !== confirmar.value) {
                confirmar.setCustomValidity('As senhas não coincidem');
            } else {
                confirmar.setCustomValidity('');
            }
        });
    </script>
</body>
</html>