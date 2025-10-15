-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 10/10/2025 às 22:38
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.2.12

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

--
-- Despejando dados para a tabela `configuracoes`
--

INSERT INTO `configuracoes` (`id`, `dispositivo_id`, `limiar_umidade_seca`, `intervalo_leitura`, `telegram_bot_token`, `wifi_ssid`, `wifi_password`, `atualizado_em`) VALUES
(1, 1, 30, 5000, '8238331019:AAG1gn4RQq9t7rK9LwWkFleuRXZyzTbw4hI', NULL, NULL, '2025-09-29 22:57:16');

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
(1, 1, 'Grampo Quintal', 'Área Externa - Varal Principal', 'ESP32_001', 'ativo', '2025-09-29 22:57:16', '2025-09-29 22:57:16');

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
-- Acionadores `leituras_umidade_roupa`
--
DELIMITER $$
CREATE TRIGGER `tr_notificar_roupa_seca` AFTER INSERT ON `leituras_umidade_roupa` FOR EACH ROW BEGIN
    DECLARE v_usuario_id INT;
    DECLARE v_ultima_notificacao TIMESTAMP;
    
    -- Obter usuário do dispositivo
    SELECT usuario_id INTO v_usuario_id
    FROM dispositivos
    WHERE id = NEW.dispositivo_id;
    
    -- Verificar se roupa está seca e não há notificação recente
    IF NEW.status_roupa = 'Seca' THEN
        -- Verificar última notificação (evitar spam)
        SELECT MAX(criado_em) INTO v_ultima_notificacao
        FROM notificacoes
        WHERE dispositivo_id = NEW.dispositivo_id
            AND tipo = 'roupa_seca';
        
        -- Se não há notificação nos últimos 30 minutos, criar nova
        IF v_ultima_notificacao IS NULL 
            OR v_ultima_notificacao < DATE_SUB(NOW(), INTERVAL 30 MINUTE) THEN
            
            INSERT INTO notificacoes (dispositivo_id, usuario_id, tipo, mensagem)
            VALUES (
                NEW.dispositivo_id,
                v_usuario_id,
                'roupa_seca',
                CONCAT('? Sua roupa já está seca! Umidade: ', NEW.umidade_percentual, '%')
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
(1, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:29:48'),
(2, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:29:53'),
(3, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:29:58'),
(4, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:03'),
(5, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:08'),
(6, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:13'),
(7, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:18'),
(8, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:23'),
(9, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:28'),
(10, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:33'),
(11, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:38'),
(12, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:43'),
(13, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:48'),
(14, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:53'),
(15, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:30:58'),
(16, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:03'),
(17, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:08'),
(18, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:13'),
(19, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:18'),
(20, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:23'),
(21, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:28'),
(22, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:33'),
(23, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:38'),
(24, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:43'),
(25, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:48'),
(26, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:53'),
(27, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:31:58'),
(28, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:03'),
(29, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:08'),
(30, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:13'),
(31, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:18'),
(32, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:23'),
(33, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:28'),
(34, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:33'),
(35, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:40'),
(36, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:45'),
(37, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:50'),
(38, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:32:55'),
(39, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:00'),
(40, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:05'),
(41, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:10'),
(42, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:15'),
(43, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:20'),
(44, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:25'),
(45, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:30'),
(46, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:35'),
(47, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:40'),
(48, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:45'),
(49, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:50'),
(50, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:33:55'),
(51, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:12'),
(52, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:17'),
(53, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:22'),
(54, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:27'),
(55, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:32'),
(56, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:37'),
(57, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:42'),
(58, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:47'),
(59, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:52'),
(60, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:34:57'),
(61, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:02'),
(62, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:07'),
(63, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:12'),
(64, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:17'),
(65, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:22'),
(66, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:27'),
(67, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:32'),
(68, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:38'),
(69, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:42'),
(70, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:47'),
(71, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:52'),
(72, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:35:58'),
(73, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:02'),
(74, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:07'),
(75, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:12'),
(76, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:17'),
(77, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:22'),
(78, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:27'),
(79, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:32'),
(80, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:37'),
(81, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:42'),
(82, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:47'),
(83, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:52'),
(84, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:36:57'),
(85, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:02'),
(86, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:07'),
(87, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:13'),
(88, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:17'),
(89, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:22'),
(90, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:27'),
(91, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:33'),
(92, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:37'),
(93, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:42'),
(94, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:47'),
(95, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:52'),
(96, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:37:57'),
(97, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:02'),
(98, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:08'),
(99, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:12'),
(100, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:17'),
(101, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:22'),
(102, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:27'),
(103, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:32'),
(104, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:50'),
(105, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:38:55'),
(106, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:00'),
(107, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:05'),
(108, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:10'),
(109, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:15'),
(110, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:20'),
(111, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:25'),
(112, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:30'),
(113, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:35'),
(114, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:40'),
(115, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:45'),
(116, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:50'),
(117, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:39:55'),
(118, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:00'),
(119, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:05'),
(120, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:10'),
(121, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:15'),
(122, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:20'),
(123, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:25'),
(124, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:30'),
(125, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:35'),
(126, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:40'),
(127, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:45'),
(128, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:50'),
(129, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:40:55'),
(130, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:00'),
(131, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:05'),
(132, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:10'),
(133, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:15'),
(134, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:20'),
(135, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:25'),
(136, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:30'),
(137, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:35'),
(138, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:40'),
(139, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:46'),
(140, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:50'),
(141, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:41:55'),
(142, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:00'),
(143, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:05'),
(144, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:10'),
(145, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:15'),
(146, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:20'),
(147, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:25'),
(148, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:30'),
(149, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:35'),
(150, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:40'),
(151, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:45'),
(152, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:50'),
(153, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:42:55'),
(154, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:00'),
(155, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:05'),
(156, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:10'),
(157, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:15'),
(158, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:20'),
(159, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:25'),
(160, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:30'),
(161, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:35'),
(162, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:40'),
(163, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:45'),
(164, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:50'),
(165, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:43:55'),
(166, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:00'),
(167, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:05'),
(168, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:10'),
(169, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:15'),
(170, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:20'),
(171, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:25'),
(172, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:30'),
(173, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:35'),
(174, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:40'),
(175, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:45'),
(176, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:50'),
(177, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:44:55'),
(178, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:00'),
(179, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:05'),
(180, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:10'),
(181, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:15'),
(182, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:20'),
(183, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:25'),
(184, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:30'),
(185, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:35'),
(186, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:40'),
(187, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:45'),
(188, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:50'),
(189, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:45:55'),
(190, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:00'),
(191, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:05'),
(192, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:10'),
(193, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:15'),
(194, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:20'),
(195, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:25'),
(196, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:30'),
(197, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:35'),
(198, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:40'),
(199, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:45'),
(200, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:50'),
(201, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:46:55'),
(202, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:00'),
(203, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:05'),
(204, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:10'),
(205, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:15'),
(206, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:20'),
(207, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:25'),
(208, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:30'),
(209, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:35'),
(210, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:40'),
(211, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:45'),
(212, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:50'),
(213, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:47:55'),
(214, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:03'),
(215, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:05'),
(216, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:10'),
(217, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:15'),
(218, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:20'),
(219, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:25'),
(220, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:30'),
(221, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:35'),
(222, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:40'),
(223, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:45'),
(224, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:50'),
(225, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:48:55'),
(226, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:00'),
(227, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:05'),
(228, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:10'),
(229, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:15'),
(230, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:20'),
(231, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:25'),
(232, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:30'),
(233, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:35'),
(234, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:40'),
(235, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:45'),
(236, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:50'),
(237, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:49:55'),
(238, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:00'),
(239, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:05'),
(240, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:10'),
(241, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:15'),
(242, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:20'),
(243, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:25'),
(244, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:30'),
(245, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:35'),
(246, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:40'),
(247, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:45'),
(248, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:50'),
(249, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:50:55'),
(250, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:00'),
(251, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:05'),
(252, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:10'),
(253, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:15'),
(254, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:20'),
(255, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:25'),
(256, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:47'),
(257, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:51:52'),
(258, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:03'),
(259, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:08'),
(260, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:13'),
(261, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:18'),
(262, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:23'),
(263, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:28'),
(264, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:33'),
(265, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:38'),
(266, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:43'),
(267, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:48'),
(268, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:53'),
(269, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:52:58'),
(270, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:03'),
(271, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:08'),
(272, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:13'),
(273, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:18'),
(274, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:23'),
(275, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:28'),
(276, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:33'),
(277, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:38'),
(278, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:43'),
(279, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:48'),
(280, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:53'),
(281, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:53:58'),
(282, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:03'),
(283, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:08'),
(284, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:13'),
(285, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:18'),
(286, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:23'),
(287, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:28'),
(288, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:33'),
(289, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:38'),
(290, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:43'),
(291, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:48'),
(292, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:53'),
(293, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:54:58'),
(294, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:03'),
(295, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:08'),
(296, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:13'),
(297, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:18'),
(298, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:23'),
(299, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:28'),
(300, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:33'),
(301, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:38'),
(302, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:43'),
(303, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:48'),
(304, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:53'),
(305, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:55:58'),
(306, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:56:03'),
(307, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:56:08'),
(308, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:56:13'),
(309, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:59:34'),
(310, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:59:38'),
(311, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:59:44'),
(312, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:59:48'),
(313, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:59:54'),
(314, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 20:59:59'),
(315, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:03'),
(316, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:08'),
(317, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:13'),
(318, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:19'),
(319, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:23'),
(320, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:28'),
(321, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:34'),
(322, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:38'),
(323, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:43'),
(324, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:49'),
(325, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:53'),
(326, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:00:58'),
(327, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:04'),
(328, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:09'),
(329, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:13'),
(330, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:18'),
(331, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:23'),
(332, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:28'),
(333, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:34'),
(334, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:38'),
(335, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:43'),
(336, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:48'),
(337, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:53'),
(338, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:01:58'),
(339, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:04'),
(340, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:09'),
(341, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:14'),
(342, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:18'),
(343, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:23'),
(344, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:28'),
(345, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:33'),
(346, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:38'),
(347, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:43'),
(348, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:48'),
(349, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:02:54'),
(350, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:07'),
(351, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:12'),
(352, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:17'),
(353, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:22'),
(354, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:27'),
(355, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:32'),
(356, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:37'),
(357, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:42'),
(358, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:47'),
(359, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:52'),
(360, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:03:57'),
(361, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:02'),
(362, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:07'),
(363, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:12'),
(364, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:17'),
(365, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:22'),
(366, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:27'),
(367, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:32'),
(368, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:37'),
(369, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:04:42'),
(370, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:00'),
(371, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:10'),
(372, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:14'),
(373, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:19'),
(374, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:24'),
(375, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:29'),
(376, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:34'),
(377, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:39'),
(378, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:44'),
(379, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:49'),
(380, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:55'),
(381, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:05:59'),
(382, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:04'),
(383, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:09'),
(384, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:14'),
(385, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:19'),
(386, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:24'),
(387, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:29'),
(388, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:34'),
(389, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:39'),
(390, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:45'),
(391, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:49'),
(392, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:54'),
(393, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:06:59'),
(394, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:04'),
(395, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:09'),
(396, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:14'),
(397, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:19'),
(398, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:41'),
(399, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:46'),
(400, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:51'),
(401, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:07:56'),
(402, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:01'),
(403, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:06'),
(404, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:11'),
(405, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:16'),
(406, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:21'),
(407, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:26'),
(408, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:31'),
(409, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:36'),
(410, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:41'),
(411, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:46'),
(412, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:51'),
(413, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:08:56'),
(414, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:01'),
(415, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:06'),
(416, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:11'),
(417, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:16'),
(418, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:21'),
(419, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:26'),
(420, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:31'),
(421, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:36'),
(422, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:41'),
(423, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:46'),
(424, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:51'),
(425, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:09:56'),
(426, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:01'),
(427, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:06'),
(428, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:11'),
(429, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:16'),
(430, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:21'),
(431, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:26'),
(432, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:31'),
(433, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:36'),
(434, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:41'),
(435, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:46'),
(436, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:51'),
(437, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:10:56'),
(438, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:11:01'),
(439, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:11:06'),
(440, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:11:11'),
(441, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:11:16'),
(442, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:11:21'),
(443, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:13:30'),
(444, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:13:30'),
(445, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:13:35'),
(446, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:13:35'),
(447, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:13:40'),
(448, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:13:40'),
(449, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:13:45'),
(450, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:13:45'),
(451, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:13:50'),
(452, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:13:50'),
(453, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:13:55'),
(454, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:13:55'),
(455, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:00'),
(456, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:00'),
(457, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:05'),
(458, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:05'),
(459, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:10'),
(460, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:10'),
(461, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:15'),
(462, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:15'),
(463, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:20'),
(464, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:20'),
(465, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:25'),
(466, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:25'),
(467, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:30'),
(468, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:30'),
(469, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:35'),
(470, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:35'),
(471, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:40'),
(472, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:40'),
(473, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:45'),
(474, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:45'),
(475, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:50'),
(476, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:50'),
(477, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:14:55'),
(478, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:14:55'),
(479, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:00'),
(480, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:00'),
(481, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:05'),
(482, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:10'),
(483, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:15'),
(484, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:15'),
(485, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:20'),
(486, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:20'),
(487, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:25'),
(488, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:25'),
(489, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:30'),
(490, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:30'),
(491, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:35'),
(492, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:35'),
(493, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:40'),
(494, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:40'),
(495, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:45'),
(496, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:45'),
(497, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:50'),
(498, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:50'),
(499, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:15:55'),
(500, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:15:55'),
(501, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:00'),
(502, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:00'),
(503, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:05'),
(504, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:05'),
(505, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:10'),
(506, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:10'),
(507, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:15'),
(508, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:15'),
(509, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:20'),
(510, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:20'),
(511, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:25'),
(512, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:25'),
(513, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:30'),
(514, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:30'),
(515, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:35'),
(516, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:35'),
(517, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:40'),
(518, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:40'),
(519, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:45'),
(520, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:45'),
(521, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:50'),
(522, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:50'),
(523, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:16:55'),
(524, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:16:55'),
(525, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:00'),
(526, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:00'),
(527, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:05'),
(528, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:05'),
(529, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:10'),
(530, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:10'),
(531, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:15'),
(532, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:15'),
(533, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:20'),
(534, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:20'),
(535, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:25'),
(536, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:25'),
(537, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:30'),
(538, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:30'),
(539, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:35'),
(540, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:35'),
(541, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:40'),
(542, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:40'),
(543, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:45'),
(544, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:45'),
(545, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:50'),
(546, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:50'),
(547, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:17:55'),
(548, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:17:55'),
(549, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:00'),
(550, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:00'),
(551, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:05'),
(552, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:05'),
(553, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:10'),
(554, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:10'),
(555, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:15'),
(556, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:15'),
(557, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:20'),
(558, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:20'),
(559, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:25'),
(560, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:25'),
(561, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:30'),
(562, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:30'),
(563, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:35'),
(564, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:35'),
(565, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:40'),
(566, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:40'),
(567, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:45'),
(568, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:45'),
(569, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:50'),
(570, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:50'),
(571, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:18:55'),
(572, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:18:55'),
(573, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:00'),
(574, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:00'),
(575, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:05'),
(576, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:05'),
(577, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:10'),
(578, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:10'),
(579, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:15'),
(580, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:15'),
(581, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:20'),
(582, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:20'),
(583, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:25'),
(584, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:25'),
(585, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:30'),
(586, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:30'),
(587, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:35'),
(588, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:35'),
(589, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:40'),
(590, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:40'),
(591, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:45'),
(592, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:45'),
(593, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:50'),
(594, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:50'),
(595, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:19:55'),
(596, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:19:55'),
(597, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:00'),
(598, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:00'),
(599, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:05'),
(600, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:05'),
(601, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:10'),
(602, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:10'),
(603, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:15'),
(604, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:15'),
(605, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:20'),
(606, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:20'),
(607, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:25'),
(608, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:25'),
(609, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:30'),
(610, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:30'),
(611, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:35'),
(612, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:35'),
(613, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:40'),
(614, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:40'),
(615, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:45'),
(616, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:45'),
(617, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:50'),
(618, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:50'),
(619, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:20:55'),
(620, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:20:55'),
(621, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:00'),
(622, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:00'),
(623, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:05'),
(624, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:05'),
(625, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:10'),
(626, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:10'),
(627, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:15'),
(628, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:15'),
(629, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:20'),
(630, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:20'),
(631, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:25'),
(632, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:25'),
(633, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:30'),
(634, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:30'),
(635, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:35'),
(636, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:35'),
(637, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:40'),
(638, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:40'),
(639, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:45');
INSERT INTO `logs_sistema` (`id`, `dispositivo_id`, `tipo`, `mensagem`, `criado_em`) VALUES
(640, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:45'),
(641, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:50'),
(642, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:50'),
(643, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:21:55'),
(644, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:21:55'),
(645, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:00'),
(646, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:00'),
(647, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:05'),
(648, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:05'),
(649, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:10'),
(650, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:10'),
(651, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:15'),
(652, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:15'),
(653, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:20'),
(654, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:20'),
(655, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:25'),
(656, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:25'),
(657, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:30'),
(658, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:30'),
(659, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:35'),
(660, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:35'),
(661, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:40'),
(662, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:40'),
(663, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:45'),
(664, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:45'),
(665, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:50'),
(666, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:50'),
(667, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:22:55'),
(668, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:22:55'),
(669, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:00'),
(670, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:00'),
(671, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:05'),
(672, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:05'),
(673, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:10'),
(674, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:10'),
(675, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:15'),
(676, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:15'),
(677, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:20'),
(678, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:20'),
(679, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:25'),
(680, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:25'),
(681, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:30'),
(682, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:30'),
(683, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:52'),
(684, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:52'),
(685, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:23:57'),
(686, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:23:57'),
(687, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:26:31'),
(688, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:26:36'),
(689, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:26:41'),
(690, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:26:41'),
(691, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:26:46'),
(692, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:26:46'),
(693, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:26:51'),
(694, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:26:51'),
(695, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:26:56'),
(696, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:26:56'),
(697, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:01'),
(698, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:06'),
(699, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:11'),
(700, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:16'),
(701, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:21'),
(702, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:26'),
(703, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:31'),
(704, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:27:36'),
(705, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:36'),
(706, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:27:41'),
(707, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:41'),
(708, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:27:46'),
(709, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:46'),
(710, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:27:51'),
(711, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:51'),
(712, 1, 'roupa_seca', 'Roupa detectada como seca', '2025-09-30 21:27:56'),
(713, 1, 'leitura_salva', 'Leituras salvas com sucesso', '2025-09-30 21:27:56');

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
(2, 1, 1, 'roupa_seca', '🎉 Sua roupa já está seca! Umidade: 0%', 1, '2025-09-30 21:27:40', '2025-09-30 21:27:36');

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
  `atualizado_em` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `usuarios`
--

INSERT INTO `usuarios` (`id`, `nome`, `email`, `senha`, `telefone`, `chat_id`, `criado_em`, `atualizado_em`) VALUES
(1, 'Usuário Teste', 'teste@teste.com', 'aa1bf4646de67fd9086cf6c79007026c', '(41) 99999-9999', '-1003035825266', '2025-09-29 22:57:16', '2025-09-29 22:57:16');

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `vw_historico_24h`
-- (Veja abaixo para a visão atual)
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
-- (Veja abaixo para a visão atual)
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
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `configuracoes`
--
ALTER TABLE `configuracoes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dispositivo_id` (`dispositivo_id`);

--
-- Índices de tabela `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `device_id` (`device_id`),
  ADD KEY `idx_device_id` (`device_id`),
  ADD KEY `idx_usuario_id` (`usuario_id`);

--
-- Índices de tabela `leituras_dht22`
--
ALTER TABLE `leituras_dht22`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dispositivo_tempo` (`dispositivo_id`,`lido_em`),
  ADD KEY `idx_lido_em` (`lido_em`),
  ADD KEY `idx_dispositivo_data_temp` (`dispositivo_id`,`lido_em`,`temperatura`);

--
-- Índices de tabela `leituras_umidade_roupa`
--
ALTER TABLE `leituras_umidade_roupa`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dispositivo_tempo` (`dispositivo_id`,`lido_em`),
  ADD KEY `idx_lido_em` (`lido_em`),
  ADD KEY `idx_dispositivo_data_umidade` (`dispositivo_id`,`lido_em`,`umidade_percentual`);

--
-- Índices de tabela `logs_sistema`
--
ALTER TABLE `logs_sistema`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tipo_data` (`tipo`,`criado_em`),
  ADD KEY `idx_dispositivo_id` (`dispositivo_id`);

--
-- Índices de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `idx_dispositivo_tipo` (`dispositivo_id`,`tipo`),
  ADD KEY `idx_enviado` (`enviado`);

--
-- Índices de tabela `usuarios`
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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `dispositivos`
--
ALTER TABLE `dispositivos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `leituras_dht22`
--
ALTER TABLE `leituras_dht22`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=584;

--
-- AUTO_INCREMENT de tabela `leituras_umidade_roupa`
--
ALTER TABLE `leituras_umidade_roupa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=584;

--
-- AUTO_INCREMENT de tabela `logs_sistema`
--
ALTER TABLE `logs_sistema`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=714;

--
-- AUTO_INCREMENT de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `configuracoes`
--
ALTER TABLE `configuracoes`
  ADD CONSTRAINT `configuracoes_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD CONSTRAINT `dispositivos_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `leituras_dht22`
--
ALTER TABLE `leituras_dht22`
  ADD CONSTRAINT `leituras_dht22_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `leituras_umidade_roupa`
--
ALTER TABLE `leituras_umidade_roupa`
  ADD CONSTRAINT `leituras_umidade_roupa_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `logs_sistema`
--
ALTER TABLE `logs_sistema`
  ADD CONSTRAINT `logs_sistema_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE SET NULL;

--
-- Restrições para tabelas `notificacoes`
--
ALTER TABLE `notificacoes`
  ADD CONSTRAINT `notificacoes_ibfk_1` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notificacoes_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
