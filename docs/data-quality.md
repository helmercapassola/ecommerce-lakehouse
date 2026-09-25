# Data Quality

## Analise de Qualidade — Bronze.Vendas

A analise de qualidade foi executada sobre a tabela `ecommerce.bronze.vendas` com **3.020 registros** no periodo de 13/12/2025 a 11/01/2026.

### Dados Limpos (sem erros)

| Verificacao | Resultado |
| --- | --- |
| Valores nulos (todas as colunas) | 0 |
| Duplicatas em id_venda | 0 |
| quantidade <= 0 | 0 |
| preco_unitario <= 0 | 0 |
| Strings vazias | 0 |
| Espacos leading/trailing nos IDs | 0 |
| Datas no futuro | 0 |
| Datas anteriores a 2020 | 0 |
| Canais de venda invalidos | 0 (apenas ecommerce e loja_fisica) |

### Problemas Identificados (tratados na Silver)

| # | Problema | Qtd | Tratamento Silver |
| --- | --- | --- | --- |
| 1 | Outliers em preco_unitario (acima de 3 desvios padrao) | 163 | Flag `preco_suspeito = true`, linha mantida |
| 2 | Multiplos precos por produto (87% dos produtos) | 179 produtos | Mantido historico; preco de referencia em silver.produtos |
| 3 | Variacao de preco por canal | Diversos | Mantido; analisavel via silver.vendas |

### Estatisticas de preco_unitario

| Metrica | Valor |
| --- | --- |
| Media | R$ 230,09 |
| Desvio padrao | R$ 299,47 |
| Minimo | R$ 26,99 |
| Maximo | R$ 1.571,89 |
| Limite outlier (media + 3-sigma) | ~R$ 1.127,36 |

### Distribuicao por Canal

| Canal | Registros |
| --- | --- |
| ecommerce | 2.155 |
| loja_fisica | 865 |

## Expectations do Pipeline (Silver)

### Fail (bloqueia o pipeline se violado)

| Tabela | Regra |
| --- | --- |
| silver.vendas | id_venda, data_venda, id_cliente, id_produto, quantidade, preco_unitario preenchidos |
| silver.vendas | quantidade > 0 |
| silver.vendas | preco_unitario > 0 |
| silver.vendas | canal_venda IN ('ecommerce', 'loja_fisica') |
| silver.produtos | id_produto preenchido |
| silver.produtos | preco_atual > 0 |
| silver.clientes | id_cliente preenchido |
| silver.clientes | regiao preenchida |
| silver.preco_competidores | id_produto preenchido |
| silver.preco_competidores | preco_concorrente > 0 |

### Warn (marca mas nao descarta)

| Tabela | Regra | Motivo |
| --- | --- | --- |
| silver.vendas | produto_cadastrado = true | Venda de produto nao cadastrado existe, nao descartar |
| silver.vendas | venda_depois_do_cadastro = true | Venda antes do cadastro pode ser legittima |
| silver.vendas | preco_dentro_intervalo (NOT preco_suspeito) | Outlier estatistico, possivel erro de digitacao |
| silver.preco_competidores | preco_plausivel (NOT preco_suspeito) | Preco suspeito < 60% do nosso preco |

## Testes Automatizados (16 testes)

Executados pelo Job apos o pipeline, em `testes/testes_qualidade.py`:

### Camada Silver (Testes 1-3)

| Teste | Descricao |
| --- | --- |
| 1a | Duplicatas em silver.produtos (id_produto) |
| 1b | Duplicatas em silver.clientes (id_cliente) |
| 1c | Duplicatas em silver.preco_competidores (id_produto + nome_concorrente) |
| 1d | Duplicatas em silver.vendas (id_venda) |
| 2 | receita != quantidade * preco_unitario |
| 3 | Vendas de produto nao cadastrado >= 1% do total |

### Camada Gold — Customer Success (G1-G5)

| Teste | Descricao |
| --- | --- |
| G1 | Receita total gold.clientes_segmentacao = silver.vendas |
| G2 | id_cliente unico em gold.clientes_segmentacao |
| G3 | segmento_cliente em {VIP, TOP_TIER, REGULAR} |
| G4 | Nenhum VIP com receita < R$ 22.000 |
| G5 | Toda coluna Gold com comentario |

### Camada Gold — Comercial (G6-G11)

| Teste | Descricao |
| --- | --- |
| G6 | Receita total gold.vendas_temporais = silver.vendas |
| G7 | Receita total gold.vendas_produtos = silver.vendas |
| G8 | Receita total gold.vendas_detalhadas = silver.vendas |
| G9 | vendas_detalhadas com mesmo numero de linhas que silver.vendas |
| G10 | id_venda unico em gold.vendas_detalhadas |
| G11 | vendas_detalhadas com segmento e regiao preenchidos |

### Camada Gold — Pricing (G12)

| Teste | Descricao |
| --- | --- |
| G12 | id_produto unico em gold.precos_competitividade |

### Resultado

Se qualquer teste falhar, o notebook levanta `AssertionError` com a lista de falhas, parando o Job.
