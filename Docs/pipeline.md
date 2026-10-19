# Projeto de Extensão BIG DATA — Grupo 11

**Autores:** Luiza Pincitori, Gustavo Henrique Fileni  
---

## 1. Ideia Inicial — Pesquisa e Análise de Hardware

Nossa ideia inicial tem como intuito facilitar a pesquisa de hardware de usuários em quantidades massivas para análise, seja para o *game development* ou *sizing* de infraestrutura corporativa.

A ideia consiste em usar todos os conceitos desse módulo (**Big Data**, **Probabilidade e Estatística**, **DevOps** e **Análise Exploratória de Dados**) para gerar e armazenar esses dados de maneira consistente e uniforme, além de apresentar um dashboard personalizado via HTML e JS.

---

## 2. Situação — Problema

Tanto no ecossistema de desenvolvimento de jogos quanto no planejamento de infraestrutura corporativa (TI), a tomada de decisão sobre dimensionamento (*sizing*) e otimização de software costuma ser baseada em dados fragmentados, desatualizados ou em meras estimativas.

* **No Game Development:** Desenvolvedores enfrentam altas taxas de reembolso, avaliações negativas e travamentos por não saberem a real capacidade computacional (RAM, VRAM, CPU) da sua base de jogadores.
* **Na Infraestrutura Corporativa:** Equipes de TI realizam compras desnecessárias de equipamentos ou sofrem com degradação de performance por não possuírem visibilidade contínua sobre o perfil e os gargalos do parque de máquinas dos colaboradores.

> **Conclusão:** A ausência de uma plataforma centralizada e automatizada de coleta e análise massiva de hardware impede que empresas e desenvolvedores tomem decisões técnicas e financeiras orientadas a dados.

---

## 3. Variáveis de Telemetria

Exemplo de dados necessários para armazenar as características de todo o estado operacional da máquina:

| Nome da Variável | Tipo de Dado | Categoria | Descrição / Exemplo | Frequência de Geração |
| :--- | :--- | :--- | :--- | :--- |
| `event_id` | UUID / String | Identificação | Identificador único da medição *(ex: `c8a2f1b0-4a8b...`)* | Por evento gerado |
| `system_id` | UUID / String | Identificação | Identificador único e anônimo da máquina | Por evento gerado |
| `timestamp` | Datetime (ISO 8601) | Temporal | Data e hora da medição em UTC *(ex: `2026-08-18T14:20:00Z`)* | Por evento gerado |
| `os_name` | Categorical / String | Sistema | Sistema Operacional *(ex: `"Windows"`, `"Linux"`, `"macOS"`)* | Baixa (inicialização/mudança) |
| `os_version` | String | Sistema | Versão detalhada do SO *(ex: `"10.0.19045"`, `"Ubuntu 22.04"`)* | Baixa |
| `cpu_model` | String | Hardware (CPU) | Modelo comercial da CPU *(ex: `"Intel Core i5-12400F"`)* | Estática (apenas no cadastro) |
| `cpu_cores_physical` | Integer | Hardware (CPU) | Quantidade de núcleos físicos *(ex: `6`)* | Estática |
| `cpu_threads` | Integer | Hardware (CPU) | Quantidade de núcleos lógicos / threads *(ex: `12`)* | Estática |
| `cpu_clock_base_ghz` | Float | Hardware (CPU) | Frequência base da CPU em GHz *(ex: `2.50`)* | Estática |
| `cpu_usage_pct` | Float | Telemetria/Uso | Percentual de uso instantâneo da CPU *(ex: `45.8`)* | Alta (coleta periódica) |
| `ram_total_gb` | Float / Integer | Hardware (RAM) | Capacidade total de RAM física em GB *(ex: `16.0`)* | Estática |
| `ram_usage_pct` | Float | Telemetria/Uso | Percentual de ocupação da RAM *(ex: `68.2`)* | Alta (periódica) |
| `gpu_model` | String | Hardware (GPU) | Modelo do processador gráfico *(ex: `"NVIDIA GeForce RTX 3060"`)* | Estática |
| `gpu_vram_total_gb` | Float | Hardware (GPU) | Memória VRAM dedicada da GPU em GB *(ex: `12.0`)* | Estática |
| `gpu_vram_usage_pct` | Float | Telemetria/Uso | Percentual de uso da VRAM *(ex: `82.4`)* | Alta (periódica) |
| `storage_primary_type` | Enum / String | Hardware (Disco) | Tecnologia do disco primário *(ex: `"NVMe"`, `"SATA_SSD"`, `"HDD"`)* | Estática |
| `storage_free_gb` | Float | Hardware (Disco) | Espaço livre na partição principal em GB *(ex: `142.5`)* | Média (periódica) |
| `display_resolution` | String | Periférico | Resolução da tela principal *(ex: `"1920x1080"`)* | Baixa |
| `system_overall_score` | Float | Score Sintético | Nota Geral Calculada do Computador | Por evento | Nota Final de 0.0 a 10.0 |


### Frequência de Geração

* **Estáticos / Baixa Frequência:** Gerados apenas no registro da máquina ou quando ocorre alteração de periférico/SO (ex: `cpu_model`, `ram_total_gb`, `os_name`).
* **Dinâmicos / Alta Frequência:** Métricas de consumo instantâneo capturadas periodicamente durante sessões de uso ou benchmarks (ex: `cpu_usage_pct`, `ram_usage_pct`, `gpu_vram_usage_pct`).
* **Média Frequência:** Atributos que mudam ocasionalmente no tempo, como espaço livre em disco (`storage_free_gb`).

