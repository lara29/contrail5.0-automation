settings = {
logfile = "/var/log/lsyncd.log",
statusFile = "/var/log/lsyncd-status.log"
}
sync{
default.rsyncssh,
delete = false,
insist,
source="/var/www/html",
host="",
targetdir="/var/www/html",
rsync = {
archive = true,
perms = true,
owner = true,
_extra = {"-a"},
},
delay = 5,
maxProcesses = 4,
ssh = {
port = 22
}
}
