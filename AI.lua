dofile("./AI/USER_AI/Const.lua")
dofile("./AI/USER_AI/Util.lua")

-----------------------------
-- Estados da IA
-----------------------------
IDLE_ST					= 0  -- Ocioso
FOLLOW_ST				= 1  -- Seguindo
CHASE_ST				= 2  -- Perseguindo
ATTACK_ST				= 3  -- Atacando
MOVE_CMD_ST				= 4  -- Comando de Mover
STOP_CMD_ST				= 5  -- Comando de Parar
ATTACK_OBJECT_CMD_ST	= 6  -- Comando de Atacar Alvo
ATTACK_AREA_CMD_ST		= 7  -- Comando de Atacar ?rea
PATROL_CMD_ST			= 8  -- Comando de Patrulhar
HOLD_CMD_ST				= 9  -- Comando de Manter Posi??o
SKILL_OBJECT_CMD_ST		= 10 -- Comando de Usar Habilidade em Alvo
SKILL_AREA_CMD_ST		= 11 -- Comando de Usar Habilidade em ?rea
FOLLOW_CMD_ST			= 12 -- Comando de Seguir
----------------------------


------------------------------------------
-- Globais
------------------------------------------
MyState				= IDLE_ST	-- O estado inicial
MyEnemy				= 0		-- ID do inimigo
MyDestX				= 0		-- Coordenada X de destino
MyDestY				= 0		-- Coordenada Y de destino
MyPatrolX			= 0		-- Coordenada X de destino da patrulha
MyPatrolY			= 0		-- Coordenada Y de destino da patrulha
ResCmdList			= List.new()	-- Lista de comandos reservados (enfileirados)
MyID				= 0		-- ID do homunculo
MySkill				= 0		-- Habilidade a ser usada
MySkillLevel		= 0		-- Nivel Habilidade
------------------------------------------

---------------------------------------------------
-- Tabelas de Prioridade de Alvos
---------------------------------------------------
-- Preencha as tabelas abaixo com os IDs dos monstros.
TARGET_PRIORITY = {
    prioritario = { 
        -- Ex: {1002, 1004} -- Monstros de alta prioridade (MVPs, etc.)
    },
    normal = {
        -- Ex: {1096, 1115} -- Monstros comuns que voc? deseja farmar
    },
    ultimo_caso = {
        -- Ex: {1272} -- Monstros de baixa prioridade (fracos, etc.)
    }
}
---------------------------------------------------


------------- Processamento de Comandos ---------------------

function	OnMOVE_CMD (x,y)
	
	TraceAI ("OnMOVE_CMD")

	if ( x == MyDestX and y == MyDestY and MOTION_MOVE == GetV(V_MOTION,MyID)) then
		return
	end

	local curX, curY = GetV (V_POSITION,MyID)

	if (math.abs(x-curX)+math.abs(y-curY) > 15) then
		List.pushleft (ResCmdList,{MOVE_CMD,x,y})
		x = math.floor((x+curX)/2)
		y = math.floor((y+curY)/2)
	end

	Move (MyID,x,y)	
	
	MyState = MOVE_CMD_ST
	MyDestX = x
	MyDestY = y
	MyEnemy = 0
	MySkill = 0

end

function	OnSTOP_CMD ()

	TraceAI ("OnSTOP_CMD")

	if (GetV(V_MOTION,MyID) ~= MOTION_STAND) then
		Move (MyID,GetV(V_POSITION,MyID))
	end
	MyState = IDLE_ST
	MyDestX = 0
	MyDestY = 0
	MyEnemy = 0
	MySkill = 0

end

function	OnATTACK_OBJECT_CMD (id)

	TraceAI ("OnATTACK_OBJECT_CMD")

	MySkill = 0
	MyEnemy = id
	MyState = CHASE_ST

end

