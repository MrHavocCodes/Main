local _readfile = readfile or (debug and debug.readfile) or function() end
local _listfiles = listfiles or (debug and debug.listfiles) or function() end
local _writefile = writefile or (debug and debug.writefile) or function() end
local _makefolder = makefolder or (debug and debug.makefolder) or function() end
local _isfolder = isfolder or (debug and debug.isfolder) or function() end
local _delfolder = delfolder or (debug and debug.delfolder) or function() end
local _delfile = delfile or (debug and debug.delfile) or function() end
local _isfile = isfile or (debug and debug.isfile) or function() end

local HttpService = game:GetService("HttpService")

local FileManager = {}

function FileManager:GetFolder(VAL)
	if not _isfolder(VAL) then _makefolder(VAL) end
end

function FileManager:DeleteFolder(VAL)
	if _isfolder(VAL) then _delfolder(VAL) end
end

function FileManager:GetFile(VAL, data)
	if not _isfile(VAL) then
		_writefile(VAL, type(data) == "table" and HttpService:JSONEncode(data) or (data or ""))
	end
end

function FileManager:WriteFile(VAL, data)
	_writefile(VAL, type(data) == "table" and HttpService:JSONEncode(data) or (data or ""))
end

function FileManager:DeleteFile(VAL)
	if _isfile(VAL) then _delfile(VAL) end
end

function FileManager:ReadFile(VAL, format)
	if _isfile(VAL) then
		local raw = _readfile(VAL)
		return format == "table" and HttpService:JSONDecode(raw) or raw
	end
end

function FileManager:ListFiles(VAL, format)
	local out = {}
	for _, path in next, _listfiles(VAL) do
		local name = path:match("[^/\\]+$")
		if format == "json" and name:match("%.json$") then
			name = name:sub(1, -6)
		elseif format == "lua" and name:match("%.lua$") then
			name = name:sub(1, -5)
		end
		table.insert(out, name or path)
	end
	return out
end

return FileManager
