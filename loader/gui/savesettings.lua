local httpService = game:GetService("HttpService")

local SaveManager = {} do
	SaveManager.Folder = "CrazyDay"
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = "Toggle", idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = "Slider", idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then
					if table.find(SaveManager.Options[idx].Values, data.value) then
						SaveManager.Options[idx]:SetValue(data.value)
					else
						if not SaveManager.Options[idx].Multi then
							local DataLoaded = SaveManager.Options[idx].Values table.insert(DataLoaded, data.value)
							SaveManager.Options[idx]:SetValues(DataLoaded) SaveManager.Options[idx]:SetValue(data.value)
						else
							local database = {
								old = SaveManager.Options[idx].Values,
								new = {},
								check = {}
							}

							for inx, val in next, data.value do
								table.insert(database.new, inx)
							end
							for num = 1, #database.old do
								if table.find(database.new, database.old[num]) then table.insert(database.check, database.old[num])
								end
							end
							if #database.check == #database.new then
								SaveManager.Options[idx]:SetValue(data.value)
							else
								for num = 1,#database.old do
									if table.find(database.new, database.old[num]) then
										table.remove(database.old, table.find(database.new, database.old[num]))
									end
								end
								for num = 1,#database.new do
									if not table.find(database.old, database.new[num]) then table.insert(database.old, database.new[num])
									end
								end
								SaveManager.Options[idx]:SetValues(database.old)
								SaveManager.Options[idx]:SetValue(data.value)
							end
						end
					end
				end
			end,
		},
		Colorpicker = {
			Save = function(idx, object)
				return { type = "Colorpicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		Keybind = {
			Save = function(idx, object)
				return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.key, data.mode)
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = "Input", idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] and type(data.text) == "string" then
					SaveManager.Options[idx]:SetValue(data.text)
				end
			end,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

	function SaveManager:Save(name)
		if (not name) then
			return false, "no config file is selected"
		end

		local fullPath = self.Folder .. "/" .. name .. ".json"

		local data = {
			objects = {}
		}

		for idx, option in next, SaveManager.Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, "failed to encode data"
		end

		writefile(fullPath, encoded)
		return true
	end

	function SaveManager:Load(name)
		if (not name) then
			return false, "no config file is selected"
		end

		local file = self.Folder .. "/" .. name .. ".json"
		if not isfile(file) then return false, "invalid file" end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then return false, "decode error" end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(
					function()
						if not SaveManager.Options[option.idx] then
							repeat
								task.wait()
							until SaveManager.Options[option.idx]
						end
						self.Parser[option.type].Load(option.idx, option)
					end
				)
			end
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			"InterfaceTheme", "AcrylicToggle", "TransparentSlider", "MenuKeybind" , "BlackScreenToggle"
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
        self.Options = library.Options
	end

	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, "Must set SaveManager.Library")

		local section = tab:AddSection("Configuration")
		section:AddToggle("Auto Save Configuration", {
			Title = "Auto Save",
			Description = nil,
			Default = true
		})
		do
			self:Load("Configuration")
		end

		section:AddButton({
			Title = "Reset Configuration",
			Callback = function()
				self.Library.Window:Dialog(
					{
						Title = "Configuration",
						Content = "Are you sure you want to reset the configuration?",
						Buttons =
						{
							{
								Title = "Yes", Callback = function()
									self.Library.Reseting = true
									for n , c in next, SaveManager.Options do
										if self.Ignore[n] then
											continue
										end
										if c.Type == "Dropdown" and c.Multi then
											local o = {}
											for x = 1,#c.Default do
												o[c.Default[x]] = true
											end
											c:SetValue(o)
										elseif (c.Type == "Dropdown" and not c.Multi) or c.Type == "Toggle" or c.Type == "Slider" or c.Type == "Input" then
											c:SetValue(c.Default)
										elseif c.Type == "Keybind" then
											c:SetValue(c.Default,c.Mode)
										elseif c.Type == "Colorpicker" then
											c:SetValueRGB(c.Default)
										end
									end
								end
							},
							{Title = "No"}
						}
					}
				)
			end
		})

		if setmetatable then
			setmetatable(SaveManager.Options,{
				__newindex = function(t,n,c)
					if not c.Save and c.OnChanged and n ~= "Auto Save Configuration" then
						   c.Save =
						   {
								c:OnChanged(
									function()
										local o = SaveManager.Options
										if o["Auto Save Configuration"] and  not o["Auto Save Configuration"].Value then
										else
											self:Save("Configuration")
										end
									end
								)
						   }
					elseif not c.Save and c.OnChanged and n == "Auto Save Configuration" then
						   c.Save =
						   {
								c:OnChanged(
									function()
										self:Save("Configuration")
									end
								)
						   }
					end
				end
			})
		end

		for n , c in next, SaveManager.Options do
			if self.Ignore[n] then
				continue
			end
			if not c.Save and c.OnChanged and n ~= "Auto Save Configuration" then
				c.Save =
				{
					c:OnChanged(
						function()
							local o = SaveManager.Options
							if o["Auto Save Configuration"] and o["Auto Save Configuration"].Value == false then
							else
								self:Save("Configuration")
							end
						end
					)
				}
			elseif not c.Save and c.OnChanged and n == "Auto Save Configuration" then
				c.Save =
				{
					c:OnChanged(
						function()
							self:Save("Configuration")
						end
					)
				}
			end
		end
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
