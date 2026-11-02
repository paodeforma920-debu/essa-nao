--[[
    Script EXECUTOR - Caracois da Sirene (v3)
    ------------------------------------------
    * Toca a sirene de alerta em LOOP
    * Spawn 5 caracois no mapa (mais longe do jogador)
    * Os caracois COLIDEM com paredes (rebatem ao bater)
    * A tela pisca em vermelho
    * Contador na tela: "VERIFIQUE OS CARACOIS"  X / 5
    * TIMER de 40 segundos
    * A GUI treme (tremer) enquanto nao coletar todos
    * O jogador coleta os caracois passando por cima
    * Vitoria: som PARA, vermelho some, tremor para
    * Derrota (tempo acabou): KICK com mensagem
]]--

local TEMPO_TOTAL = 40  -- segundos

local URL_SIRENE = "https://www.myinstants.com/media/sounds/alarm-sound-effect.mp3"
local ARQUIVO_SIRENE = "alarm_sirene.mp3"

local URL_COIN = "https://www.myinstants.com/media/sounds/subway-surfers-coin-collecting-sound.mp3"
local ARQUIVO_COIN = "coin_collect.mp3"

local TOTAL_CARACOIS = 5

-- ============================================================
-- 1. CARREGA OS SONS (sirene + coin)
-- ============================================================
local function carregarSom(url, arquivo, nomeLog)
    local data = game:HttpGet(url)
    writefile(arquivo, data)

    local function tenta(label, fn)
        local ok, res = pcall(fn)
        if ok and res then print("[Caracois] " .. nomeLog .. " carregado via: " .. label) return res end
        return nil
    end

    return tenta("getcustomasset", function()
        local s = Instance.new("Sound")
        s.SoundId = getcustomasset(arquivo)
        return s
    end) or tenta("getsynasset", function()
        local s = Instance.new("Sound")
        s.SoundId = getsynasset(arquivo)
        return s
    end) or tenta("loadaudio", function()
        local id = loadaudio(arquivo)
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. tostring(id)
        return s
    end)
end

-- Sirene (loop infinito)
local somOk, som = pcall(carregarSom, URL_SIRENE, ARQUIVO_SIRENE, "Sirene")
if not somOk or not som then
    warn("[Caracois] Nao consegui carregar a sirene. Continuando mesmo assim...")
    som = Instance.new("Sound")
end
som.Name = "SireneLoop"
som.Volume = 1
som.Looped = true
som.Parent = workspace
som:Play()

-- Som de coleta (preload)
local coinOk, coinSound = pcall(carregarSom, URL_COIN, ARQUIVO_COIN, "Coin")
if not coinOk or not coinSound then
    warn("[Caracois] Nao consegui carregar o som de coleta. Usando beep padrao.")
    coinSound = Instance.new("Sound")
    coinSound.SoundId = "rbxassetid://322911410"
end
coinSound.Name = "CoinCollect"
coinSound.Volume = 0.8
coinSound.Looped = false
coinSound.Parent = workspace

-- ============================================================
-- 2. GUI (overlay vermelho + contador + tremor)
-- ============================================================
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "CaracoisGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Overlay vermelho
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.ZIndex = 5
overlay.Parent = gui

-- Container que vai tremer (engloba o contador)
local shakeContainer = Instance.new("Frame")
shakeContainer.Size = UDim2.new(0, 280, 0, 80)
shakeContainer.Position = UDim2.new(0.5, -140, 0, 30)
shakeContainer.BackgroundTransparency = 1
shakeContainer.ZIndex = 10
shakeContainer.Parent = gui

-- Contador (dentro do shakeContainer)
local contadorFrame = Instance.new("Frame")
contadorFrame.Size = UDim2.new(1, 0, 0, 80)
contadorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
contadorFrame.BackgroundTransparency = 0.1
contadorFrame.BorderSizePixel = 0
contadorFrame.Parent = shakeContainer

-- Timer (embaixo do contador, dentro do shakeContainer)
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0, 40)
timerLabel.Position = UDim2.new(0, 0, 0, 80)
timerLabel.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
timerLabel.BackgroundTransparency = 0.1
timerLabel.BorderSizePixel = 0
timerLabel.Text = "TEMPO: " .. TEMPO_TOTAL
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextSize = 24
timerLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
timerLabel.Parent = shakeContainer

