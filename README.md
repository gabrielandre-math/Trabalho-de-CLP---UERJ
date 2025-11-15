
# Projeto de Conceitos de Linguagem de Programação: Sistema de Previsão de Demanda com R e PostgreSQL

Este repositório contém o projeto final para a disciplina de **Conceitos de Linguagem de Programação** da Universidade do Estado do Rio de Janeiro (UERJ). O projeto demonstra a aplicação de diferentes conceitos de linguagens na construção de um sistema funcional de previsão de demanda e gerenciamento de estoque.

  * **Universidade:** Universidade do Estado do Rio de Janeiro (UERJ)
  * **Curso:** Conceitos de Linguagem de Programação

-----
## Integrantes do Grupo

  * Kayan Santos
  * Jefferson Kauan
  * Fernando Rosa
  * Gabriel André
  * Felipe Paiva

-----

## Descrição do Projeto

O objetivo deste trabalho é projetar e implementar um pipeline de análise de dados para previsão de demanda de produtos. O sistema utiliza a linguagem **R** para análise estatística e modelagem de séries temporais, e **PostgreSQL** como banco de dados relacional para armazenar os dados mestres (produtos, estoque) e os dados transacionais (histórico de vendas).

O script R extrai dados do banco, processa o histórico de vendas de cada produto individualmente, aplica um modelo de previsão (ETS - Error, Trend, Seasonality) e, por fim, armazena os resultados (previsões, limites de confiança e sugestões de recompra) de volta no banco de dados, além de gerar um relatório em Excel.

## Contexto Acadêmico (Conceitos de Linguagem de Programação)

Este projeto nos permitiu explorar diversos conceitos de linguagens de programação na prática, utilizando a linguagem R como objeto de estudo principal:

  * **Paradigma de Programação:** R é uma linguagem multi-paradigma. Neste projeto, exploramos:
      * **Programação Funcional:** O uso intensivo de funções como `lapply` e o encadeamento de operações com o *pipe* (`%>%`) do pacote `dplyr` demonstram a aplicação do paradigma funcional para manipulação de dados.
      * **Programação Orientada a Objetos:** Embora não tenhamos definido novas classes, utilizamos o sistema de classes S3 de R. Funções como `forecast` são genéricas e se comportam de maneira diferente dependendo da classe do objeto (neste caso, um modelo `ets`).
  * **Tipagem Dinâmica:** A flexibilidade de R com seus tipos de dados (vetores, listas, data frames) é fundamental para a análise estatística, mas também exige atenção, como visto na função `prever_demanda` que retorna `NA` em casos específicos.
  * **Interoperabilidade de Linguagens:** O projeto integra duas linguagens distintas: **R** (uma linguagem de domínio específico para estatística) e **SQL** (uma linguagem declarativa para consulta de banco de dados). A biblioteca `DBI` serve como uma camada de abstração (interface) que permite à R "falar" com o PostgreSQL.
  * **Gerenciamento de Erros:** O bloco `tryCatch` na função `prever_demanda` é um conceito fundamental de linguagem para garantir a robustez do script. Ele permite que o *loop* continue executando mesmo que a previsão de um produto falhe (por exemplo, por falta de dados históricos).
  * **Gramática de Domínio Específico (DSL):** O pacote `dplyr` implementa uma "gramática de manipulação de dados" (ex: `group_by`, `arrange`), que é uma forma de DSL *embutida* na linguagem R, facilitando a escrita de código legível e eficiente para transformação de dados.

-----

## Arquitetura e Tecnologias

O sistema é composto pelos seguintes componentes principais:

  * **Linguagem Principal:** **R**
  * **Banco de Dados:** **PostgreSQL**
  * **Bibliotecas R Essenciais:**
      * `DBI` / `RPostgres`: Para a conexão e comunicação com o banco de dados.
      * `dplyr`: Para a manipulação e transformação de dados.
      * `forecast`: Para a modelagem da série temporal (função `ets`) e geração das previsões.
      * `lubridate`: Para manipulação de datas.
      * `openxlsx`: Para exportar o resultado final como um relatório Excel.

