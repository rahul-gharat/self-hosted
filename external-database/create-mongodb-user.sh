#!/usr/bin/env bash

# NB: local trial script has to be self-contained
# See https://sipb.mit.edu/doc/safe-shell/
set -euf -o pipefail

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  export MAYBE_SUDO="sudo"
else
  export MAYBE_SUDO=""
fi

if [ -t 1 ]; then
  export NORMAL="$(tput sgr0)"
  export RED="$(tput setaf 1)"
  export GREEN="$(tput setaf 2)"
  export MAGENTA="$(tput setaf 5)"
  export CYAN="$(tput setaf 6)"
  export WHITE="$(tput setaf 7)"
  export BOLD="$(tput bold)"
else
  export NORMAL=""
  export RED=""
  export GREEN=""
  export MAGENTA=""
  export CYAN=""
  export WHITE=""
  export BOLD=""
fi

error_exit() {
  echo ''
  echo "${RED}${BOLD}ERROR${NORMAL}${BOLD}: $1${NORMAL}"
  shift
  while [ "$#" -gt "0" ]; do
    echo " - $1"
    shift
  done
  exit 1
}

log_step() {
  echo ''
  echo "${GREEN}${BOLD}INFO${NORMAL}${BOLD}: $1${NORMAL}"
  shift
  while [ "$#" -gt "0" ]; do
    echo " - $1"
    shift
  done
}

log_warn() {
  echo ''
  echo "${CYAN}${BOLD}WARNING${NORMAL}${BOLD}: $1${NORMAL}"
  shift
  while [ "$#" -gt "0" ]; do
    echo " - $1"
    shift
  done
}

export DISTRO=$( (lsb_release -ds || cat /etc/*release || uname -om) 2>/dev/null | head -n1)

command_present() {
  type "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------------------------

echo ""
echo "Enter credentials of your MONGODB server"
echo ""

read -p "Enter database host : " mongohost
read -p "Enter port number": mongoport
read -p "Enter admin username : " mongouser
read -p "Enter admin password : " mongopassword
echo ""

# ------------------------------------------------------------------------------------------------

echo "Create new credentials for Application User"
echo ""
read -p "Enter username : " username
read -p "Enter password : " userpassword
echo ""

# ------------------------------------------------------------------------------------------------

if ! command_present mongosh; then
    log_step "mongodb database tools not present. downloading it."
    $MAYBE_SUDO chmod 755 install-mongosh.sh
    ./install-mongosh.sh
    echo ''
fi

# ------------------------------------------------------------------------------------------------

read -p "Are you using DocumentDB with SSL? (y/n):" isSsl
if [[ "$isSsl" == "y" ]]; then
    read -p "Enter SSL file name:" tlskey
    mongosh --ssl --host $mongohost:$mongoport --username $mongouser --password $mongopassword --sslCAFile=$tlskey <<EOF
    use admin
    db.createUser({
        user: '$username',
        pwd: '$userpassword',
        roles: [
            {
                role: "userAdminAnyDatabase",
                db: "admin"
            }, {
                role: 'readWrite',
                db: 'db5x_studio'
            }
        ]
    })
EOF
else
    mongosh --host $mongohost:$mongoport --username $mongouser --password $mongopassword <<EOF
    use admin
    db.createUser({
        user: '$username',
        pwd: '$userpassword',
        roles: [
            {
                role: "userAdminAnyDatabase",
                db: "admin"
            }, {
                role: 'readWrite',
                db: 'db5x_studio'
            }
        ]
    })
EOF

fi
echo ''
sleep 300

# ------------------------------------------------------------------------------------------------

log_step "Database user created for MYSQL and MongoDB."