function	OnATTACK_AREA_CMD (x,y)

	TraceAI ("OnATTACK_AREA_CMD")

	if (x ~= MyDestX or y ~= MyDestY or MOTION_MOVE ~= GetV(V_MOTION,MyID)) then
		Move (MyID,x,y)	
	end
	MyDestX = x
	MyDestY = y
	MyEnemy = 0
	MyState = ATTACK_AREA_CMD_ST
	
end

function	OnPATROL_CMD (x,y)

	TraceAI ("OnPATROL_CMD")

	MyPatrolX , MyPatrolY = GetV (V_POSITION,MyID)
	MyDestX = x
	MyDestY = y
	Move (MyID,x,y)
	MyState = PATROL_CMD_ST

end

function	OnHOLD_CMD ()

	TraceAI ("OnHOLD_CMD")

	MyDestX = 0
	MyDestY = 0
	MyEnemy = 0
	MyState = HOLD_CMD_ST

end

function	OnSKILL_OBJECT_CMD (level,skill,id)

	TraceAI ("OnSKILL_OBJECT_CMD")

	MySkillLevel = level
	MySkill = skill
	MyEnemy = id
	MyState = CHASE_ST

end

function	OnSKILL_AREA_CMD (level,skill,x,y)

	TraceAI ("OnSKILL_AREA_CMD")

	Move (MyID,x,y)
	MyDestX = x
	MyDestY = y
	MySkillLevel = level
	MySkill = skill
	MyState = SKILL_AREA_CMD_ST
	
end

function	OnFOLLOW_CMD ()

	if (MyState ~= FOLLOW_CMD_ST) then
		MoveToOwner (MyID)
		MyState = FOLLOW_CMD_ST
		MyDestX, MyDestY = GetV (V_POSITION,GetV(V_OWNER,MyID))
		MyEnemy = 0 
		MySkill = 0
		TraceAI ("OnFOLLOW_CMD")
	else
		MyState = IDLE_ST
		MyEnemy = 0 
		MySkill = 0
		TraceAI ("FOLLOW_CMD_ST --> IDLE_ST")
	end

end

function	ProcessCommand (msg)

	if		(msg[1] == MOVE_CMD) then
		OnMOVE_CMD (msg[2],msg[3])
		TraceAI ("MOVE_CMD")
	elseif	(msg[1] == STOP_CMD) then
		OnSTOP_CMD ()
		TraceAI ("STOP_CMD")
	elseif	(msg[1] == ATTACK_OBJECT_CMD) then
		OnATTACK_OBJECT_CMD (msg[2])
		TraceAI ("ATTACK_OBJECT_CMD")
	elseif	(msg[1] == ATTACK_AREA_CMD) then
		OnATTACK_AREA_CMD (msg[2],msg[3])
		TraceAI ("ATTACK_AREA_CMD")
	elseif	(msg[1] == PATROL_CMD) then
		OnPATROL_CMD (msg[2],msg[3])
		TraceAI ("PATROL_CMD")
	elseif	(msg[1] == HOLD_CMD) then
		OnHOLD_CMD ()
		TraceAI ("HOLD_CMD")
	elseif	(msg[1] == SKILL_OBJECT_CMD) then
		OnSKILL_OBJECT_CMD (msg[2],msg[3],msg[4],msg[5])
		TraceAI ("SKILL_OBJECT_CMD")
	elseif	(msg[1] == SKILL_AREA_CMD) then
		OnSKILL_AREA_CMD (msg[2],msg[3],msg[4],msg[5])
		TraceAI ("SKILL_AREA_CMD")
	elseif	(msg[1] == FOLLOW_CMD) then
		OnFOLLOW_CMD ()
		TraceAI ("FOLLOW_CMD")
	end
end

