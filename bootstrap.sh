#!/bin/bash

set -e

GITHUB_PUBLIC_KEY='AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk='

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
    echo "github.com ssh-rsa $GITHUB_PUBLIC_KEY" >> /etc/ssh/ssh_known_hosts
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
