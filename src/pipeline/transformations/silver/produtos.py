# =============================================================
# SILVER.PRODUTOS
# Limpa e enriquece a tabela de produtos da camada bronze.
#
# REGRAS DE QUALIDADE:
# - Remove duplicatas por id_produto (a bronze pode conter duplicatas
#   de re-ingestão; mantemos a primeira ocorrência)
# - TRIM no nome_produto para remover espaços em branco
# - preco_atual convertido para DECIMAL(10,2) para precisão monetária
# - faixa_preco classifica o produto em PREMIUM (>1000), MEDIO (>500)
#   ou BASICO (demais), facilitando análises de portfólio
# - Expectations fail: id_produto preenchido e preco_atual > 0
#   (sem id_produto não há como identificar o produto; preço não
#   pode ser zero ou negativo)
# =============================================================

from pyspark import pipelines as dp
from pyspark.sql import functions as F
from pyspark.sql.types import DecimalType


@dp.materialized_view()
@dp.expect_all_or_fail({
    "id_produto_preenchido": "id_produto IS NOT NULL",
    "preco_atual_positivo": "preco_atual > 0",
})
def produtos():
    df = spark.read.table("bronze.produtos")

    # Remove duplicatas por id_produto, mantendo a primeira ocorrência
    df = df.dropDuplicates(["id_produto"])

    # TRIM no nome_produto
    df = df.withColumn("nome_produto", F.trim(F.col("nome_produto")))

    # preco_atual em DECIMAL(10,2)
    df = df.withColumn("preco_atual", F.col("preco_atual").cast(DecimalType(10, 2)))

    # faixa_preco: PREMIUM (>1000), MEDIO (>500), BASICO (demais)
    df = df.withColumn(
        "faixa_preco",
        F.when(F.col("preco_atual") > 1000, "PREMIUM")
         .when(F.col("preco_atual") > 500, "MEDIO")
         .otherwise("BASICO"),
    )

    return df