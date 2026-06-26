local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character
local AR = 60
local remotes = {}
local function registerRemote(child)
	if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
		remotes[child:GetAttribute("Id")] = child
	end
end

local rsFolders = {
	ReplicatedStorage.Util,
	ReplicatedStorage.Common,
	ReplicatedStorage.Remotes,
	ReplicatedStorage.Assets,
	ReplicatedStorage.FX,
}

for _, folder in next, rsFolders do
	for _, child in next, folder:GetChildren() do
		registerRemote(child)
	end
	folder.ChildAdded:Connect(registerRemote)
end

local function getTargetsInRange()
	local targets = {}
	local myHRP = character and character:FindFirstChild("HumanoidRootPart")
	if not myHRP then
		return targets
	end
	for _, folder in ipairs({
		workspace.Enemies,
		workspace.Characters
	}) do
		if not folder then
			continue
		end
		for _, entity in ipairs(folder:GetChildren()) do
			if entity == character then
				continue
			end
			local hrp = entity:FindFirstChild("HumanoidRootPart")
			local humanoid = entity:FindFirstChild("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				if (hrp.Position - myHRP.Position).Magnitude <= AR then
					table.insert(targets, entity)
				end
			end
		end
	end
	return targets
end

task.spawn(function()
	task.wait(0.0001)
	character = player.Character
	while true do
		local targets = getTargetsInRange()
		local tool = character and character:FindFirstChildOfClass("Tool")
		if tool and # targets > 0 then
		end
		task.wait(0.0001)
	end
end)
