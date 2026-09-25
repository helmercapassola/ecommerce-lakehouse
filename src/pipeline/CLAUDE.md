# Convenções do Projeto E-commerce

## Catálogo e Schemas
- Catálogo: ecommerce
- Schemas: bronze, silver, gold
- Bronze: dados crus, sobrescrita por outra ingestão (notebook ExtratLoad)
- Silver: dados limpos e enriquecidos (Python)
- Gold: agregações para análise (SQL)

## Nomenclatura
- Nomes de tabelas e colunas em português, snake_case, sem acento
- Nomes no código sempre schema.tabela, sem catálogo (ex: bronze.vendas)
- Um arquivo por tabela: transformations/silver/<tabela>.py e transformations/gold/<tabela>.sql

## Tecnologia
- Silver em Python (from pyspark import pipelines as dp)
- Gold em SQL
- Todas as tabelas são materialized views com leitura batch (spark.read.table)
- Pipeline serverless, catálogo ecommerce, schema padrão silver
- Golds publicadas como gold.<tabela>

## Qualidade de Dados
- Dinheiro sempre DECIMAL(10,2)
- Problema de qualidade conhecido é MARCADO em uma coluna e medido com expect (warn)
- Nunca descarte linhas: apagar vendas mudaria a receita
- expect_all_or_fail só para o que nunca pode acontecer
- Cada arquivo começa com comentários explicando o PORQUÊ das regras, em português

## Tabelas Gold e Números de Referência

### Diretoria de Customer Success
- **gold.clientes_segmentacao**: 50 clientes (10 VIP, 25 TOP_TIER, 15 REGULAR). Receita total R$ 974.077,28. Topo: Ana Sophia Pereira (MG, R$ 30.716,63). Limites: VIP >= R$ 22.000, TOP_TIER R$ 17.000-21.999,99, REGULAR < R$ 17.000

### Diretoria Comercial
- **gold.vendas_temporais**: 908 linhas. Agregacao por data x hora x canal_venda. Colunas: dados, dia_semana, dia_semana_num, hora, canal_venda, total_vendas, itens_vendidos, receita, clientes_unicos
- **gold.vendas_produtos**: 205 linhas. Analise por produto com ranking_receita, ranking_na_categoria, faixa_preco, produto_cadastrado. Inclui produtos nao cadastrados
- **gold.vendas_detalhadas**: 3.020 linhas. Uma linha por venda com JOIN de produtos, clientes e clientes_segmentacao. CLUSTER BY (data)

### Diretoria de Pricing
- **gold.precos_competitividade**: 215 produtos. Compara nosso preco com concorrentes (Mercado Livre, Amazon, Magalu, Shopee). 35 MAIS_CARO_QUE_TODOS, 15 com preco suspeito. Classificacoes: ACIMA_DA_MEDIA=92, ABAIXO_DA_MEDIA=76, NA_MEDIA=6, MAIS_BARATO_QUE_TODOS=6. Preco suspeito nao exclui produto - relampago existe

### Dashboard
- **Vendas E-commerce - Visao Executiva**: 3 paginas de canvas (Visao Geral, Analise Detalhada, Segmentacao de Clientes) + pagina de Global Filters com 6 filtros (canal, regiao, categoria, data, marca, segmento)

### Testes de Qualidade (testes/testes_qualidade.py)
- 1a-1d: Chaves unicas silver; 2: receita = qty x preco; 3: vendas nao cadastrado < 1%
- G1-G5: Clientes segmentacao (receita total, id unico, segmento, VIP >= 22k, comentarios)
- G6-G11: Diretoria Comercial (receita total temporal/produtos/detalhadas, linhas vendas, id_venda unico, segmento+regiao preenchidos)
- G12: Diretoria de Pricing (id_produto unico em precos_competitividade)

## Validação
- Sempre rode databricks bundle validate --strict antes do deploy