#!/bin/bash

if [[-f /root/completed ]]; then
  echo "Firstboot completed earlier"
  exit
fi

service ssh restart
echo "Ssh service restarted"

touch /root/completed
