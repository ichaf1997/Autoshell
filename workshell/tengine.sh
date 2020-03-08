#!/bin/bash
groupadd -r nginx
useradd -g $(cat /etc/group |grep "nginx"|cut -d ":" -f 3) -M -r -s /sbin/nologin nginx
./configure --user=nginx --group=nginx --with-force-exit --with-http_sub_module
