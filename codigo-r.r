library(DBI)
library(RPostgres)
library(dplyr)
library(lubridate)
library(forecast)
library(openxlsx)
library(ggplot2)

# --- Conexão ao PostgreSQL ---
# Ajuste as credenciais conforme necessário
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "Projetos",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "soubom556"
)

# --- Consultas ---
produtos <- dbGetQuery(con, "SELECT * FROM produtos;")
estoque  <- dbGetQuery(con, "SELECT * FROM estoque_atual;")
vendas   <- dbGetQuery(con, "SELECT * FROM historico_vendas;")

# --- Função de previsão ---
prever_demanda <- function(df_vendas, horizonte = 30) {
  # Se tiver menos de 10 registros, não faz a previsão (retorna NA)
  if (nrow(df_vendas) < 10) return(list(media = NA, inf = NA, sup = NA))
  
  tryCatch({
    # Cria a série temporal (frequência 7 dias/semana assumida)
    ts_data <- ts(df_vendas$quantidade_vendida, frequency = 7)
    
    # Aplica o modelo ETS
    modelo <- ets(ts_data)
    
    # Gera a previsão para o horizonte definido
    previsao <- forecast(modelo, h = horizonte)
    
    list(media = mean(previsao$mean),
         inf = mean(previsao$lower[,2]),
         sup = mean(previsao$upper[,2]))
  }, error = function(e) list(media = NA, inf = NA, sup = NA))
}

# --- Calcular previsões ---
horizonte <- 30

resultados <- vendas %>%
  group_by(produto_id) %>%
  arrange(data_venda) %>%
  group_split() %>%
  lapply(function(df) {
    res <- prever_demanda(df, horizonte)
    tibble(
      produto_id = df$produto_id[1],
      data_previsao = Sys.Date(),
      horizonte_dias = horizonte,
      demanda_prevista = res$media,
      limite_inferior = res$inf,
      limite_superior = res$sup,
      sugestao_recompra = ceiling(res$media),
      resumo_ia = paste0("Previsão calculada para produto ", df$produto_id[1])
    )
  }) %>% bind_rows()

# --- Limpar tabela antes de inserir ---
# Remove dados antigos para evitar duplicidade ou dados obsoletos
dbExecute(con, "DELETE FROM resultados_previsao")

# --- Inserir todas as linhas de uma vez ---
dbWriteTable(
  conn = con,
  name = "resultados_previsao",
  value = resultados,
  append = TRUE,  # adiciona após limpar
  row.names = FALSE
)

# --- Exportar Excel ---
write.xlsx(resultados, "previsao_estoque.xlsx")

# --- Fechar conexão ---
dbDisconnect(con)
