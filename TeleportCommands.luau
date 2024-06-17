--[==[
    EasternBloxxer
    Astra Defense Network
--]==]
server = nil
service = nil

local places = {
	Crossroads = { PlaceId = 1818 };
	-- Example = { PlaceId = 1; Hidden = true };
}

return function()
	local Functions = server.Functions
	for name,place in pairs(places) do
		server.Commands[name] = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {string.lower(name)};
			Args = {};
			Description = "Teleports to a facility";
			Hidden = place.Hidden or false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Functions.Message(`Teleport`, `You are teleporting to {name}`, {plr}, true)
				service.TeleportService:TeleportAsync(place.PlaceId, {plr})
			end
		}
	end
end
