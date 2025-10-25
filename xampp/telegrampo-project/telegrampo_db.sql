-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geraÃ§Ã£o: 25/10/2025 Ã s 23:02
-- VersÃ£o do servidor: 10.4.32-MariaDB
-- VersÃ£o do PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `telegrampo_db`
--

DELIMITER $$
--
-- Procedimentos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `limpar_leituras_antigas` ()   BEGIN
    DELETE FROM leituras_dht22 WHERE lido_em < DATE_SUB(NOW(), INTERVAL 30 DAY);
    DELETE FROM leituras_umidade_roupa WHERE lido_em < DATE_SUB(NOW(), INTERVAL 30 DAY);
    DELETE FROM logs_sistema WHERE criado_em < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `obter_estatisticas_dispositivo` (IN `p_dispositivo_id` INT)   BEGIN
    SELECT 
        COUNT(*) AS total_leituras,
        AVG(temperatura) AS temp_media,
        MAX(temperatura) AS temp_maxima,
        MIN(temperatura) AS temp_minima,
        AVG(umidade_ar) AS umidade_media,
        DATE(lido_em) AS data
    FROM leituras_dht22
    WHERE dispositivo_id = p_dispositivo_id
        AND lido_em >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY DATE(lido_em)
    ORDER BY data DESC;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `configuracoes`
--

