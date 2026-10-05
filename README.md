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
│   ├── exemplo_dados.csv       # Amostra do dataset 
│   └── gerador_hardware.csv    # Dataset completo gerado (ignorado pelo gitignore)
├── Docs/
│   ├── .gitkeep                
│   ├── como_o_gerador_f...md    # Documentação de funcionamento do gerador
│   └── pipeline.md              # Documentação da pipeline de dados
├── infraestrutura/
│   ├── ansible/
│   │   ├── inventory.ini        # Inventário de IPs para o Ansible
│   │   └── playbook.yml         # Automação do ambiente e pacotes Python
│   ├── cloud_init.cfg           # Configuração de usuários e chaves SSH
│   ├── main.tf                  # Provisionamento da VM via OpenTofu
│   └── variables.tf             # Variáveis do OpenTofu
├── simulador/
│   ├── gerador_hardware.py      # Script em Python do gerador de hardware
│   └── requirements.txt         # Dependências de execução (NumPy, Pandas)
├── .gitignore                   # Arquivos ignorados pelo controle de versão
└── README.md                    # Documentação principal do projeto
```

---

##  Requisitos Prévios

Para reproduzir a automação da infraestrutura e a execução do simulador de dados:

- **Sistema Operacional:** Linux (Ubuntu 22.04 LTS ou superior) com suporte a KVM/libvirt.
- **Infraestrutura como Código (IaC):**
  - **OpenTofu** (`>= 1.6.0`) – Provisionamento declarativo da máquina virtual.
  - **Ansible** (`>= 2.10`) – Automação e preparação do ambiente de execução.
- **Conectividade & Segurança:** OpenSSH Client com chave SSH pública configurada em `~/.ssh/id_rsa.pub` (mapeada no `cloud_init.cfg`).
- **Linguagem & Bibliotecas:** Python 3.10+ (instalado automaticamente na VM via playbook do Ansible).

---

##  Passo a Passo para Reprodução e Implantação

### 1. Provisionamento da Máquina Virtual (OpenTofu + cloud-init)

1. Acesse o diretório de infraestrutura:
   ```bash
   cd infraestrutura
   ```
2. Inicialize o OpenTofu:
   ```bash
   tofu init
   ```
3. Aplique o plano de execução para criar a VM:
   ```bash
   tofu apply -auto-approve
   ```
4. Anote o **endereço IP** exibido na saída (`vm_ip`).

---

### 2. Configuração do Ambiente (Ansible)

1. Atualize o IP da VM no arquivo `infraestrutura/ansible/inventory.ini`:
   ```ini
   [gerador]
   vm_hardware ansible_host=<IP_DA_VM> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_python_interpreter=/usr/bin/python3
   ```
2. Execute o playbook do Ansible para preparar a VM:
   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
   ```

---

### 3. Implantação da Aplicação via SSH / SCP

1. A partir da raiz do projeto na máquina hospedeira, transfira os arquivos do simulador para a VM:
   ```bash
   scp -r simulador/* ubuntu@<IP_DA_VM>:/home/ubuntu/projeto_telemetria/simulador/
   ```

---

### 4. Execução do Simulador e Geração dos Dados

1. Acesse a máquina virtual via SSH:
   ```bash
   ssh ubuntu@<IP_DA_VM>
   ```
2. Ative o ambiente virtual criado pelo Ansible:
   ```bash
   source /home/ubuntu/projeto_telemetria/venv/bin/activate
   ```
3. Execute o simulador dentro da VM:
   ```bash
   python3 /home/ubuntu/projeto_telemetria/simulador/gerador_hardware.py
   ```
4. Valide a geração e persistência do arquivo de dados:
   ```bash
   head -n 5 /home/ubuntu/projeto_telemetria/dados/gerador_hardware.csv
   wc -l /home/ubuntu/projeto_telemetria/dados/gerador_hardware.csv
   ```