-------------- Processamento de Estados --------------------
function	OnIDLE_ST ()
	
	TraceAI ("OnIDLE_ST")

	local cmd = List.popleft(ResCmdList)
	if (cmd ~= nil) then		
		ProcessCommand (cmd)
		return 
	end

	local	object = GetOwnerEnemy (MyID)
	if (object ~= nil and object ~= 0) then
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("IDLE_ST -> CHASE_ST : MESTRE_ATACADO")
		return 
	end

	object = GetMyEnemy (MyID)
	if (object ~= nil and object ~= 0) then
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("IDLE_ST -> CHASE_ST : ATACADO_OU_ALVO_ENCONTRADO")
		return
	end

	local distance = GetDistanceFromOwner(MyID)
	if ( distance > MAX_DISTANCE_FROM_OWNER or distance == -1) then
		MyState = FOLLOW_ST
		TraceAI ("IDLE_ST -> FOLLOW_ST")
		return
	end

end



function	OnFOLLOW_ST ()

	TraceAI ("OnFOLLOW_ST")

	if (GetDistanceFromOwner(MyID) <= MAX_DISTANCE_FROM_OWNER) then		-- Chegou ao destino (perto do mestre)
		MyState = IDLE_ST
		TraceAI ("FOLLOW_ST -> IDLE_ST")
		return
	elseif (GetV(V_MOTION,MyID) == MOTION_STAND) then
		MoveToOwner (MyID)
		TraceAI ("FOLLOW_ST -> FOLLOW_ST")
		return
	end

end



function	OnCHASE_ST ()

	TraceAI ("OnCHASE_ST")
	if (MyEnemy == nil) or (true == IsOutOfSight(MyID,MyEnemy)) then	-- Inimigo fora de vis?o
		MyState = IDLE_ST
		MyEnemy = 0
		MyDestX, MyDestY = 0,0
		TraceAI ("CHASE_ST -> IDLE_ST : INIMIGO_FORA_DE_VISAO")
		return
	end
	if (true == IsInAttackSight(MyID,MyEnemy)) then  -- Inimigo em alcance de ataque
		MyState = ATTACK_ST
		TraceAI ("CHASE_ST -> ATTACK_ST : INIMIGO_NO_ALCANCE")
		return
	end

	local x, y = GetV (V_POSITION_APPLY_SKILLATTACKRANGE, MyEnemy, MySkill, MySkillLevel)
	if (MyDestX ~= x or MyDestY ~= y) then
		MyDestX, MyDestY = GetV (V_POSITION_APPLY_SKILLATTACKRANGE, MyEnemy, MySkill, MySkillLevel)
		Move (MyID,MyDestX,MyDestY)
		TraceAI ("CHASE_ST -> CHASE_ST : DESTINO_MUDOU")
		return
	end

end



function	OnATTACK_ST ()

	TraceAI ("OnATTACK_ST")
	
	if (true == IsOutOfSight(MyID,MyEnemy)) then	-- Inimigo fora de vis?o
		MyState = IDLE_ST
		TraceAI ("ATTACK_ST -> IDLE_ST")
		return 
	end

	if (MOTION_DEAD == GetV(V_MOTION,MyEnemy)) then   -- Inimigo morto
		MyState = IDLE_ST
		TraceAI ("ATTACK_ST -> IDLE_ST")
		return
	end
		
	if (false == IsInAttackSight(MyID,MyEnemy)) then  -- Inimigo fora do alcance de ataque
		MyState = CHASE_ST
		MyDestX, MyDestY = GetV(V_POSITION_APPLY_SKILLATTACKRANGE, MyEnemy, MySkill, MySkillLevel)
		Move (MyID,MyDestX,MyDestY)
		TraceAI ("ATTACK_ST -> CHASE_ST  : INIMIGO_FORA_DO_ALCANCE")
		return
	end
	
	if (MySkill == 0) then
		Attack (MyID,MyEnemy)
	else
		if (1 == SkillObject(MyID,MySkillLevel,MySkill,MyEnemy)) then
			MyEnemy = 0
		end
		
		MySkill = 0
	end
	TraceAI ("ATTACK_ST -> ATTACK_ST  : ATACANDO")
	return


end



function	OnMOVE_CMD_ST ()

	TraceAI ("OnMOVE_CMD_ST")

	local x, y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then				-- Chegou ao destino
		MyState = IDLE_ST
	end
end



function OnSTOP_CMD_ST ()


end



