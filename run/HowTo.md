### HowToUse
> 依赖
* redis 3.0+
* LMDB 0.9+ (用于本地缓存数据库,[lightningmdb](https://github.com/shmul/lightningmdb.git),编译后的动态链接库so文件放到run文件夹中)
* lua 5.1+（单独运行脚本）
* luajit 2.1+（[bytecode-wiki](http://wiki.luajit.org/Bytecode-2.0)）notice: 尽量利用JIT的特性，避免NYI，热加载后，提高性能
* openresty 1.9+ (集成了lua环境和依赖包)
* [ngx_http_dyups_module](https://github.com/yzprofile/ngx_http_dyups_module)

#### MAC OS for dev (ngx+lua gateway)
> 启动服务(软件通过brew自行安装,最好用源码安装,详见ops/sh/install.sh, 安装到目录/data/openresty/1.11.2.5)

* redis: `sudo redis-server conf/redis.conf`
* 进入run目录,创建logs目录（线上日志目录根据日志收集指定目录而定）`cd  /Users/wuyong/project/nginx_lua/demo-api-gateway/run && mkdir logs`
* FE-UI-server(前端): `sudo /data/openresty/1.11.2.5/bin/openresty -p /Users/wuyong/project/nginx_lua/demo-api-gateway/run -c conf/dev.demo.com.conf`
* gateway-server: `/data/openresty/1.11.2.5/bin/openresty -p /Users/wuyong/project/nginx_lua/demo-api-gateway/run -c conf/gateway_dev.conf`
* gateway-admin(需要切到admin-lua-api分支,或者单独checkout -b admin-lua-api -o 到单独一个分支下启动): `/data/openresty/1.11.2.5/bin/openresty -p /Users/wuyong/project/nginx_lua/demo-api-gateway/run -c conf/dev-admin.gateway.conf`

> 添加一个策略
```
curl "http://127.0.0.1:8080/ab_admin?action=policy_set" -d '{ "divtype": "request_body_countryCode", "divdata": [ { "countryCode": "SG", "upstream": "demo_global_base_api#dayangzhou" }, { "countryCode": "AU", "upstream": "demo_global_base_api#dayangzhou" }, { "countryCode": "TH", "upstream": "demo_global_base_api#dayangzhou" }, { "countryCode": "US", "upstream": "demo_global_base_api#beimeizhou" }, { "countryCode": "GB", "upstream": "demo_global_base_api#ouzhou" }, { "countryCode": "ES", "upstream": "demo_global_base_api#ouzhou" } ] }'
```

> 添加一个策略组
```
curl "http://127.0.0.1:8080/ab_admin?action=policygroup_set" -d '{"1":{"divtype":"uidsuffix","divdata":[{"suffix":"1","upstream":"beta1"},{"suffix":"3","upstream":"beta2"},{"suffix":"5","upstream":"beta1"},{"suffix":"0","upstream":"beta3"}]},"2":{"divtype":"arg_city","divdata":[{"city":"BJ","upstream":"beta1"},{"city":"SH","upstream":"beta2"},{"city":"XA","upstream":"beta1"},{"city":"HZ","upstream":"beta3"}]},"3":{"divtype":"iprange","divdata":[{"range":{"start":1111,"end":2222},"upstream":"beta1"},{"range":{"start":3333,"end":4444},"upstream":"beta2"},{"range":{"start":7777,"end":2130706433},"upstream":"beta2"}]}}'
```

> 设置运行的策略
`curl "http://127.0.0.1:8080/ab_admin?action=runtime_set&hostname=dev.one.demo.com&policyid=0"`

> 根据countryCode分流
`curl -XPOST "http://127.0.0.1?a=1&foo=123123&countryCode=SG" -H "Host: demoapi-dev.demo.com" -d "countryCode=SG" -d "ccc=123"`
`curl -XPOST "http://127.0.0.1:4321?a=1&foo=123123&countryCode=SG" -H "Host: dev.one.demo.com" -d "countryCode=SG" -d "ccc=123"`

#### CentOS for product/qa (ngx+lua gateway)
> 启动服务
* redis: 已有的测试redis环境(`redis-cli -h 172.0.0.1 -p 2010 -a MKL7cOEehQf8aoIBtHxs -n 1`)
* FE-UI-server(前端): `cd /usr/local/webserver/tengine/conf/ && sudo ../sbin/nginx`
* gateway-server: `/data/openresty/1.11.2.5/nginx/sbin/nginx -p /home/www/gateway/demo-api-gateway/utils -c conf/gateway_qa.conf`
* gateway-admin: `/data/openresty/1.11.2.5/nginx/sbin/nginx -p /home/www/gateway/demo-api-gateway/utils -c conf/qa-admin.gateway.conf`

> 其他策略添加、运行方式一样，需要修改成添加的ip/host

#### bakend upstream 
> 可以直连线上/测试已有app服务进行开发测试（nodejs 2500)

