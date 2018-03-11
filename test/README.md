## 测试记录
> watch
* 监听网络状态：watch -n 1 "netstat -n | awk '/^tcp/ {++S[\$NF]} END {for(a in S) print a, S[a]}'" 
* 监听cpu负载，tcp协议传输，io负载等：tsar -l -i 1 (tsar是sar升级版,可以自定义监听选项)
* 监听io负载：iostat -d -x -k 1

### 压测环境(server)
> dev_env: (sysctl -a machdep.cpu)  本地环境压测。。。。。（仅参考，本身开了其他服务，有cpu时间片的切换）
* OS: Mac DRAW（UNIX)
* CPU：8*Intel(R) Core(TM) i7-4770HQ CPU @ 2.20GHz

> qa_env:(sysctl -a machdep.cpu)
* OS: LINUX
* CPU: 4*Intel(R) Xeon(R) CPU E5-2682 v4 @ 2.50GHz

### 操作
> 开启lua cache 热加载(luaJIT)
> 利用缓存这个银弹，提高并发性能，网络优化调整系统建立和断开连接时的net相关参数，
* 一层结构：(运行时策略数据通过接口直接写入本地redis中,本地redis中的内存数据结构选做缓存策略，万金油好用，但是本地内存/磁盘有限，不方便扩展)
	* L1(redis string,hash,list,set,zset; redis本地缓存) or L1(lmdb (B+Tree)，mmap 本地持久化缓存) or L1(shared dict (rbTree), LRU 本地内存中)
* 两层结构：(tradeoff HA vs performance)
	* 方案1: L2(redis string,hash,list,set,zset; 远端缓存) -> L1(shared dict (rbTree), LRU 本地内存中)
	* 方案2: L2(redis string,hash,list,set,zset; 远端缓存) -> L1(lmdb (B+Tree)，mmap 本地持久化缓存,一致性考虑,都ok了才是真的ok)
* 三层结构:（中间加入本地持久化，即使redis策略挂了后，保证本地运行时策略还可以正常执行,性能可以通过本地缓存保证)
	* L3 (redis string,hash,list,set,zset; 远端缓存,数据结构比较多，适合存放运行时策略数据) -> L2(lmdb (B+Tree)，mmap 本地持久化缓存,一致性考虑,都ok了才是真的ok) -> L1(shared dict (rbTree), LRU 本地内存中)


### 简单测试
> 直接走nginx的proxy_pass `wrk -c1000 -t4 -d20s --latency -s wrk_post.lua 'http://10.5.27.238:8181/abc'`
```
Running 20s test @ http://10.5.27.238:8181/abc
  4 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    86.69ms   11.78ms   1.10s    78.15%
    Req/Sec     2.87k   330.88     3.87k    69.38%
  Latency Distribution
     50%   85.91ms
     75%   92.09ms
     90%   99.46ms
     99%  116.81ms
  228498 requests in 20.01s, 42.48MB read
Requests/sec:  11416.44
Transfer/sec:      2.12MB
```
> 直接请求到对应服务 `wrk -c1000 -t4 -d20s --latency -s wrk_post.lua 'http://10.5.27.238:8020/abc'`
```
Running 20s test @ http://10.5.27.238:8020/abc
  4 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    54.29ms    4.67ms  80.66ms   85.50%
    Req/Sec     4.62k   391.14     5.05k    80.75%
  Latency Distribution
     50%   52.61ms
     75%   53.49ms
     90%   63.92ms
     99%   69.29ms
  367883 requests in 20.01s, 78.24MB read
Requests/sec:  18383.45
Transfer/sec:      3.91MB
```
> 通过策略网关分流 `wrk -c1000 -t4 -d20s --latency -s wrk_post.lua 'http://10.5.27.238:4321/abc'`
* 行时策略都在L1(shared dict)缓存中
```
Running 20s test @ http://10.5.27.238:4321/abc
  4 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   111.76ms   11.26ms 197.95ms   79.71%
    Req/Sec     2.24k   204.80     2.80k    72.00%
  Latency Distribution
     50%  109.85ms
     75%  116.00ms
     90%  125.24ms
     99%  145.43ms
  178393 requests in 20.02s, 33.17MB read
Requests/sec:   8911.53
Transfer/sec:      1.66MB
```
* 行时策略都在L1(lmdb)缓存中(待优化，用一个打开索引文件句柄池handlerPool,缓存打开的句柄,以便重复利用,避免过多的io)
```
Running 20s test @ http://10.5.27.238:4321/abc
  4 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   295.43ms   96.59ms 720.15ms   66.11%
    Req/Sec   846.26    268.61     1.80k    68.22%
  Latency Distribution
     50%  308.52ms
     75%  325.22ms
     90%  386.62ms
     99%  613.92ms
  67139 requests in 20.02s, 12.48MB read
Requests/sec:   3353.81
Transfer/sec:    638.63KB
```





