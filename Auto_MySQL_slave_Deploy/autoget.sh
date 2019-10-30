#!/usr/bin/expect
set hostip [lindex $argv 0]
set passwd [lindex $argv 1]
set user [lindex $argv 2]
set mapping [lindex $argv 3]
set file [lindex $argv 4]
set timeout 5
spawn scp -r ${user}@${hostip}:${file} ${mapping}
expect {
"*yes/no" { send "yes\r"; exp_continue}
"*password:" { send "$passwd\r" }
}
expect eof

