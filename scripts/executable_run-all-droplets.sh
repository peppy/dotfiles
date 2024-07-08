#!/bin/bash
# run a command on all droplets

for droplet in `doctl compute droplet list --format Name --no-header`
do
    echo -e ""
    echo -e "Running command \033[93m$1\033[39m on \033[96m$droplet\033[39m"
    doctl compute ssh $droplet -o ConnectTimeout=10 --ssh-command "$1"
done
