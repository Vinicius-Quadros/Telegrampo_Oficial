# TeleGrampo - Sistema de Monitoramento de Secagem de Roupas

Sistema completo de monitoramento desenvolvido em PHP com dashboard interativo, gráficos em tempo real e painel administrativo.

## 📋 Características

- ✅ Sistema de login e cadastro com dois níveis de usuário (Comum e Admin)
- 📊 Dashboard com gráficos dinâmicos (Chart.js)
- 🔄 Atualização automática a cada 5 minutos
- 📝 Página de logs com filtros e paginação
- 🛠️ Painel administrativo completo com CRUD
- 🎨 Interface responsiva com Bootstrap 5
- 🔐 Controle de sessão e permissões

## 🚀 Tecnologias Utilizadas

- **Backend:** PHP 8+ com PDO
- **Banco de Dados:** MySQL/MariaDB
- **Frontend:** HTML5, CSS3, Bootstrap 5
- **JavaScript:** Vanilla JS, Chart.js
- **Ícones:** Font Awesome 6

## 📁 Estrutura de Pastas

```
telegrampo-project/
├── public/                      # Arquivos públicos
│   ├── index.php               # Página inicial (redireciona)
│   ├── login.php               # Página de login
│   ├── register.php            # Página de cadastro
│   ├── dashboard.php           # Dashboard principal
│   ├── logs.php                # Visualização de logs
│   ├── admin.php               # Painel administrativo
│   ├── logout.php              # Logout
│   ├── assets/
│   │   ├── css/
│   │   │   └── style.css       # Estilos customizados
│   │   └── js/
│   │       ├── dashboard.js    # Scripts do dashboard
│   │       └── admin.js        # Scripts do admin
│   └── actions/                # Actions (processamento)
│       ├── login_action.php
│       ├── register_action.php
│       ├── api_dashboard.php   # API para gráficos
│       ├── update_record.php
│       └── delete_record.php
├── includes/                    # Arquivos de inclusão
│   ├── db_connect.php          # Conexão com banco
│   ├── auth.php                # Autenticação
│   ├── header.php              # Header HTML
│   └── footer.php              # Footer HTML
└── README.md
```

## 🔧 Instalação

### Pré-requisitos

- PHP 8.0 ou superior
- MySQL 5.7+ ou MariaDB 10.4+
- Apache ou servidor web compatível
- XAMPP, WAMP, ou servidor PHP embutido

### Passo 1: Clonar/Baixar o Projeto

```bash
# Baixe e extraia os arquivos do projeto
# Coloque na pasta htdocs (XAMPP) ou www (WAMP)
```

### Passo 2: Criar o Banco de Dados

