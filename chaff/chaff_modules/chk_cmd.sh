#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
#set spath [lindex $argv 2]
#set ddir [lindex $argv 3]
set timeout 30
spawn scp root@${hostip}:/tmp/qwerasdf /tmp
#spawn scp root@${hostip}:${spath} ${ddir}
expect {
"*yes/no" { send "yes\r"; exp_continue}
"*password:" { send "$passwd\r" }
}
expect eof

