## Script que roda diretamente na vm consumidor
- Gera um csv tratado pronto para EDA:

```R
library(tidyverse)
library(data.table)

cat("Iniciando o processamento e limpeza dos dados de telemetria...\n")

# 1. Carregar os dados brutos gerados pela VM Gerador
arquivo_entrada <- "gerador_hardware.csv"
dados <- fread(arquivo_entrada)

cat(sprintf("Total de registros brutos carregados: %d\n", nrow(dados)))

# 2. Limpeza e Tratamento de Inconsistências
dados_tratados <- dados %>%
  # Remover valores nulos críticos em colunas de identificação e uso
  drop_na(event_id, system_id, timestamp, cpu_usage_pct) %>%
  
  # Filtrar outliers e leituras impossíveis (ex: percentuais fora de 0 a 100%)
  filter(
    cpu_usage_pct >= 0 & cpu_usage_pct <= 100,
    ram_usage_pct >= 0 & ram_usage_pct <= 100,
    gpu_vram_usage_pct >= 0 & gpu_vram_usage_pct <= 100
  ) %>%
  
  # Tratar valores nulos de VRAM em máquinas com vídeo integrado (atribuindo 0)
  mutate(
    gpu_vram_total_gb = replace_na(gpu_vram_total_gb, 0),
    gpu_vram_usage_pct = replace_na(gpu_vram_usage_pct, 0),
    
    # Padronização de strings (removendo espaços extras e inconsistências de nomenclatura)
    os_name = str_trim(os_name),
    cpu_model = str_trim(cpu_model),
    gpu_model = str_trim(gpu_model)
  ) %>%
  
  # Remover registros duplicados baseados no event_id
  distinct(event_id, .keep_all = TRUE)

cat(sprintf("Total de registros após limpeza e remoção de duplicatas: %d\n", nrow(dados_tratados)))

# 3. Exportar o arquivo tratado para a próxima etapa (Google Colab / AED)
arquivo_saida <- "dados_hardware_tratados.csv"
fwrite(dados_tratados, arquivo_saida)

cat(sprintf("Sucesso! Arquivo tratado salvo em: %s\n", arquivo_saida))
