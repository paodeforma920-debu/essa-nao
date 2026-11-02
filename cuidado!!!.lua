--[[
    Script EXECUTOR - Caracois da Sirene (v2)
    ------------------------------------------
    * Toca a sirene de alerta em LOOP
    * Spawn 5 caracois no mapa que se movem bem lentamente
    * A tela pisca em vermelho
    * Contador na tela: "VERIFIQUE OS CARACOIS"  X / 5
    * A GUI treme (tremer) enquanto nao coletar todos
    * O jogador coleta os caracois passando por cima
    * Quando coletar todos: som PARA, vermelho some, tremor para
]]--

local URL = "https://www.myinstants.com/media/sounds/alerta-sirena.mp3"
local ARQUIVO = "alerta_sirena.mp3"
local TOTAL_CARACOIS = 5

-- ============================================================
-- 1. CARREGA O SOM
-- ============================================================
local function carregarSom()
    local data = game:HttpGet(URL)
    writefile(ARQUIVO, data)

    local function tenta(nome, fn)
        local ok, res = pcall(fn)
        if ok and res then print("[Caracois] Som carregado via: " .. nome) return res end
        return nil
    end

    return tenta("getcustomasset", function()
        local s = Instance.new("Sound")
        s.SoundId = getcustomasset(ARQUIVO)
        return s
    end) or tenta("getsynasset", function()
        local s = Instance.new("Sound")
        s.SoundId = getsynasset(ARQUIVO)
        return s
    end) or tenta("loadaudio", function()
        local id = loadaudio(ARQUIVO)
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. tostring(id)
        return s
    end)
end

local somOk, som = pcall(carregarSom)
if not somOk or not som then
    warn("[Caracois] Nao consegui carregar o som. Continuando mesmo assim...")
    som = Instance.new("Sound")  -- sound vazio, so pra nao quebrar
end
som.Name = "SireneLoop"
som.Volume = 1
som.Looped = true
som.Parent = workspace
som:Play()

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
contadorFrame.Size = UDim2.new(1, 0, 1, 0)
contadorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
contadorFrame.BackgroundTransparency = 0.1
contadorFrame.BorderSizePixel = 0
contadorFrame.Parent = shakeContainer

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
-- 5. ACHAR SPAWN NO CHAO
-- ============================================================
local function acharSpawn(raio)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local origem = hrp.Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }

    for _ = 1, 60 do
        local ang = math.random() * math.pi * 2
        local dist = raio + math.random() * 20
        local alvo = origem + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)

        local result = workspace:Raycast(
            alvo + Vector3.new(0, 80, 0),
            Vector3.new(0, -150, 0),
            params
        )
        if result then
            return result.Position
        end
    end

    -- Fallback: spawn na posicao do proprio jogador + offset
    return origem + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
end

-- ============================================================
-- 6. SPAWN DOS 5 CARACOIS
-- ============================================================
local caracois = {}

for i = 1, TOTAL_CARACOIS do
    local pos = acharSpawn(20 + i * 8)
    local model, primary = criarCaracol(pos)
    local caracol = {
        model = model,
        primary = primary,
        coletado = false,
        velocidade = 0.4 + math.random() * 0.3,  -- bem lento
        direcao = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit,
        centroSpawn = pos,
    }
    table.insert(caracois, caracol)
    print("[Caracois] Caracol " .. i .. " spawnado em: " .. tostring(pos))
end

-- ============================================================
-- 7. MOVIMENTO LENTO (move partes via CFrame, mantendo relativo)
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

                -- Move o modelo inteiro (PrimaryPart + offset relativo)
                local delta = c.direcao * c.velocidade * 0.2  -- bem lento
                c.model:TranslateBy(delta)

                -- Limita pra nao fugir demais (volta pro centro se passar de 60 studs)
                local distCentro = (c.primary.Position - c.centroSpawn).Magnitude
                if distCentro > 60 then
                    c.direcao = (c.centroSpawn - c.primary.Position).Unit
                end
            end
        end
        task.wait(0.2)
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

                            -- Som de coleta
                            local beep = Instance.new("Sound")
                            beep.SoundId = "rbxassetid://322911410"
                            beep.Volume = 0.6
                            beep.Parent = workspace
                            beep:Play()
                            task.delay(1.5, function() beep:Destroy() end)

                            -- Fim?
                            if coletados >= TOTAL_CARACOIS then
                                ativo = false
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
