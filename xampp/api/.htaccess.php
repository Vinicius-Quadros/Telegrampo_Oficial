# ========================================
# CONFIGURAÇÕES DE SEGURANÇA E OTIMIZAÇÃO
# api/.htaccess
# ========================================

# Habilitar Rewrite Engine
RewriteEngine On

# Prevenir acesso direto ao config.php
<Files "config.php">
    Order Allow,Deny
    Deny from all
</Files>

# Prevenir listagem de diretórios
Options -Indexes

# Definir página de erro personalizada
ErrorDocument 404 "API endpoint não encontrado"
ErrorDocument 500 "Erro interno no servidor"

# Limitar tamanho máximo de upload (2MB)
php_value upload_max_filesize 2M
php_value post_max_size 2M

# Configurações de segurança PHP
php_flag display_errors Off
php_flag log_errors On
php_value error_log /var/log/php_errors.log

# Prevenir acesso a arquivos sensíveis
<FilesMatch "\.(md|txt|log|bak|sql)$">
    Order Allow,Deny
    Deny from all
</FilesMatch>

# Headers de segurança
Header set X-Content-Type-Options "nosniff"
Header set X-Frame-Options "DENY"
Header set X-XSS-Protection "1; mode=block"

# CORS para ESP32
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
Header set Access-Control-Allow-Headers "Content-Type, Authorization"

# Compressão GZIP
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE application/json
    AddOutputFilterByType DEFLATE text/plain
</IfModule>

# Cache control
<FilesMatch "\.(php)$">
    Header set Cache-Control "no-cache, no-store, must-revalidate"
    Header set Pragma "no-cache"
    Header set Expires 0
</FilesMatch>   