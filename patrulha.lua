--[[
 Módulo de Patrulha Urbana para Homunculus AI
 Autor: Gemini (baseado na lógica de IAs de Ragnarok)
 Descrição: Faz o Homunculus andar aleatoriamente ao redor do mestre
 quando em estado de "Standby" (ALT+T) e em mapas sem monstros.
--]]

-- Configurações
local RAIO_PATRULHA = 5 -- Distância máxima em células que o Homunculus andará do mestre.
local TEMPO_ESPERA_MIN = 2000 -- Tempo mínimo em milissegundos para esperar antes de um novo movimento.
local TEMPO_ESPERA_MAX = 5000 -- Tempo máximo em milissegundos para esperar antes de um novo movimento.

-- Variáveis de controle interno
local proximoMovimento = 0 -- Armazena o tempo do próximo movimento.
local isPatrolActive = false -- Controla se a patrulha está ativa.

--[[
 Função: GetMonsterList
 Descrição: Varre todos os atores na tela, filtra para encontrar apenas os monstros
            que estão vivos e não são alvos inválidos, e retorna uma lista (tabela)
            com informações detalhadas sobre cada um.
 Retorna: Uma tabela contendo outras tabelas, onde cada uma representa um monstro.
          Ex: { {id=123, x=150, y=100, dist=5, hp=100}, {id=456, ...} }
--]]
function GetMonsterList()
    -- 1. Primeiro, criamos uma tabela vazia que irá armazenar os monstros encontrados.
    local monsterList = {}
    local myID = GetMyID() -- Pega o ID do nosso Homunculus para calcular distâncias.

    -- 2. O cliente do jogo nos dá o número de "atores" visíveis na tela.
    --    Vamos iterar por todos eles para encontrar os monstros.
    local actorCount = GetV(V_MAX_ACTOR)
    for i = 1, actorCount do
        local actorID = GetV(V_ACTOR, i)

        -- 3. Verificamos se o ator atual é, de fato, um monstro.
        if actorID > 0 and GetV(V_TYPE, actorID) == ACTOR_TYPE_MONSTER then

            -- 4. Filtramos os monstros que não nos interessam.
            --    Neste caso, ignoramos monstros que já estão mortos.
            local monsterState = GetV(V_STATE, actorID)
            if monsterState ~= ACTOR_STATE_DEAD then

                -- 5. Se o monstro passou nos filtros, coletamos suas informações
                --    e as armazenamos em uma tabela de "propriedades".
                local monsterX, monsterY = GetV(V_POSITION, actorID)
                local monsterHP = GetV(V_HP, actorID)

                local propriedades = {
                    id = actorID,
                    x = monsterX,
                    y = monsterY,
                    hp = monsterHP,
                    maxHP = GetV(V_MAXHP, actorID),
                    dist = GetDistance(myID, actorID),
                    nome = GetV(V_NAME, actorID)
                }

                -- 6. Adicionamos a tabela de propriedades do monstro à nossa lista principal.
                table.insert(monsterList, propriedades)
            end
        end
    end

    -- 7. Finalmente, retornamos a lista completa de monstros válidos.
    return monsterList
end

-- NOTA: A função GetDistance() também é necessária. Se você não a tiver, aqui está uma implementação:
function GetDistance(id1, id2)
    local x1, y1 = GetV(V_POSITION, id1)
    local x2, y2 = GetV(V_POSITION, id2)

    if x1 == -1 or x2 == -1 then
        return 999 -- Retorna uma distância grande se uma das posições for inválida.
    end

    -- Cálculo da distância euclidiana
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Função principal a ser chamada no loop da sua IA
function ExecutarPatrulhaUrbana(myID, ownerID)
    -- Passo 1: Verificar se o Homunculus está no modo Standby.
    -- O modo Standby é o nosso gatilho para ativar/desativar a patrulha.
    if GetV(V_HOMUNSTATE, myID) == HOMUN_STATE_STANDBY then
        isPatrolActive = true
    else
        isPatrolActive = false
        -- Se não está em Standby, garantimos que a patrulha pare.
        return
    end

    -- Se a patrulha não está ativa por qualquer motivo, paramos aqui.
    if not isPatrolActive then
        return
    end

    -- Passo 2: Verificar se o ambiente é seguro (sem monstros na tela).
    local monsterList = GetMonsterList()
    if #monsterList > 0 then
        -- Encontrou um monstro! Desativa a patrulha e deixa a IA de combate agir.
        isPatrolActive = false
        return
    end

    -- Passo 3: Verificar o temporizador para o próximo movimento.
    if GetTick() < proximoMovimento then
        -- Ainda não é hora de se mover.
        return
    end

    -- Passo 4: Calcular a nova posição e mover o Homunculus.
    local ownerX, ownerY = GetV(V_POSITION, ownerID)
    if ownerX == -1 then return end -- Checagem de segurança

    -- Gera um ângulo e uma distância aleatórios para um movimento mais natural.
    local angulo = math.random() * 2 * math.pi
    local distancia = math.random(2, RAIO_PATRULHA)

    -- Calcula as novas coordenadas X e Y.
    local destX = ownerX + math.floor(math.cos(angulo) * distancia + 0.5)
    local destY = ownerY + math.floor(math.sin(angulo) * distancia + 0.5)

    -- Envia o comando de movimento para o Homunculus.
    Move(myID, destX, destY)
    --Trace("Patrulha Urbana: Movendo para " .. destX .. ", " .. destY) -- Descomente para debug

    -- Passo 5: Definir o temporizador para o próximo movimento.
    proximoMovimento = GetTick() + math.random(TEMPO_ESPERA_MIN, TEMPO_ESPERA_MAX)
end
