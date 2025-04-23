local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local DataService = Knit.CreateService{
	Name = 'DataService',
	Client = {}
}

--//Game Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")

--//Modules
local ProfileService = require(ServerScriptService.Server.ProfileService)
local Maid = require(ReplicatedStorage.Shared.lib.Maid)

--//Variable
local ProfileStore

--//Tables
local defaultData = {
	--//Main data.
	["Gems"] = 0,
    ["Level"] = 1,
    ["XP"] = 0,

}
local profiles = {}

--//Services & Controllers

function DataService:KnitInit()
	ProfileStore = ProfileService.GetProfileStore("MainData",defaultData)
end

function DataService:KnitStart()
	--//Player is joining.
	
	local function playerAdded(player)
		--//Load player's profile.
		local profile = ProfileStore:LoadProfileAsync("PlrData" .. player.UserId)
		if profile then
			local function loadDataAttributes()
				local attributeChangesMaid = Maid.new()
				
				--//Loading player attributes.
				for data,value in pairs(defaultData) do
					if typeof(value) ~= "table" then
						player:SetAttribute(data, profile.Data[data])
						attributeChangesMaid:GiveTask(player:GetAttributeChangedSignal(data):Connect(function()
							profile.Data[data] = player:GetAttribute(data)
						end))
					else
						for data2,value2 in pairs(value) do
							if typeof(value2) ~= "table" then
								player:SetAttribute(data2, profile.Data[data][data2])
								attributeChangesMaid:GiveTask(player:GetAttributeChangedSignal(data2):Connect(function()
									profile.Data[data][data2] = player:GetAttribute(data2)
								end))
							end
						end
					end
				end
			end
			
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			
			loadDataAttributes()
			
			profile:ListenToRelease(function()
				profiles[player] = nil
				player:Kick("Uh oh! It appears that you have multiple clients open. Please close all clients and rejoin the game.")
			end)

			if player:IsDescendantOf(Players) then
				profiles[player] = profile
			else
				profile:Release()
			end
		else
			player:Kick("Uh oh! We failed to load your data. Please rejoin the game.")
		end
	end

    --//In case players join the server earlier than this script ran.
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(playerAdded, player)
	end
	
	--//Load player profile upon joining.
	Players.PlayerAdded:Connect(playerAdded)

    --//Release player profile upon leaving.
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile ~= nil then
			profile:Release()
		end
	end)
end

function DataService:GetProfiles()
	return profiles
end

function DataService:GetDefaultData()
	return defaultData
end

function DataService:GetProfileData(player)
	local attempts = 0
	repeat
		attempts += 1
		if profiles[player] and profiles[player]["Data"] then
			return profiles[player]["Data"]
		end
		task.wait(0.5)
	until profiles[player] and profiles[player]["Data"] or attempts >= 10

	if profiles[player] and profiles[player]["Data"] then
		return profiles[player]["Data"]
	end
end

function DataService.Client:GetProfileData(player)
	return self.Server:GetProfileData(player)
end

return DataService