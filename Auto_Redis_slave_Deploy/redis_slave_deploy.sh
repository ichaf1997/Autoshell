#!/bin/bash
# This script will create redis slave from redis master automatically 
# Usage:
# Step 1 : Set variables in redis.ini depend on your enviroment
# Step 2 : Run $0 
# Notice : Please run this script in your personal host instead of master or slave .

# Check configuration 
[ ! -e "$(pwd)/redis.ini" ] && echo "$(pwd)/redis.ini is needed" && exit 1
[ -z "$MASTER_CONF_PATH" ] && MASTER_CONF_PATH=/etc/redis.conf

