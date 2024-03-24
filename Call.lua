--!nonstrict

server = nil
service = nil
Routine = nil
reportedplr = nil
cooldowndata = {}
return function()
	local Admin = server.Admin;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Remote = server.Remote;
	local Variables = server.Variables;
	local HTTP = server.HTTP;
	local Anti = server.Anti;

	local TextService = service.TextService
	local MarketplaceService = service.MarketplaceService
	
	local PrivateServerId = game.PrivateServerId
	local PrivateServerOwnerId = game.PrivateServerOwnerId

	local Asset = { Name = "Failed to fetch Place Info" }
	local placeId = game.PlaceId
	

	--[==[
		As of right now i don't know of any good ways to have a custom UI without editing the
		MainModule. To make this work you have to grab the MainModule and put CallMenu.lua in
		the MainModule -> Client -> UI -> Default
		Rename the module "Server-Call" if you're adding it in the Loader -> Config -> Plugins
		Leave it named as whatever you want if you put it in the MainModule -> Server -> Plugins
		
		You can expect a lot of old and bad code here. A lot of the code is from a very long time ago
		I have rewritten some of it but a lot of things here could still be done better.
		~ Eastern
	]==]
	
	local PluginSettings = {
		CallCooldown = 60 :: number,
		Reasons = {"Exploiting","Spamming","Chat bypassing","Inappropriate behavior","Announcement","Misc"},
		BaseURL = "https://webhook.lewisakura.moe" :: string, --// This will be whatever proxy you use without / obviously
		Webhook = "/api/webhooks/channel_id/token" :: string, --// Webhook goes here
		APIKey = "" :: string,
		--// This can be left blank unless
		--// You are using a custom backend 
		--// That requires api key
	}
	
	pcall(function()
		Asset = MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	
	server.Commands.Call = {
		Prefix = Settings.PlayerPrefix,
		Commands = { "call", "report" },
		Args = {},
		Fun = false,
		Hidden = false,
		Description = "Report a player to moderators",
		AdminLevel = "Players",
		Function = function(plr, args)
			if cooldowndata[plr.UserId] then
				return Remote.MakeGui(plr, "Hint", { Message = "Your call cooldown has not ended!" })
			end

			local Name = plr.Name

			local extras = { "Server" }

			for i, v in service.GetPlayers() do
				local level = Admin.GetLevel(v)
				local name = v.Name

				if level < 100 and name == Name then
					table.insert(extras, name)
				end
			end

			Remote.MakeGui(plr, "CallMenu", { Reasons = PluginSettings.Reasons, Players = extras })
		end,
	};

	server.Commands.ClearCallCooldown = {
		Prefix = Settings.Prefix,
		Commands = { "ClearCooldown" },
		Args = {},
		Fun = false,
		Hidden = false,
		Disabled = true,
		Description = "Clears the cooldown of the current user.",
		AdminLevel = "Admins",
		Function = function(plr, args)
			table.remove(cooldowndata, plr.UserId)
			server.Remote.MakeGui(plr, "Hint", {
				Message = "Your call cooldown has been reset",
			})
		end,
	}
	server.Remote.Commands.SendReport = function(plr, args)
		-- Checking if we have the args before continuing further
		assert(args[1], "Missing player name")
		assert(args[2], "Missing reason")
		assert(args[3], "Missing extra notes")

		--// Variables
		local userId = plr.UserId
		local filtered = TextService:FilterStringAsync(args[2], plr.UserId)
		local extranotes = TextService:FilterStringAsync(args[3], plr.UserId)
		local admins = service.GetPlayers(plr, "admins")
		local InGameAdmins = {}

		--// Main Code
		for i, v in pairs(service.GetPlayers(plr, args[1])) do
			reportedplr = v
			break
		end

		if not reportedplr and args[1] ~= "Server" then
			Anti.Detected(plr,"log",`Attempted to report a player not in the server`)
			return Remote.MakeGui(plr, "Output", {
				Message = "Player you reported is not in the server!",
			})
			
		elseif Admin.GetLevel(reportedplr) > 1 then
			Anti.Detected(plr,"log",`Attempted to report an moderator: {reportedplr.Name}`)
			return Remote.MakeGui(plr, "Output", {
				Message = "No.",
			})
			
		elseif plr.Name and plr.Name == reportedplr.Name then
			return server.Remote.MakeGui(plr, "Output", {
				Message = "You cannot report yourself!",
			})
			
		end

		local EmbedData = {}
		
		EmbedData.title = Asset.Name or "Something went wrong!"
		EmbedData.url = "https://www.roblox.com/games/" .. placeId .. "/redirect"
		EmbedData.description = "["
			.. plr.Name
			.. "](https://www.roblox.com/users/"
			.. plr.UserId
			.. "/profile) has sent in a report\n\n"
		EmbedData.thumbnail = {
			url = "https://www.astracorp.xyz/headshot-thumbnail/image?userId=" 
				.. userId
				.. "&width=420&height=420&format=png",
		}

		EmbedData.fields = {
			{
				name = "Reporting",
				value = "["
					.. reportedplr.Name
					.. "](https://www.roblox.com/users/"
					.. reportedplr.UserId
					.. "/profile)",
			},
			{ name = "Reason", value = filtered:GetNonChatStringForUserAsync(plr.UserId) },
			{ name = "Extra notes", value = extranotes:GetNonChatStringForUserAsync(plr.UserId) },
			{ name = "Join Command", value = `{Settings.Prefix}jplace me {game.JobId}`},
			{
				name = "Join Link",
				value = `https://www.astracorp.xyz/game-launch?placeId={placeId}&jobId={game.JobId}`
			},
			{
				name = "Players",
				value = #service.GetPlayers() or 0 .. "/" .. service.Players.MaxPlayers or 0,
				inline = true,
			},
			{ name = "Time Reported", value = "<t:" .. tostring(os.time()) .. ":R>", inline = true },
			{
				name = "Server type",
				value = tostring(Functions.getServerType() or "Something failed when fetching the server type"),
				inline = true,
			},
		}


		if #admins >= 1 then
			for i, v in ipairs(admins) do
				table.insert(InGameAdmins, `[{v.Name}](https://www.roblox.com/users/{v.UserId}/profile)`)
			end
			table.insert(
				EmbedData.fields,
				{ name = "Admins In-Game", value = table.concat(InGameAdmins, ","), inline = false }
			)
		end

		local Data = {
			["embeds"] = { EmbedData },
		}

		--Core.CrossServer(
		--	"ExploitNotif",
		--	plr.Name,
		--	'<font size="29">From ' .. plr.Name .. "</font><br/>" .. reportedplr.Name .. " - " .. tostring(args[2]),
		--	game.JobId
		--)
		
		local request
		
		local success, msg = pcall(function()
			request = service.HttpService:RequestAsync({
				Url = `{PluginSettings.BaseURL}{PluginSettings.Webhook}`,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["Access-Key"] = PluginSettings.APIKey,
				},
				Body = service.HttpService:JSONEncode(Data),
			})
		end)

		if success then
			if request.StatusCode == 200 then
				cooldowndata[plr.UserId] = true
				server.Remote.MakeGui(plr, "Output", {
					Message = "Your report was successfully sent!",
				})
				table.insert(cooldowndata, plr.UserId)
			else
				server.Remote.MakeGui(plr, "Output", {
					Message = "Something went wrong while sending your call!",
				})
			end
		else
			server.Remote.MakeGui(plr, "Output", {
				Message = "Something went wrong while sending your call!",
			})
		end
		
		Routine(function()
			cooldowndata[plr.UserId] = true
			task.wait(PluginSettings.CallCooldown)
			cooldowndata[plr.UserId] = nil
		end)
	end
end;
