#!/bin/bash

set -e

GITHUB_PUBLIC_KEY="AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="

if [[ ! -d /vagrant ]]; then
    echo "There's no /vagrant directory, so I'm nervous you're running"
    echo "the vagrant-modules bootstrapper inside a host environment.  Exiting"
    echo "in a most cowardly fashion."
    exit 1
fi

if [[ ! -f /etc/ssh/ssh_known_hosts ]] \
        || ! grep github.com /etc/ss/ssh_known_hosts &> /dev/null; then
    mkdir -p /etc/ssh
    
    # Baked-in results of `ssh-keyscan github.com`.
    echo 'github.com ssh-rsa $GITHUB_PUBLIC_KEY' > /etc/ssh/ssh_known_hosts
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
