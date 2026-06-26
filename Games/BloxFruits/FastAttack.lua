loadstring(game:HttpGet("https://raw.githubusercontent.com/LurnaiHub/Main/refs/heads/main/BloxFruits/Funcs/HittingFast.lua"))()

local RS           = game:GetService("ReplicatedStorage")
local Players      = game:GetService("Players")
local RunSvc       = game:GetService("RunService")
local VIM          = game:GetService("VirtualInputManager")
local WS           = game:GetService("Workspace")

local lp           = Players.LocalPlayer
local Mods         = RS:WaitForChild("Modules")
local Net          = Mods:WaitForChild("Net")
local HitRE        = Net:WaitForChild("RE/RegisterHit")
local AttackRE     = Net:WaitForChild("RE/RegisterAttack")
local ShootRE      = Net:WaitForChild("RE/ShootGunEvent")
local Validator    = RS:WaitForChild("Remotes"):WaitForChild("Validator2")

local Cfg = {
    Range         = 65,
    HitMobs       = true,
    HitPlayers    = true,
    Cooldown      = 0.2,
    ComboReset    = 0.3,
    MaxCombo      = 4,
    Limbs         = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"},
    AutoClick     = true,
}

local State = {
    lastSwing    = 0,
    lastShot     = 0,
    lastComboTick= 0,
    combo        = 0,
    firstTarget  = nil,
    conns        = {},
    overheat     = {
        Dragonstorm = { max=3, cd=0, total=0, dist=350, active=false }
    },
    shotsPerGun  = { ["Dual Flintlock"]=2 },
    specialGuns  = { ["Skull Guitar"]="TAP", ["Bazooka"]="Position", ["Cannon"]="Position", ["Dragonstorm"]="Overheat" },
}

pcall(function()
    State.combatFlags = require(Mods.Flags).COMBAT_REMOTE_THREAD
    State.shootFn     = getupvalue(require(RS.Controllers.CombatController).Attack, 9)
    local ls = lp:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
    if ls and getsenv then
        State.hitFn = getsenv(ls)._G.SendHitsToServer
    end
end)

local function isAlive(model)
    local hum = model and model:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function checkStun(char, hum, tip)
    local stun = char:FindFirstChild("Stun")
    local busy = char:FindFirstChild("Busy")
    if hum.Sit and (tip=="Sword" or tip=="Melee" or tip=="Blox Fruit") then return false end
    if stun and stun.Value > 0 then return false end
    if busy and busy.Value then return false end
    return true
end

