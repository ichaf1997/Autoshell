#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
#set user [lindex $argv 2]
set mapping [lindex $argv 2]
set file [lindex $argv 3]
set timeout 300
spawn scp -r ${file} root@${hostip}:${mapping}
expect {
"*yes/no" { send "yes\r"; exp_continue}
"*password:" { send "$passwd\r"}
}
send "echo $?\r"
#interact
expect eof
catch wait res
exit [lindex $res 3]
