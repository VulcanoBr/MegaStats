# MegaStats

**Plataforma de análise estatística dos resultados da Mega-Sena**

O **MegaStats** é uma aplicação web desenvolvida para importar, armazenar, validar, organizar e analisar estatisticamente o histórico de resultados da Mega-Sena, utilizando dados oficiais disponibilizados pela Caixa Econômica Federal.

O projeto tem como objetivo transformar o histórico de sorteios em informações estatísticas estruturadas, permitindo explorar frequências, distribuições, tendências históricas e diferentes características matemáticas das combinações sorteadas.

A aplicação está sendo desenvolvida com Ruby on Rails 8.1, PostgreSQL, Tailwind CSS e Hotwire, priorizando organização arquitetural, integridade dos dados, manutenibilidade e evolução incremental.

> **Importante:** o MegaStats é uma ferramenta de análise estatística e exploração histórica. Seus resultados não permitem prever sorteios futuros nem aumentam matematicamente a probabilidade de uma combinação ser sorteada.

---

## Índice

- [1. Visão geral](#1-visão-geral)
- [2. Objetivos do projeto](#2-objetivos-do-projeto)
- [3. Tecnologias utilizadas](#3-tecnologias-utilizadas)
- [4. Fonte de dados](#4-fonte-de-dados)
- [5. Funcionalidades](#5-funcionalidades)
- [6. Processo de importação de dados](#6-processo-de-importação-de-dados)
- [7. Arquitetura da aplicação](#7-arquitetura-da-aplicação)
- [8. Estrutura do projeto](#8-estrutura-do-projeto)
- [9. Requisitos para instalação](#9-requisitos-para-instalação)
- [10. Instalação e configuração](#10-instalação-e-configuração)
- [11. Comandos disponíveis](#11-comandos-disponíveis)
- [12. Integridade e qualidade dos dados](#12-integridade-e-qualidade-dos-dados)
- [13. Testes](#13-testes)
- [14. Ambiente de desenvolvimento](#14-ambiente-de-desenvolvimento)
- [15. Roadmap](#15-roadmap)
- [16. Contribuição](#16-contribuição)
- [17. Licença](#17-licença)

---

## 1. Visão geral

A Mega-Sena é uma modalidade de loteria administrada pela Caixa Econômica Federal, na qual são sorteadas seis dezenas entre 01 e 60.

O MegaStats utiliza o histórico desses sorteios como base para análises estatísticas e matemáticas.

A aplicação foi concebida para oferecer uma estrutura confiável de armazenamento e processamento dos resultados, permitindo que diferentes análises sejam realizadas sobre o conjunto histórico completo ou sobre períodos específicos.

O sistema está sendo desenvolvido de maneira incremental, começando pela infraestrutura de dados e avançando para os módulos de análise e visualização estatística.

### Situação atual do projeto

- Importação do histórico oficial em formato XLSX.
- Armazenamento dos resultados no PostgreSQL.
- Importação incremental, sem duplicação de concursos.
- Identificação de divergências em registros históricos.
- Registro dos processos de importação.
- Validação automática da integridade do histórico após importações.
- Interface web para envio de planilhas e consulta ao histórico de importações.

---

## 2. Objetivos do projeto

Os principais objetivos do MegaStats são:

1. Centralizar o histórico dos resultados da Mega-Sena em uma base de dados estruturada.
2. Garantir a integridade e a consistência dos dados importados.
3. Automatizar a atualização do histórico a partir dos arquivos oficiais.
4. Disponibilizar ferramentas para análises estatísticas e matemáticas.
5. Facilitar a identificação de padrões e distribuições observadas nos resultados históricos.
6. Oferecer gráficos, indicadores e relatórios para exploração dos dados.
7. Manter uma arquitetura organizada, extensível e de fácil manutenção.

---

## 3. Tecnologias utilizadas

| Tecnologia        | Finalidade                                 |
| ----------------- | ------------------------------------------ |
| Ruby              | Linguagem de programação                   |
| Ruby on Rails 8.1 | Framework principal                        |
| PostgreSQL        | Banco de dados relacional                  |
| Tailwind CSS      | Interface e estilização                    |
| Hotwire           | Interatividade e atualização da interface  |
| Turbo             | Navegação e atualização parcial de páginas |
| Stimulus          | Comportamentos JavaScript da interface     |
| Roo               | Leitura de planilhas XLSX                  |
| Minitest          | Testes automatizados                       |
| Git               | Controle de versão                         |
| GitHub            | Hospedagem do código e documentação        |

### Ambiente de desenvolvimento

O ambiente principal de desenvolvimento utiliza:

- Windows.
- WSL2.
- Ubuntu.
- Ruby.
- Rails.
- PostgreSQL.

---

## 4. Fonte de dados

A fonte prioritária de dados do MegaStats é o histórico oficial de resultados da Mega-Sena disponibilizado pela **Caixa Econômica Federal**.

Os dados são obtidos por meio de planilha no formato XLSX.

O arquivo contém informações como:

- Número do concurso.
- Data do sorteio.
- As seis dezenas sorteadas.
- Quantidade de ganhadores da Sena.
- Quantidade de ganhadores da Quina.
- Quantidade de ganhadores da Quadra.
- Valores dos prêmios.
- Valores acumulados.
- Arrecadação total.
- Estimativa do prêmio.
- Outras informações disponibilizadas na planilha oficial.

### Princípios de utilização dos dados

- Priorizar sempre a fonte oficial.
- Preservar os dados históricos já importados.
- Identificar alterações em concursos existentes.
- Evitar duplicidade de registros.
- Registrar a origem e o histórico das importações.
- Validar os dados antes de disponibilizá-los para análise.

---

## 5. Funcionalidades

As funcionalidades estão organizadas em módulos para permitir evolução independente.

### 5.1. Importação do histórico

**Implementado**

- Upload de planilhas XLSX pela interface web.
- Leitura da planilha com a biblioteca Roo.
- Verificação do formato do arquivo.
- Validação dos campos obrigatórios.
- Verificação das seis dezenas de cada concurso.
- Identificação de concursos já existentes.
- Inserção somente de concursos novos.
- Identificação de divergências em concursos históricos.
- Identificação de arquivos já importados por meio de SHA-256.
- Registro dos resultados de cada importação.

### 5.2. Histórico de importações

**Implementado**

Cada execução de importação gera um registro de auditoria (`ImportBatch`), contendo informações como:

- Nome do arquivo.
- Hash SHA-256.
- Status do processamento.
- Quantidade de linhas processadas.
- Quantidade de registros inseridos.
- Quantidade de registros ignorados.
- Quantidade de registros atualizados.
- Quantidade de erros.
- Detalhes das divergências.
- Data e horário de início e término.
- Resultado da validação histórica.

Os status de processamento são:

| Status       | Descrição                           |
| ------------ | ----------------------------------- |
| `pending`    | Importação aguardando processamento |
| `processing` | Importação em execução              |
| `succeeded`  | Importação concluída                |
| `failed`     | Importação rejeitada ou com falha   |

### 5.3. Validação do histórico

**Implementado**

O serviço `HistoricalValidator` realiza verificações sobre a base histórica, incluindo:

- Validação das seis dezenas.
- Verificação de números entre 01 e 60.
- Identificação de dezenas repetidas no mesmo concurso.
- Verificação de datas.
- Verificação da ordem cronológica.
- Identificação de valores monetários negativos.
- Identificação de concursos duplicados.
- Identificação de lacunas na sequência dos concursos.

O resultado da validação é classificado como:

| Resultado | Descrição                       |
| --------- | ------------------------------- |
| `passed`  | Nenhum erro ou aviso encontrado |
| `warning` | Foram encontrados avisos        |
| `failed`  | Foram encontrados erros         |

O relatório é armazenado no lote de importação para consulta posterior.

### 5.4. Análises estatísticas

**Planejado**

O módulo estatístico será responsável por processar o histórico e disponibilizar indicadores e análises.

Entre as funcionalidades previstas estão:

**Frequência das dezenas**

- Frequência absoluta de cada dezena.
- Frequência relativa e percentual.
- Ranking das dezenas mais sorteadas.
- Ranking das dezenas menos sorteadas.
- Comparação entre períodos.

**Distribuição das combinações**

- Distribuição de números pares e ímpares.
- Distribuição por faixas numéricas.
- Soma das seis dezenas.
- Distribuição das somas dos concursos.
- Quantidade de dezenas consecutivas.
- Distribuição das dezenas por grupos.

**Análise temporal**

- Frequência nos últimos 50 concursos.
- Frequência nos últimos 100 concursos.
- Frequência nos últimos 500 concursos.
- Frequência considerando todo o histórico.
- Intervalo entre aparições de cada dezena.
- Tempo decorrido desde a última ocorrência.

**Análise combinatória**

- Pares de dezenas mais frequentes.
- Ternos mais frequentes.
- Repetição de dezenas entre concursos consecutivos.
- Distribuição de combinações por características matemáticas.

### 5.5. Dashboard estatístico

**Planejado**

O dashboard deverá apresentar uma visão consolidada do histórico e dos principais indicadores.

Entre os elementos previstos:

- Total de concursos cadastrados.
- Data do primeiro e do último sorteio.
- Frequência das dezenas.
- Gráficos de distribuição.
- Indicadores de pares e ímpares.
- Distribuição das somas.
- Comparativos por período.
- Evolução histórica das frequências.

### 5.6. Relatórios e exploração dos dados

**Planejado**

- Relatórios estatísticos.
- Filtros por período.
- Consulta de resultados por concurso.
- Comparação de períodos.
- Visualização de indicadores históricos.
- Exportação de resultados e relatórios.

---

## 6. Processo de importação de dados

A importação foi projetada para preservar a integridade dos registros existentes.

O processo é incremental: concursos já cadastrados e idênticos são ignorados, enquanto somente concursos novos e válidos são inseridos.

### Fluxo de processamento

1. Recebimento do arquivo XLSX.
2. Verificação da extensão, tamanho e estrutura do arquivo.
3. Cálculo da assinatura SHA-256.
4. Verificação de importação anterior do mesmo arquivo.
5. Criação do registro de controle da importação.
6. Leitura e interpretação das linhas da planilha.
7. Validação dos dados.
8. Verificação da sequência histórica.
9. Comparação dos concursos existentes com os dados da planilha.
10. Rejeição integral em caso de divergência histórica.
11. Inserção dos concursos novos em uma transação.
12. Registro dos resultados do processamento.
13. Execução automática do `HistoricalValidator`.
14. Armazenamento do relatório de auditoria.

### Regra fundamental

O MegaStats não deve atualizar silenciosamente um concurso histórico.

Quando um concurso existente apresenta informações divergentes em relação à planilha, a importação deve ser rejeitada antes da gravação dos novos registros.

Dessa maneira, evita-se que uma alteração inesperada na fonte de dados modifique o histórico já armazenado.

### Exemplo de importação incremental

Na primeira importação controlada da planilha atualizada em 02/11/2026, foi obtido o seguinte resultado:

| Indicador                      | Resultado |
| ------------------------------ | --------: |
| Concursos lidos                |     3.080 |
| Concursos existentes ignorados |     3.077 |
| Novos concursos inseridos      |         3 |
| Concursos atualizados          |         0 |
| Erros                          |         0 |
| Resultado da auditoria         |  `passed` |

Após o processamento, a base passou a conter 3.080 concursos, numerados de 1 a 3.080.

Esse resultado demonstra o funcionamento da importação incremental e da preservação dos registros históricos.

---

## 7. Arquitetura da aplicação

O MegaStats utiliza a arquitetura MVC do Ruby on Rails, complementada por serviços de domínio para separar regras de negócio dos controllers.

### Organização conceitual

**Models**

Responsáveis pela representação dos dados, associações, validações e regras de persistência.

**Controllers**

Responsáveis por receber as requisições HTTP, coordenar os serviços e apresentar os resultados na interface.

**Services**

Responsáveis pela execução de processos de negócio, cálculos e operações especializadas.

**Views**

Responsáveis pela apresentação dos dados e interação com o usuário.

### Principais componentes

| Componente                      | Responsabilidade                    |
| ------------------------------- | ----------------------------------- |
| `Draw`                          | Representa um concurso da Mega-Sena |
| `ImportBatch`                   | Registra uma execução de importação |
| `MegaSena::XlsxImporter`        | Importa e valida planilhas XLSX     |
| `MegaSena::HistoricalValidator` | Audita a integridade do histórico   |
| `ImportBatchesController`       | Gerencia o fluxo de importações     |

### Princípios arquiteturais

- Separação de responsabilidades.
- Regras de negócio isoladas em serviços.
- Validação em múltiplas camadas.
- Integridade garantida pelo banco de dados.
- Transações para operações de gravação.
- Testes automatizados.
- Código organizado para facilitar a evolução dos módulos estatísticos.

---

## 8. Estrutura do projeto

A estrutura lógica da aplicação segue a organização convencional do Rails.

```text
megastats/
├── app/
│   ├── controllers/
│   │   └── import_batches_controller.rb
│   ├── models/
│   │   ├── draw.rb
│   │   └── import_batch.rb
│   ├── services/
│   │   └── mega_sena/
│   │       ├── xlsx_importer.rb
│   │       └── historical_validator.rb
│   └── views/
│       └── import_batches/
│           ├── index.html.erb
│           ├── new.html.erb
│           └── show.html.erb
├── config/
│   ├── database.yml
│   └── routes.rb
├── db/
│   ├── migrate/
│   └── schema.rb
├── lib/
│   └── tasks/
│       └── mega_sena.rake
├── storage/
│   ├── imports/
│   └── backups/
├── test/
│   └── services/
│       └── mega_sena/
├── Gemfile
├── Gemfile.lock
└── README.md
```

A estrutura poderá ser ampliada conforme os módulos estatísticos forem implementados.

---

## 9. Requisitos para instalação

Para executar o projeto, são necessários:

- Ruby compatível com Rails 8.1.
- Ruby on Rails 8.1.
- PostgreSQL.
- Node.js, caso exigido pela configuração dos assets.
- Bundler.
- Git.

O ambiente de desenvolvimento utilizado no projeto é Windows com WSL2 e Ubuntu.

---

## 10. Instalação e configuração

### 10.1. Clonar o repositório

```bash
git clone https://github.com/VulcanoBr/MegaStats.git
cd megastats
```

### 10.2. Instalar as dependências

```bash
bundle install
```

### 10.3. Configurar o banco de dados

Verifique as configurações do PostgreSQL em:

```text
config/database.yml
```

Crie e prepare o banco:

```bash
bin/rails db:create
bin/rails db:migrate
```

### 10.4. Iniciar a aplicação

```bash
bin/rails server
```

Acesse:

```text
http://localhost:3000
```

### 10.5. Importar a planilha oficial

Coloque o arquivo oficial no diretório:

```text
storage/imports/Mega-Sena.xlsx
```

A importação pode ser realizada pela interface web, acessando:

```text
/import_batches/new
```

Ou pelo terminal:

```bash
bin/rails mega_sena:import_xlsx
```

Também é possível informar outro caminho:

```bash
MEGA_SENA_XLSX=/caminho/arquivo.xlsx bin/rails mega_sena:import_xlsx
```

---

## 11. Comandos disponíveis

### Importação

```bash
bin/rails mega_sena:import_xlsx
```

Importa o histórico utilizando o arquivo padrão ou o caminho informado pela variável `MEGA_SENA_XLSX`.

### Validação histórica

```bash
bin/rails mega_sena:validate
```

Executa a validação independente da base histórica.

### Testes

```bash
bin/rails test
```

Executa a suíte de testes automatizados.

### Rotas

```bash
bin/rails routes
```

Exibe as rotas disponíveis na aplicação.

---

## 12. Integridade e qualidade dos dados

A integridade dos dados é um dos principais requisitos do MegaStats.

As validações são realizadas tanto na aplicação quanto no PostgreSQL.

### Regras de integridade

- Número do concurso obrigatório e positivo.
- Número do concurso único.
- Data do sorteio obrigatória.
- Seis dezenas obrigatórias.
- Dezenas entre 01 e 60.
- Não pode haver dezenas repetidas no mesmo concurso.
- Quantidades de ganhadores não podem ser negativas.
- Valores monetários não podem ser negativos na importação.
- Concursos históricos divergentes não podem ser sobrescritos silenciosamente.

### Estratégia de persistência

As gravações da importação são realizadas em transação.

Se ocorrer uma falha durante a gravação, a transação é revertida, evitando uma importação parcialmente concluída.

O registro de controle do lote permite manter informações sobre o resultado da tentativa, inclusive quando ela falha.

---

## 13. Testes

O projeto utiliza Minitest, framework de testes integrado ao Ruby on Rails.

Os testes da importação contemplam cenários como:

- Importação de concursos novos.
- Ignorar concursos existentes e idênticos.
- Reconhecimento de arquivos já importados.
- Rejeição de arquivos XLSX inválidos.
- Identificação de divergências históricas.
- Identificação de lacunas na numeração dos concursos.
- Reversão da transação em caso de falha durante a gravação.

Executar todos os testes:

```bash
bin/rails test
```

Executar os testes específicos do importador:

```bash
bin/rails test test/services/mega_sena/xlsx_importer_test.rb
```

---

## 14. Ambiente de desenvolvimento

O projeto é desenvolvido localmente utilizando:

- Windows como sistema operacional principal.
- WSL2 como ambiente Linux.
- Ubuntu como distribuição Linux.
- PostgreSQL como banco de dados.
- Ruby on Rails como plataforma de desenvolvimento.

Essa configuração permite desenvolver e executar a aplicação em um ambiente Linux integrado ao Windows.

---

## 15. Roadmap

O desenvolvimento do MegaStats está organizado em etapas.

### Fase 1 — Estrutura inicial e persistência

- [x] Criação do projeto Rails.
- [x] Configuração do PostgreSQL.
- [x] Configuração do Tailwind CSS.
- [x] Estrutura inicial dos modelos.
- [x] Estrutura de importação do histórico.

### Fase 2 — Importação e integridade dos dados

- [x] Importação da planilha oficial XLSX.
- [x] Registro dos lotes de importação.
- [x] Importação incremental.
- [x] Identificação de arquivos duplicados.
- [x] Identificação de divergências históricas.
- [x] Reversão de transações em caso de falha.
- [x] Interface de upload.
- [x] Histórico de importações.
- [x] Relatório de auditoria.
- [x] Execução automática do `HistoricalValidator`.
- [x] Primeira atualização controlada do histórico.

### Fase 3 — Análises estatísticas básicas

- [ ] Frequência absoluta e relativa das dezenas.
- [ ] Ranking das dezenas.
- [ ] Distribuição de pares e ímpares.
- [ ] Distribuição por faixas numéricas.
- [ ] Análise da soma das dezenas.
- [ ] Intervalos entre aparições.
- [ ] Análises por períodos.

### Fase 4 — Análises estatísticas avançadas

- [ ] Frequência de pares e ternos.
- [ ] Repetição entre concursos consecutivos.
- [ ] Distribuição de combinações.
- [ ] Análise de sequências.
- [ ] Comparações entre janelas temporais.
- [ ] Outras métricas matemáticas.

### Fase 5 — Dashboard e visualizações

- [ ] Dashboard estatístico.
- [ ] Gráficos de frequência.
- [ ] Indicadores históricos.
- [ ] Filtros por período.
- [ ] Comparativos estatísticos.
- [ ] Relatórios.

### Fase 6 — Evolução e otimização

- [ ] Otimização de consultas.
- [ ] Estratégias de cache para cálculos recorrentes.
- [ ] Exportação de relatórios.
- [ ] Melhorias de usabilidade.
- [ ] Ampliação da cobertura de testes.

---

## 16. Contribuição

Contribuições são bem-vindas.

Para contribuir:

1. Faça um fork do repositório.
2. Crie uma branch para sua alteração.
3. Implemente a funcionalidade ou correção.
4. Execute os testes automatizados.
5. Envie um Pull Request com a descrição das alterações.

Sugestões de melhorias, correções e novas análises estatísticas também são bem-vindas.

---

## 17. Licença

A licença do projeto deverá ser definida antes da distribuição pública do código.

Os dados históricos utilizados devem respeitar as condições de disponibilização e utilização estabelecidas pela fonte oficial.

---

## Considerações finais

O MegaStats é um projeto de estudo e desenvolvimento de uma plataforma de análise estatística baseada em dados históricos da Mega-Sena.

Seu desenvolvimento prioriza a confiabilidade da base de dados, a transparência dos processos de importação e a separação entre armazenamento, validação e análise estatística.

O objetivo é construir uma ferramenta consistente para exploração matemática e estatística dos resultados históricos, com arquitetura preparada para incorporar novas funcionalidades ao longo do tempo.

**MegaStats — Dados históricos, análise estatística e informação.**
