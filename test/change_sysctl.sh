#!/bin/bash
 sudo sysctl -w fs.file-max = 1000000
 sudo sysctl -w net.core.somaxconn=65536
 sudo sysctl -w net.core.netdev_max_backlog=65536
 sudo sysctl -w net.ipv4.tcp_max_tw_buckets=200000
 sudo sysctl -w net.ipv4.tcp_tw_recycle=1
 sudo sysctl -w net.ipv4.tcp_tw_reuse=1
 sudo sysctl -w net.unix.max_dgram_qlen=65536

