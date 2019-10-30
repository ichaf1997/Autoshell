#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
set user [lindex $argv 2]
set mapping [lindex $argv 3]
set conf [lindex $argv 4]
set sqluser [lindex $argv 5]
set sqlpasswd [lindex $argv 6]
set timeout -1
spawn ssh ${user}@${hostip}
expect {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "$passwd\r" }
}
expect "]*"
send "cd ${mapping}\r"
expect "]*"
send "./innobackupex --defaults-file=${conf} --user=${sqluser} --password=${sqlpasswd} --stream=tar /tmp | gzip >/tmp/xtra_fullbak.tar.gz \r"
expect "]#"
send "exit\r"
expect eof
