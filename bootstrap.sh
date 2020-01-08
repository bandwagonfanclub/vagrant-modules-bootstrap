set -e

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

if [[ -d 'vagrant-modules' ]]; then
    cd 'vagrant-modules'
    git pull &> /dev/null
    cd ..
else
    git clone \
            -b v1 \
            "git@github.com:bandwagonfanclub/vagrant-modules.git"
fi

/bin/bash vagrant-modules/install /home/vagrant/vagrant-modules
