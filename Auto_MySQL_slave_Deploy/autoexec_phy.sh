#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
set user [lindex $argv 2]
set mapping [lindex $argv 3]
set data [lindex $argv 4]
set timeout -1
spawn ssh ${user}@${hostip}
expect {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "$passwd\r" }
}
expect "]*"
send "cd ${mapping}\r"
expect "]*"
send "cd ..\r"
expect "]*"
send "tar -czvf phy_fullbak.tar.gz ${data}\r"
expect "]*"
send "mv phy_fullbak.tar.gz /tmp/\r"
expect "]*"
send "exit\r"
expect eof