local function getNearby(char, dist)
    dist = dist or Cfg.Range
    local origin = char:GetPivot().Position
    local hits = {}
    State.firstTarget = nil

    local function scan(folder)
        for _, e in ipairs(folder:GetChildren()) do
            if e ~= char and isAlive(e) then
                local limb = e:FindFirstChild(Cfg.Limbs[math.random(#Cfg.Limbs)]) or e:FindFirstChild("HumanoidRootPart")
                if limb and (origin - limb.Position).Magnitude <= dist then
                    if not State.firstTarget then
                        State.firstTarget = limb
                    else
                        table.insert(hits, {e, limb})
                    end
                end
            end
        end
    end

    if Cfg.HitMobs    then scan(WS.Enemies) end
    if Cfg.HitPlayers then scan(WS.Characters) end
    return hits
end

local function getClosest(char, dist)
    local hits = getNearby(char, dist)
    local origin = char:GetPivot().Position
    local best, bestDist = nil, math.huge
    for _, h in ipairs(hits) do
        local d = (origin - h[2].Position).Magnitude
        if d < bestDist then bestDist = d; best = h[2] end
    end
    return best
end

local function tickCombo()
    local now = tick()
    local c = (now - State.lastComboTick) <= Cfg.ComboReset and State.combo or 0
    c = c >= Cfg.MaxCombo and 1 or c + 1
    State.lastComboTick = now
    State.combo = c
    return c
end

local function calcValidator()
    local fn = State.shootFn
    local v1=getupvalue(fn,15) local v2=getupvalue(fn,13) local v3=getupvalue(fn,16)
    local v4=getupvalue(fn,17) local v5=getupvalue(fn,14) local v6=getupvalue(fn,12)
    local v7=getupvalue(fn,18)
    local a = v6*v2
    local b = (v5*v2 + v6*v1) % v3
    b = (b*v3 + a) % v4
    v5 = math.floor(b/v3)
    v6 = b - v5*v3
    v7 = v7+1
    setupvalue(fn,15,v1) setupvalue(fn,13,v2) setupvalue(fn,16,v3)
    setupvalue(fn,17,v4) setupvalue(fn,14,v5) setupvalue(fn,12,v6)
    setupvalue(fn,18,v7)
    return math.floor(b/v4*16777215), v7
end

local function shootAt(pos)
    local char = lp.Character
    if not isAlive(char) then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.ToolTip ~= "Gun" then return end
    local cd = tool:FindFirstChild("Cooldown") and tool.Cooldown.Value or 0.3
    if tick() - State.lastShot < cd then return end
    local stype = State.specialGuns[tool.Name] or "Normal"
    if stype == "Position" or (stype == "TAP" and tool:FindFirstChild("RemoteEvent")) then
        tool:SetAttribute("LocalTotalShots", (tool:GetAttribute("LocalTotalShots") or 0) + 1)
        Validator:FireServer(calcValidator())
        if stype == "TAP" then
            tool.RemoteEvent:FireServer("TAP", pos)
        else
            ShootRE:FireServer(pos)
        end
    else
        VIM:SendMouseButtonEvent(0,0,0,true,game,1)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0,0,0,false,game,1)
    end
    State.lastShot = tick()
end

local function swingMelee(char, hum, cd)
    State.firstTarget = nil
    local hits = getNearby(char)
    if State.firstTarget then
        AttackRE:FireServer(cd)
        if State.combatFlags and State.hitFn then
            State.hitFn(State.firstTarget, hits)
        else
            HitRE:FireServer(State.firstTarget, hits)
        end
    end
end

local function fruitM1(char, tool, combo)
    local hits = getNearby(char)
    if not hits[1] then return end
    local dir = (hits[1][2].Position - char:GetPivot().Position).Unit
    tool.LeftClickRemote:FireServer(dir, combo)
end

local function doAttack()
    if not Cfg.AutoClick then return end
    if tick() - State.lastSwing < Cfg.Cooldown then return end
    local char = lp.Character
    if not char or not isAlive(char) then return end
    local hum  = char.Humanoid
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local tip = tool.ToolTip
    if not table.find({"Melee","Blox Fruit","Sword","Gun"}, tip) then return end
    local cd = tool:FindFirstChild("Cooldown") and tool.Cooldown.Value or Cfg.Cooldown
    if not checkStun(char, hum, tip) then return end
    local combo = tickCombo()
    cd = cd + (combo >= Cfg.MaxCombo and 0.05 or 0)
    State.lastSwing = combo >= Cfg.MaxCombo and tip ~= "Gun" and (tick()+0.05) or tick()
    if tip == "Blox Fruit" and tool:FindFirstChild("LeftClickRemote") then
        fruitM1(char, tool, combo)
    elseif tip == "Gun" then
        local closest = getClosest(char, 120)
        if closest then shootAt(closest.Position) end
    else
        swingMelee(char, hum, cd)
    end
end

table.insert(State.conns, RunSvc.Stepped:Connect(doAttack))

for _, v in pairs(getgc(true)) do
    if typeof(v)=="function" and iscclosure(v) then
        local n = debug.getinfo(v).name
        if n=="Attack" or n=="attack" or n=="RegisterHit" then
            hookfunction(v, function(...)
                doAttack()
                return v(...)
            end)
        end
    end
end

local function quickGetHits()
    local out = {}
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return out end
    for _, folder in ipairs({WS.Enemies, WS.Characters}) do
        for _, e in ipairs(folder:GetChildren()) do
            if e.Name ~= lp.Name then
                local hrp = e:FindFirstChild("HumanoidRootPart")
                local hum = e:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= 65 then
                    table.insert(out, e)
                end
            end
        end
    end
    return out
end

local function quickAttack()
    local hits = quickGetHits()
    if #hits == 0 then return end
    local args = { nil, {}, nil, "078da341" }
    for i, e in ipairs(hits) do
        AttackRE:FireServer(0)
        if not args[1] then args[1] = e.Head end
        args[2][i] = { e, e.HumanoidRootPart }
    end
    HitRE:FireServer(table.unpack(args))
end

spawn(function()
    while task.wait() do quickAttack() end
end)
