--@tips: if u use sm function of lmdb api, u can view lmdb.h 
--@data: 2017年12月19日 星期二 15时36分11秒 CST by wuyong
--@todo: dynamic grow mapsize
local modulename = "abtestingLmdb"
local ERRORINFO     = require('abtesting.error.errcode').info
local lightningmdb_lib = require('lightningmdb')
local cjson         = require('cjson.safe')

local _M = {}

_M._VERSION = '0.0.1'

--@param[in] string dbPath default "/data/lmdb/runtime_policy"
--@param[in] number mapSize default 2G
--@param[in] number maxDbs default 4 
--@param[in] string dbName default nil is single db
--@return meta table self module obj
_M.new = function(self,dbPath,mapSize,maxDbs,dbName)
   assert(type(dbPath)=="string")
   assert(type(mapSize)=="number")
   assert(type(maxDbs)=="number")
   dbPath = dbPath or ( not dbPath  and "/data/lmdb/runtime_policy" )
   mapSize = mapSize  or ( (not mapSize or mapSize<=0) and 1024*1024*1024*2 )
   maxDbs = maxDbs  or ( (not maxDbs or maxDbs<=0) and 4 )

   self.db_name = dbName  or ( not dbName and nil )

   self.LMDB = _VERSION>="Lua 5.2" and lightningmdb_lib or lightningmdb
   if not self.LMDB then
      error{ERRORINFO.LMDB_SO_LOAD_ERROR, ' lmdb so lib don\'t include'}
   end

   self.env = self.LMDB.env_create()
   if not self.env then
      error{ERRORINFO.LMDB_OP_CREATE_ERROR, ' please check env'}
   end
   self.env:set_mapsize(mapSize)
   self.env:set_maxdbs(maxDbs)
   opened = self.env:open(dbPath,self.LMDB["MDB_FIXEDMAP"],420)
   if not opened then
      error{ERRORINFO.LMDB_OP_OPEN_ERROR, ' please check the dbPath '..dbPath..' is ok?'}
   end

   return setmetatable(self,{ __index = _M })
end

--@return env stat table
_M.getStat = function(self)
   return self.env:stat()
end

--@param[in] pagesize  dynamic grow map size
--@return true or false
local function growMapSize(pagesize)
   local res = true
   return res
end

--@param[in] cursorHandle cursor_
--@param[in] str key_ 
--@param[in] str op_ 
--@return iterator (yield)
local function cursor_pairs(cursor_,key_,op_)
   return coroutine.wrap(
   function()
      local k = key_
      repeat
         k,v = cursor_:get(k,op_ or MDB.NEXT)
         if k then
            coroutine.yield(k,v)
         end
      until not k
   end)
end

--@return true or false
_M.close = function(self)
   return self.env:close()
end

--@param[in] str hostname nginx server_name(Host)
--@return number diversion steps 
_M.get = function(self, key)
   assert(type(key)=="string")

   local val = nil

   local txn = self.env:txn_begin(nil,0)
   if not txn then
      error{ERRORINFO.LMDB_OP_TXN_ERROR, "txn error"}
   end

   local db_index = txn:dbi_open(self.db_name,0)
   if not db_index then
      error{ERRORINFO.LMDB_OP_DBI_ERROR, "dbi error"}
   end

   val = txn:get(db_index,key)
   if not val then
      error{ERRORINFO.LMDB_OP_READ_ERROR, "db read error"}
   end

   self.env:dbi_close(db_index)

   txn:abort()

   return val
end

--@param[in] str key
--@param[in] string/number val 
--@param[in] number expire default nil,don't delete in db;nothing todo
--@return true or error 
_M.set = function(self, key, val, expire)
   assert(type(key)=="string")

   local res = true

   local txn = self.env:txn_begin(nil,0)
   if not txn then
      error{ERRORINFO.LMDB_OP_TXN_ERROR, "txn error"}
   end

   local db_index = txn:dbi_open(self.db_name,self.LMDB['MDB_CREATE'])
   if not db_index then
      error{ERRORINFO.LMDB_OP_DBI_ERROR, "dbi error"}
   end

   rc = txn:put(db_index,key,val,self.LMDB['MDB_CURRENT'])
   if not rc then
      error{ERRORINFO.LMDB_OP_WRITE_ERROR, "db key:"..key.." val:"..val.." write error"}
   end

   txn:commit()

   self.env:dbi_close(db_index)

   txn:abort()

   return res
end

--@param[in] str key
--@return true or false 
_M.del = function(self, key)
   assert(type(key)=="string")

   local res = false
   local txn = self.env:txn_begin(nil,0)
   if not txn then
      error{ERRORINFO.LMDB_OP_TXN_ERROR, "txn error"}
   end

   local db_index = txn:dbi_open(self.db_name,0)
   if not db_index then
      error{ERRORINFO.LMDB_OP_DBI_ERROR, "dbi error"}
   end

   if txn:del(db_handle,key,val,nil) ~= 0 then
      error{ERRORINFO.LMDB_OP_DEL_ERROR, "dbi error"}
   end

   txn:commit()

   self.env:dbi_close(db_index)

   txn:abort()

   return res
end

return _M
