-- =================================================================
-- Esquema de Banco de Dados PostgreSQL para Previsão de Estoque
-- Integrado com n8n, R e IA
-- =================================================================

-- 1. Tabela de Produtos (Dados Mestres)
-- Contém informações básicas sobre cada item de estoque (SKU).
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL, -- Código único do produto, chave de busca
    nome VARCHAR(255) NOT NULL,
    unidade_medida VARCHAR(20), -- Ex: UN, KG, M
    preco_custo NUMERIC(10, 2),
    preco_venda NUMERIC(10, 2),
    lead_time_dias INTEGER, -- Tempo de espera do fornecedor em dias (crucial para o ponto de pedido)
    data_cadastro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabela de Histórico de Vendas (Série Temporal)
-- Contém os dados de demanda histórica que serão usados pelo R para rodar o modelo de série temporal.
CREATE TABLE historico_vendas (
    id BIGSERIAL PRIMARY KEY,
    produto_id INTEGER REFERENCES produtos(id) ON DELETE CASCADE,
    data_venda DATE NOT NULL,
    quantidade_vendida INTEGER NOT NULL,
    data_registro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índice para otimizar consultas por produto e data (essencial para o R)
CREATE INDEX idx_vendas_produto_data ON historico_vendas (produto_id, data_venda);

-- 3. Tabela de Estoque Atual
-- Contém o nível de estoque atual e o ponto de pedido (reorder point - ROP)
CREATE TABLE estoque_atual (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER UNIQUE REFERENCES produtos(id) ON DELETE CASCADE,
    quantidade_atual INTEGER NOT NULL,
    estoque_seguranca INTEGER DEFAULT 0, -- Estoque mínimo para evitar stockout
    ponto_pedido INTEGER, -- Quantidade que dispara a necessidade de recompra
    data_ultima_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela de Resultados de Previsão (Opcional, mas Recomendada)
-- Armazena os resultados da previsão gerada pelo R e a sugestão da IA para auditoria e histórico.
CREATE TABLE resultados_previsao (
    id BIGSERIAL PRIMARY KEY,
    produto_id INTEGER REFERENCES produtos(id) ON DELETE CASCADE,
    data_previsao DATE NOT NULL, -- Data para a qual a previsão foi feita
    horizonte_dias INTEGER NOT NULL, -- Período da previsão (ex: 90 dias)
    demanda_prevista NUMERIC(10, 2) NOT NULL,
    limite_inferior NUMERIC(10, 2), -- Limite inferior do Intervalo de Confiança
    limite_superior NUMERIC(10, 2), -- Limite superior do Intervalo de Confiança
    sugestao_recompra INTEGER, -- Sugestão final da IA
    resumo_ia TEXT, -- O texto gerado pela IA
    data_execucao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índice para buscar rapidamente as previsões
CREATE INDEX idx_previsao_produto_data ON resultados_previsao (produto_id, data_previsao);
