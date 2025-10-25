<?php
require_once '../includes/db_connect.php';
require_once '../includes/auth.php';

// Se já estiver logado, redireciona para dashboard
if (isLoggedIn()) {
    header('Location: dashboard.php');
    exit;
}

$pageTitle = 'Cadastro - TeleGrampo';
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $pageTitle; ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body class="bg-light">
    <div class="container">
        <div class="row justify-content-center align-items-center min-vh-100">
            <div class="col-md-6">
                <div class="card shadow">
                    <div class="card-body p-5">
                        <div class="text-center mb-4">
                            <i class="fas fa-user-plus fa-3x text-primary"></i>
                            <h3 class="mt-3">Criar Conta</h3>
                            <p class="text-muted">Cadastre-se no TeleGrampo</p>
                        </div>
                        
                        <?php if (isset($_GET['error'])): ?>
                        <div class="alert alert-danger">
                            <i class="fas fa-exclamation-circle"></i> 
                            <?php
                            if ($_GET['error'] === 'exists') {
                                echo 'Este email já está cadastrado.';
                            } else {
                                echo 'Erro ao cadastrar. Tente novamente.';
                            }
                            ?>
                        </div>
                        <?php endif; ?>
                        
                        <form action="actions/register_action.php" method="POST">
                            <div class="mb-3">
                                <label for="nome" class="form-label">
                                    <i class="fas fa-user"></i> Nome Completo
                                </label>
                                <input type="text" class="form-control" id="nome" name="nome" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="email" class="form-label">
                                    <i class="fas fa-envelope"></i> Email
                                </label>
                                <input type="email" class="form-control" id="email" name="email" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="telefone" class="form-label">
                                    <i class="fas fa-phone"></i> Telefone
                                </label>
                                <input type="text" class="form-control" id="telefone" name="telefone" placeholder="(00) 00000-0000">
                            </div>
                            
                            <div class="mb-3">
                                <label for="senha" class="form-label">
                                    <i class="fas fa-lock"></i> Senha
                                </label>
                                <input type="password" class="form-control" id="senha" name="senha" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="tipo_usuario" class="form-label">
                                    <i class="fas fa-user-tag"></i> Tipo de Usuário
                                </label>
                                <select class="form-select" id="tipo_usuario" name="tipo_usuario" required>
                                    <option value="C">Comum</option>
                                    <option value="A">Administrador</option>
                                </select>
                            </div>
                            
                            <button type="submit" class="btn btn-primary w-100 mb-3">
                                <i class="fas fa-user-plus"></i> Cadastrar
                            </button>
                        </form>
                        
                        <div class="text-center">
                            <p class="mb-0">Já tem conta? <a href="login.php">Faça login</a></p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
