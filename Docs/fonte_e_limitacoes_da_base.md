# **Fonte, Descrição e Limitações da Base de Dados**

## **1. Origem dos dados**

A base é **sintética**, gerada pela própria solução com o script `simulador/gerador_hardware.py` (Python, NumPy e Pandas). O gerador produz uma massa de telemetria de hardware (CPU, GPU, RAM, disco, sistema operacional e resolução de tela) por **geração procedural condicional**: o modelo de CPU, por exemplo, condiciona núcleos, threads e clock, e a GPU condiciona a VRAM.

Cada máquina é identificada por um `system_id` anônimo, escolhido de um **pool fixo de 25.000 máquinas**. Os eventos de telemetria (medições de uso) são gerados até o limite de **5.000.000 de eventos** e gravados de forma incremental em arquivo `.csv`.

O gerador injeta **ruídos propositais** (valores nulos e outliers) para que existam problemas reais a tratar na etapa de ETL.

## **2. Resumo da base**

| Característica | Descrição |
| :--- | :--- |
| **Fonte** | Gerador próprio (`gerador_hardware.py`) – dados simulados, sem uso de dados pessoais |
| **Formato** | CSV (texto delimitado) |
| **Período coberto** | Setembro e outubro de 2026 (timestamps em UTC, ISO 8601) |
| **Registros gerados** | Aproximadamente 5.000.000 de eventos |
| **Registros após o tratamento** | **4.975.224** (após limpeza em R) |
| **Variáveis** | 19 (identificação, temporal, hardware estático, telemetria de uso e score sintético) |
| **Tratamento** | Script em R (`tratar_telemetria.R`): padronização, tratamento de nulos, remoção de outliers e duplicidades |
| **Arquivo analisado** | `dados_hardware_tratados.csv` |
| **Disponibilização** | O repositório contém apenas uma **amostra** (`dados/exemplo_dados.csv`). A base completa excede o limite de tamanho do GitHub e está disponível em: **[PREENCHER: link de download]** |
| **Restrições de uso** | Uso acadêmico. Por ser sintética, não há dados pessoais nem restrições de privacidade (LGPD) |

O dicionário de dados completo (nome, tipo, categoria, descrição, frequência de geração e critério de pontuação de cada variável) está na seção **"Variáveis"** deste notebook.

## **3. Relação com os 5 Vs do Big Data**

| V | Aplicação no projeto |
| :--- | :--- |
| **Volume** | Cerca de 5 milhões de registros de telemetria, acima do que cabe confortavelmente em planilhas e que exigiu leitura com Polars e carga em lotes de 500 mil linhas no Data Warehouse |
| **Velocidade** | Métricas de uso (`cpu_usage_pct`, `ram_usage_pct`, `gpu_vram_usage_pct`) coletadas periodicamente, simulando um fluxo contínuo de telemetria |
| **Variedade** | Dados categóricos, numéricos e temporais, com possibilidade de evolução para JSON recebido por endpoint (semiestruturado) |
| **Veracidade** | Ruídos propositais (nulos e outliers) tratados em R, com remoção de duplicidades e inconsistências (≈ 25 mil registros descartados) |
| **Valor** | Apoio ao dimensionamento (*sizing*) de hardware em jogos e em infraestrutura corporativa |

## **4. Limitações da base**

- **Dados sintéticos:** os padrões refletem as regras do gerador, e não o comportamento de usuários reais. As conclusões precisam ser validadas com dados reais.
- **Período curto:** apenas dois meses, com médias praticamente estáveis, o que impede análises de sazonalidade e tendência.
- **Score sintético:** `system_overall_score` é calculado por regras de pontuação definidas pela equipe, e não por uma medida independente de desempenho.
- **Distribuições simplificadas:** as variáveis de uso apresentam dispersão ampla e pouca estrutura temporal, o que limita a capacidade de modelos preditivos.
- **Perda por tratamento:** a remoção de outliers e duplicidades descarta cerca de 0,5% dos registros e pode ter eliminado casos legítimos extremos.
- **Disponibilização parcial no repositório:** o GitHub guarda só a amostra, então a execução completa do notebook depende do download da base.
