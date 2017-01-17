#!/bin/sh
set -e

export NAMESERVERS=$(cat /etc/resolv.conf | grep nameserver | cut -d' ' -f 2 | xargs echo)
confd -onetime -backend env
exec nginx