---

## 4. Inconsistências Mapeadas

* **Falta de padronização:** O mesmo componente é reportado de formas diferentes (ex: `"NVIDIA RTX 3060"`, `"RTX 3060"`, `"Nvidia GeForce RTX 3060"`), o que quebra agrupamentos e contagens.
* **Valores nulos:** Máquinas com vídeo integrado não possuem VRAM dedicada e enviam campos vazios (`null`), o que trava cálculos matemáticos.
* **Erro de leitura:** Falhas do sistema operacional geram leituras surreais, como uso de RAM em 150%, uso de CPU em -1% ou memória total zerada.
* **Eventos duplicados e fora de ordem:** Lags ou conexões de rede fazem o cliente enviar a mesma medição duas vezes ou fora de ordem cronológica.

---

## 5. Pipeline de Dados

### 1. Geração dos Dados — VM "Gerador" [x] 
* **Origem:** Script Python (`gerador_hardware.py`) executado em uma VM Linux (Ubuntu 26.04 LTS), usando geração procedural condicional (`NumPy`/`Pandas`).
* **Escala:** Pool fixo de 25.000 identificadores de máquina (`system_id`), distribuídos em 5.000.000 de eventos, com gravação incremental em *chunks*.
* **Saída:** Arquivo `.csv` gravado localmente na VM.
* **Versionamento e deploy:** O código do gerador é versionado no GitHub; um workflow de CI/CD sincroniza (via SSH/rsync) a pasta do gerador para a VM e prepara o ambiente Python.
* **Status:** Concluido.
  
  * [x] OpenTofu: Provisionamento bem-sucedido da máquina virtual por código no ambiente KVM/libvirt com disco de 15GB.
  * [x] Cloud-init: Configuração inicial automatizada da máquina virtual e chaves de acesso SSH.
  * [x] Ansible: Playbook executado com sucesso (failed=0), configurando dependências, diretórios e ambiente virtual Python na VM.
  * [x] SSH / SCP: Conexão segura estabelecida e implantação da aplicação realizada com sucesso na máquina virtual.   
---

### 2. Consumo e Tratamento — VM "Consumidor R" [x]
- **Mecanismo:** Script em R (`tratar_telemetria.R`), executado de forma autônoma na segunda VM Linux (Ubuntu), consome o lote bruto `.csv` gerado pela etapa 1.

- **Ações:** Carga de alta performance via `data.table` (`fread`), limpeza de inconsistências, eliminação de duplicatas e sanitização dos tipos de dados.

- **Isolamento de Amostras:** Garantia de separação estrita do conjunto de dados, mantendo o arquivo `exemplo_dados.csv` exclusivamente na raiz do GitHub para análises prévias e documentação, sem interferência no fluxo de processamento de dados reais.

- **Saída:** Base higienizada e consolidada exportada como `dados_hardware_tratados.csv`, que serve como artefato de entrada oficial para a etapa de Big Data e AED.

- **Status:** Concluído.

  * [x] **Infraestrutura e Dependências:** Resolução do ambiente de compilação C/C++ no SO da VM e instalação global do `r-cran-tidyverse` via gerenciador de pacotes `apt`.
  * [x] **Transferência Segura (SCP):** Recebimento do arquivo bruto `gerador_hardware.csv` via SSH/SCP diretamente da máquina de geração para o diretório `/home/ubuntu/` na VM Consumidor R.
  * [x] **Gestão de Memória (Swap):** Otimização da alocação de RAM e ativação de espaço de *swap* no Linux para evitar falhas do *Out-Of-Memory Killer* (OOM) durante o processamento do volume massivo.
  * [x] **Higienização e Deduplicação:** Leitura de 5.000.000 de registros brutos e expurgo de 24.776 eventos duplicados ou corrompidos, resultando na gravação com sucesso de 4.975.224 registros válidos no arquivo final.

---

### 3. Big Data & Análise Exploratória de Dados (AED)— Google Colab [ ]
* **Mecanismo:** Leitura e processamento do arquivo `.csv` higienizado no ambiente **Google Colab**, utilizando Python e suas bibliotecas ecossistêmicas de análise de dados (`Pandas`, `NumPy`, `Matplotlib` e `Seaborn`).
* **Ações de Análise e Modelagem:**
  * **Análise Exploratória de Dados (AED):** Cálculo de estatísticas descritivas (média, mediana, desvio padrão, percentis e quartis e etc.)

---

### 4. Disponibilização & Dashboard *(Fase futura)* [ ]
* **Front-end:** Dashboard em HTML e JavaScript (`Chart.js` / `Plotly`), a ser implementado em uma etapa posterior do projeto.

---

## Infraestrutura e Provisionamento
* **Ansible:** Responsável pelo provisionamento e pela configuração automatizada das VMs (gerador, consumo em R, monitoramento).
* **CI/CD (GitHub Actions):** Versiona o código no GitHub e realiza o deploy automatizado do gerador na respectiva VM.

---

## Monitoramento
VM dedicada de monitoramento, com **Docker** e **Kubernetes** para orquestração dos containers de observabilidade do ambiente.