CREATE TABLE `configuracoes` (
  `id` int(11) NOT NULL,
  `dispositivo_id` int(11) NOT NULL,
  `limiar_umidade_seca` int(11) DEFAULT 30,
  `intervalo_leitura` int(11) DEFAULT 5000,
  `telegram_bot_token` varchar(100) DEFAULT NULL,
  `wifi_ssid` varchar(50) DEFAULT NULL,
  `wifi_password` varchar(100) DEFAULT NULL,
  `atualizado_em` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `dispositivos`
--

CREATE TABLE `dispositivos` (
  `id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `localizacao` varchar(150) DEFAULT NULL,
  `device_id` varchar(50) NOT NULL,
  `status` varchar(20) DEFAULT 'ativo',
  `criado_em` timestamp NOT NULL DEFAULT current_timestamp(),
  `atualizado_em` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `dispositivos`
--

INSERT INTO `dispositivos` (`id`, `usuario_id`, `nome`, `localizacao`, `device_id`, `status`, `criado_em`, `atualizado_em`) VALUES
(1, 1, 'Grampo Quintal', 'Ãrea Externa - Varal Principal', 'ESP32_001', 'ativo', '2025-09-29 22:57:16', '2025-09-29 22:57:16');

-- --------------------------------------------------------

--
-- Estrutura para tabela `leituras_dht22`
--

CREATE TABLE `leituras_dht22` (
  `id` int(11) NOT NULL,
  `dispositivo_id` int(11) NOT NULL,
  `temperatura` float NOT NULL,
  `umidade_ar` float NOT NULL,
  `lido_em` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `leituras_dht22`
--

INSERT INTO `leituras_dht22` (`id`, `dispositivo_id`, `temperatura`, `umidade_ar`, `lido_em`) VALUES
(1, 1, 25.3, 57.6, '2025-10-25 21:01:45');

-- --------------------------------------------------------

--
-- Estrutura para tabela `leituras_umidade_roupa`
--

CREATE TABLE `leituras_umidade_roupa` (
  `id` int(11) NOT NULL,
  `dispositivo_id` int(11) NOT NULL,
  `valor_bruto` int(11) NOT NULL,
  `umidade_percentual` int(11) NOT NULL,
  `status_roupa` varchar(20) NOT NULL,
  `lido_em` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `leituras_umidade_roupa`
--

INSERT INTO `leituras_umidade_roupa` (`id`, `dispositivo_id`, `valor_bruto`, `umidade_percentual`, `status_roupa`, `lido_em`) VALUES
(1, 1, 4095, 0, 'Seca', '2025-10-25 21:01:45');

--
-- Acionadores `leituras_umidade_roupa`
--
DELIMITER $$
CREATE TRIGGER `tr_notificar_roupa_seca` AFTER INSERT ON `leituras_umidade_roupa` FOR EACH ROW BEGIN
    DECLARE v_usuario_id INT;
    DECLARE v_ultima_notificacao TIMESTAMP;
    
    -- Obter usuÃ¡rio do dispositivo
    SELECT usuario_id INTO v_usuario_id
    FROM dispositivos
    WHERE id = NEW.dispositivo_id;
    
    -- Verificar se roupa estÃ¡ seca e nÃ£o hÃ¡ notificaÃ§Ã£o recente
    IF NEW.status_roupa = 'Seca' THEN
        -- Verificar Ãºltima notificaÃ§Ã£o (evitar spam)
        SELECT MAX(criado_em) INTO v_ultima_notificacao
        FROM notificacoes
        WHERE dispositivo_id = NEW.dispositivo_id
            AND tipo = 'roupa_seca';
        
        -- Se nÃ£o hÃ¡ notificaÃ§Ã£o nos Ãºltimos 30 minutos, criar nova
        IF v_ultima_notificacao IS NULL 
            OR v_ultima_notificacao < DATE_SUB(NOW(), INTERVAL 30 MINUTE) THEN
            
            INSERT INTO notificacoes (dispositivo_id, usuario_id, tipo, mensagem)
            VALUES (
                NEW.dispositivo_id,
                v_usuario_id,
                'roupa_seca',
                CONCAT('? Sua roupa jÃ¡ estÃ¡ seca! Umidade: ', NEW.umidade_percentual, '%')
            );
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `logs_sistema`
--

CREATE TABLE `logs_sistema` (
  `id` int(11) NOT NULL,
  `dispositivo_id` int(11) DEFAULT NULL,
  `tipo` varchar(50) NOT NULL,
  `mensagem` text NOT NULL,
  `criado_em` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `logs_sistema`
--

INSERT INTO `logs_sistema` (`id`, `dispositivo_id`, `tipo`, `mensagem`, `criado_em`) VALUES
(1, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-10-25 21:01:45'),
(2, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-10-25 21:01:45');

-- --------------------------------------------------------

--
-- Estrutura para tabela `notificacoes`
--

CREATE TABLE `notificacoes` (
  `id` int(11) NOT NULL,
  `dispositivo_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `tipo` varchar(50) NOT NULL,
  `mensagem` text NOT NULL,
  `enviado` tinyint(1) DEFAULT 0,
  `enviado_em` timestamp NULL DEFAULT NULL,
  `criado_em` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `notificacoes`
--

INSERT INTO `notificacoes` (`id`, `dispositivo_id`, `usuario_id`, `tipo`, `mensagem`, `enviado`, `enviado_em`, `criado_em`) VALUES
(1, 1, 1, 'roupa_seca', '? Sua roupa jÃ¡ estÃ¡ seca! Umidade: 0%', 0, NULL, '2025-10-25 21:01:45');

-- --------------------------------------------------------

--
-- Estrutura para tabela `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `chat_id` varchar(50) DEFAULT NULL,
  `criado_em` timestamp NOT NULL DEFAULT current_timestamp(),
  `atualizado_em` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `tipo_usuario` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `usuarios`
--

INSERT INTO `usuarios` (`id`, `nome`, `email`, `senha`, `telefone`, `chat_id`, `criado_em`, `atualizado_em`, `tipo_usuario`) VALUES
(1, 'UsuÃ¡rio Teste', 'teste@teste.com', '123456789', '(41) 99999-9999', '-1003035825266', '2025-09-29 22:57:16', '2025-10-20 23:26:10', 'C');

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `vw_historico_24h`
-- (Veja abaixo para a visÃ£o atual)
--
CREATE TABLE `vw_historico_24h` (
`dispositivo_nome` varchar(100)
,`umidade_percentual` int(11)
,`status_roupa` varchar(20)
,`temperatura` float
,`umidade_ar` float
,`lido_em` timestamp
);

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `vw_ultima_leitura`
-- (Veja abaixo para a visÃ£o atual)
--
CREATE TABLE `vw_ultima_leitura` (
`dispositivo_id` int(11)
,`dispositivo_nome` varchar(100)
,`localizacao` varchar(150)
,`usuario_nome` varchar(100)
,`chat_id` varchar(50)
,`umidade_percentual` int(11)
,`status_roupa` varchar(20)
,`leitura_roupa_em` timestamp
,`temperatura` float
,`umidade_ar` float
,`leitura_ambiente_em` timestamp
);

-- --------------------------------------------------------

--
-- Estrutura para view `vw_historico_24h`
--
DROP TABLE IF EXISTS `vw_historico_24h`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_historico_24h`  AS SELECT `d`.`nome` AS `dispositivo_nome`, `lr`.`umidade_percentual` AS `umidade_percentual`, `lr`.`status_roupa` AS `status_roupa`, `ld`.`temperatura` AS `temperatura`, `ld`.`umidade_ar` AS `umidade_ar`, `lr`.`lido_em` AS `lido_em` FROM ((`dispositivos` `d` join `leituras_umidade_roupa` `lr` on(`d`.`id` = `lr`.`dispositivo_id`)) join `leituras_dht22` `ld` on(`d`.`id` = `ld`.`dispositivo_id` and abs(timestampdiff(SECOND,`lr`.`lido_em`,`ld`.`lido_em`)) < 5)) WHERE `lr`.`lido_em` >= current_timestamp() - interval 24 hour ORDER BY `lr`.`lido_em` DESC ;

-- --------------------------------------------------------

--
-- Estrutura para view `vw_ultima_leitura`
--
DROP TABLE IF EXISTS `vw_ultima_leitura`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_ultima_leitura`  AS SELECT `d`.`id` AS `dispositivo_id`, `d`.`nome` AS `dispositivo_nome`, `d`.`localizacao` AS `localizacao`, `u`.`nome` AS `usuario_nome`, `u`.`chat_id` AS `chat_id`, `lr`.`umidade_percentual` AS `umidade_percentual`, `lr`.`status_roupa` AS `status_roupa`, `lr`.`lido_em` AS `leitura_roupa_em`, `ld`.`temperatura` AS `temperatura`, `ld`.`umidade_ar` AS `umidade_ar`, `ld`.`lido_em` AS `leitura_ambiente_em` FROM (((`dispositivos` `d` left join `usuarios` `u` on(`d`.`usuario_id` = `u`.`id`)) left join `leituras_umidade_roupa` `lr` on(`d`.`id` = `lr`.`dispositivo_id`)) left join `leituras_dht22` `ld` on(`d`.`id` = `ld`.`dispositivo_id`)) WHERE `lr`.`id` = (select max(`leituras_umidade_roupa`.`id`) from `leituras_umidade_roupa` where `leituras_umidade_roupa`.`dispositivo_id` = `d`.`id`) AND `ld`.`id` = (select max(`leituras_dht22`.`id`) from `leituras_dht22` where `leituras_dht22`.`dispositivo_id` = `d`.`id`) ;

--
-- Ãndices para tabelas despejadas
--

--
-- Ãndices de tabela `configuracoes`
--
ALTER TABLE `configuracoes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dispositivo_id` (`dispositivo_id`);

--
-- Ãndices de tabela `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `device_id` (`device_id`),
  ADD KEY `idx_device_id` (`device_id`),
  ADD KEY `idx_usuario_id` (`usuario_id`);

--
-- Ãndices de tabela `leituras_dht22`
--
ALTER TABLE `leituras_dht22`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dispositivo_tempo` (`dispositivo_id`,`lido_em`),
  ADD KEY `idx_lido_em` (`lido_em`),
  ADD KEY `idx_dispositivo_data_temp` (`dispositivo_id`,`lido_em`,`temperatura`);

--
-- Ãndices de tabela `leituras_umidade_roupa`
--
ALTER TABLE `leituras_umidade_roupa`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dispositivo_tempo` (`dispositivo_id`,`lido_em`),
  ADD KEY `idx_lido_em` (`lido_em`),
  ADD KEY `idx_dispositivo_data_umidade` (`dispositivo_id`,`lido_em`,`umidade_percentual`);

--
-- Ãndices de tabela `logs_sistema`
--
ALTER TABLE `logs_sistema`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tipo_data` (`tipo`,`criado_em`),
  ADD KEY `idx_dispositivo_id` (`dispositivo_id`);

--
-- Ãndices de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `idx_dispositivo_tipo` (`dispositivo_id`,`tipo`),
  ADD KEY `idx_enviado` (`enviado`);

--
-- Ãndices de tabela `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `chat_id` (`chat_id`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_chat_id` (`chat_id`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `configuracoes`
--
ALTER TABLE `configuracoes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `dispositivos`
--
ALTER TABLE `dispositivos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `leituras_dht22`
--
ALTER TABLE `leituras_dht22`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `leituras_umidade_roupa`
--
ALTER TABLE `leituras_umidade_roupa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `logs_sistema`
--
ALTER TABLE `logs_sistema`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- RestriÃ§Ãµes para tabelas despejadas
--

--
-- RestriÃ§Ãµes para tabelas `configuracoes`
--
ALTER TABLE `configuracoes`
  ADD CONSTRAINT `configuracoes_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE;

--
-- RestriÃ§Ãµes para tabelas `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD CONSTRAINT `dispositivos_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- RestriÃ§Ãµes para tabelas `leituras_dht22`
--
ALTER TABLE `leituras_dht22`
  ADD CONSTRAINT `leituras_dht22_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE;

--
-- RestriÃ§Ãµes para tabelas `leituras_umidade_roupa`
--
ALTER TABLE `leituras_umidade_roupa`
  ADD CONSTRAINT `leituras_umidade_roupa_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE;

--
-- RestriÃ§Ãµes para tabelas `logs_sistema`
--
ALTER TABLE `logs_sistema`
  ADD CONSTRAINT `logs_sistema_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE SET NULL;

--
-- RestriÃ§Ãµes para tabelas `notificacoes`
--
ALTER TABLE `notificacoes`
  ADD CONSTRAINT `notificacoes_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notificacoes_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
