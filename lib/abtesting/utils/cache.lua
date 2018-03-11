local modulename = "abtestingCache"

local _M = {}
_M._VERSION = '0.0.1'

local cjson = require('cjson.safe')
local ERRORINFO     = require('abtesting.error.errcode').info
local systemConf    = require('abtesting.utils.init')
local LMDB          = require('abtesting.utils.lmdb')

local prefixConf    = systemConf.prefixConf
local runtimeLib    = prefixConf.runtimeInfoPrefix

local indices       = systemConf.indices
local fields        = systemConf.fields

local divConf       = systemConf.divConf
local shdict_expire = divConf.shdict_expire or 60

_M.new = function(self, cacheType, args)
    args = args or ( not args and {} )
    assert(type(cacheType)=="string")

    --ngx.log(ngx.DEBUG,"cacheType:"..cacheType," args:"..cjson.encode(args))

    
    if "lmdb" == cacheType then
        dbPath = args['dbPath'] or ( not args['dbPath'] and "/data/lmdb/runtime_policy" )
        mapSize = args['mapSize']  or ( (not args['mapSize'] or mapSize<=0) and 1024*1024*1024*1 )
        maxDbs = args['maxDbs']  or ( (not args['maxDbs'] or args['maxDbs']<=0) and 4 )
        dbName = args['dbName']

        self.cache = LMDB:new(dbPath,mapSize,maxDbs,dbName)
    else
        if not args['sharedDict'] then
            error{ERRORINFO.ARG_BLANK_ERROR, 'cache name valid from nginx.conf'}
        end
        self.cache = ngx.shared[args['sharedDict']]
        if not self.cache then
            error{ERRORINFO.PARAMETER_ERROR, 'cache name [' .. args['sharedDict'] .. '] valid from nginx.conf'}
        end
    end

    self.cacheType = cacheType

    return setmetatable(self, { __index = _M } )
end

_M.close = function(self)
    if "lmdb" == self.cacheType then
        self.cache:close()
    end
end

local isNULL = function(v)
    return not v or v == ngx.null
end

local areNULL = function(v1, v2, v3)
    if isNULL(v1) or isNULL(v2) or isNULL(v3) then
        return true
    end
    return false 
end

_M.getSteps = function(self, hostname)
    local cache = self.cache
    local k_divsteps    = runtimeLib..':'..hostname..':'..fields.divsteps
    local divsteps      = cache:get(k_divsteps)
    return tonumber(divsteps)
end

_M.getRuntime = function(self, hostname, divsteps)
    local cache = self.cache
    local runtimegroup = {}
    local prefix = runtimeLib .. ':' .. hostname
    for i = 1, divsteps do
        local idx = indices[i]
        local k_divModname      = prefix .. ':'..idx..':'..fields.divModulename
        local k_divDataKey      = prefix .. ':'..idx..':'..fields.divDataKey
        local k_userInfoModname = prefix .. ':'..idx..':'..fields.userInfoModulename

        local divMod, err1        = cache:get(k_divModname)
        local divPolicy, err2     = cache:get(k_divDataKey)
        local userInfoMod, err3   = cache:get(k_userInfoModname)

        if areNULL(divMod, divPolicy, userInfoMod) then
            return false
        end

        local runtime = {}
        runtime[fields.divModulename  ] = divMod
        runtime[fields.divDataKey     ] = divPolicy
        runtime[fields.userInfoModulename] = userInfoMod
        runtimegroup[idx] = runtime
    end

    return true, runtimegroup

end

_M.setRuntime = function(self, hostname, divsteps, runtimegroup)
    local cache = self.cache
    local prefix = runtimeLib .. ':' .. hostname
    local expire = shdict_expire

    local trace_log_info = ''
    for i = 1, divsteps do
        local idx = indices[i]

        local k_divModname      = prefix .. ':'..idx..':'..fields.divModulename
        local k_divDataKey      = prefix .. ':'..idx..':'..fields.divDataKey
        local k_userInfoModname = prefix .. ':'..idx..':'..fields.userInfoModulename

        local runtime = runtimegroup[idx]
        local ok1, err = cache:set(k_divModname, runtime[fields.divModulename], expire)
        local ok2, err = cache:set(k_divDataKey, runtime[fields.divDataKey], expire)
        local ok3, err = cache:set(k_userInfoModname, runtime[fields.userInfoModulename], expire)
        if areNULL(ok1, ok2, ok3) then return false end
        trace_log_info = trace_log_info.."==setRuntimeCacheKeys=["..k_divModname..","..k_divDataKey..","..k_userInfoModname.."]"
    end

    local k_divsteps = prefix ..':'..fields.divsteps
    local ok, err = cache:set(k_divsteps, divsteps, shdict_expire)
    --ngx.log(ngx.DEBUG,trace_log_info.."==setRuntimeCacheKey=["..k_divsteps.."..]")
    if not ok then return false end

    return true
end

_M.getUpstream = function(self, divsteps, usertable)
    local upstable = {}
    local cache = self.cache
    for i = 1, divsteps do
        local idx   = indices[i]
        local info  = usertable[idx]
        -- ups will be an actually value or nil
        if info then
            local ups   = cache:get(info)
            upstable[idx] = ups
        end
    end
    return upstable
end

_M.getAllUpstream = function(self, divsteps, allUsertable)
    local upstable = {}
    local cache = self.cache
    for i = 1, divsteps do
        local idx   = indices[i]
        local infos  = allUsertable[idx]
        -- ups will be an actually value or nil
        if infos then
            local ups = {}
            for key,info in ipairs(infos) do
                upstream = cache:get(info)
                ups[info] = upstream
            end
            upstable[idx] = ups
        end
    end
    return upstable
end

-- notice: info must a unique key for multi runtime policies
_M.setUpstream = function(self, info, upstream)
    local cache  = self.cache
    local expire = shdict_expire
    cache:set(info, upstream, expire)
	--ngx.log(ngx.ERR,"cache_type:\t"..cjson.encode(self.cacheType),"\tkey:"..info.."\tval:"..upstream)
end

return _M