1. Acesse o phpMyAdmin (http://localhost/phpmyadmin)
2. Crie um banco de dados chamado `telegrampo_db`
3. Importe o arquivo SQL fornecido (`telegrampo_db.sql`)

Ou execute via linha de comando:

```bash
mysql -u root -p < telegrampo_db.sql
```

### Passo 3: Configurar Conexão com Banco

Edite o arquivo `includes/db_connect.php` com suas credenciais:

```php
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'telegrampo_db');
define('DB_USER', 'root');
define('DB_PASS', ''); // Sua senha do MySQL
```

### Passo 4: Configurar o Servidor Web

#### Opção A: XAMPP/WAMP

1. Coloque a pasta do projeto em `htdocs/` ou `www/`
2. Inicie o Apache e MySQL
3. Acesse: http://localhost/telegrampo-project/public/

#### Opção B: Servidor PHP Embutido

```bash
cd telegrampo-project/public
php -S localhost:8000
```

Acesse: http://localhost:8000/

### Passo 5: Primeiro Acesso

#### Usuário Padrão (já cadastrado no banco):

- **Email:** teste@teste.com
- **Senha:** 123456789
- **Tipo:** Comum (C)

#### Criar Novo Usuário:

1. Acesse a página de registro
2. Preencha os dados
3. Escolha o tipo de usuário:
   - **Comum (C):** Visualiza dashboard e logs
   - **Administrador (A):** Acesso completo + painel admin

## 📊 Funcionalidades

### Para Usuários Comuns

1. **Dashboard**
   - Visualizar estatísticas em tempo real
   - Gráficos de temperatura, umidade do ar e umidade da roupa
   - Última leitura dos sensores
   - Auto-refresh a cada 5 minutos

2. **Logs**
   - Listar todos os logs do sistema
   - Filtrar por dispositivo, tipo, data
   - Paginação automática

### Para Administradores

Tudo do usuário comum, mais:

3. **Painel Administrativo**
   - Gerenciar todas as tabelas do banco
   - Editar registros
   - Excluir registros (com confirmação)
   - Busca em tempo real
   - Visualizar 100 registros mais recentes

**Tabelas Disponíveis:**
- Usuários
- Dispositivos
- Configurações
- Leituras DHT22
- Leituras Umidade Roupa
- Notificações
- Logs do Sistema

## 🔒 Segurança

⚠️ **IMPORTANTE:** Este projeto foi desenvolvido para fins educacionais/demonstração.

### Melhorias de Segurança Recomendadas para Produção:

1. **Senhas:**
   ```php
   // Em vez de: $senha = $_POST['senha'];
   // Use: $senha_hash = password_hash($_POST['senha'], PASSWORD_DEFAULT);
   ```

2. **Validação de Entrada:**
   ```php
   // Validar e sanitizar todos os dados de entrada
   $email = filter_var($_POST['email'], FILTER_VALIDATE_EMAIL);
   ```

3. **Proteção CSRF:**
   - Implementar tokens CSRF em formulários

4. **SQL Injection:**
   - Já usa PDO com prepared statements ✅

5. **XSS:**
   - Já usa htmlspecialchars() ✅

6. **HTTPS:**
   - Usar certificado SSL em produção

7. **Variáveis de Ambiente:**
   - Mover credenciais para arquivo .env

## 📝 Estrutura do Banco de Dados

### Tabelas Principais:

- **usuarios:** Dados dos usuários do sistema
- **dispositivos:** Dispositivos ESP32 cadastrados
- **configuracoes:** Configurações por dispositivo
- **leituras_dht22:** Leituras de temperatura e umidade do ar
- **leituras_umidade_roupa:** Leituras do sensor de umidade da roupa
- **notificacoes:** Notificações do sistema
- **logs_sistema:** Logs de eventos

### Views:

- **vw_ultima_leitura:** Última leitura de cada dispositivo
- **vw_historico_24h:** Histórico das últimas 24 horas

### Stored Procedures:

- **limpar_leituras_antigas:** Remove leituras antigas (30 dias)
- **obter_estatisticas_dispositivo:** Estatísticas dos últimos 7 dias

## 🎨 Personalização

### Alterar Cores

Edite o arquivo `assets/css/style.css`:

```css
:root {
    --primary-color: #0d6efd;
    --secondary-color: #6c757d;
    --success-color: #198754;
    /* ... */
}
```

### Alterar Intervalo de Atualização

Edite `assets/js/dashboard.js`:

```javascript
// Mudar de 5 minutos (300000ms) para outro valor
setInterval(updateDashboard, 300000);
```

### Alterar Período dos Gráficos

Edite `actions/api_dashboard.php`:

```sql
-- Mudar de 1 HOUR para outro intervalo
WHERE lido_em >= NOW() - INTERVAL 1 HOUR
```

## 🐛 Troubleshooting

### Erro: "Call to undefined function..."
- Verifique se as extensões PHP necessárias estão habilitadas (PDO, pdo_mysql)

### Erro: "Access denied for user..."
- Verifique as credenciais em `includes/db_connect.php`

### Gráficos não aparecem
- Verifique se o Chart.js está carregando (internet necessária)
- Verifique o console do navegador (F12)

### Página em branco
- Habilite exibição de erros no PHP:
  ```php
  ini_set('display_errors', 1);
  error_reporting(E_ALL);
  ```

## 📚 Dependências CDN

O projeto usa CDNs para bibliotecas externas:

- Bootstrap 5.3.0
- Font Awesome 6.4.0
- Chart.js 4.4.0

💡 Para uso offline, baixe essas bibliotecas e ajuste os links.

## 🤝 Contribuindo

Este é um projeto educacional. Sugestões de melhorias são bem-vindas!

## 📄 Licença

Este projeto é livre para uso educacional e pessoal.

## 👨‍💻 Autor

Desenvolvido como projeto demonstrativo de sistema PHP completo.

## 📞 Suporte

Para dúvidas ou problemas, verifique:
1. Os logs de erro do PHP
2. O console do navegador (F12)
3. As configurações de banco de dados

---

**🎉 Projeto pronto para uso! Bons estudos!**
