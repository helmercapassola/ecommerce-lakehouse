# =============================================================
# SILVER.PRECO_COMPETIDORES
# Limpa e enriquece a tabela de preços de concorrentes da bronze.
#
# REGRAS DE QUALIDADE:
# - Remove duplicatas por id_produto + nome_concorrente
# - preco_concorrente convertido para DECIMAL(10,2)
# - data_coleta convertida de texto (string) para timestamp
# - preco_suspeito = true quando o preço do concorrente é menor que
#   60% do nosso preco_atual (join com silver.produtos)
# - Expectations fail: id_produto preenchido e preco_concorrente > 0
# - Expectation warn: preco_plausivel (NOT preco_suspeito)
#   — preços suspeitos não descartamos, apenas marcamos
# =============================================================

from pyspark import pipelines as dp
from pyspark.sql import functions as F
from pyspark.sql.types import DecimalType


@dp.materialized_view()
@dp.expect_all_or_fail({
    "id_produto_preenchido": "id_produto IS NOT NULL",
    "preco_concorrente_positivo": "preco_concorrente > 0",
})
@dp.expect("preco_plausivel", "NOT preco_suspeito")
def preco_competidores():
    df = spark.read.table("bronze.preco_competidores")

    # Remove duplicatas por id_produto + nome_concorrente
    df = df.dropDuplicates(["id_produto", "nome_concorrente"])

    # preco_concorrente em DECIMAL(10,2)
    df = df.withColumn(
        "preco_concorrente", F.col("preco_concorrente").cast(DecimalType(10, 2))
    )

    # data_coleta de texto (string) para timestamp
    df = df.withColumn("data_coleta", F.col("data_coleta").cast("timestamp"))

    # Join com silver.produtos para obter preco_atual
    produtos = spark.read.table("silver.produtos")
    df = df.join(
        produtos.select("id_produto", "preco_atual"), "id_produto", "left"
    )

    # preco_suspeito: preço do concorrente < 60% do nosso preco_atual
    df = df.withColumn(
        "preco_suspeito",
        F.when(F.col("preco_concorrente") < (F.col("preco_atual") * 0.60), True)
         .otherwise(False),
    )

    # Seleciona as colunas finais (sem preco_atual do produto)
    df = df.select(
        "id_produto",
        "nome_concorrente",
        "preco_concorrente",
        "data_coleta",
        "preco_suspeito",
    )

    return df