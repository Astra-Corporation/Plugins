--!nolint UnknownGlobal
--[[
    Server-AdonisWebhookLogs
    Author: crywink / Samuel#0440
    Modified by Ender / Ender#2345
    I'm by no means an amazing scripter so if you find anything that could be imrpvoed feel free to do so.
  Whacky code. I recommend  using https://github.com/Epix-Incorporated/Adonis-Plugins/blob/master/Server/Server-DiscordWebhookLogs.lua
--]]


-- Services
local HttpService = game:GetService("HttpService")

-- Variables
local Settings = {
	Webhook = ""; -- Replace with your webhook link. (MAKE SURE YOU KEEP THE QUOTES AND USE A PROXY (NOT A DISCORD.COM LINK!))
	RunForGuests = false; -- Set to true if you want guests (players without admin) commands to be logged.
	Ignore = {}; -- Commands you want ignored. Example: {":fly", ":speed"}
}

--//Garbage scripting below
Asset = {Name = "Something probably went wrong while getting the name lol"}
local PrivateServerId = game.PrivateServerId
local PrivateServerOwnerId = game.PrivateServerOwnerId
local RunService = game:GetService("RunService")
local function FindInArray(arr, obj)
	for i = 1, #arr do
		if arr[i] == obj then
			return i
		end
	end
	return nil
end
local function GetJob()
	if RunService:IsServer() then
		return tostring(game.JobId)
	elseif RunService:IsStudio() then
		return "Test Server"
	else
		return "Failed to get jobid"
	end
end


if game:GetService("RunService"):IsStudio() then
	ServerType = "Studio"
else
	if PrivateServerId ~= "" then
		if PrivateServerOwnerId ~= 0 then
			ServerType = "Private"
		else
			ServerType = "Reserved"
		end
	else
		ServerType = "Standard"
	end
end
return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service

	local Admin = server.Admin


	service.Events.CommandRan:Connect(function(plr, data)
		local unixtime = os.time()
		local msg = data.Message;
		local cmd = data.Matched;
		local args = data.Args;
		local admincount = 0
		local num = 0
		local TextService = game:GetService("TextService")
		local FilterMessage = TextService:FilterStringAsync(msg,plr.UserId)
		if FindInArray(Settings.Ignore, cmd:lower()) then
			return
		end
		pcall(function() Asset = game:GetService("MarketplaceService"):GetProductInfo(tostring(game.PlaceId)) end)
		local pLevel = data.PlayerData.Level
		local Level = server.Admin.LevelToListName(pLevel)
		if Level or (not Level and Settings.RunForGuests) then
			for i,v in pairs(service.GetPlayers()) do
				local level, rank = Admin.GetLevel(v);
				num += 1
				if level > 0 then
					admincount +=1
				end
			end

			local data = {
				["content"] = "",
				["embeds"] = {{
					["title"] = "Command Logs", 
					["color"] = 0001, 
					["fields"] = {
						{
							["name"] = "Place",
							["value"] = tostring(Asset.Name or "Failed to fetch game name!")
						},
						{
							["name"] = "Player",
							["value"] = plr.Name or "Server";
							["inline"] = true
						},

						{
							["name"] = "Admin Level", 
							["value"] = Level or "Guest" ;
							["inline"] = true
						},
						{
							["name"] = "Command", 
							["value"] = tostring(FilterMessage:GetNonChatStringForUserAsync(plr.UserId) or "Something went wrong while getting the filtered text");
						},

						{
							["name"] = "Players",
							["value"] = num.."/"..game.Players.MaxPlayers,
							["inline"] = true
						},
						{
							["name"] = "Admins in-game",
							["value"] = admincount.."/"..game.Players.MaxPlayers,
							["inline"] = true
						},
						{
							["name"] = "Time",
							["value"] = "<t:"..unixtime..":R>",
							["inline"] = true
						},
						{
							["name"] = "Server Type",
							["value"] = tostring(ServerType),
							["inline"] = true
						}


					},
					["footer"] = {
						--you can change this to something ill just remove it for now ["icon_url"] = "https://media.discordapp.net/attachments/792746291184271390/871104702929063946/unknown-191.png", -- optional
						["text"] = GetJob().." | Adonis"
					}
				}

				}
			}
			local jsonData = HttpService:JSONEncode(data)
			HttpService:PostAsync(Settings.Webhook, jsonData)
		end
	end)
end
