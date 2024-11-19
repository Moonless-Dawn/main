local httpService = game:GetService("HttpService")

local InterfaceManager = {} do
    InterfaceManager.Folder = "GuiSettings"
    InterfaceManager.Settings = {
        Theme = "Darker",
        Transparency = 0,
        MenuKeybind = "LeftAlt",
        BlackScreen = false
    }

    function InterfaceManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

    function InterfaceManager:SetLibrary(library)
		self.Library = library
	end

    function InterfaceManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split("/")
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, "/", 1, idx)
		end

		table.insert(paths, self.Folder)

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

    function InterfaceManager:SaveSettings()
        writefile(self.Folder .. "/options.json", httpService:JSONEncode(InterfaceManager.Settings))
    end

    function InterfaceManager:LoadSettings()
        local path = self.Folder .. "/options.json"
        if isfile(path) then
            local data = readfile(path)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)

            if success then
                for i, v in next, decoded do
                    if i == "Transparency" and typeof(v) == "boolean" then
                        InterfaceManager.Settings[i] = 0.5
                    else
                        InterfaceManager.Settings[i] = v
                    end
                end
            end
        end
    end

    function InterfaceManager:BuildInterfaceSection(tab)
        assert(self.Library, "Must set InterfaceManager.Library")
		local Library = self.Library
        local Settings = InterfaceManager.Settings

        InterfaceManager:LoadSettings()

		local section = tab:AddSection("Interface")

		local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
			Title = "Theme",
			Description = "Changes the interface theme.",
			Values = Library.Themes,
			Default = Settings.Theme,
			Callback = function(Value)
				Library:SetTheme(Value)
                Settings.Theme = Value
                InterfaceManager:SaveSettings()
			end
		})

        InterfaceTheme:SetValue(Settings.Theme)

        local TransparentSlider = section:AddSlider("TransparentSlider", {
            Title = "Transparency",
            Description = "Makes the interface transparent.",
            Min = 0,
            Max = 1,
            Rounding = 2,
            Default = Settings.Transparency,
            Callback = function(Value)
                Library:ToggleTransparency(tonumber(Value))
                Settings.Transparency = tostring(Value)
                InterfaceManager:SaveSettings()
            end
        })

        section:AddToggle("BlackScreenToggle", {
            Title = "Black Screen",
            Description = "Disable 3DRendering for best performance.",
            Default = Settings.BlackScreen,
            Callback = function (Value)
                Library.Window:Black(Value)
                Settings.BlackScreen = Value
                InterfaceManager:SaveSettings()
            end
        })

		local MenuKeybind = section:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = Settings.MenuKeybind })
		MenuKeybind:OnChanged(function()
			Settings.MenuKeybind = MenuKeybind.Value
            InterfaceManager:SaveSettings()
		end)
		Library.MinimizeKeybind = MenuKeybind
        TransparentSlider:SetValue(Settings.Transparency)
    end
end

return InterfaceManager
