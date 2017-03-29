-- inmation.http-client
-- inmation Script Library Lua Script
--
-- (c) 2016 inmation
--
-- Version history:
--
-- 20170328.6   Lazy loading of the 'ssl.https' library.
-- 20170304.5   Support for dependency injection via options in the HttpClient.new().
-- 20161113.4   Changed Function signature method, get, post, put.
--              Body comes now after headers.
-- 20161020.3   Refactoring;
--              Returns now response header instead of isJson;
--              Added HTTPS support.
-- 20160302.2   Check whether the response Content-Type is application/json.
-- 20160104.1   Initial release.
--

local http = require('socket.http')
local ltn12 = require('ltn12')

-- Script library dependencies
local json = require('json')

--http.TIMEOUT = 10

local HttpClient = {
    http = {},
    https = {},
    json = {},
    ltn12 = {},

	METHOD_NAME = {
        GET = "GET",
	    POST = "POST",
	    PUT = "PUT"
    },

    HEADER_NAME = {
        AUTHORIZATION = "Authorization",
        CONTENT_LENGTH = "Content-Length",
        CONTENT_TYPE = "Content-Type",
    },

    HEADER_VALUE = {
        APPLICATION_JSON = "application/json",
    }
}

HttpClient.__index = HttpClient

-- Public

function HttpClient.new(o, options)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, HttpClient)

    local _options = options or {}
    HttpClient.http = _options.http or http
    HttpClient.https = _options.https
    HttpClient.json = _options.json or json
    HttpClient.ltn12 = _options.ltn12 or ltn12

    return o
end

-- Returns: result, code, data, headers
function HttpClient:method(method, url, headers, reqData)
    if type(headers) ~= 'table' then headers = {} end

    local reqbody = reqData or ''
	if type(reqData) == 'table' then
	    reqbody = self.json:encode(reqData)
        headers[self.HEADER_NAME.CONTENT_TYPE] = self.HEADER_VALUE.APPLICATION_JSON
	end

    headers[self.HEADER_NAME.CONTENT_LENGTH] = string.len(reqbody)

    local protocolLib = self.http
    if string.match(url, '^https:') ~= nil then
        if self.https == nil then self.https = require('ssl.https') end
        protocolLib = self.https
    end

    local respBody = {}
    local  response, code, respHeaders = protocolLib.request {
        method = method,
        url = url,
		source = self.ltn12.source.string(reqbody),
        headers = headers,
        sink = self.ltn12.sink.table(respBody)
    }

    -- Note: response header is in lowercase.
    local isJson_Response = false
    if respHeaders then
        local respContentType = respHeaders[self.HEADER_NAME.CONTENT_TYPE:lower()]
        isJson_Response = string.find(respContentType or '', self.HEADER_VALUE.APPLICATION_JSON:lower()) ~= nil
    end

    local respData = nil
	if response and respBody ~= nil then
        if respBody ~= '' and isJson_Response then
            local jsonString = table.concat(respBody)
            respData = self.json:decode(jsonString)
        else
            respData = respBody
        end
	end

	if response == nil then response = 0 end
	if code == nil then code = 0 end

    return response, code, respData, respHeaders
end

function HttpClient:get(url, headers)
	return self:method(self.METHOD_NAME.GET, url, headers)
end

function HttpClient:post(url, headers, body)
	return self:method(self.METHOD_NAME.POST, url, headers, body)
end

function HttpClient:put(url, headers, body)
	return self:method(self.METHOD_NAME.PUT, url, headers, body)
end

return HttpClient