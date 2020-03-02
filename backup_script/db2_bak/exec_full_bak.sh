#!/bin/bash
export LANG=en_US.UTF-8
export BAK_SAVE_DIR=/data002/backup    
export DB_NAME=rmis_dg     
echo "$(date +%Y.%m.%d\ %T\ %a) - [info] execute db2 connect to $DB_NAME" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
db2 connect to $DB_NAME >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log 
echo "$(date +%Y.%m.%d\ %T\ %a) - [info] execute db2 prune logfile prior to $(db2 get db cfg for $DB_NAME | grep "First active " | awk '{print $6}')" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
db2 prune logfile prior to $(db2 get db cfg for $DB_NAME | grep "First active " | awk '{print $6}') >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log 
echo "$(date +%Y.%m.%d\ %T\ %a) - [info] execute db2 backup db $DB_NAME online to $BAK_SAVE_DIR/full/$(date +%Y%m%d) include logs" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
db2 backup db $DB_NAME online to $BAK_SAVE_DIR/full/$(date +%Y%m%d) include logs >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log 
