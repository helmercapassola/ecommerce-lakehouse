-- =============================================================
-- GOLD.PRECOS_COMPETITIVIDADE
-- Análise de competitividade de preços para a Diretoria de Pricing.
--
-- OBJETIVO: Responder "somos mais caros que a concorrência?"
-- Compara nosso preço (preco_atual) com os preços de
-- concorrentes (Mercado Livre, Amazon, Magalu, Shopee).
--
-- PERÍODO: 13/12/2025 a 11/01/2026.
--
-- PREÇO SUSPEITO: O produto com preço suspeito continua em todas
-- as contas — relâmpago existe. A coluna possui_preco_suspeito
-- apenas alerta que o preço precisa ser confirmado antes de
-- reagir (ajustar, barganhar, etc.).
--
-- ESTRUTURA: JOIN de silver.produtos com a agregação de
-- silver.preco_competidores (uma linha por produto que tem preço
-- de concorrente); LEFT JOIN com a receita de silver.vendas
-- (produtos sem venda ficam com receita e itens = 0).
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.precos_competitividade (
    id_produto STRING COMMENT 'Identificador único do produto',
    nome_produto STRING COMMENT 'Nome do produto',
    categoria STRING COMMENT 'Categoria do produto',
    marca STRING COMMENT 'Marca do produto',
    nosso_preco DECIMAL(10, 2) COMMENT 'Nosso preço atual em R$ (preco_atual de silver.produtos)',
    preco_medio_concorrentes DECIMAL(10, 2) COMMENT 'Preço médio dos concorrentes em R$ (ROUND(AVG, 2))',
    preco_minimo_concorrentes DECIMAL(10, 2) COMMENT 'Preço mínimo entre os concorrentes em R$',
    preco_maximo_concorrentes DECIMAL(10, 2) COMMENT 'Preço máximo entre os concorrentes em R$',
    total_concorrentes INT COMMENT 'Número de concorrentes com preço coletado para este produto',
    diferenca_pct_vs_media DECIMAL(10, 2) COMMENT 'Diferença percentual do nosso preço vs a média dos concorrentes, em pontos percentuais. 10 = 10% mais caro. Negativo = mais barato',
    diferenca_pct_vs_minimo DECIMAL(10, 2) COMMENT 'Diferença percentual do nosso preço vs o preço mínimo dos concorrentes, em pontos percentuais. 10 = 10% mais caro. Negativo = mais barato',
    classificacao_preco STRING COMMENT 'Classificação do preço: MAIS_CARO_QUE_TODOS (acima do máximo), MAIS_BARATO_QUE_TODOS (abaixo do mínimo), ACIMA_DA_MEDIA, ABAIXO_DA_MEDIA ou NA_MEDIA',
    possui_preco_suspeito BOOLEAN COMMENT 'TRUE se algum concorrente tem preço suspeito. O produto continua em todas as contas: relâmpago existe. Apenas alerta que o preço precisa ser confirmado antes de reagir',
    receita DECIMAL(10, 2) COMMENT 'Receita total em R$ do produto (soma de receita de silver.vendas). 0 se nunca vendeu',
    itens_vendidos BIGINT COMMENT 'Total de itens vendidos (soma de quantidade). 0 se nunca vendeu'
)
COMMENT 'Análise de competitividade de preços para a Diretoria de Pricing. Compara nosso preço com concorrentes (Mercado Livre, Amazon, Magalu, Shopee). Inclui todos os produtos com preço de concorrente, mesmo os com preço suspeito. Período: 13/12/2025 a 11/01/2026.'
AS
WITH agg_competidores AS (
    SELECT
        id_produto,
        ROUND(AVG(preco_concorrente), 2) AS preco_medio,
        MIN(preco_concorrente) AS preco_minimo,
        MAX(preco_concorrente) AS preco_maximo,
        COUNT(*) AS total_concorrentes,
        MAX(CASE WHEN preco_suspeito THEN 1 ELSE 0 END) AS tem_suspeito
    FROM silver.preco_competidores
    GROUP BY id_produto
),
agg_vendas AS (
    SELECT
        id_produto,
        COALESCE(SUM(receita), 0) AS receita_total,
        COALESCE(SUM(quantidade), 0) AS itens_total
    FROM silver.vendas
    GROUP BY id_produto
)
SELECT
    CAST(p.id_produto AS STRING) AS id_produto,
    CAST(p.nome_produto AS STRING) AS nome_produto,
    CAST(p.categoria AS STRING) AS categoria,
    CAST(p.marca AS STRING) AS marca,
    CAST(p.preco_atual AS DECIMAL(10, 2)) AS nosso_preco,
    CAST(c.preco_medio AS DECIMAL(10, 2)) AS preco_medio_concorrentes,
    CAST(c.preco_minimo AS DECIMAL(10, 2)) AS preco_minimo_concorrentes,
    CAST(c.preco_maximo AS DECIMAL(10, 2)) AS preco_maximo_concorrentes,
    CAST(c.total_concorrentes AS INT) AS total_concorrentes,
    CAST(ROUND(((p.preco_atual - c.preco_medio) / c.preco_medio) * 100, 2) AS DECIMAL(10, 2)) AS diferenca_pct_vs_media,
    CAST(ROUND(((p.preco_atual - c.preco_minimo) / c.preco_minimo) * 100, 2) AS DECIMAL(10, 2)) AS diferenca_pct_vs_minimo,
    CAST(
        CASE
            WHEN p.preco_atual > c.preco_maximo THEN 'MAIS_CARO_QUE_TODOS'
            WHEN p.preco_atual < c.preco_minimo THEN 'MAIS_BARATO_QUE_TODOS'
            WHEN p.preco_atual > c.preco_medio THEN 'ACIMA_DA_MEDIA'
            WHEN p.preco_atual < c.preco_medio THEN 'ABAIXO_DA_MEDIA'
            ELSE 'NA_MEDIA'
        END AS STRING
    ) AS classificacao_preco,
    CAST(c.tem_suspeito = 1 AS BOOLEAN) AS possui_preco_suspeito,
    CAST(COALESCE(v.receita_total, 0) AS DECIMAL(10, 2)) AS receita,
    CAST(COALESCE(v.itens_total, 0) AS BIGINT) AS itens_vendidos
FROM silver.produtos p
JOIN agg_competidores c ON p.id_produto = c.id_produto
LEFT JOIN agg_vendas v ON p.id_produto = v.id_produto