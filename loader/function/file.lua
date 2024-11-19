local func = {}

function func:delfile(path)
	assert(typeof(path) == "string", "Unable to concat: " .. tostring(path) .. " not string")
	if isfile(path) then
		repeat
			delfile(path)
			task.wait()
		until not isfile(path)
	end
end

function func:delfolder(path)
	assert(typeof(path) == "string", "Unable to concat: " .. tostring(path) .. " not string")
	if isfolder(path) then
		repeat
			delfolder(path)
			task.wait()
		until not isfolder(path)
	end
end

function func:makefolder(path)
	assert(typeof(path) == "string", "Unable to concat: " .. tostring(path) .. " not string")
	local j = {}
	local b = {
		path
	}
	if path:find("/") then
		b = path:split("/")
	end
	for i = 1, # b do
		j[i] = table.concat(b, "/", 1, i)
	end
	for i = 1, # j do
		local s = j[i]
		if not isfolder(s) then
			makefolder(s)
		end
	end
end

function func:writefile(path, value)
	assert(typeof(path) == "string", "Unable to concat: " .. tostring(path) .. " not string")
	assert(typeof(value) == "string" or typeof(value) == "table", "Unable to concat: " .. tostring(value) .. " with " .. typeof(value))
	local j = path
	local b = {}
	if path:find("/") then
		j = ""
		b = path:split("/")
	end
	for i = 1, # b do
		if i ~= # b then
			j = j .. b[i] .. "/"
		else
			j = j:sub(1, tonumber(# j - 1))
		end
	end
	makefolder(j)
	if not isfile(path) then
		repeat
			writefile(path, typeof(value) == "table" and game:GetService("HttpService"):JSONEncode(value) or value or "")
			task.wait()
		until isfile(path)
	end
end

function func:readfile(path, type)
	assert(typeof(path) == "string", "Unable to concat: " .. tostring(path) .. " not string")
	if isfile(path) then
		return typeof(type) == "table" and game:GetService("HttpService"):JSONDecode(readfile(path)) or readfile(path)
	end
end

function func:listfiles(path, type)
	assert(typeof(path) == "string", "Unable to concat: " .. tostring(path) .. " not string")
	local t = {}
	local n = nil
	for i, v in next, listfiles(path) do
		if v:sub(1, 1) == "." then
			n = v:sub(2, #v)
		end
		if (n or v):find("/") then
			n = (n or v):gsub("/", "")
		end
		if (n or v):find([[\]]) then
			n = (n or v):gsub([[\]], "")
		end
		if type and type == "lua" and (n or v:find(".lua")) then
			if (n or v):sub(tonumber(#n - 3), tonumber(#n)) == ".lua" then
				n = (n or v):sub(1, tonumber(#n - 4))
			end
		end
		if type and type == "json" and (n or v):find(".json") then
			if (n or v):sub(tonumber(#n - 4), tonumber(#n)) == ".json" then
				n = (n or v):sub(1, tonumber(#n - 5))
			end
		end
		local l = path:gsub("/", "")
		n = (n or v):gsub(l, "")
		table.insert(t, n or v)
	end
	return t
end

function func:filelocation(path, value, place)
	return string.format(path and path or "CrazyDay/" .. tostring(place) .. "/Macro/%s.json", value)
end

return func
