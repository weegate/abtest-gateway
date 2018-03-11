#!/bin/bash
# for www user to run
#todo: use start/stop/reload params to run

[ "x`whoami`" != "xwww" ] && echo "need www user to do~!" && exit

cmd=`which pm2`
if [ "x${cmd}" == "x" ]; then
   export PATH=$PATH:/usr/local/webserver/node-6.5.0/bin
   /usr/local/webserver/node-6.5.0/bin/npm install pm2 -g
fi

ngx_lua_gateway(){
   # run nginx+lua gateway
   cd /home/www/gateway/demo-api-gateway/run
   mkdir -p /data/logs/gateway/demo-api-gateway
   [ ! -s /home/www/gateway/demo-api-gateway/run/logs ] && ln -s /data/logs/gateway/demo-api-gateway /home/www/gateway/demo-api-gateway/run/logs
   rm *temp -rf

   # run gateway.conf for dev to test
   pid=`cat /home/www/gateway/demo-api-gateway/run/logs/nginx_qa_gateway.pid`
   run_pid=`ps -ef | grep $pid | grep -v grep`
   if [ "x$run_pid" == "x" ]; then
      /data/openresty/1.11.2.5/nginx/sbin/nginx -p /home/www/gateway/demo-api-gateway/run -c conf/gateway_qa.conf
   else
      /data/openresty/1.11.2.5/nginx/sbin/nginx -p /home/www/gateway/demo-api-gateway/run -c conf/gateway_qa.conf -s reload 
   fi
}

golang_gateway(){
   # use pm2 to run golang gateway
   # run dev
   pm2 show demo-api-gateway
   if [ $? -eq 1 ]; then
      cd ~/gateway/demo-api-gateway 
      GIN_MODE=release pm2 start ./demo-api-gateway.dev --kill-timeout 6000 -- -c ./dev.yaml
   else
      pm2 reload demo-api-gateway
   fi
}

global_demoapi(){
   #run app service
   #cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
   #cat /proc/cpuinfo| grep "cpu cores"| uniq
   #cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
   # use pm2 to load app
   processor_num=`cat /proc/cpuinfo| grep "processor"| wc -l`
   cd /home/www/demoapi-international
   pm2 show demoapi
   if [ $? -eq 1 ]; then
      NODE_PATH=. pm2 start index.js --merge-logs -l logs/demoapi.log --name demoapi -i $processor_num -o /dev/null
   else
      pm2 reload demoapi
   fi
}

run(){
   if [ "x$1" == "xglobal_demoapi" ];then
      global_demoapi
   fi
   if [ "x$1" == "xgolang_gateway" ];then
      golang_gateway
   fi
   if [ "x$1" == "xngx_lua_gateway" ];then
      ngx_lua_gateway
   fi
   if [ "x$1" == "x" ];then
      ngx_lua_gateway
      golang_gateway
      global_demoapi
   fi
}

run $1

