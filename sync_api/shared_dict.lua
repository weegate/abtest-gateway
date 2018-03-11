--@data: 2017年12月27日 星期六 15时36分11秒 CST by wuyong
local utils         = require('abtesting.utils.utils')
local cache         = require('abtesting.utils.cache')
local handler	    = require('abtesting.error.handler').handler
local ERRORINFO	    = require('abtesting.error.errcode').info
local log			= require('abtesting.utils.log')
local cjson         = require('cjson.safe')
local systemConf    = require('abtesting.utils.init')

local indices       = systemConf.indices
local fields        = systemConf.fields
local doresp        = utils.doresp
local dolog         = utils.dolog
local doerror       = utils.doerror

local getAllUserInfo = function(runtime)
    local userInfoModname = runtime[fields.userInfoModulename]
    local userInfoMod     = require(userInfoModname)
    -- use abtesting.userinfo.** module get userInfo
    local userInfo        = userInfoMod:getAll()
    return userInfo
end

-- @params[in]: hostname 
-- @description: cache L2(b+tree) -> cache L1(rbtree)
local updateSharedDictFromLmdb = function(hostname)
	local args = {}
	-- 1. update runtime info
	-- set lmdb args from ngx var
	args['dbPath'] = ngx.var.lmdb_path
	args['mapSize'] = tonumber(ngx.var.lmdb_mapsize)
	args['maxDbs'] = tonumber(ngx.var.lmdb_maxdbs)
	args['dbName'] = ngx.var.lmdb_dbname

    local runtimeLmdbCache = cache:new("lmdb",args)
    local divsteps = runtimeLmdbCache:getSteps(hostname)
	if not divsteps then
		error{ERRORINFO.DICT_UPDATE_OP_ERROR, 'divsteps get error from lmdb'}
	end
	local ok, runtimegroup = runtimeLmdbCache:getRuntime(hostname, divsteps)
	if not ok then
		error{ERRORINFO.DICT_UPDATE_OP_ERROR, 'runtime group get error from lmdb'}
	end
	runtimeLmdbCache:close()

	-- set sharedDict args from ngx var
	args['sharedDict'] = ngx.var.sysConfig
    local runtimeCache = cache:new("dict",args)
    ok = runtimeCache:setRuntime(hostname, divsteps, runtimegroup)
	if not ok then
		error{ERRORINFO.DICT_UPDATE_OP_ERROR, 'runtime group get error from lmdb'}
	end

	-- 2. update policy upstream

    local usertable = {}
    for i = 1, divsteps do
        local idx = indices[i]
        local runtime = runtimegroup[idx]
        local info = getAllUserInfo(runtime)

        if info and info ~= '' then
            usertable[idx] = info
        end
    end

	args['dbPath'] = ngx.var.lmdb_path
	args['mapSize'] = tonumber(ngx.var.lmdb_mapsize)
	args['maxDbs'] = tonumber(ngx.var.lmdb_maxdbs)
	args['dbName'] = ngx.var.lmdb_dbname

    local runtimeLmdbCache = cache:new("lmdb",args)
    local upstable = runtimeLmdbCache:getAllUpstream(divsteps, usertable)
	runtimeLmdbCache:close()

	args['sharedDict'] = ngx.var.kv_upstream
    local upstreamCache = cache:new("dict",args)
    for i = 1, divsteps do
        local idx = indices[i]
        local runtime = runtimegroup[idx]
        local infos = usertable[idx]
		for _,info in ipairs(infos) do
			local upstream = upstable[idx][info]
			--ngx.log(ngx.ERR,"idx:"..idx.."\tinfo:"..cjson.encode(info).."\tupstream:"..cjson.encode(upstream))
			if not upstream then
				upstreamCache:setUpstream(info, -1)
				log:info('fetch userinfo [', info, '] from lmdb, get [nil]')
			else
				upstreamCache:setUpstream(info, upstream)
			end
		end
	end

	return "update success!"
end

local getValueByHost = function(hostname)
	local res = {}
	local args = {}
	-- set sharedDict args from ngx var
	args['sharedDict'] = ngx.var.sysConfig
    local runtimeCache = cache:new("dict",args)

	divsteps  = tonumber(runtimeCache:getSteps(hostname))
	if not divsteps then
		error{ERRORINFO.DICT_GET_OP_ERROR, 'divsteps get error from dict'}
	end
	res["divsteps"] = divsteps
	local ok, runtimegroup = runtimeCache:getRuntime(hostname, res["divsteps"])
	if ok then
		res["runtimegroup"] = runtimegroup 
	end

    local usertable = {}
    for i = 1, res["divsteps"] do
        local idx = indices[i]
        local runtime = runtimegroup[idx]
        local info = getAllUserInfo(runtime)

        if info and info ~= '' then
            usertable[idx] = info
        end
    end

	args['sharedDict'] = ngx.var.kv_upstream
    local runtimeCache = cache:new("dict",args)
    res["upstable"] = runtimeCache:getAllUpstream(res["divsteps"], usertable)
	return res
end


local dict_actions = {}
dict_actions["query"] = getValueByHost
dict_actions["update"] = updateSharedDictFromLmdb

local args = ngx.req.get_uri_args()
if args.host then
    local action = ngx.var.action or args.action
	local host = args.host
	ngx.log(ngx.ERR,"host:"..host.." action:"..action)
	if not action or not host or string.len(action)==0 or string.len(host)==0 then
		local response = doresp(ERRORINFO.ACTION_BLANK_ERROR, 'user request params error')
		log:errlog(dolog(ERRORINFO.ACTION_BLANK_ERROR, 'user request params error'))
		ngx.say(response)
	end
    local do_action = dict_actions[action]
    if do_action then
		local pfunc = function() return do_action(host) end
		local status, info = xpcall(pfunc, handler)
		if not status then
			local response = doerror(info)
			ngx.say(response)
		else
			local response = doresp(ERRORINFO.SUCCESS, nil, info)
			log:errlog(dolog(ERRORINFO.SUCCESS, nil))
			ngx.say(response)
		end
    else
		local response = doresp(ERRORINFO.DOACTION_ERROR, 'user request params error,not this action:'..do_action)
		log:errlog(dolog(ERRORINFO.DOACTION_ERROR, 'user request params error,not this action:'..do_action))
		ngx.say(response)
    end
else
	local response = doresp(ERRORINFO.ACTION_BLANK_ERROR, 'user request params error')
	log:errlog(dolog(ERRORINFO.ACTION_BLANK_ERROR, 'user request params error'))
	ngx.say(response)
end


