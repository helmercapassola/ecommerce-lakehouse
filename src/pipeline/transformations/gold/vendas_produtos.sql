-- =============================================================
-- GOLD.VENDAS_PRODUTOS
-- Análise de vendas por produto para a Diretoria Comercial.
--
-- OBJETIVO: Responder "com quais produtos vendemos". Uma linha
-- por produto vendido (agregado por id_produto), com totais de
-- vendas, itens, receita, ticket médio e rankings.
--
-- PERÍODO: 13/12/2025 a 11/01/2026.
--
-- INCLUI TODAS AS VENDAS, inclusive de produto não cadastrado:
-- quando o id_produto não existe em silver.produtos, nome e
-- categoria recebem "Produto não cadastrado" e marca recebe
-- "Não cadastrado". Dinheiro que entrou é receita e não pode
-- ser descartado.
--
-- AVISO: produtos diferentes possuem o mesmo nome. A contagem
-- e o ranking são por id_produto, não por nome_produto.
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.vendas_produtos (
    id_produto STRING COMMENT 'Identificador único do produto (chave primária). Produtos diferentes podem ter o mesmo nome; contagem e ranking são por id_produto',
    nome_produto STRING COMMENT 'Nome do produto. Quando não cadastrado: "Produto não cadastrado". AVISO: produtos diferentes possuem o mesmo nome, contados por id_produto',
    categoria STRING COMMENT 'Categoria do produto (ex: Eletrônicos, Moda, Casa). Quando não cadastrado: "Produto não cadastrado"',
    marca STRING COMMENT 'Marca do produto (ex: Sony, Apple). Quando não cadastrado: "Não cadastrado"',
    faixa_preco STRING COMMENT 'Faixa de preço do produto (ex: BASICO, PREMIUM). Quando não cadastrado: "Não cadastrado"',
    produto_cadastrado BOOLEAN COMMENT 'TRUE se o produto existe em silver.produtos, FALSE caso contrário',
    total_vendas BIGINT COMMENT 'Número de transações do produto. Inclui TODAS as vendas, inclusive de produto não cadastrado',
    itens_vendidos BIGINT COMMENT 'Total de itens vendidos (soma de quantidade)',
    receita DECIMAL(10, 2) COMMENT 'Receita total em R$ (soma de receita). Inclui TODAS as vendas, inclusive de produto não cadastrado',
    ticket_medio DECIMAL(10, 2) COMMENT 'Ticket médio em R$ = média de receita por transação. ROUND(AVG(receita), 2)',
    ranking_receita INT COMMENT 'Posição do produto no ranking geral de receita (1 = maior receita)',
    ranking_na_categoria INT COMMENT 'Posição do produto no ranking de receita dentro de sua categoria (1 = maior receita na categoria)'
)
COMMENT 'Análise de vendas por produto para a Diretoria Comercial. Uma linha por id_produto com totais, ticket médio e rankings de receita. Inclui produtos não cadastrados. Período: 13/12/2025 a 11/01/2026.'
AS
WITH base AS (
    SELECT
        v.id_produto,
        COALESCE(p.nome_produto, 'Produto não cadastrado') AS nome_produto,
        COALESCE(p.categoria, 'Produto não cadastrado') AS categoria,
        COALESCE(p.marca, 'Não cadastrado') AS marca,
        COALESCE(p.faixa_preco, 'Não cadastrado') AS faixa_preco,
        v.produto_cadastrado,
        COUNT(*) AS total_vendas,
        SUM(v.quantidade) AS itens_vendidos,
        CAST(SUM(v.receita) AS DECIMAL(10, 2)) AS receita,
        CAST(ROUND(AVG(v.receita), 2) AS DECIMAL(10, 2)) AS ticket_medio
    FROM silver.vendas v
    LEFT JOIN silver.produtos p ON v.id_produto = p.id_produto
    GROUP BY ALL
)
SELECT
    CAST(id_produto AS STRING) AS id_produto,
    CAST(nome_produto AS STRING) AS nome_produto,
    CAST(categoria AS STRING) AS categoria,
    CAST(marca AS STRING) AS marca,
    CAST(faixa_preco AS STRING) AS faixa_preco,
    CAST(produto_cadastrado AS BOOLEAN) AS produto_cadastrado,
    CAST(total_vendas AS BIGINT) AS total_vendas,
    CAST(itens_vendidos AS BIGINT) AS itens_vendidos,
    CAST(receita AS DECIMAL(10, 2)) AS receita,
    CAST(ticket_medio AS DECIMAL(10, 2)) AS ticket_medio,
    CAST(ROW_NUMBER() OVER (ORDER BY receita DESC) AS INT) AS ranking_receita,
    CAST(ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY receita DESC) AS INT) AS ranking_na_categoria
FROM base