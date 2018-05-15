-- inmation.http-client
-- inmation Script Library Lua Script
--
-- (c) 2018 inmation
--
-- Version history:
--
-- 20180223.9   Convert response body to string when this is a table.
-- 20180207.8   Supports loading the default present JSON library 'dkjson'.
-- 20170912.7   Refactoring and options (HTTPClient.new({}, options) now supports port, proxy, timeout and useragent.
--              Added support for DELETE method and additional header names and values.
-- 20170328.6   Lazy loading of the 'ssl.https' library.
-- 20170304.5   Support for dependency injection via options in the HTTPClient.new().
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

local present, JSON = pcall(function() return require('dkjson') end)
if present then
    -- Make sure 'dkjson' functions can be called with colon notation, like the Jeffrey Friedl 'json' library.
    local dkjson = JSON
    JSON = {}
    function JSON.decode(_, ...)
        return dkjson.decode(...)
    end
    function JSON.encode(_, ...)
        return dkjson.encode(...)
    end
else
    present, JSON = pcall(function() return require('json') end)
    if not present then
        error("Unable to load JSON library")
    end
end
package.loaded.JSON = JSON


local HEADER_NAME = {
    ACCEPT = "Accept",
    AUTHORIZATION = "Authorization",
    CONTENT_LENGTH = "Content-Length",
    CONTENT_TYPE = "Content-Type"
}

local HEADER_VALUE = {
    APPLICATION_X_WWW_FORM_URLENCODED = "application/x-www-form-urlencoded",
    APPLICATION_JSON = "application/json",
    APPLICATION_XML = "application/xml"
}

local METHOD_NAME = {
    DELETE = "DELETE",
    GET = "GET",
    POST = "POST",
    PUT = "PUT"
}

local HTTPClient = {
    http = nil,
    https = nil,
    ltn12 = nil
}

HTTPClient.HEADER_NAME = HEADER_NAME
HTTPClient.METHOD_NAME = METHOD_NAME
HTTPClient.HEADER_VALUE = HEADER_VALUE

HTTPClient.__index = HTTPClient

-- Public

function HTTPClient.new(o, options)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, HTTPClient)

    local _options = options or {}
    o.http = _options.http or http
    o.https = _options.https
    o.ltn12 = _options.ltn12 or ltn12
    if (_options.port) then o.http.PORT = _options.port end
    if (_options.proxy) then o.http.PROXY = _options.proxy end
    if (_options.timeout) then o.http.TIMEOUT = _options.timeout end
    if (_options.useragent) then o.http.USERAGENT = _options.useragent end

    return o
end

-- Returns: result, code, data, headers
function HTTPClient:method(method, url, headers, reqData)
    if type(headers) ~= 'table' then headers = {} end

    local reqbody = reqData or ''
	if type(reqData) == 'table' then
	    reqbody = JSON:encode(reqData)
        headers[HEADER_NAME.CONTENT_TYPE] = HEADER_VALUE.APPLICATION_JSON
	end

    headers[HEADER_NAME.CONTENT_LENGTH] = string.len(reqbody)

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
        local respContentType = respHeaders[HEADER_NAME.CONTENT_TYPE:lower()]
        isJson_Response = string.find(respContentType or '', HEADER_VALUE.APPLICATION_JSON:lower()) ~= nil
    end

    local respData = nil
    if response and respBody ~= nil then
        if type(respBody) == 'table' then
            respData = table.concat(respBody)
            if respData ~= '' and isJson_Response then
                respData = JSON:decode(respData)
            end
        else
            respData = respBody
        end
	end

	if response == nil then response = 0 end
	if code == nil then code = 0 end

    return response, code, respData, respHeaders
end

function HTTPClient:delete(url, headers)
	return self:method(METHOD_NAME.DELETE, url, headers)
end

function HTTPClient:get(url, headers)
	return self:method(METHOD_NAME.GET, url, headers)
end

function HTTPClient:post(url, headers, body)
	return self:method(METHOD_NAME.POST, url, headers, body)
end

function HTTPClient:put(url, headers, body)
	return self:method(METHOD_NAME.PUT, url, headers, body)
end

return HTTPClient