# **Fluxo ETL (Extração, Transformação e Carga)**

O processo segue o modelo **ETL**: os dados são extraídos, **transformados e validados antes** de serem carregados no Data Warehouse (*schema-on-write*).

## **Visão geral do fluxo**

```
Gerador (Python) ──► CSV bruto ──► Tratamento (R) ──► CSV tratado ──► Leitura (Polars) ──► Carga em lotes ──► Data Warehouse (SQLite) ──► OLAP / ML / Spark
```

## **1. Extração (E)**

| Item | Descrição |
| :--- | :--- |
| **Fonte** | Script `gerador_hardware.py`, executado na VM geradora |
| **Saída** | Arquivo `gerador_hardware.csv`, gravado de forma incremental (até 5.000.000 de eventos) |
| **Transferência** | O CSV bruto é disponibilizado à VM consumidora, provisionada com OpenTofu e Ansible |

## **2. Transformação (T)**

A transformação ocorre em duas camadas:

**2.1 Limpeza e padronização em R** (`tratar_telemetria.R`, na VM consumidora)
- Padronização de textos e categorias (modelos de CPU/GPU, sistema operacional).
- Tratamento de valores nulos injetados pelo gerador.
- Remoção de outliers (valores fora de faixa plausível, como percentuais de uso acima de 100%).
- Remoção de registros duplicados.
- Resultado: `dados_hardware_tratados.csv`, com **4.975.224 registros** e 19 variáveis.

**2.2 Modelagem dimensional no notebook** (Python, Google Colab)
- Leitura do CSV tratado com **Polars** (`pl.read_csv`), adequado a arquivos grandes.
- Separação dos atributos em **dimensões** (valores únicos) e **fato** (métricas e chaves).
- Criação de **chaves substitutas** (*surrogate keys*): `sk_maquina`, `sk_cpu`, `sk_gpu`, `sk_sistema` e `sk_tempo`.
- Construção da chave temporal `sk_tempo` no formato `AAAAMMDDHH` (granularidade horária), com derivação de ano, mês, dia, hora e dia da semana.
- Associação de cada registro às suas chaves por *merge* com as dimensões.

## **3. Carga (L)**

| Item | Descrição |
| :--- | :--- |
| **Destino** | Data Warehouse em SQLite (`dw_hardware_analitico.db`) |
| **Ordem da carga** | 1) dimensões (`dim_maquina`, `dim_cpu`, `dim_gpu`, `dim_sistema`, `dim_tempo`); 2) tabela fato (`fato_telemetria`) |
| **Estratégia** | Carga da fato em **lotes de 500.000 linhas** (10 lotes), com inserção em blocos de 100.000 (`chunksize`), evitando estouro de memória |
| **Resultado** | Esquema estrela com 1 fato e 5 dimensões, pronto para consultas OLAP |

## **4. Modelo dimensional resultante**

| Tabela | Tipo | Conteúdo |
| :--- | :--- | :--- |
| `fato_telemetria` | Fato | `event_id`, chaves das 5 dimensões e métricas: `cpu_usage_pct`, `ram_total_gb`, `ram_usage_pct`, `gpu_vram_usage_pct`, `storage_free_gb`, `system_overall_score` |
| `dim_maquina` | Dimensão | `system_id` |
| `dim_cpu` | Dimensão | modelo, núcleos físicos, threads e clock base |
| `dim_gpu` | Dimensão | modelo e VRAM total |
| `dim_sistema` | Dimensão | SO, versão, tipo de armazenamento e resolução |
| `dim_tempo` | Dimensão | data/hora, ano, mês, dia, hora e dia da semana |

## **5. Consumo dos dados carregados**

Após a carga, o Data Warehouse alimenta as **consultas OLAP** (roll-up, slice & dice e cubo 3D), a visualização dinâmica com `ipywidgets` e, futuramente, o **dashboard em HTML/JS**.

## **Observação**

A carga acrescenta linhas (`append`). Para reexecutar o processo do zero, apague o arquivo `dw_hardware_analitico.db` antes, para evitar duplicidade na tabela fato.
