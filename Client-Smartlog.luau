client = nil
service = nil
-- The old smartlog UI
-- It should be in the default Ui folder just named Smartlog
-- I did not write this and i dont recommend using it im just uploading it here as a reference and for whoever wants to use the Smartlog plugin on this repo

return function(data)
	local window = client.UI.Make("Window",{
		Name  = "Smartlog";
		Title = "Smartlog";
		Size  = {562, 300};
	})
	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local Remote = client.Remote
	
	local cliSettings = {}
	
	for _, tab in ipairs({
		[1] = tabFrame:NewTab("Commands", {Text = "Usage"}),
		[2] = tabFrame:NewTab("Data", {Text = "Player Data"}),
		[3] = tabFrame:NewTab("Settings", {Text = "Settings"})
		})
	do
		local scroller = tab:Add("ScrollingFrame",{
			List = {};
			ScrollBarThickness = 3;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 30);
			Size = UDim2.new(1, -10, 1, -35);
		})

		local search = tab:Add("TextBox", {
			Position = UDim2.new(0, 5, 0, 5);
			Size = UDim2.new(1, -10, 0, 20);
			BackgroundTransparency = 0.25;
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "";
			PlaceholderText = "Search";
			TextStrokeTransparency = 0.8;
		})

		local function generate()
			local i = 1
			local filter = search.Text
			scroller:ClearAllChildren() 
			for _,c in ipairs(data[tab.Name] or {}) do
				if tab.Name == "Data" then 
					if (c.Text:sub(1, #filter):lower() == filter:lower()) then
						scroller:Add("TextLabel", {
							Text = c.Text;
							ToolTip = c.Desc or "";
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, 0, 0, 30);
							Position = UDim2.new(0, 0, 0, (30*(i-1)));
							TextXAlignment = "Left";
						})
							:Add("TextButton",{
								Text = "Remove";
								BackgroundTransparency = 1;
								Size = UDim2.new(0, 90,0, 30);
								Position = UDim2.new(0.83,0,0,0);
								TextXAlignment = "Left";
								OnClicked = function(button)
									client.Remote.Send("ProcessCommand",`;smartlog remove {c.Text}`)
								end,
							})
						i += 1
					end
					print(tab)
				elseif tab.Name == "Settings" then
					for i, setData in ipairs(cliSettings) do
						local label = scroller:Add("TextLabel", {
							Text = `  {setData.Text}`;
							ToolTip = setData.Desc;
							TextXAlignment = "Left";
							Size = UDim2.new(1, -10, 0, 30);
							Position = UDim2.new(0, 5, 0, i*30+5);
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
						})

						if setData.Entry == "Boolean" then
							label:Add("Boolean", {
								Size = UDim2.new(0, 120, 1, 0);
								Position = UDim2.new(1, -120, 0, 0);
								Enabled = setData.Value;
								OnToggle = setData.Function;
								BackgroundTransparency = 1;
							})
						elseif setData.Entry == "Keybind" then
							label:Add("TextButton", {
								Text = tostring(setData.Value);
								Size = UDim2.new(0, 120, 1, 0);
								Position = UDim2.new(1, -120, 0, 0);
								OnClick = setData.Function;
								BackgroundTransparency = 1;
							})
						elseif setData.Entry == "DropDown" then
							label:Add("Dropdown", {
								Size = UDim2.new(0, 120, 1, 0);
								Position = UDim2.new(1, -120, 0, 0);
								Selected = setData.Value;
								OnSelect = setData.Function;
								Options = setData.Options;
								--BackgroundColor3 = label.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.25);
								BackgroundTransparency = 1;
							})
						end
						i += 1
					end
				elseif tab.Name == "Commands" then 
					if (c.Text:sub(1, #filter):lower() == filter:lower()) then
						scroller:Add("TextLabel", {
							Text = `  {c.Text}  `;
							ToolTip = c.Desc or "";
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, 0, 0, 30);
							Position = UDim2.new(0, 0, 0, (30*(i-1)));
							TextXAlignment = "Left";
						})
						i += 1
					end
				end
				scroller:ResizeCanvas(false, true, false, false, 5, 0)

			end

		end
		search:GetPropertyChangedSignal("Text"):Connect(generate)
		generate()

		task.spawn(function() --// this is horrible (idc about client code peformance)
			while true do
				data = Remote.Get("SmartlogData")
				generate()
				task.wait(3)
			end
		end)
	end

	window:Ready()
end
