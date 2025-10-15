-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 18/09/2025 às 21:21
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
-- Banco de dados: `grampo_iot`
--

-- --------------------------------------------------------

--
-- Estrutura para tabela `dispositivos`
--

CREATE TABLE `dispositivos` (
  `id_dispositivo` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `localizacao` varchar(150) DEFAULT NULL,
  `modelo` varchar(50) DEFAULT 'ESP32',
  `status` enum('ativo','inativo') DEFAULT 'ativo',
  `criado_em` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `dispositivos`
--

INSERT INTO `dispositivos` (`id_dispositivo`, `id_usuario`, `nome`, `localizacao`, `modelo`, `status`, `criado_em`) VALUES
(1, 2, 'Grampo Quintal', 'Quintal - Varal Principal', 'ESP32', 'ativo', '2025-09-18 18:53:22'),
(2, 3, 'Grampo Quintal Principal', 'Quintal - Varal Principal', 'ESP32', 'ativo', '2025-09-18 19:10:23'),
(3, 3, 'Grampo Área de Serviço', 'Área de Serviço - Varal Interno', 'ESP32', 'ativo', '2025-09-18 19:10:23'),
(4, 3, 'Grampo Sacada', 'Sacada do Apartamento', 'ESP32', 'inativo', '2025-09-18 19:10:23');

-- --------------------------------------------------------

--
-- Estrutura para tabela `leituras`
--

CREATE TABLE `leituras` (
  `id_leitura` int(11) NOT NULL,
  `id_dispositivo` int(11) NOT NULL,
  `id_sensor` int(11) NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `data_hora` timestamp NOT NULL DEFAULT current_timestamp(),
  `status_roupa` enum('Úmida','Seca') DEFAULT 'Úmida'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `leituras`
--

INSERT INTO `leituras` (`id_leitura`, `id_dispositivo`, `id_sensor`, `valor`, `data_hora`, `status_roupa`) VALUES
(1, 1, 1, 25.50, '2025-09-18 18:53:22', 'Seca'),
(2, 1, 2, 65.00, '2025-09-18 18:53:22', 'Seca'),
(3, 1, 3, 15.00, '2025-09-18 18:53:22', 'Seca'),
(4, 1, 4, 0.00, '2025-09-18 18:53:22', 'Seca'),
(5, 2, 1, 28.50, '2025-09-18 19:00:23', 'Seca'),
(6, 2, 2, 45.20, '2025-09-18 19:00:23', 'Seca'),
(7, 2, 3, 12.00, '2025-09-18 19:00:23', 'Seca'),
(8, 2, 4, 0.00, '2025-09-18 19:00:23', 'Seca'),
(9, 2, 1, 27.80, '2025-09-18 18:45:23', 'Úmida'),
(10, 2, 2, 52.10, '2025-09-18 18:45:23', 'Úmida'),
(11, 2, 3, 35.50, '2025-09-18 18:45:23', 'Úmida'),
(12, 2, 4, 0.00, '2025-09-18 18:45:23', 'Úmida'),
(13, 2, 1, 26.30, '2025-09-18 18:25:23', 'Úmida'),
(14, 2, 2, 65.80, '2025-09-18 18:25:23', 'Úmida'),
(15, 2, 3, 58.20, '2025-09-18 18:25:23', 'Úmida'),
(16, 2, 4, 1.00, '2025-09-18 18:25:23', 'Úmida'),
(17, 3, 1, 24.10, '2025-09-18 19:05:23', 'Seca'),
(18, 3, 2, 38.70, '2025-09-18 19:05:23', 'Seca'),
(19, 3, 3, 8.50, '2025-09-18 19:05:23', 'Seca'),
(20, 3, 4, 0.00, '2025-09-18 19:05:23', 'Seca'),
(21, 3, 1, 23.90, '2025-09-18 18:40:23', 'Úmida'),
(22, 3, 2, 48.30, '2025-09-18 18:40:23', 'Úmida'),
(23, 3, 3, 42.10, '2025-09-18 18:40:23', 'Úmida'),
(24, 3, 4, 0.00, '2025-09-18 18:40:23', 'Úmida'),
(25, 2, 1, 32.10, '2025-09-18 17:10:23', 'Seca'),
(26, 2, 2, 41.50, '2025-09-18 17:10:23', 'Seca'),
(27, 2, 3, 15.20, '2025-09-18 17:10:23', 'Seca'),
(28, 2, 4, 0.00, '2025-09-18 17:10:23', 'Seca'),
(29, 2, 1, 29.80, '2025-09-18 16:10:23', 'Úmida'),
(30, 2, 2, 68.40, '2025-09-18 16:10:23', 'Úmida'),
(31, 2, 3, 45.70, '2025-09-18 16:10:23', 'Úmida'),
(32, 2, 4, 0.00, '2025-09-18 16:10:23', 'Úmida'),
(33, 3, 1, 25.60, '2025-09-18 18:10:23', 'Seca'),
(34, 3, 2, 43.20, '2025-09-18 18:10:23', 'Seca'),
(35, 3, 3, 18.90, '2025-09-18 18:10:23', 'Seca'),
(36, 3, 4, 0.00, '2025-09-18 18:10:23', 'Seca'),
(37, 2, 1, 26.70, '2025-09-17 21:10:23', 'Seca'),
(38, 2, 2, 39.80, '2025-09-17 21:10:23', 'Seca'),
(39, 2, 3, 11.30, '2025-09-17 21:10:23', 'Seca'),
(40, 2, 4, 0.00, '2025-09-17 21:10:23', 'Seca'),
(41, 2, 1, 28.90, '2025-09-17 19:10:23', 'Úmida'),
(42, 2, 2, 72.10, '2025-09-17 19:10:23', 'Úmida'),
(43, 2, 3, 61.40, '2025-09-17 19:10:23', 'Úmida'),
(44, 2, 4, 1.00, '2025-09-17 19:10:23', 'Úmida'),
(45, 3, 1, 22.40, '2025-09-17 22:10:23', 'Seca'),
(46, 3, 2, 35.60, '2025-09-17 22:10:23', 'Seca'),
(47, 3, 3, 14.80, '2025-09-17 22:10:23', 'Seca'),
(48, 3, 4, 0.00, '2025-09-17 22:10:23', 'Seca');

-- --------------------------------------------------------

--
-- Estrutura para tabela `notificacoes`
--

CREATE TABLE `notificacoes` (
  `id_notificacao` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `tipo_notificacao` varchar(50) NOT NULL,
  `mensagem` text NOT NULL,
  `lida` tinyint(1) DEFAULT 0,
  `data_hora` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `notificacoes`
--

INSERT INTO `notificacoes` (`id_notificacao`, `id_usuario`, `tipo_notificacao`, `mensagem`, `lida`, `data_hora`) VALUES
(1, 2, 'roupa_seca', 'Sua roupa no Grampo Quintal está seca!', 0, '2025-09-18 18:53:22'),
(2, 3, 'roupa_seca', 'Sua roupa no Grampo Quintal Principal está seca!', 0, '2025-09-18 18:55:23'),
(3, 3, 'chuva_detectada', 'Chuva detectada! Recolha suas roupas do Grampo Quintal Principal.', 0, '2025-09-18 17:10:23'),
(4, 3, 'roupa_seca', 'Sua roupa no Grampo Área de Serviço está seca!', 0, '2025-09-18 18:35:23'),
(5, 3, 'sistema', 'Bem-vindo ao sistema Grampo IoT!', 1, '2025-09-17 19:10:23'),
(6, 3, 'dispositivo_offline', 'O dispositivo Grampo Sacada está offline.', 0, '2025-09-18 15:10:23');

-- --------------------------------------------------------

--
-- Estrutura para tabela `recuperacao_senha`
--

CREATE TABLE `recuperacao_senha` (
  `id` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `expira_em` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `usado` tinyint(1) DEFAULT 0,
  `criado_em` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `sensores`
--

CREATE TABLE `sensores` (
  `id_sensor` int(11) NOT NULL,
  `tipo_sensor` varchar(50) NOT NULL,
  `unidade_medida` varchar(20) NOT NULL,
  `descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `sensores`
--

INSERT INTO `sensores` (`id_sensor`, `tipo_sensor`, `unidade_medida`, `descricao`) VALUES
(1, 'temperatura', '°C', 'Sensor de temperatura ambiente'),
(2, 'umidade_ar', '%', 'Sensor de umidade relativa do ar'),
(3, 'umidade_roupa', '%', 'Sensor de umidade da roupa'),
(4, 'chuva', 'boolean', 'Sensor de detecção de chuva');

-- --------------------------------------------------------

--
-- Estrutura para tabela `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `cpf` varchar(11) NOT NULL,
  `celular` varchar(15) NOT NULL,
  `email` varchar(100) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `data_nascimento` date NOT NULL,
  `tipo_usuario` enum('A','C') DEFAULT 'C',
  `criado_em` timestamp NOT NULL DEFAULT current_timestamp(),
  `atualizado_em` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nome`, `cpf`, `celular`, `email`, `senha`, `data_nascimento`, `tipo_usuario`, `criado_em`, `atualizado_em`) VALUES
(1, 'Administrador', '00000000000', '(00) 00000-0000', 'admin@grampo.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '1990-01-01', 'A', '2025-09-18 18:53:22', '2025-09-18 18:53:22'),
(2, 'Usuário Teste', '12345678901', '(11) 99999-9999', 'usuario@teste.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '1995-05-15', 'C', '2025-09-18 18:53:22', '2025-09-18 18:53:22'),
(3, 'Vinicius Quadros', '05178689976', '(41) 99245-7725', 'vini@gmail.com', '$2y$10$8jn4FrKeXNXpThknQi6khOJVH8/zrmKNFv5eqMgkgWOdaUUrnNzRm', '2002-09-24', 'C', '2025-09-18 19:04:00', '2025-09-18 19:04:00');

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD PRIMARY KEY (`id_dispositivo`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Índices de tabela `leituras`
--
ALTER TABLE `leituras`
  ADD PRIMARY KEY (`id_leitura`),
  ADD KEY `id_dispositivo` (`id_dispositivo`),
  ADD KEY `id_sensor` (`id_sensor`);

--
-- Índices de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  ADD PRIMARY KEY (`id_notificacao`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Índices de tabela `recuperacao_senha`
--
ALTER TABLE `recuperacao_senha`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Índices de tabela `sensores`
--
ALTER TABLE `sensores`
  ADD PRIMARY KEY (`id_sensor`);

--
-- Índices de tabela `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `cpf` (`cpf`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `dispositivos`
--
ALTER TABLE `dispositivos`
  MODIFY `id_dispositivo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `leituras`
--
ALTER TABLE `leituras`
  MODIFY `id_leitura` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  MODIFY `id_notificacao` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de tabela `recuperacao_senha`
--
ALTER TABLE `recuperacao_senha`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `sensores`
--
ALTER TABLE `sensores`
  MODIFY `id_sensor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD CONSTRAINT `dispositivos_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE;

--
-- Restrições para tabelas `leituras`
--
ALTER TABLE `leituras`
  ADD CONSTRAINT `leituras_ibfk_1` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`) ON DELETE CASCADE,
  ADD CONSTRAINT `leituras_ibfk_2` FOREIGN KEY (`id_sensor`) REFERENCES `sensores` (`id_sensor`);

--
-- Restrições para tabelas `notificacoes`
--
ALTER TABLE `notificacoes`
  ADD CONSTRAINT `notificacoes_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE;

--
-- Restrições para tabelas `recuperacao_senha`
--
ALTER TABLE `recuperacao_senha`
  ADD CONSTRAINT `recuperacao_senha_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
