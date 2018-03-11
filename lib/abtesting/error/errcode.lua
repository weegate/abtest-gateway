local modulename = 'abtestingErrorInfo'
local _M = {}

_M._VERSION = '0.0.1'

_M.info = {
    --	index			    code    desc
    --	SUCCESS
    ["SUCCESS"]			        = { 200,   'success '},
    
    --	System Level ERROR
    ['REDIS_ERROR']		        = { 40101, 'redis error for '},
    ['POLICY_DB_ERROR']		    = { 40102, 'policy in db error '},
    ['RUNTIME_DB_ERROR']	    = { 40103, 'runtime info in db error '},
  
    ['LUA_RUNTIME_ERROR']	    = { 40201, 'lua runtime error '},
    ['BLANK_INFO_ERROR']	    = { 40202, 'errinfo blank in handler '},
    
    --	Service Level ERROR
    --	input or parameter error
    ['PARAMETER_NONE']		    = { 50101, 'expected parameter for '},
    ['PARAMETER_ERROR']		    = { 50102, 'parameter error for '},
    ['PARAMETER_NEEDED']	    = { 50103, 'need parameter for '},
    ['PARAMETER_TYPE_ERROR']	= { 50104, 'parameter type error for '},
    
    --	input policy error
    ['POLICY_INVALID_ERROR']	= { 50201, 'policies invalid for ' },
    
    ['POLICY_BUSY_ERROR']	    = { 50202, 'policy is busy and policyID is ' },
    
    --	redis connect error
    ['REDIS_CONNECT_ERROR']	    = { 50301, 'redis connect error for '},
    ['REDIS_KEEPALIVE_ERROR']   = { 50302, 'redis keepalive error for '},
    
    --	runtime error
    ['POLICY_BLANK_ERROR']	    = { 50401, 'policy contains no data '},
    ['RUNTIME_BLANK_ERROR']     = { 50402, 'expect runtime info for '},
    ['MODULE_BLANK_ERROR']	    = { 50403, 'no required module for '},
    ['USERINFO_BLANK_ERROR']	= { 50404, 'no userinfo fetched from '},

    ['ARG_BLANK_ERROR']	        = { 50405, 'no arg fetched from req '},
    ['ACTION_BLANK_ERROR']	    = { 50406, 'no action fetched from '},

    ['DOACTION_ERROR']	        = { 50501, 'error during action of '},
    
    --  unknown reason
    ['UNKNOWN_ERROR']		    = { 50601, 'unknown reason '},

    -- lmdb op error
    ['LMDB_SO_LOAD_ERROR']      = { 50700, 'lmdb so lib load faild ' },
    ['LMDB_OP_CREATE_ERROR']    = { 50701, 'lmdb create db env faild ' },
    ['LMDB_OP_OPEN_ERROR']      = { 50702, 'lmdb open db faild ' },
    ['LMDB_OP_TXN_ERROR']       = { 50703, 'lmdb transaction faild ' },
    ['LMDB_OP_DBI_ERROR']       = { 50704, 'lmdb open db index faild ' },
    ['LMDB_OP_CURSOR_ERROR']    = { 50705, 'lmdb open db cursor faild ' },
    ['LMDB_OP_WRITE_ERROR']     = { 50710, 'lmdb write/put data faild ' },
    ['LMDB_OP_READ_ERROR']      = { 50711, 'lmdb read/get data faild ' },
    ['LMDB_OP_DEL_ERROR']       = { 50712, 'lmdb delete data faild ' },

    -- shared dict runtime policy error
    ['DICT_UPDATE_OP_ERROR']       = { 50800, 'shared dict update runtime policy error ' },
    ['DICT_GET_OP_ERROR']       = { 50801, 'shared dict get runtime policy error ' },
}


return _M