function OnATTACK_OBJECT_CMD_ST ()

	
end



function OnATTACK_AREA_CMD_ST ()

	TraceAI ("OnATTACK_AREA_CMD_ST")

	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID) 
	end

	if (object ~= nil and object ~= 0) then
		MyState = CHASE_ST
		MyEnemy = object
		return
	end

	local x , y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then
			MyState = IDLE_ST
	end

end



function OnPATROL_CMD_ST ()

	TraceAI ("OnPATROL_CMD_ST")

	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID) 
	end

	if (object ~= nil and object ~= 0) then
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("PATROL_CMD_ST -> CHASE_ST : INIMIGO_ENCONTRADO")
		return
	end

	local x , y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then
		MyDestX = MyPatrolX
		MyDestY = MyPatrolY
		MyPatrolX = x
		MyPatrolY = y
		Move (MyID,MyDestX,MyDestY)
	end

end

function OnHOLD_CMD_ST ()

	TraceAI ("OnHOLD_CMD_ST")
	
	if (MyEnemy ~= nil and MyEnemy ~= 0) then
		local d = GetDistanceById(MyEnemy,MyID)
		if (d ~= -1 and d <= GetV(V_ATTACKRANGE,MyID)) then
				Attack (MyID,MyEnemy)
		else
			MyEnemy = 0
		end
		return
	end


	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID)
		if (object == 0) then					
			MyEnemy = 0
			return
		end
	end

	MyEnemy = object

end

function OnSKILL_OBJECT_CMD_ST ()
	
end

function OnSKILL_AREA_CMD_ST ()

	TraceAI ("OnSKILL_AREA_CMD_ST")

	local x , y = GetV (V_POSITION,MyID)
	if (GetDistance(x,y,MyDestX,MyDestY) <= GetV(V_SKILLATTACKRANGE_LEVEL, MyID, MySkill, MySkillLevel)) then
		SkillGround (MyID,MySkillLevel,MySkill,MyDestX,MyDestY)
		MyState = IDLE_ST
		MySkill = 0
	end

end

function OnFOLLOW_CMD_ST ()

	TraceAI ("OnFOLLOW_CMD_ST")
	local owner = GetV(V_OWNER,MyID)
	local d = GetDistance (owner,MyID)

	if ( d <= MAX_DISTANCE_FROM_OWNER) then
		return 
	end

	local motion = GetV (V_MOTION,MyID)
	local ownerX, ownerY = GetV (V_POSITION,owner)
	if (motion == MOTION_MOVE) then
		d = GetDistance (owner,MyID)
		if ( d > MAX_DISTANCE_FROM_OWNER) then
			MoveToOwner (MyID)
			MyDestX = ownerX
			MyDestY = ownerY
			return
		end
	else
		MoveToOwner (MyID)
		MyDestX = ownerX
		MyDestY = ownerY
		return
	end
	
end

function table.contains(tbl, element)
    for _, value in pairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end

function IsTargetedByOtherPlayer(target_id, my_id, owner_id)
    local actors = GetActors()
    for _, actor_id in ipairs(actors) do
        if actor_id ~= my_id and actor_id ~= owner_id and IsMonster(actor_id) == 0 then
            if (GetV(V_TARGET, actor_id) == target_id) then
                return true 
            end
        end
    end
    return false
end

function FindClosestEnemy(myid, enemy_list)
    local result = 0
    local min_dis = MAX_DISTANCE * 3
    local dis

    for _, enemy_id in ipairs(enemy_list) do
        dis = GetDistanceById(myid, enemy_id)
        if (dis < min_dis) then
            result = enemy_id
            min_dis = dis
        end
    end
    return result
end

