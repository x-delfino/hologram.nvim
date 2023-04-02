local http = require("socket.http")
local fs = require("nviz.utils.fs")

local remote = {}

function remote.is_url(path)
    local scheme = path:match('(.-):.-')
    if scheme == 'https' or scheme == 'http' then
	return true
    else
	return false
    end
end

function remote.download_file(url)
    fs.init_tmp_dir()
    local body, code = http.request(url)
    if not body then error(code) end
    return fs.write_tmp_file(CacheDir .. '/file_XXXXXX', body)
end

return remote
