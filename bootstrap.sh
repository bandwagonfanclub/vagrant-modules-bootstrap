set -e

if [[ ! -d /vagrant ]]; then
    echo "There's no /vagrant directory, so I'm nervous you're running"
    echo "the vagrant-modules bootstrapper inside a host environment.  Exiting"
    echo "in a most cowardly fashion."
    exit 1
fi

if [[ ! -f /etc/ssh/ssh_known_hosts ]] \
        || ! grep github.com /etc/ss/ssh_known_hosts &> /dev/null; then
    mkdir -p /etc/ssh
    ssh-keyscan github.com > /etc/ssh/ssh_known_hosts 2> /dev/null
    if [[ "$?" -ne "0" ]]; then
        echo "Couldn't keyscan github?  Try again later?"
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
    git pull &> /dev/null
    cd ..
else
    echo 'Cloning vagrant-modules/v1...'
    git clone \
            -b v1 \
            "git@github.com:bandwagonfanclub/vagrant-modules.git" 2>/dev/null
fi

/bin/bash vagrant-modules/install /home/vagrant/vagrant-modules
