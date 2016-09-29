-- inmation.HTTP-Client
-- inmation Script Library Lua Script
--
-- inmation BNX
--
-- Version history:
--
-- 20160104.1       Initial release.
-- 20160302.2       Check whether the response Content-Type is application/json.
--
local http = require("socket.http")
local ltn12 = require("ltn12")

-- Script library dependencies
local json = require("json")

--http.TIMEOUT = 10

HTTPClient = {
    JSON = {},
	MethodName = {
        GET = "GET",
	    POST = "POST",
	    PUT = "PUT"
    },
    HeaderName = {
        Authorization = "authorization",
        ContentLength = "content-length",
        ContentType = "content-type",
        GrantType = "grant_type"
    },
    HeaderValue = {
        ApplicationJSON = "application/json",
        ClientCredentials = "client_credentials"
    }
}

HTTPClient.__index = HTTPClient

function HTTPClient:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, HTTPClient)

    HTTPClient.JSON = json

    return o
end

-- Result response result, code and JSON
function HTTPClient:method(method, url, body, headers)
    local reqbody = ""
    if headers == nil then headers = {} end
    local requestContentType = headers[HTTPClient.HeaderName.ContentType]
    local requestContentIsJSON = false
    if requestContentType then
        requestContentIsJSON = string.find(requestContentType, HTTPClient.HeaderValue.ApplicationJSON) ~= nil
    end
    
	if body ~= nil and body ~= '' then
        if requestContentIsJSON then
		    reqbody = HTTPClient.JSON:encode(body)
        else
            reqbody = body
        end
	end
	
    headers[HTTPClient.HeaderName.ContentLength] = string.len(reqbody)
    
    local respbody = {}
    local  response, code, headers = http.request {
        method = method,
        url = url,
		source = ltn12.source.string(reqbody),
        headers = headers,
        sink = ltn12.sink.table(respbody)
    }

	local respData = ""
    
    -- Note: response header is in lowercase.
    local responseContentIsJSON = false
    if headers then
        local responseContentType = headers[HTTPClient.HeaderName.ContentType]
        if responseContentType then
            responseContentIsJSON = string.find(responseContentType, HTTPClient.HeaderValue.ApplicationJSON) ~= nil
        end
    end
    
	if response and respbody ~= nil and respbody ~= '' then
        if responseContentIsJSON then
            local jsonString = table.concat(respbody)
            respData = HTTPClient.JSON:decode(jsonString)
        else
            respData = respbody
        end
	end

	if response == nil then response = 0 end
	if code == nil then code = 0 end

    return response, code, responseContentIsJSON, respData
end

function HTTPClient:get(url, headers)
	return HTTPClient:method(HTTPClient.MethodName.GET, url, '', headers)
end

function HTTPClient:post(url, body, headers)
	return HTTPClient:method(HTTPClient.MethodName.POST, url, body, headers)
end

function HTTPClient:put(url, body, headers)
	return HTTPClient:method(HTTPClient.MethodName.PUT, url, body, headers)
end

return HTTPClient