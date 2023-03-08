local http = require("socket.http")

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
    local body, code = http.request(url)
    if not body then error(code) end
    return body
end

return remote
