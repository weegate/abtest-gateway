#!/bin/bash
#deploy for www user to test
#todo rsync  to deploy for www user

[ "x`whoami`" != "xwww" ] && echo "need www user to do~!" && exit

#deploy gateway for test
mkdir -p /home/www/gateway

#ngx+lua gateway
if [ -d /home/www/gateway/demo-api-gateway ]; then
   cd /home/www/gateway/demo-api-gateway
   git pull origin master 
else
   cd /home/www/gateway
    git clone git@demordcode.demo.so:global_backend/demo-api-gateway.git 
fi

#deploy go gateway for test to build binary execute file; online don't use
mkdir -p /home/www/go/src
mkdir -p /home/www/go/pkg

if [ -d /home/www/go/src/demo-api-gateway ]; then
   cd /home/www/go/src/demo-api-gateway
   mv bin/demo-api-gateway bin/demo-api-gateway.back
   git pull origin master 
else
   cd /home/www/go/src
   git clone git@demordcode.demo.so:baseservice/demo-api-gateway.git

   gopath=`echo $GOPATH`
   if [ "x${gopath}" == "x" ]; then
      echo "
      export GOPATH=\$HOME/go
      export PATH=\$GOPATH/bin:\$PATH
      " >> /home/www/.bash_profile
      source /home/www/.bash_profile
      export GOPATH=$HOME/go
      export PATH=$GOPATH/bin:$PATH
   fi
fi
cd /home/www/go/src/demo-api-gateway
#just local build to gen execute file for test
sh build.sh
mkdir -p /data/logs/gateway/demo-api-gateway
[ ! -s ~/go/src/demo-api-gateway/bin/logs ] && ln -s /data/logs/gateway/demo-api-gateway ~/go/src/demo-api-gateway/bin/logs
[ ! -s ~/gateway/demo-api-gateway ] && ln -s ~/go/src/demo-api-gateway/bin ~/gateway/demo-api-gateway

#deploy app service
if [ -d /home/www/demoapi-international ]; then
   cd /home/www/demoapi-international
   git pull origin master 
else
   cd /home/www
   git clone git@demordcode.demo.so:backend/demoapi-international.git
fi
cd /home/www/demoapi-international
npm install


