-- =============================================================
-- GOLD.CLIENTES_SEGMENTACAO
-- Segmentação de clientes para a Diretoria de Customer Success.
--
-- OBJETIVO: Identificar os melhores clientes (VIP, TOP_TIER, REGULAR),
-- onde estão (estado e região) e como dividir a carteira em segmentos.
-- Alimenta dashboard e Genie (IA que escreve SQL a partir de perguntas
-- em português), por isso toda coluna tem comentário autoexplicativo.
--
-- REGRAS DE SEGMENTAÇÃO (definidas com a diretora a partir da
-- distribuição real de receita no período 13/12/2025 a 11/01/2026):
--   VIP       receita >= R$ 22.000,00
--   TOP_TIER  receita de R$ 17.000,00 a R$ 21.999,99
--   REGULAR   receita abaixo de R$ 17.000,00
--
-- Os limites antigos (R$ 10.000 e R$ 5.000) não serviam: com eles quase
-- todo mundo virava VIP, o que tornava a segmentação inútil para
-- priorizar o atendimento do CS. Os novos limites foram calibrados a
-- partir da distribuição real: ~20% VIP, ~50% TOP_TIER, ~30% REGULAR.
--
-- INCLUI TODOS OS CLIENTES: LEFT JOIN a partir de silver.clientes,
-- inclusive quem nunca comprou (receita = 0). É justamente esse
-- cliente que o horário do CS precisa ativar.
--
-- INCLUI TODAS AS VENDAS, inclusive de produto não cadastrado:
-- dinheiro que entrou é receita e não pode ser descartado.
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.clientes_segmentacao (
    id_cliente STRING COMMENT 'Identificador único do cliente (chave primária, vem de silver.clientes)',
    nome_cliente STRING COMMENT 'Nome do cliente sem pronome de tratamento (limpo no silver: Sr., Sra., Dr. etc. removidos, formato título)',
    estado STRING COMMENT 'Sigla da UF em maiúsculas (ex: MG, SP, RJ). Use para filtro geográfico',
    nome_estado STRING COMMENT 'Nome completo do estado (ex: Minas Gerais, São Paulo). Derivado do mapeamento IBGE',
    regiao STRING COMMENT 'Região do Brasil: Norte, Nordeste, Sudeste, Sul ou Centro-Oeste',
    total_compras INT COMMENT 'Número de transações do cliente. COALESCE 0: clientes sem compras têm zero',
    receita DECIMAL(10, 2) COMMENT 'Receita total em R$. Inclui TODAS as vendas, inclusive de produto não cadastrado. COALESCE 0 para clientes sem compras',
    ticket_medio DECIMAL(10, 2) COMMENT 'Ticket médio em R$ = receita / total_compras. Zero para clientes sem compras',
    primeira_compra DATE COMMENT 'Data da primeira compra. NULL se o cliente nunca comprou',
    ultima_compra DATE COMMENT 'Data da última compra. NULL se o cliente nunca comprou',
    segmento_cliente STRING COMMENT 'Segmento do cliente: VIP (receita >= R$ 22.000,00), TOP_TIER (R$ 17.000,00 a R$ 21.999,99), REGULAR (abaixo de R$ 17.000,00). Não use outros valores',
    ranking_receita INT COMMENT 'Posição do cliente no ranking de receita (1 = maior receita). Inclui todos os clientes, mesmo sem compras'
)
COMMENT 'Segmentação de clientes para a Diretoria de Customer Success. Use para identificar VIP/TOP_TIER/REGULAR, ranking de receita e ativar clientes sem compras. Período: 13/12/2025 a 11/01/2026.'
CLUSTER BY (segmento_cliente, regiao)
AS
WITH base AS (
    SELECT
        c.id_cliente,
        c.nome_cliente,
        c.estado,
        c.nome_estado,
        c.regiao,
        COALESCE(COUNT(v.id_venda), 0) AS total_compras,
        CAST(COALESCE(SUM(v.receita), 0) AS DECIMAL(10, 2)) AS receita,
        CAST(COALESCE(SUM(v.receita) / NULLIF(COUNT(v.id_venda), 0), 0) AS DECIMAL(10, 2)) AS ticket_medio,
        MIN(v.data) AS primeira_compra,
        MAX(v.data) AS ultima_compra
    FROM silver.clientes c
    LEFT JOIN silver.vendas v ON c.id_cliente = v.id_cliente
    GROUP BY ALL
)
SELECT
    CAST(id_cliente AS STRING) AS id_cliente,
    CAST(nome_cliente AS STRING) AS nome_cliente,
    CAST(estado AS STRING) AS estado,
    CAST(nome_estado AS STRING) AS nome_estado,
    CAST(regiao AS STRING) AS regiao,
    CAST(total_compras AS INT) AS total_compras,
    CAST(receita AS DECIMAL(10, 2)) AS receita,
    CAST(ticket_medio AS DECIMAL(10, 2)) AS ticket_medio,
    CAST(primeira_compra AS DATE) AS primeira_compra,
    CAST(ultima_compra AS DATE) AS ultima_compra,
    CASE
        WHEN receita >= 22000 THEN 'VIP'
        WHEN receita >= 17000 THEN 'TOP_TIER'
        ELSE 'REGULAR'
    END AS segmento_cliente,
    CAST(ROW_NUMBER() OVER (ORDER BY receita DESC) AS INT) AS ranking_receita
FROM base