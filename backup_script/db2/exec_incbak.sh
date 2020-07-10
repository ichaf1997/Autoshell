#!/bin/bash
export DATE=$(date +%Y%m%d)
export BAK_SAVE_DIR=
export DB_NAME=
export BAK_METHOD=

db2 connect to $DB_NAME
db2 prune logfile prior to $(db2 get db cfg for $DB_NAME | grep "First active " | awk '{print $6}')
db2 backup db $DB_NAME online incremental to $BAK_SAVE_DIR/$BAK_METHOD/$DATE include logs
