#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
set user [lindex $argv 2]
set mapping [lindex $argv 3]
set sqluser [lindex $argv 4]
set sqlpasswd [lindex $argv 5]
set timeout -1
spawn ssh ${user}@${hostip}
expect {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "$passwd\r" }
}
expect "]*"
send "${mapping}/bin/mysqldump -u${sqluser} -p${sqlpasswd} --all-databases --master-data --single-transaction |gzip > /tmp/dump_fullbak.sql.gz\r"
expect "]*"
send "exit\r"
expect eof

