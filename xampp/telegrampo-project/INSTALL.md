# 🚀 GUIA RÁPIDO DE INSTALAÇÃO

## Instalação Rápida (5 minutos)

### 1. Configurar Banco de Dados

```bash
# Entre no MySQL
mysql -u root -p

# Crie o banco e importe
CREATE DATABASE telegrampo_db;
USE telegrampo_db;
SOURCE telegrampo_db.sql;
```

### 2. Configurar Projeto

```bash
# Extrair projeto para htdocs ou www
# Editar includes/db_connect.php com suas credenciais
```

### 3. Acessar Sistema

```
URL: http://localhost/telegrampo-project/public/

USUÁRIO PADRÃO:
- Email: teste@teste.com
- Senha: 123456789
```

### 4. Estrutura de Pastas

```
public/          → Arquivos acessíveis pelo navegador
includes/        → Arquivos PHP internos (protegidos)
assets/          → CSS, JS, imagens
actions/         → Processamento de formulários
```

### 5. Permissões Necessárias

- PHP 8.0+
- Extensões: PDO, pdo_mysql
- Apache mod_rewrite (opcional)

### 6. Primeiro Login

1. Acesse: http://localhost/telegrampo-project/public/login.php
2. Use o usuário padrão OU crie uma nova conta
3. Para ser admin, registre-se com tipo "Administrador"

### 7. Funcionalidades

**Dashboard** (Todos os usuários):
- Gráficos em tempo real
- Estatísticas
- Auto-refresh (5 min)

**Admin** (Apenas administradores):
- CRUD completo
- Gerenciar usuários
- Editar todas as tabelas

### 8. Troubleshooting

**Erro de conexão:**
- Verifique includes/db_connect.php
- Confirme que MySQL está rodando

**Página em branco:**
- Habilite display_errors no php.ini
- Verifique logs do Apache

**Gráficos não aparecem:**
- Verifique conexão com internet (CDN)
- Abra F12 e veja console

---

✅ **PRONTO! Sistema funcionando!**
