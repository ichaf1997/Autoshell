#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
set timeout 15

spawn ssh-keygen -t rsa
expect "(/root/.ssh/id_rsa):"
send "\r"
expect "empty"
send "\r"
expect "again"
send "\r"
send "echo $?\r"
expect eof
catch wait res
exit [lindex $res 3]