---------------------------------------------------
function	GetOwnerEnemy (myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local target
	for i,v in ipairs(actors) do
		if (v ~= owner and v ~= myid) then
			target = GetV (V_TARGET,v)
			if (target == owner) then
				if (IsMonster(v) == 1) then
					enemys[index] = v
					index = index+1
				else
					local motion = GetV(V_MOTION,i)
					if (motion == MOTION_ATTACK or motion == MOTION_ATTACK2) then
						enemys[index] = v
						index = index+1
					end
				end
			end
		end
	end

	local min_dis = MAX_DISTANCE * 3
	local dis
	if #enemys > 0 then 
		for i,v in ipairs(enemys) do
			dis = GetDistanceById (myid,v)
			if (dis < min_dis) then
				result = v
				min_dis = dis
			end
		end
	end
	
	return result
end

function	GetMyEnemy (myid)
	local result = 0

	local type = GetV (V_HOMUNTYPE,myid)
	if (EVERYBODY_AGRESSIVE == 1) or (type == FILIR or type == FILIR_H or type == VANILMIRTH or type == VANILMIRTH_H or type == FILIR2 or type == FILIR_H2 or type == VANILMIRTH2 or type == VANILMIRTH_H2) then
		result = GetMyEnemy (myid)
	elseif (type == LIF or type == LIF_H or type == AMISTR or type == AMISTR_H or type == LIF2 or type == LIF_H2 or type == AMISTR2 or type == AMISTR_H2)  then
		result = GetMyEnemyNotAgressive (myid)
	end
	return result
end

function	GetMyEnemyNotAgressive (myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local target
	for i,v in ipairs(actors) do
		if (v ~= owner and v ~= myid) then
			target = GetV (V_TARGET,v)
			if (target == myid) then
				enemys[index] = v
				index = index+1
			end
		end
	end

	return FindClosestEnemy(myid, enemys)
end

function	GetMyEnemy (myid)
	local owner  = GetV(V_OWNER, myid)
	local actors = GetActors()

	local enemys = {}
	local index = 1

	for _, v in ipairs(actors) do
		if (v ~= owner and v ~= myid and IsMonster(v) == 1) then
			if not IsTargetedByOtherPlayer(v, myid, owner) then
				enemys[index] = v
				index = index+1
			end
		end
	end

	local min_dis = MAX_DISTANCE * 3
	local dis
	for i,v in ipairs(enemys) do
		dis = GetDistanceById (myid,v)
		if (dis < min_dis) then
			result = v
			min_dis = dis
		end
	end

	return result
end

function AI(myid)

	MyID = myid
	local msg	= GetMsg (myid)
	local rmsg	= GetResMsg (myid)

	
	if msg[1] == NONE_CMD then
		if rmsg[1] ~= NONE_CMD then
			if List.size(ResCmdList) < 10 then
				List.pushright (ResCmdList,rmsg)
			end
		end
	else
		List.clear (ResCmdList)
		ProcessCommand (msg)
	end
 	if (MyState == IDLE_ST) then
		OnIDLE_ST ()
	elseif (MyState == CHASE_ST) then					
		OnCHASE_ST ()
	elseif (MyState == ATTACK_ST) then
		OnATTACK_ST ()
	elseif (MyState == FOLLOW_ST) then
		OnFOLLOW_ST ()
	elseif (MyState == MOVE_CMD_ST) then
		OnMOVE_CMD_ST ()
	elseif (MyState == STOP_CMD_ST) then
		OnSTOP_CMD_ST ()
	elseif (MyState == ATTACK_OBJECT_CMD_ST) then
		OnATTACK_OBJECT_CMD_ST ()
	elseif (MyState == ATTACK_AREA_CMD_ST) then
		OnATTACK_AREA_CMD_ST ()
	elseif (MyState == PATROL_CMD_ST) then
		OnPATROL_CMD_ST ()
	elseif (MyState == HOLD_CMD_ST) then
		OnHOLD_CMD_ST ()
	elseif (MyState == SKILL_OBJECT_CMD_ST) then
		OnSKILL_OBJECT_CMD_ST ()
	elseif (MyState == SKILL_AREA_CMD_ST) then
		OnSKILL_AREA_CMD_ST ()
	elseif (MyState == FOLLOW_CMD_ST) then
		OnFOLLOW_CMD_ST ()
	end

end
