# Projeto integrado segundo semestre 2026 - Data Science
## **Grupo 11** - Luiza Pincitori, Gustavo Fileni.

## CONTEXTO - Pesquisa e análise de Hardware

Nossa ideia inicial tem como o intuito de facilitar a pesquisa de hardware de usuários em quantidades massivas para análise, seja para o game development ou sizing de infraestrutura corporativa.

A ideia consiste em usar todos os conceitos desse módulo (Big Data, Probabilidade e Estatística, DevOps e Análise exploratória de dados) para gerar e armazenar esses dados de maneira consistente e uniforme, além de apresentar um dashboard personalizado via HTML e JS.

## Situação - Problema
Tanto no ecossistema de desenvolvimento de jogos quanto no planejamento de infraestrutura corporativa (TI), a tomada de decisão sobre dimensionamento (sizing) e otimização de software costuma ser baseada em dados fragmentados, desatualizados ou em meras estimativas.
- **No Game Development:** Desenvolvedores enfrentam altas taxas de reembolso, avaliações negativas e travamentos por não saberem a real capacidade computacional (RAM, VRAM, CPU) da sua base de jogadores.
- **Na Infraestrutura Corporativa:** Equipes de TI realizam compras desnecessárias de equipamentos ou sofrem com degradação de performance por não possuírem visibilidade contínua sobre o perfil e gargalos do parque de máquinas dos colaboradores.

A ausência de uma plataforma centralizada e automatizada de coleta e análise massiva de hardware impede que empresas e desenvolvedores tomem decisões técnicas e financeiras orientadas a dados. 

---

##  Estrutura do Repositório

```text
Pesquisa_e_analise_de_Hardware/
├── dados/
│   ├── exemplo_dados.csv            # Amostra do dataset
│   └── gerador_hardware.csv         # Dataset completo gerado (ignorado pelo gitignore)
├── Docs/
│   ├── .gitkeep                 
│   ├── como_o_gerador_funciona.md   # Documentação de funcionamento do gerador
│   └── pipeline.md                  # Documentação da pipeline de dados
├── infraestrutura/
│   ├── ansible/
│   │   ├── ansible.cfg              # Configurações globais do Ansible
│   │   ├── inventory.ini            # Inventário de IPs para o Ansible
│   │   ├── playbook.yml             # Automação do ambiente da VM Gerador
│   │   └── playbook_consumidor.yml  # Automação do ambiente da VM Consumidor R
│   ├── cloud_init.cfg               # Configuração de usuários e chaves SSH
│   ├── consumidor.tf                # Provisionamento da VM Consumidor via OpenTofu
│   ├── main.tf                      # Provisionamento da VM Gerador via OpenTofu
│   └── variables.tf                 # Variáveis do OpenTofu
├── simulador/
│   ├── gerador_hardware.py          # Script em Python do gerador de hardware
│   └── requirements.txt             # Dependências de execução (NumPy, Pandas)
├── .gitignore                       # Arquivos ignorados pelo controle de versão
└── README.md                        # Documentação principal do projeto
```

## Requisitos Previos

Para reproduzir a automacao da infraestrutura, a geracao dos dados e a etapa de consumo em R:

- **Sistema Operacional:** Linux (Ubuntu 22.04 LTS ou superior) com suporte a KVM/libvirt.
- **Infraestrutura como Codigo (IaC):**
  - **OpenTofu** (`>= 1.6.0`) – Provisionamento declarativo das maquinas virtuais.
  - **Ansible** (`>= 2.10`) – Automacao e preparacao dos ambientes.
- **Conectividade & Seguranca:** OpenSSH Client com chave SSH publica configurada em `~/.ssh/id_rsa.pub` (mapeada no `cloud_init.cfg`).
- **Linguagens & Ambientes:**
  - Python 3.10+ (instalado automaticamente na VM geradora via Ansible).
  - R (`>= 4.0`) com `tidyverse` e `data.table` (instalados na VM consumidor R).

---

## Passo a Passo para Reproducao e Implantacao

### 1. Provisionamento das Maquinas Virtuais (OpenTofu + cloud-init)

1. Acesse o diretorio de infraestrutura:
   ```bash
   cd infraestrutura
   ```
2. Inicialize o OpenTofu:
   ```bash
   tofu init
   ```
3. Aplique o plano de execucao para criar as VMs (gerador e consumidor):
   ```bash
   tofu apply -auto-approve
   ```
4. Anote os **enderecos IP** exibidos na saida (`vm_ip` e `vm_consumidor_ip`).

---

### 2. Configuracao do Ambiente (Ansible)

1. Atualize os IPs das VMs no arquivo `infraestrutura/ansible/inventory.ini`:
   ```ini
   [gerador]
   vm_hardware ansible_host=<IP_DA_VM_GERADOR> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_python_interpreter=/usr/bin/python3

   [consumidor]
   vm_consumidor_r ansible_host=<IP_DA_VM_CONSUMIDOR> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
   ```
2. Execute os playbooks do Ansible para preparar os ambientes em ambas as VMs:
   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
   ansible-playbook -i ansible/inventory.ini ansible/playbook_consumidor.yml
   ```

---

### 3. Implantacao e Execucao do Simulador de Dados

1. A partir da raiz do projeto na maquina hospedeira, transfira os arquivos do simulador para a VM Gerador:
   ```bash
   scp -r simulador/* ubuntu@<IP_DA_VM_GERADOR>:/home/ubuntu/projeto_telemetria/simulador/
   ```
2. Acesse a VM Gerador via SSH, ative o ambiente virtual e execute o script:
   ```bash
   ssh ubuntu@<IP_DA_VM_GERADOR>
   source /home/ubuntu/projeto_telemetria/venv/bin/activate
   python3 /home/ubuntu/projeto_telemetria/simulador/gerador_hardware.py
   ```

---

### 4. Transferencia e Tratamento de Dados (Consumidor R)

1. Transfira o dataset bruto gerado (`gerador_hardware.csv`) da VM Gerador para a sua maquina local e depois para a VM Consumidor R (ou diretamente via SCP entre as maquinas se houver rota):
   ```bash
   scp ubuntu@<IP_DA_VM_GERADOR>:/home/ubuntu/projeto_telemetria/dados/gerador_hardware.csv ./gerador_hardware.csv
   scp gerador_hardware.csv ubuntu@<IP_DA_VM_CONSUMIDOR>:/home/ubuntu/
   ```
2. Acesse a VM Consumidor R via SSH:
   ```bash
   ssh ubuntu@<IP_DA_VM_CONSUMIDOR>
   ```
3. Execute o script em R para realizar a limpeza, remocao de duplicatas e tratamento dos 5 milhoes de registros:
   ```bash
   Rscript tratar_telemetria.R
   ```
4. Valide a criacao do arquivo tratado `dados_hardware_tratados.csv`, pronto para a etapa de Big Data no Google Colab.
