# =============================================================
# SILVER.VENDAS
# Limpa e enriquece a tabela de vendas da camada bronze.
#
# REGRAS DE QUALIDADE:
# - Remove duplicatas por id_venda
# - preco_unitario em DECIMAL(10,2)
# - receita = quantidade × preco_unitario em DECIMAL(10,2)
# - data (date extraído de data_venda), hora (0-23), dia_semana_num
#   (1=domingo...7=sábado), dia_semana em português
# - produto_cadastrado = false quando id_produto não existe em silver.produtos
# - venda_antes_do_cadastro = true quando data_venda < data_criacao do produto
# - Expectations fail: id_venda, data_venda, id_cliente, id_produto,
#   quantidade, preco_unitario preenchidos; quantidade > 0; preco_unitario > 0;
#   canal_venda em ('ecommerce', 'loja_fisica')
# - preco_suspeito = true quando preco_unitario > média + 3σ
#   (outlier estatístico, possível erro de digitação)
# - Expectations warn: produto_cadastrado; venda_depois_do_cadastro;
#   preco_dentro_intervalo — vendas com problema conhecido não são
#   descartadas (mudariam a receita), apenas marcadas
# =============================================================

from pyspark import pipelines as dp
from pyspark.sql import functions as F
from pyspark.sql.types import DecimalType


@dp.materialized_view()
@dp.expect_all_or_fail({
    "id_venda_preenchido": "id_venda IS NOT NULL",
    "data_venda_preenchida": "data_venda IS NOT NULL",
    "id_cliente_preenchido": "id_cliente IS NOT NULL",
    "id_produto_preenchido": "id_produto IS NOT NULL",
    "quantidade_preenchida": "quantidade IS NOT NULL",
    "preco_unitario_preenchido": "preco_unitario IS NOT NULL",
    "quantidade_positiva": "quantidade > 0",
    "preco_unitario_positivo": "preco_unitario > 0",
    "canal_venda_valido": "canal_venda IN ('ecommerce', 'loja_fisica')",
})
@dp.expect("produto_cadastrado", "produto_cadastrado = true")
@dp.expect("venda_depois_do_cadastro", "venda_depois_do_cadastro = true")
@dp.expect("preco_dentro_intervalo", "preco_suspeito = false")
def vendas():
    df = spark.read.table("bronze.vendas")

    # Remove duplicatas por id_venda
    df = df.dropDuplicates(["id_venda"])

    # preco_unitario em DECIMAL(10,2)
    df = df.withColumn(
        "preco_unitario", F.col("preco_unitario").cast(DecimalType(10, 2))
    )

    # Outliers em preco_unitario: preços acima de média + 3σ
    # Preços suspeitos não são descartados, apenas marcados
    stats = df.select(
        F.avg("preco_unitario").alias("media"),
        F.stddev("preco_unitario").alias("desvio"),
    ).collect()[0]
    limite_outlier = float(stats["media"]) + 3 * float(stats["desvio"])
    df = df.withColumn("preco_suspeito", F.col("preco_unitario") > limite_outlier)

    # receita = quantidade × preco_unitario em DECIMAL(10,2)
    df = df.withColumn(
        "receita",
        (F.col("quantidade") * F.col("preco_unitario")).cast(DecimalType(10, 2)),
    )

    # data (date), hora (0-23), dia_semana_num (1=domingo...7=sábado)
    df = df.withColumn("data", F.col("data_venda").cast("date"))
    df = df.withColumn("hora", F.hour(F.col("data_venda")))
    df = df.withColumn("dia_semana_num", F.dayofweek(F.col("data_venda")))

    # dia_semana em português (1=Domingo, 2=Segunda, ..., 7=Sábado)
    df = df.withColumn(
        "dia_semana",
        F.when(F.col("dia_semana_num") == 1, "Domingo")
         .when(F.col("dia_semana_num") == 2, "Segunda")
         .when(F.col("dia_semana_num") == 3, "Terça")
         .when(F.col("dia_semana_num") == 4, "Quarta")
         .when(F.col("dia_semana_num") == 5, "Quinta")
         .when(F.col("dia_semana_num") == 6, "Sexta")
         .when(F.col("dia_semana_num") == 7, "Sábado")
         .otherwise(None),
    )

    # Join com silver.produtos para produto_cadastrado e venda_antes_do_cadastro
    produtos = spark.read.table("silver.produtos")
    df = df.join(
        produtos.select("id_produto", "data_criacao"),
        "id_produto",
        "left",
    )

    # produto_cadastrado: false quando id_produto não existe em silver.produtos
    df = df.withColumn("produto_cadastrado", F.col("data_criacao").isNotNull())

    # venda_antes_do_cadastro: true quando data_venda < data_criacao do produto
    df = df.withColumn(
        "venda_antes_do_cadastro",
        F.when(
            F.col("data_criacao").isNotNull()
            & (F.col("data_venda") < F.col("data_criacao")),
            True,
        ).otherwise(False),
    )

    # venda_depois_do_cadastro = NOT venda_antes_do_cadastro
    df = df.withColumn("venda_depois_do_cadastro", ~F.col("venda_antes_do_cadastro"))

    # Seleciona as colunas finais (sem data_criacao do produto)
    df = df.select(
        "id_venda",
        "data_venda",
        "data",
        "hora",
        "dia_semana_num",
        "dia_semana",
        "id_cliente",
        "id_produto",
        "canal_venda",
        "quantidade",
        "preco_unitario",
        "preco_suspeito",
        "receita",
        "produto_cadastrado",
        "venda_antes_do_cadastro",
        "venda_depois_do_cadastro",
    )

    return df