#!/bin/bash
# for centos & for ops user
[ "x`whoami`" != "xops" ] && echo "need ops user to do~!" && exit
which g++
[ $? -eq 1 ] && echo "y" | sudo yum install gcc-c++
which git
[ $? -eq 1 ] && echo "y" | sudo yum install git

mkdir -p ~/opt

#OR && Tengine 
if [ ! -d /data/openresty ] || [ ! -d /usr/local/webserver/tengine ]; then
   cd ~/opt
   wget https://openresty.org/download/openresty-1.11.2.5.tar.gz
   wget http://tengine.taobao.org/download/tengine-2.2.0.tar.gz
   wget https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz
   wget http://zlib.net/fossils/zlib-1.2.11.tar.gz
   wget https://www.openssl.org/source/openssl-1.0.2l.tar.gz

   git clone https://github.com/yzprofile/ngx_http_dyups_module.git
   git clone https://github.com/cubicdaiya/ngx_dynamic_upstream.git

   tar zxvf openresty-1.11.2.5.tar.gz && rm openresty-1.11.2.5.tar.gz
   tar zxvf tengine-2.2.0.tar.gz && rm tengine-2.2.0.tar.gz
   tar zxvf pcre-8.41.tar.gz && rm pcre-8.41.tar.gz
   tar zxvf openssl-1.0.2l.tar.gz && openssl-1.0.2l.tar.gz
   tar zxvf zlib-1.2.11.tar.gz && zlib-1.2.11.tar.gz

   if [ ! -d /data/openresty ]; then
      cd  ~/opt/openresty-1.11.2.5

      ./configure \
         --prefix=/data/openresty/1.11.2.5 \
         --with-pcre=../pcre-8.41/ \
         --with-openssl=../openssl-1.0.2l/ \
         --with-zlib=../zlib-1.2.11/ \
         --add-module=../ngx_http_dyups_module \
         --add-module=../ngx_dynamic_upstream 

      make && sudo make install
      sudo chown -R www:www /data/openresty
   fi

   if [ ! -d /usr/local/webserver/tengine ]; then
      cd  ~/opt/tengine-2.2.0

      echo "y" | sudo yum install lua-devel.x86_64
      echo "y" | sudo yum install luajit-devel.x86_64
      echo "y" | sudo yum install postgresql-devel.x86_64
      ./configure \
         --prefix=/usr/local/webserver/tengine \
         --with-pcre=../pcre-8.41/ \
         --with-openssl=../openssl-1.0.2l/ \
         --with-zlib=../zlib-1.2.11/ \
         --with-http_lua_module \
         --add-module=../ngx_http_dyups_module \
         --add-module=../openresty-1.11.2.5/bundle/ngx_devel_kit-0.3.0 \
         --add-module=../openresty-1.11.2.5/bundle/headers-more-nginx-module-0.32 \
         --add-module=../openresty-1.11.2.5/bundle/rds-json-nginx-module-0.14 \
         --add-module=../openresty-1.11.2.5/bundle/ngx_coolkit-0.2rc3 \
         --add-module=../openresty-1.11.2.5/bundle/memc-nginx-module-0.18 \
         --add-module=../openresty-1.11.2.5/bundle/echo-nginx-module-0.61 \
         --add-module=../openresty-1.11.2.5/bundle/redis-nginx-module-0.3.7 \
         --add-module=../openresty-1.11.2.5/bundle/encrypted-session-nginx-module-0.06 \
         --add-module=../openresty-1.11.2.5/bundle/form-input-nginx-module-0.12 \
         --add-module=../openresty-1.11.2.5/bundle/array-var-nginx-module-0.05 \
         --add-module=../openresty-1.11.2.5/bundle/iconv-nginx-module-0.14 \
         --add-module=../openresty-1.11.2.5/bundle/rds-csv-nginx-module-0.07 \
         --add-module=../openresty-1.11.2.5/bundle/xss-nginx-module-0.05 \
         --add-module=../openresty-1.11.2.5/bundle/redis2-nginx-module-0.14 \
         --add-module=../openresty-1.11.2.5/bundle/set-misc-nginx-module-0.31 \
         --add-module=../openresty-1.11.2.5/bundle/srcache-nginx-module-0.31 \
         --add-module=../openresty-1.11.2.5/bundle/ngx_lua_upstream-0.07 \
         --add-module=../openresty-1.11.2.5/bundle/ngx_postgres-1.0 


      make && sudo make install
      sudo chown -R www:www /usr/local/webserver/tengine
   fi
fi

# node 6.5.0 (need g++ 4.8+)
if [ ! -d /usr/local/webserver/node-6.5.0/ ]; then
   cd ~/opt
   g++_version=`g++ --version | grep "4.8"`
   if [ "x$g++_version" != "x" ]; then
      wget https://nodejs.org/dist/v6.5.0/node-v6.5.0-linux-x64.tar.gz
      tar zxvf node-v6.5.0-linux-x64.tar.gz
      sudo mkdir -p /usr/local/webserver/node-6.5.0
      sudo cp -r node-v6.5.0-linux-x64/*  /usr/local/webserver/node-6.5.0
   else
      wget https://nodejs.org/dist/v6.5.0/node-v6.5.0.tar.gz
      tar zxvf node-v6.5.0.tar.gz
      cd node-v6.5.0
      ./configure --prefix=/usr/local/webserver/node-6.5.0/
      make && sudo make install
   fi
   sudo chown -R www:www /usr/local/webserver/

   echo "PATH=\$PATH:/usr/local/webserver/node-6.5.0/bin
   export PATH
   export NODE_ENV=production">node.sh
   sudo mv node.sh /etc/profile.d/node.sh
fi

#golang
if [ ! -d /usr/local/go/ ]; then
   cd ~/opt
   #src install
   #wget https://redirector.gvt1.com/edgedl/go/go1.9.2.src.tar.gz
   #wget https://storage.googleapis.com/golang/go1.4-bootstrap-20170531.tar.gz
   #tar zxvf go1.4-bootstrap-20170531.tar.gz
   #tar zxvf go1.9.2.src.tar.gz

   #install golang bin
   wget https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz
   tar zxvf go1.9.2.linux-amd64.tar.gz
   sudo mv go /usr/local
   sudo chown -R www:www /usr/local/go/

   echo "export GOROOT=/usr/local/go
   export PATH=\$GOROOT/bin:\$PATH">go.sh
   sudo mv go.sh /etc/profile.d/go.sh
fi

#log
sudo mkdir -p /data/logs/gateway
sudo chown -R www:www /data/logs/

#lmdb
cd ~/opt
git clone https://github.com/LMDB/lmdb
cd lmdb/libraries/liblmdb/
make && sudo make install
#lua lmdb
cd ~/opt
echo "export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH">init.sh
sudo mv init.sh /etc/profile.d/init.sh
git clone https://github.com/shmul/lightningmdb.git
cd lightningmdb
make && sudo cp lightningmdb.so /home/www/gateway/demo-api-gateway/run/



