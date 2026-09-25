# Databricks notebook source
# =============================================================
# TESTES DE QUALIDADE DA CAMADA SILVER
# Cada teste conta linhas com problema. Se algum teste achar
# problemas, o notebook falha com AssertionError e mostra uma
# tabela com o resultado de cada teste.
# =============================================================

# COMMAND ----------

# Widget com o catálogo (padrão: ecommerce)
dbutils.widgets.text("catalogo", "ecommerce", "Catálogo")
catalogo = dbutils.widgets.get("catalogo")

# Lista para armazenar resultados dos testes
resultados = []

def run_test(nome, query):
    """Executa um teste e armazena o resultado."""
    count = spark.sql(query).collect()[0][0]
    status = "PASS" if count == 0 else "FAIL"
    resultados.append((nome, count, status))

# COMMAND ----------

# =============================================================
# TESTE 1: Chaves únicas das 4 silver tables
# =============================================================

# 1a. silver.produtos - id_produto único
run_test(
    "1a. Duplicatas em silver.produtos (id_produto)",
    f"""
    SELECT COUNT(*) FROM (
        SELECT id_produto, COUNT(*) AS c
        FROM {catalogo}.silver.produtos
        GROUP BY id_produto
        HAVING COUNT(*) > 1
    )
    """,
)

# 1b. silver.clientes - id_cliente único
run_test(
    "1b. Duplicatas em silver.clientes (id_cliente)",
    f"""
    SELECT COUNT(*) FROM (
        SELECT id_cliente, COUNT(*) AS c
        FROM {catalogo}.silver.clientes
        GROUP BY id_cliente
        HAVING COUNT(*) > 1
    )
    """,
)

# 1c. silver.preco_competidores - (id_produto, nome_concorrente) único
run_test(
    "1c. Duplicatas em silver.preco_competidores (id_produto + nome_concorrente)",
    f"""
    SELECT COUNT(*) FROM (
        SELECT id_produto, nome_concorrente, COUNT(*) AS c
        FROM {catalogo}.silver.preco_competidores
        GROUP BY id_produto, nome_concorrente
        HAVING COUNT(*) > 1
    )
    """,
)

# 1d. silver.vendas - id_venda único
run_test(
    "1d. Duplicatas em silver.vendas (id_venda)",
    f"""
    SELECT COUNT(*) FROM (
        SELECT id_venda, COUNT(*) AS c
        FROM {catalogo}.silver.vendas
        GROUP BY id_venda
        HAVING COUNT(*) > 1
    )
    """,
)

# COMMAND ----------

# =============================================================
# TESTE 2: receita = quantidade × preco_unitario
# =============================================================

run_test(
    "2. receita != quantidade * preco_unitario",
    f"""
    SELECT COUNT(*) FROM {catalogo}.silver.vendas
    WHERE receita != (quantidade * preco_unitario)
    """,
)

# COMMAND ----------

# =============================================================
# TESTE 3: Vendas de produto não cadastrado < 1% do total
# =============================================================

run_test(
    "3. Vendas de produto nao cadastrado >= 1% do total",
    f"""
    WITH total AS (
        SELECT COUNT(*) AS n FROM {catalogo}.silver.vendas
    ),
    nao_cadastrado AS (
        SELECT COUNT(*) AS n FROM {catalogo}.silver.vendas
        WHERE NOT produto_cadastrado
    )
    SELECT CASE
        WHEN (SELECT n FROM total) = 0 THEN 0
        WHEN (SELECT n FROM nao_cadastrado) * 100.0 / (SELECT n FROM total) >= 1.0 THEN 1
        ELSE 0
    END
    """,
)

# COMMAND ----------

# =============================================================
# TESTES DA CAMADA GOLD
# =============================================================

# G1. Receita total da gold.clientes_segmentacao = silver.vendas
run_test(
    "G1. Receita total gold.clientes_segmentacao != silver.vendas",
    f"""
    SELECT CASE
        WHEN ABS(
            (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.gold.clientes_segmentacao)
            - (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.silver.vendas)
        ) > 0.01 THEN 1
        ELSE 0
    END
    """,
)

# G2. id_cliente único em gold.clientes_segmentacao
run_test(
    "G2. Duplicatas em gold.clientes_segmentacao (id_cliente)",
    f"""
    SELECT COUNT(*) FROM (
        SELECT id_cliente, COUNT(*) AS c
        FROM {catalogo}.gold.clientes_segmentacao
        GROUP BY id_cliente
        HAVING COUNT(*) > 1
    )
    """,
)

# G3. segmento_cliente só pode ser VIP, TOP_TIER ou REGULAR
run_test(
    "G3. segmento_cliente com valor invalido (nao VIP/TOP_TIER/REGULAR)",
    f"""
    SELECT COUNT(*) FROM {catalogo}.gold.clientes_segmentacao
    WHERE segmento_cliente NOT IN ('VIP', 'TOP_TIER', 'REGULAR')
    """,
)

