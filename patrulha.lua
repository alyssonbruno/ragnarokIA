--[[
 Módulo de Patrulha Urbana para Homunculus AI
 Autor: Gemini (baseado na lógica de IAs de Ragnarok)
 Descrição: Faz o Homunculus andar aleatoriamente ao redor do mestre
 quando em estado de "Standby" (ALT+T) e em mapas sem monstros.
--]]

dofile("./AI/USER_AI/Const.lua")

-- Variáveis de controle interno
proximoMovimento = 0 -- Armazena o tempo do próximo movimento.

-- Função principal a ser chamada no loop da sua IA
function ExecutarPatrulhaUrbana(myID, ownerID)

    local ownerX, ownerY = GetV(V_POSITION, ownerID)
    if ownerX == -1 then return end -- Checagem de segurança

    -- Gera um ângulo e uma distância aleatórios para um movimento mais natural.
    local angulo = math.random() * 2 * math.pi
    local distancia = math.random(2, RAIO_PATRULHA)

    -- Calcula as novas coordenadas X e Y.
    local destX = ownerX + math.floor(math.cos(angulo) * distancia + 0.5)
    local destY = ownerY + math.floor(math.sin(angulo) * distancia + 0.5)

    Move(myID, destX, destY)

    proximoMovimento = GetTick() + math.random(TEMPO_ESPERA_MIN, TEMPO_ESPERA_MAX)
end
