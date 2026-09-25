-- =============================================================
-- GOLD.VENDAS_DETALHADAS
-- Vendas detalhadas (uma linha por venda) para a Diretoria
-- Comercial.
--
-- OBJETIVO: Permitir cruzar diretorias em análises ("receita
-- por região e categoria", "canal preferido dos VIPs") e servir
-- de base para os filtros cruzados do dashboard. Cada venda vem
-- com todas as dimensões: temporal (data, hora, dia_semana),
-- produto (nome, categoria, marca, faixa_preco), cliente (estado,
-- região, segmento) e métricas (quantidade, preço, receita).
--
-- PERÍODO: 13/12/2025 a 11/01/2026.
--
-- INCLUI TODAS AS VENDAS, inclusive de produto não cadastrado:
-- quando o id_produto não existe em silver.produtos, nome e
-- categoria recebem "Produto não cadastrado" e marca e faixa_preco
-- recebem "Não cadastrado". Dinheiro que entrou é receita e não
-- pode ser descartado.
--
-- CLUSTER BY (data): otimiza consultas com filtro de data,
-- comum no dashboard e em análises temporais.
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.vendas_detalhadas (
    id_venda STRING COMMENT 'Identificador único da venda (chave primária, vem de silver.vendas)',
    data_venda TIMESTAMP COMMENT 'Timestamp da venda com data e hora completas',
    data DATE COMMENT 'Data da venda (formato ISO: YYYY-MM-DD). Usada para filtro temporal e CLUSTER BY',
    dia_semana STRING COMMENT 'Nome do dia da semana em português (Domingo, Segunda, etc.)',
    dia_semana_num INT COMMENT 'Número do dia da semana: 1=Domingo, 2=Segunda, ..., 7=Sábado',
    hora INT COMMENT 'Hora da venda (0 a 23)',
    canal_venda STRING COMMENT 'Canal de venda: ecommerce ou loja_fisica',
    id_produto STRING COMMENT 'Identificador do produto. Pode não existir em silver.produtos (produto não cadastrado)',
    nome_produto STRING COMMENT 'Nome do produto. Quando não cadastrado: "Produto não cadastrado"',
    categoria STRING COMMENT 'Categoria do produto. Quando não cadastrado: "Produto não cadastrado"',
    marca STRING COMMENT 'Marca do produto. Quando não cadastrado: "Não cadastrado"',
    faixa_preco STRING COMMENT 'Faixa de preço do produto. Quando não cadastrado: "Não cadastrado"',
    id_cliente STRING COMMENT 'Identificador único do cliente (vem de silver.vendas)',
    nome_cliente STRING COMMENT 'Nome do cliente sem pronome de tratamento (limpo no silver)',
    estado STRING COMMENT 'Sigla da UF em maiúsculas (ex: MG, SP, RJ)',
    regiao STRING COMMENT 'Região do Brasil: Norte, Nordeste, Sudeste, Sul ou Centro-Oeste',
    segmento_cliente STRING COMMENT 'Segmento do cliente: VIP, TOP_TIER ou REGULAR. Vem de gold.clientes_segmentacao. LEFT JOIN: clientes sem segmento ficam NULL',
    quantidade INT COMMENT 'Quantidade de itens vendidos nesta transação',
    preco_unitario DECIMAL(10, 2) COMMENT 'Preço unitário em R$ do produto na venda',
    receita DECIMAL(10, 2) COMMENT 'Receita total em R$ = quantidade x preco_unitario. Inclui TODAS as vendas, inclusive de produto não cadastrado',
    produto_cadastrado BOOLEAN COMMENT 'TRUE se o produto existe em silver.produtos, FALSE caso contrário',
    venda_antes_do_cadastro BOOLEAN COMMENT 'TRUE se a venda ocorreu antes do produto ser cadastrado em silver.produtos'
)
COMMENT 'Vendas detalhadas (uma linha por venda) com todas as dimensões para cruzar diretorias e filtros do dashboard. Inclui produtos não cadastrados e segmento do cliente. Período: 13/12/2025 a 11/01/2026.'
CLUSTER BY (data)
AS
SELECT
    CAST(v.id_venda AS STRING) AS id_venda,
    CAST(v.data_venda AS TIMESTAMP) AS data_venda,
    CAST(v.data AS DATE) AS data,
    CAST(v.dia_semana AS STRING) AS dia_semana,
    CAST(v.dia_semana_num AS INT) AS dia_semana_num,
    CAST(v.hora AS INT) AS hora,
    CAST(v.canal_venda AS STRING) AS canal_venda,
    CAST(v.id_produto AS STRING) AS id_produto,
    CAST(COALESCE(p.nome_produto, 'Produto não cadastrado') AS STRING) AS nome_produto,
    CAST(COALESCE(p.categoria, 'Produto não cadastrado') AS STRING) AS categoria,
    CAST(COALESCE(p.marca, 'Não cadastrado') AS STRING) AS marca,
    CAST(COALESCE(p.faixa_preco, 'Não cadastrado') AS STRING) AS faixa_preco,
    CAST(v.id_cliente AS STRING) AS id_cliente,
    CAST(c.nome_cliente AS STRING) AS nome_cliente,
    CAST(c.estado AS STRING) AS estado,
    CAST(c.regiao AS STRING) AS regiao,
    CAST(cs.segmento_cliente AS STRING) AS segmento_cliente,
    CAST(v.quantidade AS INT) AS quantidade,
    CAST(v.preco_unitario AS DECIMAL(10, 2)) AS preco_unitario,
    CAST(v.receita AS DECIMAL(10, 2)) AS receita,
    CAST(v.produto_cadastrado AS BOOLEAN) AS produto_cadastrado,
    CAST(v.venda_antes_do_cadastro AS BOOLEAN) AS venda_antes_do_cadastro
FROM silver.vendas v
LEFT JOIN silver.produtos p ON v.id_produto = p.id_produto
LEFT JOIN silver.clientes c ON v.id_cliente = c.id_cliente
LEFT JOIN gold.clientes_segmentacao cs ON v.id_cliente = cs.id_cliente