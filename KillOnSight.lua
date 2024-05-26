--[==[
    EasternBloxxer, 8ch_32bit
    Astra Defense Network
    
    TODO: notify only onduty users of that specific subgroup and the user itself (Would require a onduty playerfinder)
    
    Place this in a ModuleScript under Adonis_Loader > Config > Plugins and named "Server-KillOnSight"
--]==]
return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service
	local Core = server.Core
	local Admin = server.Admin
	local Process = server.Process
	local Settings = server.Settings
	local Functions = server.Functions
	local Commands = server.Commands
	local Remote = server.Remote
	local Deps = server.Deps
	local Logs = server.Logs
	local Variables = server.Variables
	local Functions = server.Functions

	local koslist = {
		TMS = {};
		PBST = {};
		PET = {};
	}

	local methods = {
		add = function(p:Player,name:string,list,group) 
			assert(name,"The username is required when adding a KOS!")

			if table.find(list,name) then
				return error('Player is already on KOS!')
			end

			table.insert(list,name)
			Functions.Hint(`{name} is now on {group} KOS!`, service.GetPlayers())
		end,

		remove = function(p:Player,name:string,list) 
			assert(name,"The username is required when removing a KOS!")

			if not table.find(list,name) then
				return error('Player is not on KOS!')
			end

			table.remove(list,list[name])
			
		end,

		clear = function(p:Player, name:string, list) 
			table.clear(list)
		end,
		
		open = function(p:Player,list,group,AutoUpdate)
			Remote.MakeGui(p, "List", {
				Title = `{group} KOS`;
				TextSelectable = true;
				AutoUpdate = AutoUpdate;
				Tab = Logs.ListUpdaters[`view{string.lower(group)}kos`]();
				Update = `view{string.lower(group)}kos`;
			})
		end,
	}

	for name, list in pairs(koslist) do
		local Name = `{name}kos`;

		server.Commands[Name] = {
			Prefix = server.Settings.Prefix;
			Commands = {string.lower(Name)};
			Args = {"method", "optional argument"};
			Description = "Manages a KOS";
			Hidden = false;
			Fun = false;
			AdminLevel = "Mods"; --TODO: Custom permission checks for commands such as group ranks
			Function = function(plr,args)
				local method = string.lower(assert(args[1], "Method argument missing!"));

				local arg = args[2];

				local Method = assert(methods[method], "Invalid method! Valid methods: add/remove/clear")

				Method(plr, arg, list, name);
			end
		}

		server.Commands[`view{string.lower(Name)}`] = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {string.lower(`view{Name}`)};
			Args = {"autoupdate"};
			Description = "View a KOS";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			ListUpdater = function(plr: Player, selection: string?)

				local tab = {
					{
						Text = `{#list} player(s) on {name} KOS`;
					},
					{
						Text = `―――――――――――――――――――――――`;
					}
				}

				for _, v: Player in list do
					table.insert(tab, {
						Text = v;
					})
				end

				return tab
			end;

			Function = function(plr,args)
				local AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
				methods["open"](plr,list,name,AutoUpdate)
			end
		}

	end
end