-----

## Interface
<img width="1277" height="712" alt="image" src="https://github.com/user-attachments/assets/7a686623-a14e-4255-bf6e-cb624410092a" />

## Fluxo do processo
<img width="1164" height="453" alt="image" src="https://github.com/user-attachments/assets/ce3a8fe6-9e06-4a1d-83a2-fd0620ec93ec" />

## Modelagem do banco de dados
<img width="904" height="911" alt="image" src="https://github.com/user-attachments/assets/669bcc15-9a8c-44ef-abf4-8a2258744efd" />

## Componentes do Projeto

1.  **Esquema do Banco de Dados (`schema.sql`)**

      * Define a estrutura do banco de dados no PostgreSQL.
      * **`produtos`**: Tabela de dados mestres dos produtos (SKU, nome, lead time).
      * **`historico_vendas`**: Armazena a série temporal de vendas de cada produto.
      * **`estoque_atual`**: Mantém a quantidade atual em estoque e o ponto de pedido.
      * **`resultados_previsao`**: Tabela onde o script R insere os resultados do modelo.

2.  **Diagrama Entidade-Relacionamento (ER)**

      * A imagem `diagrama_er.jpg` ilustra visualmente as relações entre as tabelas, destacando as chaves primárias (PK) e estrangeiras (FK).
      * `produtos` possui uma relação 1:1 com `estoque_atual`.
      * `produtos` possui uma relação 1:N com `historico_vendas` e `resultados_previsao`.

3.  **Script de Previsão (`forecast.R`)**

      * Este é o "cérebro" da aplicação. O fluxo de execução é o seguinte:
        1.  **Conexão:** Estabelece a conexão com o banco PostgreSQL.
        2.  **Consulta:** Busca os dados das tabelas `produtos`, `estoque_atual` e `historico_vendas`.
        3.  **Função `prever_demanda`:** Uma função de abstração que recebe os dados de venda de um produto, cria um objeto de série temporal (`ts`) e treina um modelo `ets`. Ela retorna a média da previsão, o limite inferior e o superior.
        4.  **Processamento em Lote:** Utiliza `group_by` e `group_split` (do `dplyr`) para separar o data frame de vendas por produto.
        5.  **Cálculo:** Aplica a função `prever_demanda` a cada produto usando `lapply`.
        6.  **Gravação no BD:** Limpa a tabela de previsões anteriores (`DELETE FROM`) e insere os novos resultados em lote usando `dbWriteTable`.
        7.  **Exportação:** Salva os mesmos resultados no arquivo `previsao_estoque.xlsx`.
        8.  **Encerramento:** Fecha a conexão com o banco.

-----

## Como Executar

1.  **Configurar o Banco de Dados:**

      * Tenha uma instância do PostgreSQL rodando.
      * Execute o script `schema.sql` para criar as tabelas e seus relacionamentos.
      * Popule as tabelas `produtos` e `historico_vendas` com dados de exemplo.

2.  **Configurar o Ambiente R:**

      * Instale o R e o RStudio.
      * Instale as bibliotecas necessárias:
        ```r
        install.packages(c("DBI", "RPostgres", "dplyr", "lubridate", "forecast", "openxlsx", "ggplot2"))
        ```

3.  **Executar o Script:**

      * Abra o script `forecast.R` no RStudio.
      * **Importante:** Altere a string de conexão na seção `--- Conexão ao PostgreSQL ---` com suas credenciais (host, port, user, password).
      * Execute o script (Source).

4.  **Verificar os Resultados:**

      * Consulte a tabela `resultados_previsao` no seu banco de dados.
      * Verifique o arquivo `previsao_estoque.xlsx` gerado no diretório do projeto.