-- Aumenta o tamanho do container pra abranger os dois
shakeContainer.Size = UDim2.new(0, 280, 0, 125)
contadorFrame.Size = UDim2.new(1, 0, 0, 80)

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 12)
timerCorner.Parent = timerLabel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = contadorFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 60, 60)
stroke.Parent = contadorFrame

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 28)
titulo.Position = UDim2.new(0, 0, 0, 6)
titulo.BackgroundTransparency = 1
titulo.Text = "VERIFIQUE OS CARACOIS"
titulo.Font = Enum.Font.GothamBold
titulo.TextSize = 14
titulo.TextColor3 = Color3.fromRGB(255, 120, 120)
titulo.Parent = contadorFrame

local numero = Instance.new("TextLabel")
numero.Size = UDim2.new(1, 0, 0, 42)
numero.Position = UDim2.new(0, 0, 0, 32)
numero.BackgroundTransparency = 1
numero.Text = "0 / " .. TOTAL_CARACOIS
numero.Font = Enum.Font.GothamBlack
numero.TextSize = 32
numero.TextColor3 = Color3.fromRGB(255, 255, 255)
numero.Parent = contadorFrame

local coletados = 0
local ativo = true  -- controla tremor e piscar
local function atualizarContador()
    numero.Text = coletados .. " / " .. TOTAL_CARACOIS
end

-- ============================================================
-- 3. TREMOR DA GUI + PISCAR VERMELHO (rodando em loop)
-- ============================================================
local basePos = UDim2.new(0.5, -140, 0, 30)
local tempoRestante = TEMPO_TOTAL
local tempoAcabou = false
local jogoAtivo = true  -- controla tudo (vitoria ou derrota)

-- ============================================================
-- 3a. TIMER (40 segundos -> kick se acabar)
-- ============================================================
task.spawn(function()
    while jogoAtivo and tempoRestante > 0 do
        task.wait(1)
        if not jogoAtivo then break end
        tempoRestante = tempoRestante - 1
        timerLabel.Text = "TEMPO: " .. tempoRestante

        -- Fica vermelho quando faltam <= 10s
        if tempoRestante <= 10 then
            timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end

        if tempoRestante <= 0 then
            break
        end
    end

    -- Se o tempo acabou e o jogador nao venceu -> KICK
    if jogoAtivo and coletados < TOTAL_CARACOIS then
        tempoAcabou = true
        jogoAtivo = false
        ativo = false
        som:Stop()
        -- Pequeno delay pra garantir que a GUI fecha
        task.wait(0.3)
        player:Kick("você não verificou os caracóis!!!")
    end
end)

-- Tremor da GUI
task.spawn(function()
    while ativo do
        -- Tremor: offset aleatorio pequeno
        local dx = math.random(-6, 6)
        local dy = math.random(-6, 6)
        shakeContainer.Position = UDim2.new(0.5, -140 + dx, 0, 30 + dy)
        task.wait(0.03)
    end
end)

task.spawn(function()
    while ativo do
        -- Vermelho piscando
        for t = 1, 0.55, -0.04 do
            if not ativo then break end
            overlay.BackgroundTransparency = t
            task.wait(0.025)
        end
        for t = 0.55, 1, 0.04 do
            if not ativo then break end
            overlay.BackgroundTransparency = t
            task.wait(0.025)
        end
    end
    overlay.BackgroundTransparency = 1
    shakeContainer.Position = basePos
end)

