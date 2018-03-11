-- this module like arg_city
local modulename = "abtestingDiversionRequestBodyCountryCode"

local _M    = {}
local mt    = { __index = _M }
_M._VERSION = "0.0.1"

local cjson = require('cjson.safe')
local ERRORINFO	= require('abtesting.error.errcode').info

local countryCodes = require('abtesting.utils.dict').country_codes

local k_countryCode = 'countryCode'
local k_upstream    = 'upstream'

_M.new = function(self, database, policyLib)
    if not database then
        error{ERRORINFO.PARAMETER_NONE, 'need avaliable redis db'}
    end if not policyLib then
        error{ERRORINFO.PARAMETER_NONE, 'need avaliable policy lib'}
    end

    self.database = database
    self.policyLib = policyLib
    return setmetatable(self, mt)
end

--	policy is in format as {{countryCode = 'US', upstream = '192.132.23.125'}}
_M.check = function(self, policy)
    for _, v in pairs(policy) do
        local countryCode = v[k_countryCode]
        local upstream  = v[k_upstream]

        if not countryCode or not upstream then
            local info = ERRORINFO.POLICY_INVALID_ERROR 
            local desc = ' need '..k_countryCode..' and '..k_upstream
            return {false, info, desc}
        end

    end

    return {true}
end

-- use redis hashtable to set
_M.set = function(self, policy)
    local database  = self.database 
    local policyLib = self.policyLib

    database:init_pipeline()
    for _, v in pairs(policy) do
        database:hset(policyLib, v[k_countryCode], v[k_upstream])
    end
    local ok, err = database:commit_pipeline()
    if not ok then 
        error{ERRORINFO.REDIS_ERROR, err} 
    end

end

_M.get = function(self)
    local database  = self.database 
    local policyLib = self.policyLib

    local data, err = database:hgetall(policyLib)
    if not data then 
        error{ERRORINFO.REDIS_ERROR, err} 
    end

    return data
end

_M.getUpstream = function(self, countryCode)
    
    local database	= self.database
    local policyLib = self.policyLib
    local upstream = nil
    
    local data, err = database:hgetall(policyLib)
    if not data then error{ERRORINFO.REDIS_ERROR, err} end
    
    local index = 1
    local country_key = ""
    local div_data = {}
    for _,v in ipairs(data) do
        if(index%2==1) then
            country_key = v
        else
            div_data[country_key] = v
        end
        index = index + 1
    end

    ngx.log(ngx.DEBUG,"redis_policy_division_data:\t"..cjson.encode(div_data))
    -- in redis div data
    if data ~= ngx.null and div_data[countryCode] then
        upstream = div_data[countryCode]
    end

    -- not in redis div data but in countryCode dict
    if upstream == nil then
        for _,v in ipairs(countryCodes) do
            if v == countryCode then
                upstream = div_data["OTHER"]
                break
            end
        end
    end

    return upstream
end


return _M
