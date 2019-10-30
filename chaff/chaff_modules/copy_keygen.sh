#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
set timeout 30
spawn ssh-copy-id ${hostip}
#spawn ssh ${hostip}
expect {
"*yes/no" { send "yes\r"; exp_continue}
"*password:" { send "$passwd\r"}
#"~]#" {send "\r"}
}
send "echo $?\r"
expect eof
catch wait res
exit [lindex $res 3]