# G4. Nenhum VIP com receita abaixo de 22000
run_test(
    "G4. VIP com receita abaixo de R$ 22.000",
    f"""
    SELECT COUNT(*) FROM {catalogo}.gold.clientes_segmentacao
    WHERE segmento_cliente = 'VIP' AND receita < 22000
    """,
)

# G5. Toda coluna do esquema gold com comentário
# (ignora tabelas internas do pipeline: __materialization, __DECOMP, __enzyme)
run_test(
    "G5. Colunas gold sem comentario",
    f"""
    SELECT COUNT(*) FROM (
        SELECT column_name
        FROM {catalogo}.information_schema.columns
        WHERE table_schema = 'gold'
          AND table_name NOT LIKE '%materialization%'
          AND comment IS NULL
    )
    """,
)

# COMMAND ----------

# =============================================================
# TESTES DA CAMADA GOLD - DIRETORIA COMERCIAL
# =============================================================

# G6. Receita total de vendas_temporais = silver.vendas
run_test(
    "G6. Receita total gold.vendas_temporais != silver.vendas",
    f"""
    SELECT CASE
        WHEN ABS(
            (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.gold.vendas_temporais)
            - (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.silver.vendas)
        ) > 0.01 THEN 1
        ELSE 0
    END
    """,
)

# G7. Receita total de vendas_produtos = silver.vendas
run_test(
    "G7. Receita total gold.vendas_produtos != silver.vendas",
    f"""
    SELECT CASE
        WHEN ABS(
            (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.gold.vendas_produtos)
            - (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.silver.vendas)
        ) > 0.01 THEN 1
        ELSE 0
    END
    """,
)

# G8. Receita total de vendas_detalhadas = silver.vendas
run_test(
    "G8. Receita total gold.vendas_detalhadas != silver.vendas",
    f"""
    SELECT CASE
        WHEN ABS(
            (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.gold.vendas_detalhadas)
            - (SELECT COALESCE(SUM(receita), 0) FROM {catalogo}.silver.vendas)
        ) > 0.01 THEN 1
        ELSE 0
    END
    """,
)

# G9. vendas_detalhadas com mesmo nUmero de linhas que silver.vendas
run_test(
    "G9. vendas_detalhadas com numero de linhas diferente de silver.vendas",
    f"""
    SELECT ABS(
        (SELECT COUNT(*) FROM {catalogo}.gold.vendas_detalhadas)
        - (SELECT COUNT(*) FROM {catalogo}.silver.vendas)
    )
    """,
)

# G10. id_venda unico em vendas_detalhadas
run_test(
    "G10. Duplicatas em gold.vendas_detalhadas (id_venda)",
    f"""
    SELECT COUNT(*) FROM (
        SELECT id_venda, COUNT(*) AS c
        FROM {catalogo}.gold.vendas_detalhadas
        GROUP BY id_venda
        HAVING COUNT(*) > 1
    )
    """,
)

# G11. Toda venda de vendas_detalhadas com segmento e regiao preenchidos
run_test(
    "G11. vendas_detalhadas com segmento_cliente ou regiao NULL",
    f"""
    SELECT COUNT(*) FROM {catalogo}.gold.vendas_detalhadas
    WHERE segmento_cliente IS NULL OR regiao IS NULL
    """,
)

# COMMAND ----------

# =============================================================
# TESTES DA CAMADA GOLD - DIRETORIA DE PRICING
# =============================================================

# G12. id_produto único em gold.precos_competitividade
run_test(
    "G12. Duplicatas em gold.precos_competitividade (id_produto)",
    f"""
    SELECT COUNT(*) FROM (
        SELECT id_produto, COUNT(*) AS c
        FROM {catalogo}.gold.precos_competitividade
        GROUP BY id_produto
        HAVING COUNT(*) > 1
    )
    """,
)

# COMMAND ----------

# =============================================================
# MOSTRAR RESULTADOS
# =============================================================

print("\n" + "=" * 60)
print("RESULTADOS DOS TESTES DE QUALIDADE")
print("=" * 60)

for nome, count, status in resultados:
    emoji = "OK" if status == "PASS" else "FAIL"
    print(f"{emoji} {nome}: {count} linhas com problema ({status})")

print("=" * 60)

# Criar DataFrame com os resultados para exibição
df_resultados = spark.createDataFrame(
    resultados, ["teste", "linhas_com_problema", "status"]
)
display(df_resultados)

# Verificar se algum teste falhou
falhas = [r for r in resultados if r[2] == "FAIL"]
if falhas:
    print(f"\n{len(falhas)} teste(s) falharam!")
    for nome, count, _ in falhas:
        print(f"   - {nome}: {count} linhas com problema")
    raise AssertionError(f"{len(falhas)} teste(s) de qualidade falharam!")
else:
    print("\nTodos os testes passaram!")