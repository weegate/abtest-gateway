#!/bin/bash
h="10.5.27.238:4321"
cc=(10 100 1000)
cc=(10)
t=8
d=10
for c in ${cc[@]};do
	echo -e "并发数：${c}\n"
	for i in `seq 1 10`;do
		echo -e " wrk -c${c} -t${t} -d${d}s --latency  -s wrk_post.lua 'http://${h}/abc'\n";
		wrk -c${c} -t${t} -d${d}s --latency -s wrk_post.lua "http://${h}/abc" ;
	done
done
