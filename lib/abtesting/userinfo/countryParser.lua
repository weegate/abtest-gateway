-- countryCode from request_body or uri params by wuyong
local _M = {
    _VERSION = '0.01'
}

local cjson = require('cjson.safe')
local countryCodes = require('abtesting.utils.dict').country_codes

local function getPostArgsFromRequestBody(_str,seperator)

	local substr, pos, args  = "", 0, {}
	for st, sp in function() return string.find(_str, seperator, pos, true) end do
		substr = string.sub(_str,pos,st-1)	
		local _,_,name,value = string.find(substr,"\r\nContent%-Disposition: form%-data; name=\"(.+)\"\r\n\r\n(.*)\r\n")
		if name and value then
			args[name] = value
		end
		pos = sp + 1
	end

	return args
end

_M.get = function()
	local request_method = ngx.var.request_method
	local args = nil
	local countryCode = nil
	if "GET" == request_method then
		args = ngx.req.get_uri_args()
		countryCode = args['countryCode']
	elseif "POST" == request_method then
		local content_type = ngx.req.get_headers()['content-type']
		if string.find(content_type, "application%/x%-www%-form%-urlencoded") then
			args = ngx.req.get_post_args()
		elseif string.find(content_type, "multipart%/form%-data") then
			local boundary = "--" .. string.sub(content_type,31)
			local request_body = ngx.req.get_body_data()
			args  = getPostArgsFromRequestBody(request_body,boundary)
		end

		if args['countryCode'] then
			countryCode = args['countryCode']
		else
			args = ngx.req.get_uri_args()
			countryCode = args['countryCode']
		end
	end
    ngx.log(ngx.DEBUG,"request_method:"..request_method.." data["..cjson.encode(args).."] ",countryCode)

	return countryCode
end

-- get all userinfo
_M.getAll = function()

	return countryCodes
end

return _M
