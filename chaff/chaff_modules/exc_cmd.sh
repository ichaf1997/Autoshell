#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
set cmd [lindex $argv 2]
set timeout 1200
spawn ssh ${hostip} 
expect {
"*yes/no" { send "yes\r"; exp_continue}
"*password:" { send "$passwd\r" }
}
expect "root*]#"
send "$cmd\r"
expect "root*]#"
send "echo \$(echo \$?)>/tmp/qwerasdf\r"
expect "root*]#"
send "exit\r"