-- ============================================================
-- 4. CRIAR CARACOL (anchored, movido por CFrame)
-- ============================================================
local function criarCaracol(posicao)
    local model = Instance.new("Model")
    model.Name = "Caracol"

    -- Corpo (deitado no chao) - Blok retangular baixo
    local corpo = Instance.new("Part")
    corpo.Name = "Corpo"
    corpo.Size = Vector3.new(3.5, 0.8, 2)
    corpo.Color = Color3.fromRGB(140, 210, 100)
    corpo.Material = Enum.Material.SmoothPlastic
    corpo.Anchored = true
    corpo.CanCollide = false
    corpo.Position = posicao + Vector3.new(0, 0.4, 0)
    corpo.Parent = model

    -- Concha (esfera em cima do corpo)
    local concha = Instance.new("Part")
    concha.Name = "Concha"
    concha.Shape = Enum.PartType.Ball
    concha.Size = Vector3.new(2.6, 2.6, 2.6)
    concha.Color = Color3.fromRGB(180, 110, 70)
    concha.Material = Enum.Material.SmoothPlastic
    concha.Anchored = true
    concha.CanCollide = false
    concha.Position = posicao + Vector3.new(-0.3, 1.5, 0)
    concha.Parent = model

    -- Antenas (2 cilindros finos na frente)
    for _, offset in ipairs({ Vector3.new(1.4, 1, -0.5), Vector3.new(1.4, 1, 0.5) }) do
        local antena = Instance.new("Part")
        antena.Name = "Antena"
        antena.Size = Vector3.new(0.1, 1, 0.1)
        antena.Color = Color3.fromRGB(140, 210, 100)
        antena.Material = Enum.Material.SmoothPlastic
        antena.Anchored = true
        antena.CanCollide = false
        antena.Position = posicao + offset
        antena.Parent = model
    end

    -- Olhos (2 bolinhas pretas pequenas na frente)
    for _, offset in ipairs({ Vector3.new(1.75, 0.7, -0.4), Vector3.new(1.75, 0.7, 0.4) }) do
        local olho = Instance.new("Part")
        olho.Name = "Olho"
        olho.Shape = Enum.PartType.Ball
        olho.Size = Vector3.new(0.3, 0.3, 0.3)
        olho.Color = Color3.fromRGB(20, 20, 20)
        olho.Material = Enum.Material.SmoothPlastic
        olho.Anchored = true
        olho.CanCollide = false
        olho.Position = posicao + offset
        olho.Parent = model
    end

    -- PrimaryPart = corpo (centro de controle)
    model.PrimaryPart = corpo

    -- Tag
    model:SetAttribute("Coletado", false)

    model.Parent = workspace
    return model, corpo
end

