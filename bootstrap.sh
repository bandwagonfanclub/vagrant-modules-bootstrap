#!/bin/bash

set -e

echo Changes took!

if [[ ! -d /vagrant ]]; then
    echo "There's no /vagrant directory, so I'm nervous you're running"
    echo "the vagrant-modules bootstrapper inside a host environment.  Exiting"
    echo "in a most cowardly fashion."
    exit 1
fi

if ! which jq; then
    apt -qqy update
    apt install -qqy jq
fi

if [[ ! -f /etc/ssh/ssh_known_hosts ]] \
        || ! grep github.com /etc/ss/ssh_known_hosts &> /dev/null; then
    mkdir -p /etc/ssh
    
    KEY=$(curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/meta | jq -r '.ssh_keys[0]')
    echo "Adding github key $KEY"
    
    # Baked-in results of `ssh-keyscan github.com`.
    echo "github.com $KEY" >> /etc/ssh/ssh_known_hosts
fi

# Windows seems to have some issue making ssh-agent available during provision.
# As a workaround, we'll use keys found in /external-keys if they are available.
if ! ssh-add -l &> /dev/null; then
    if ls /external-keys/* &> /dev/null; then
        echo "No ssh-agent!  But it's ok, you gave me some keys.  I'll get"
        echo "that going for you..."

        eval "$(ssh-agent -s)"
        for KEY in /external-keys/*; do
            ssh-add "$KEY"
        done
    else
        echo "No ssh-agent and no keys in /external-keys.  Helplessly"
        echo "failing.  :("
        exit 1
    fi
fi

ABLE_TO_CONNECT_TO_GITHUB=$((ssh -T git@github.com &> /dev/null); echo "$?")
if [[ "$ABLE_TO_CONNECT_TO_GITHUB" -ne "1" ]]; then
    echo "No github key.  See https://bit.ly/2T56TDu ."
    exit 1
fi

cd /home/vagrant
if [[ -d 'vagrant-modules' ]]; then
    echo 'Checking vagrant-modules/v1 for updates...'
    cd 'vagrant-modules'
    git reset --hard HEAD &> /dev/null
    git clean -df &> /dev/null
    git pull &> /dev/null

    if [[ "$?" -ne "0" ]]; then
        echo "Couldn't pull from vagrant modules.  :("
        exit 1
    fi

    cd ..
else
    echo 'Cloning vagrant-modules/v1...'
    git clone \
            -b v1 \
            "git@github.com:bandwagonfanclub/vagrant-modules.git" 2>/dev/null
fi

/bin/bash vagrant-modules/install /home/vagrant/vagrant-modules