-- ============================================================
-- 5. ACHAR SPAWN NO CHAO (mais longe, mas sempre valido)
-- ============================================================
local function acharSpawn(distMin, distMax)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local origem = hrp.Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }

    local candidatos = {}

    for _ = 1, 120 do
        local ang = math.random() * math.pi * 2
        local dist = distMin + math.random() * (distMax - distMin)
        local alvo = origem + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)

        -- 1) Raycast curto pra baixo (so 80 studs) pra achar o chao
        local result = workspace:Raycast(
            alvo + Vector3.new(0, 30, 0),
            Vector3.new(0, -80, 0),
            params
        )
        if not result then continue end

        local pos = result.Position

        -- 2) Validacao de sanidade: Y tem que estar perto do jogador
        if math.abs(pos.Y - origem.Y) > 30 then continue end

        -- 3) Verifica se ha parede entre o jogador e o spawn (raio horizontal)
        local dirH = (Vector3.new(pos.X, origem.Y, pos.Z) - origem)
        local distH = dirH.Magnitude
        local hitHorizontal = workspace:Raycast(
            origem + Vector3.new(0, 2, 0),
            dirH.Unit * distH,
            params
        )
        if hitHorizontal then
            -- Tem parede no caminho: rejeita
            continue
        end

        -- 4) Verifica se o spawn esta dentro de uma parede (raycast das 4 direcoes)
        local dentroParede = false
        for _, dir in ipairs({
            Vector3.new(2, 0, 0), Vector3.new(-2, 0, 0),
            Vector3.new(0, 0, 2), Vector3.new(0, 0, -2),
        }) do
            local hit = workspace:Raycast(pos + Vector3.new(0, 1, 0), dir, params)
            if hit and hit.Distance < 2 then
                dentroParede = true
                break
            end
        end
        if dentroParede then continue end

        table.insert(candidatos, pos)
        if #candidatos >= 5 then break end
    end

    if #candidatos > 0 then
        return candidatos[math.random(1, #candidatos)]
    end

    -- Fallback SEGURO: na altura do proprio jogador
    local ang = math.random() * math.pi * 2
    local dist = math.random(distMin, distMax)
    return origem + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)
end

-- ============================================================
-- 6. SPAWN DOS 5 CARACOIS
-- ============================================================
local caracois = {}

for i = 1, TOTAL_CARACOIS do
    -- Snails spawnam mais longe: entre 50 e 90 studs do jogador
    local pos = acharSpawn(50, 90)
    local model, primary = criarCaracol(pos)
    local caracol = {
        model = model,
        primary = primary,
        coletado = false,
        velocidade = 3 + math.random() * 2,  -- 3 a 5 studs/s
        direcao = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit,
        centroSpawn = pos,
        rotacaoAtual = CFrame.new(pos),
    }
    table.insert(caracois, caracol)
    print("[Caracois] Caracol " .. i .. " spawnado em: " .. tostring(pos))
end

-- ============================================================
-- 7. MOVIMENTO + ROTACAO + COLISAO COM PAREDES
-- ============================================================
task.spawn(function()
    while ativo do
        for _, c in ipairs(caracois) do
            if not c.coletado and c.model.Parent then
                -- Muda direcao de vez em quando
                if math.random() < 0.03 then
                    local ang = math.random() * math.pi * 2
                    c.direcao = Vector3.new(math.cos(ang), 0, math.sin(ang))
                end

                -- Limita pra nao fugir demais (volta pro centro se passar de 50 studs)
                local distCentro = (c.primary.Position - c.centroSpawn).Magnitude
                if distCentro > 50 then
                    c.direcao = (c.centroSpawn - c.primary.Position).Unit
                end

                -- Distancia que vai mover neste frame
                local distanciaMovimento = c.velocidade * 0.1

                -- Verifica colisao com parede (raycast na direcao do movimento)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { c.model }

                local rayOrigin = c.primary.Position + Vector3.new(0, 1, 0)
                local rayDir = c.direcao * (distanciaMovimento + 2)  -- margem de seguranca
                local hit = workspace:Raycast(rayOrigin, rayDir, params)

                if hit then
                    -- Bateu na parede: REBATE a direcao usando a normal da parede
                    local normal = hit.Normal
                    normal = Vector3.new(normal.X, 0, normal.Z).Unit
                    c.direcao = (c.direcao - 2 * c.direcao:Dot(normal) * normal).Unit
                    -- Pequeno empurrao pra fora da parede
                    c.model:TranslateBy(normal * 0.5)
                else
                    -- Caminho livre: move normalmente
                    c.model:TranslateBy(c.direcao * distanciaMovimento)
                end

                -- Rotaciona o modelo pra olhar na direcao do movimento
                local alvoPos = c.primary.Position + c.direcao
                local novaCFrame = CFrame.lookAt(c.primary.Position, alvoPos)
                local atual = c.primary.CFrame
                local nova = atual:Lerp(novaCFrame, 0.15)
                c.model:PivotTo(CFrame.new(c.primary.Position) * (nova - nova.Position))
            end
        end
        task.wait(0.1)
    end
end)

-- ============================================================
-- 8. SISTEMA DE COLETA
-- ============================================================
task.spawn(function()
    while ativo do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, c in ipairs(caracois) do
                    if not c.coletado and c.model.Parent then
                        local dist = (hrp.Position - c.primary.Position).Magnitude
                        if dist < 5 then
                            c.coletado = true
                            coletados += 1
                            atualizarContador()

                            -- Efeito de coleta: crescer e sumir
                            for _, p in ipairs(c.model:GetDescendants()) do
                                if p:IsA("BasePart") then
                                    task.spawn(function()
                                        for i = 1, 12 do
                                            p.Transparency = i / 12
                                            p.Size = p.Size * 1.08
                                            task.wait(0.025)
                                        end
                                    end)
                                end
                            end
                            task.delay(0.5, function()
                                if c.model.Parent then c.model:Destroy() end
                            end)

                            -- Som de coleta (coin do Subway Surfers)
                            local beep = coinSound:Clone()
                            beep.Parent = workspace
                            beep:Play()
                            task.delay(1.5, function() beep:Destroy() end)

                            -- Fim?
                            if coletados >= TOTAL_CARACOIS then
                                ativo = false
                                jogoAtivo = false  -- para o timer tambem
                                som:Stop()

                                -- Mensagem de vitoria
                                local msg = Instance.new("TextLabel")
                                msg.Size = UDim2.new(0, 600, 0, 90)
                                msg.Position = UDim2.new(0.5, -300, 0.4, 0)
                                msg.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
                                msg.BackgroundTransparency = 0.1
                                msg.Font = Enum.Font.GothamBlack
                                msg.TextSize = 28
                                msg.TextColor3 = Color3.fromRGB(255, 255, 255)
                                msg.Text = "VOCE COLETOU TODOS OS CARACOIS!"
                                msg.ZIndex = 20
                                msg.Parent = gui
                                local mc = Instance.new("UICorner")
                                mc.CornerRadius = UDim.new(0, 16)
                                mc.Parent = msg
                                task.delay(5, function() msg:Destroy() end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

print("[Caracois] Script iniciado! Colete os " .. TOTAL_CARACOIS .. " caracois para parar a sirene.")
